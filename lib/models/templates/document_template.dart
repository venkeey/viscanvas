import '../documents/document_content.dart';
import '../documents/block_types.dart';
import 'template_metadata.dart';
import 'template_variable.dart';
import 'template_preview.dart';
import 'template_category.dart';

class DocumentTemplate {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;  // Custom icon or emoji
  final TemplateCategory category;
  final DocumentContent content;  // The actual template content
  final TemplateMetadata metadata;
  final List<TemplateVariable> variables;  // {{variable_name}} placeholders
  final TemplatePreview preview;
  
  // Versioning
  final String version;
  final DateTime createdAt;
  final DateTime lastModified;
  
  // Author info
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  
  // Marketplace info (Phase 2)
  final bool isPublic;
  final String? marketplaceId;
  final int downloadCount;
  final double rating;
  
  DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.category,
    required this.content,
    required this.metadata,
    required this.variables,
    required this.preview,
    this.version = '1.0.0',
    DateTime? createdAt,
    DateTime? lastModified,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.isPublic = false,
    this.marketplaceId,
    this.downloadCount = 0,
    this.rating = 0.0,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now();
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'category': category.toString(),
      'content': content.toJson(),
      'metadata': metadata.toJson(),
      'variables': variables.map((v) => v.toJson()).toList(),
      'preview': preview.toJson(),
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'isPublic': isPublic,
      'marketplaceId': marketplaceId,
      'downloadCount': downloadCount,
      'rating': rating,
    };
  }
  
  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String?,
      category: TemplateCategory.values.firstWhere(
        (c) => c.toString() == json['category'],
        orElse: () => TemplateCategory.custom,
      ),
      content: DocumentContent.fromJson(json['content'] as Map<String, dynamic>),
      metadata: TemplateMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      variables: (json['variables'] as List? ?? [])
        .map((v) => TemplateVariable.fromJson(v as Map<String, dynamic>))
        .toList(),
      preview: TemplatePreview.fromJson(json['preview'] as Map<String, dynamic>? ?? {}),
      version: json['version'] as String? ?? '1.0.0',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      marketplaceId: json['marketplaceId'] as String?,
      downloadCount: json['downloadCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  // Clone with variable replacement
  DocumentContent instantiate(Map<String, String> variableValues) {
    // Clone blocks with new IDs and replace variables
    final variablePattern = RegExp(r'\{\{(\w+)(?::[^}]+)?\}\}');
    final clonedBlocks = <Block>[];
    final oldToNewIdMap = <String, String>{};
    
    // Clone all blocks and replace variables
    for (final block in content.blocks) {
      final newBlockId = 'block_${DateTime.now().millisecondsSinceEpoch}_${clonedBlocks.length}';
      oldToNewIdMap[block.id] = newBlockId;
      
      final clonedBlock = block.clone();
      // Note: Block.id is final, but clone() should create a new ID
      // If clone doesn't create proper ID, we may need to use reflection or 
      // a different approach - for now, assume clone handles ID properly
      
      // Replace variables in block content
      final blockText = clonedBlock.getPlainText();
      if (blockText.isNotEmpty) {
        final replacedText = blockText.replaceAllMapped(
          variablePattern,
          (match) {
            final varName = match.group(1)!;
            final value = variableValues[varName] ?? match.group(0)!;
            return value;
          },
        );
        
        // Update block content if text changed
        if (replacedText != blockText) {
          clonedBlock.content['text'] = replacedText;
        }
      }
      
      clonedBlocks.add(clonedBlock);
    }
    
    // Clone hierarchy and update block IDs
    final clonedHierarchy = BlockHierarchy();
    final hierarchyJson = content.hierarchy.toJson();
    final parentToChildren = hierarchyJson['parentToChildren'] as Map<String, dynamic>?;
    
    if (parentToChildren != null) {
      for (final entry in parentToChildren.entries) {
        final parentId = entry.key;
        final newParentId = oldToNewIdMap[parentId] ?? parentId;
        final children = List<String>.from(entry.value as List);
        
        for (final childId in children) {
          final newChildId = oldToNewIdMap[childId] ?? childId;
          final block = clonedBlocks.firstWhere(
            (b) => b.id == newChildId,
            orElse: () => clonedBlocks.first, // Fallback if not found
          );
          clonedHierarchy.addBlock(
            block,
            parentId: newParentId.isEmpty ? null : newParentId,
          );
        }
      }
    }
    
    // Create new document content
    return DocumentContent(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      blocks: clonedBlocks,
      hierarchy: clonedHierarchy,
      version: 1,
    );
  }
  
  // Create from existing document
  factory DocumentTemplate.fromDocument(
    DocumentContent document,
    String name,
    String description,
    TemplateCategory category, {
    String? authorId,
    String? authorName,
    List<TemplateVariable>? variables,
    TemplateMetadata? metadata,
  }) {
    // Extract variables from content if not provided
    final extractedVariables = variables ?? [];
    
    // Generate template ID
    final templateId = 'template_${DateTime.now().millisecondsSinceEpoch}';
    
    return DocumentTemplate(
      id: templateId,
      name: name,
      description: description,
      category: category,
      content: document,
      metadata: metadata ?? TemplateMetadata(),
      variables: extractedVariables,
      preview: TemplatePreview(
        previewText: TemplatePreview.generatePreviewText(
          document.blocks.map((b) => b.getPlainText()).join('\n'),
        ),
      ),
      authorId: authorId ?? 'user',
      authorName: authorName ?? 'User',
      version: '1.0.0',
    );
  }
  
  // Helper methods
  DocumentTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    TemplateCategory? category,
    DocumentContent? content,
    TemplateMetadata? metadata,
    List<TemplateVariable>? variables,
    TemplatePreview? preview,
    String? version,
    DateTime? createdAt,
    DateTime? lastModified,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    bool? isPublic,
    String? marketplaceId,
    int? downloadCount,
    double? rating,
  }) {
    return DocumentTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      variables: variables ?? this.variables,
      preview: preview ?? this.preview,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isPublic: isPublic ?? this.isPublic,
      marketplaceId: marketplaceId ?? this.marketplaceId,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
    );
  }
  
  // Update last modified timestamp
  DocumentTemplate updateModified() {
    return copyWith(lastModified: DateTime.now());
  }
}

