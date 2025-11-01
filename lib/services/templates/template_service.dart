import 'dart:convert';
import 'dart:io';
import '../../models/templates/document_template.dart';
import '../../models/templates/template_category.dart';
import '../../models/documents/document_content.dart';
import 'template_repository.dart';
import 'template_variable_service.dart';
import 'prebuilt_templates.dart';

abstract class TemplateService {
  // Template CRUD
  Future<DocumentTemplate> createTemplate(
    DocumentContent document,
    String name,
    String description,
    TemplateCategory category,
  );
  
  Future<DocumentTemplate> getTemplate(String templateId);
  Future<List<DocumentTemplate>> getAllTemplates({
    TemplateCategory? category,
    List<String>? tags,
    String? searchQuery,
  });
  
  Future<void> updateTemplate(DocumentTemplate template);
  Future<void> deleteTemplate(String templateId);
  
  // Template instantiation
  Future<DocumentContent> instantiateTemplate(
    String templateId,
    Map<String, String> variableValues,
  );
  
  // Template metadata
  Future<void> updateTemplateUsage(String templateId);
  Future<void> addTemplateRating(String templateId, double rating);
  
  // Pre-built templates
  Future<List<DocumentTemplate>> getPreBuiltTemplates();
  Future<DocumentTemplate?> getPreBuiltTemplate(TemplateCategory category);
  
  // Import/Export
  Future<void> exportTemplate(String templateId, String filePath);
  Future<DocumentTemplate> importTemplate(String filePath);
  
}

class TemplateServiceImpl implements TemplateService {
  final TemplateRepository _repository;
  final TemplateVariableService _variableService;
  
  // Usage tracking
  final Map<String, int> _usageCounts = {};
  final Map<String, List<double>> _ratings = {};
  
  TemplateServiceImpl({
    required TemplateRepository repository,
    TemplateVariableService? variableService,
  }) : _repository = repository,
       _variableService = variableService ?? TemplateVariableService();
  
  @override
  Future<DocumentTemplate> createTemplate(
    DocumentContent document,
    String name,
    String description,
    TemplateCategory category,
  ) async {
    // Extract variables from document
    final variables = _variableService.extractVariables(document);
    
    // Create template
    final template = DocumentTemplate.fromDocument(
      document,
      name,
      description,
      category,
      variables: variables,
      authorId: 'current_user', // TODO: Get from user service
      authorName: 'User', // TODO: Get from user service
    );
    
    // Save template
    await _repository.saveTemplate(template);
    
    return template;
  }
  
  @override
  Future<DocumentTemplate> getTemplate(String templateId) async {
    // Check if it's a pre-built template
    if (templateId.startsWith('prebuilt_')) {
      final prebuilt = await PrebuiltTemplateFactory.getTemplateByIdStatic(templateId);
      if (prebuilt != null) {
        return prebuilt;
      }
    }
    
    // Load from repository
    return await _repository.loadTemplate(templateId);
  }
  
  @override
  Future<List<DocumentTemplate>> getAllTemplates({
    TemplateCategory? category,
    List<String>? tags,
    String? searchQuery,
  }) async {
    // Load user templates
    final userTemplates = await _repository.loadAllTemplates(
      category: category,
      tags: tags,
      searchQuery: searchQuery,
    );
    
    // Load pre-built templates (if no category filter or category matches)
    final prebuiltTemplates = await getPreBuiltTemplates();
    final filteredPrebuilt = category == null
      ? prebuiltTemplates
      : prebuiltTemplates.where((t) => t.category == category).toList();
    
    // Combine and sort by name
    final allTemplates = [...filteredPrebuilt, ...userTemplates];
    allTemplates.sort((a, b) => a.name.compareTo(b.name));
    
    return allTemplates;
  }
  
  @override
  Future<void> updateTemplate(DocumentTemplate template) async {
    final updatedTemplate = template.updateModified();
    await _repository.saveTemplate(updatedTemplate);
  }
  
  @override
  Future<void> deleteTemplate(String templateId) async {
    if (templateId.startsWith('prebuilt_')) {
      throw ArgumentError('Cannot delete pre-built templates');
    }
    
    await _repository.deleteTemplate(templateId);
    _usageCounts.remove(templateId);
    _ratings.remove(templateId);
  }
  
  @override
  Future<DocumentContent> instantiateTemplate(
    String templateId,
    Map<String, String> variableValues,
  ) async {
    final template = await getTemplate(templateId);
    
    // Validate variable values
    final isValid = _variableService.validateVariableValues(
      template.variables,
      variableValues,
    );
    
    if (!isValid) {
      throw ArgumentError('Invalid variable values provided');
    }
    
    // Merge with defaults
    final defaults = _variableService.getDefaultValues(template.variables);
    final mergedValues = {...defaults, ...variableValues};
    
    // Instantiate template
    final content = template.instantiate(mergedValues);
    
    // Update usage count
    await updateTemplateUsage(templateId);
    
    return content;
  }
  
  @override
  Future<void> updateTemplateUsage(String templateId) async {
    _usageCounts[templateId] = (_usageCounts[templateId] ?? 0) + 1;
    
    // Save usage stats (could persist to file)
    // For now, just track in memory
  }
  
  @override
  Future<void> addTemplateRating(String templateId, double rating) async {
    if (rating < 0.0 || rating > 5.0) {
      throw ArgumentError('Rating must be between 0.0 and 5.0');
    }
    
    _ratings[templateId] ??= [];
    _ratings[templateId]!.add(rating);
    
    // Calculate average rating
    final ratings = _ratings[templateId]!;
    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    
    // Update template rating
    final template = await getTemplate(templateId);
    final updatedTemplate = template.copyWith(rating: avgRating);
    await updateTemplate(updatedTemplate);
  }
  
  @override
  Future<List<DocumentTemplate>> getPreBuiltTemplates() async {
    return PrebuiltTemplateFactory.getAllPrebuiltTemplates();
  }
  
  @override
  Future<DocumentTemplate?> getPreBuiltTemplate(TemplateCategory category) async {
    return await PrebuiltTemplateFactory.getTemplateByCategoryStatic(category);
  }
  
  @override
  Future<void> exportTemplate(String templateId, String filePath) async {
    final template = await getTemplate(templateId);
    final json = template.toJson();
    
    final file = File(filePath);
    await file.writeAsString(jsonEncode(json));
  }
  
  @override
  Future<DocumentTemplate> importTemplate(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    
    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    
    final template = DocumentTemplate.fromJson(json);
    
    // Generate new ID to avoid conflicts
    final newId = 'template_${DateTime.now().millisecondsSinceEpoch}';
    final importedTemplate = template.copyWith(id: newId);
    
    // Save imported template
    await _repository.saveTemplate(importedTemplate);
    
    return importedTemplate;
  }
  
  // Helper methods
  int getUsageCount(String templateId) {
    return _usageCounts[templateId] ?? 0;
  }
  
  double getAverageRating(String templateId) {
    final ratings = _ratings[templateId];
    if (ratings == null || ratings.isEmpty) {
      return 0.0;
    }
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}

