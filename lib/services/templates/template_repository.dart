import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/templates/document_template.dart';
import '../../models/templates/template_category.dart';

abstract class TemplateRepository {
  Future<void> saveTemplate(DocumentTemplate template);
  Future<DocumentTemplate> loadTemplate(String templateId);
  Future<List<DocumentTemplate>> loadAllTemplates({
    TemplateCategory? category,
    List<String>? tags,
    String? searchQuery,
  });
  Future<void> deleteTemplate(String templateId);
  Future<bool> templateExists(String templateId);
  Future<void> updateTemplateIndex(DocumentTemplate template);
  Future<void> removeFromIndex(String templateId);
}

class TemplateNotFoundException implements Exception {
  final String templateId;
  TemplateNotFoundException(this.templateId);
  
  @override
  String toString() => 'Template not found: $templateId';
}

class LocalTemplateRepository implements TemplateRepository {
  final String templatesDirectory;
  final String thumbnailsDirectory;
  
  LocalTemplateRepository({
    required this.templatesDirectory,
    required this.thumbnailsDirectory,
  });
  
  // Ensure directories exist
  Future<void> _ensureDirectories() async {
    final templatesDir = Directory(templatesDirectory);
    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }
    
    final thumbnailsDir = Directory(thumbnailsDirectory);
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }
  }
  
  @override
  Future<void> saveTemplate(DocumentTemplate template) async {
    await _ensureDirectories();
    
    // Create template directory
    final templateDir = Directory('$templatesDirectory/${template.id}');
    await templateDir.create(recursive: true);
    
    // Write template JSON (atomic write)
    final templateFile = File('${templateDir.path}/template.json');
    final tempFile = File('${templateDir.path}/template.json.tmp');
    
    final json = jsonEncode(template.toJson());
    await tempFile.writeAsString(json);
    await tempFile.rename(templateFile.path);
    
    // Save thumbnail if exists
    if (template.preview.thumbnailPath != null) {
      final sourceThumbnail = File(template.preview.thumbnailPath!);
      if (await sourceThumbnail.exists()) {
        final destThumbnail = File('${templateDir.path}/thumbnail.png');
        await sourceThumbnail.copy(destThumbnail.path);
      }
    }
    
    // Update index
    await updateTemplateIndex(template);
  }
  
  @override
  Future<DocumentTemplate> loadTemplate(String templateId) async {
    final templateFile = File('$templatesDirectory/$templateId/template.json');
    
    if (!await templateFile.exists()) {
      throw TemplateNotFoundException(templateId);
    }
    
    try {
      final jsonString = await templateFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Load template
      final template = DocumentTemplate.fromJson(json);
      
      // Update thumbnail path if exists
      final thumbnailPath = '${templatesDirectory}/$templateId/thumbnail.png';
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        final updatedPreview = template.preview.copyWith(thumbnailPath: thumbnailPath);
        return template.copyWith(preview: updatedPreview);
      }
      
      return template;
    } catch (e) {
      debugPrint('Error loading template $templateId: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<DocumentTemplate>> loadAllTemplates({
    TemplateCategory? category,
    List<String>? tags,
    String? searchQuery,
  }) async {
    await _ensureDirectories();
    
    final indexFile = File('$templatesDirectory/index.json');
    if (!await indexFile.exists()) {
      return [];
    }
    
    try {
      final indexJson = jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      final templateIds = List<String>.from(indexJson['templates'] ?? []);
      
      final templates = <DocumentTemplate>[];
      for (final id in templateIds) {
        try {
          final template = await loadTemplate(id);
          
          // Apply filters
          if (category != null && template.category != category) continue;
          
          if (tags != null && tags.isNotEmpty) {
            final hasMatchingTag = template.metadata.tags
              .any((tag) => tags.any((filterTag) => tag.toLowerCase().contains(filterTag.toLowerCase())));
            if (!hasMatchingTag) continue;
          }
          
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            final matches = 
              template.name.toLowerCase().contains(query) ||
              template.description.toLowerCase().contains(query) ||
              template.metadata.tags.any((tag) => tag.toLowerCase().contains(query));
            if (!matches) continue;
          }
          
          templates.add(template);
        } catch (e) {
          debugPrint('Error loading template $id: $e');
          // Continue with other templates
        }
      }
      
      return templates;
    } catch (e) {
      debugPrint('Error loading templates index: $e');
      return [];
    }
  }
  
  @override
  Future<void> deleteTemplate(String templateId) async {
    final templateDir = Directory('$templatesDirectory/$templateId');
    if (await templateDir.exists()) {
      await templateDir.delete(recursive: true);
    }
    
    await removeFromIndex(templateId);
  }
  
  @override
  Future<bool> templateExists(String templateId) async {
    final templateFile = File('$templatesDirectory/$templateId/template.json');
    return await templateFile.exists();
  }
  
  @override
  Future<void> updateTemplateIndex(DocumentTemplate template) async {
    await _ensureDirectories();
    
    final indexFile = File('$templatesDirectory/index.json');
    Map<String, dynamic> index;
    
    if (await indexFile.exists()) {
      try {
        final jsonString = await indexFile.readAsString();
        index = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error reading index, creating new: $e');
        index = {'templates': [], 'metadata': {}};
      }
    } else {
      index = {'templates': [], 'metadata': {}};
    }
    
    final templates = List<String>.from(index['templates'] ?? []);
    if (!templates.contains(template.id)) {
      templates.add(template.id);
    }
    
    index['templates'] = templates;
    index['metadata'] ??= {};
    (index['metadata'] as Map<String, dynamic>)[template.id] = {
      'name': template.name,
      'category': template.category.toString(),
      'lastModified': template.lastModified.toIso8601String(),
      'tags': template.metadata.tags,
    };
    
    // Atomic write
    final tempIndexFile = File('${indexFile.path}.tmp');
    await tempIndexFile.writeAsString(jsonEncode(index));
    await tempIndexFile.rename(indexFile.path);
  }
  
  @override
  Future<void> removeFromIndex(String templateId) async {
    final indexFile = File('$templatesDirectory/index.json');
    if (!await indexFile.exists()) {
      return;
    }
    
    try {
      final jsonString = await indexFile.readAsString();
      final index = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final templates = List<String>.from(index['templates'] ?? []);
      templates.remove(templateId);
      
      final metadata = Map<String, dynamic>.from(index['metadata'] ?? {});
      metadata.remove(templateId);
      
      index['templates'] = templates;
      index['metadata'] = metadata;
      
      // Atomic write
      final tempIndexFile = File('${indexFile.path}.tmp');
      await tempIndexFile.writeAsString(jsonEncode(index));
      await tempIndexFile.rename(indexFile.path);
    } catch (e) {
      debugPrint('Error removing template from index: $e');
    }
  }
}

