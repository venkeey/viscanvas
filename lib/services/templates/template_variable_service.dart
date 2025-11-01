import '../../models/documents/document_content.dart';
import '../../models/templates/template_variable.dart';

class TemplateVariableService {
  // Extract variables from document content
  List<TemplateVariable> extractVariables(DocumentContent content) {
    final variables = <TemplateVariable>[];
    final variablePattern = RegExp(r'\{\{(\w+)(?::([^}]+))?\}\}');
    
    // Collect all text from all blocks
    final allText = StringBuffer();
    for (final block in content.blocks) {
      final blockText = block.getPlainText();
      if (blockText.isNotEmpty) {
        allText.writeln(blockText);
      }
    }
    
    final text = allText.toString();
    final matches = variablePattern.allMatches(text);
    
    final foundNames = <String>{};
    for (final match in matches) {
      final name = match.group(1)!;
      if (foundNames.contains(name)) continue;
      
      final metadata = match.group(2);
      final variable = _parseVariable(name, metadata);
      variables.add(variable);
      foundNames.add(name);
    }
    
    return variables;
  }
  
  TemplateVariable _parseVariable(String name, String? metadata) {
    if (metadata == null) {
      return TemplateVariable(
        name: name,
        displayName: _formatDisplayName(name),
        type: VariableType.text,
      );
    }
    
    // Parse metadata like "type:text,required:true,placeholder:Enter name"
    final parts = metadata.split(',');
    final props = <String, String>{};
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        props[kv[0].trim()] = kv[1].trim();
      }
    }
    
    return TemplateVariable(
      name: name,
      displayName: props['displayName'] ?? _formatDisplayName(name),
      type: _parseType(props['type'] ?? 'text'),
      required: props['required'] == 'true',
      placeholder: props['placeholder'],
      defaultValue: props['defaultValue'],
      options: props['options'] != null 
        ? props['options']!.split('|').map((o) => o.trim()).toList()
        : null,
    );
  }
  
  // Replace variables in document content
  DocumentContent replaceVariables(
    DocumentContent content,
    Map<String, String> variableValues,
  ) {
    final variablePattern = RegExp(r'\{\{(\w+)(?::[^}]+)?\}\}');
    
    // Clone blocks and replace variables
    final clonedBlocks = content.blocks.map((block) {
      final clonedBlock = block.clone();
      final blockText = clonedBlock.getPlainText();
      
      if (blockText.isNotEmpty) {
        final replacedText = blockText.replaceAllMapped(
          variablePattern,
          (match) {
            final varName = match.group(1)!;
            return variableValues[varName] ?? match.group(0)!;
          },
        );
        
        // Update block content if text changed
        if (replacedText != blockText) {
          clonedBlock.content['text'] = replacedText;
        }
      }
      
      return clonedBlock;
    }).toList();
    
    // Clone hierarchy (simplified - preserves structure)
    final clonedHierarchy = BlockHierarchy();
    final hierarchyJson = content.hierarchy.toJson();
    final parentToChildren = hierarchyJson['parentToChildren'] as Map<String, dynamic>?;
    
    if (parentToChildren != null) {
      // Map old block IDs to new block IDs
      final idMap = <String, String>{};
      for (var i = 0; i < content.blocks.length && i < clonedBlocks.length; i++) {
        idMap[content.blocks[i].id] = clonedBlocks[i].id;
      }
      
      // Rebuild hierarchy with new IDs
      for (final entry in parentToChildren.entries) {
        final parentId = entry.key;
        final newParentId = idMap[parentId] ?? parentId;
        final children = List<String>.from(entry.value as List);
        
        for (final childId in children) {
          final newChildId = idMap[childId] ?? childId;
          final block = clonedBlocks.firstWhere(
            (b) => b.id == newChildId,
            orElse: () => clonedBlocks.first,
          );
          clonedHierarchy.addBlock(
            block,
            parentId: newParentId.isEmpty ? null : newParentId,
          );
        }
      }
    }
    
    return DocumentContent(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      blocks: clonedBlocks,
      hierarchy: clonedHierarchy,
      version: 1,
    );
  }
  
  String _formatDisplayName(String name) {
    // Convert snake_case to Title Case
    return name
      .split('_')
      .map((word) => word.isEmpty 
        ? '' 
        : word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : ''))
      .join(' ');
  }
  
  VariableType _parseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'date': return VariableType.date;
      case 'number': return VariableType.number;
      case 'select': return VariableType.select;
      case 'email': return VariableType.email;
      case 'url': return VariableType.url;
      default: return VariableType.text;
    }
  }
  
  // Validate variable values
  bool validateVariableValues(
    List<TemplateVariable> variables,
    Map<String, String> values,
  ) {
    for (final variable in variables) {
      if (variable.required) {
        final value = values[variable.name];
        if (value == null || value.isEmpty) {
          return false;
        }
      }
      
      // Type-specific validation
      if (values.containsKey(variable.name)) {
        final value = values[variable.name]!;
        switch (variable.type) {
          case VariableType.email:
            if (!value.contains('@') || !value.contains('.')) {
              return false;
            }
            break;
          case VariableType.url:
            if (!value.startsWith('http://') && !value.startsWith('https://')) {
              return false;
            }
            break;
          case VariableType.number:
            if (double.tryParse(value) == null) {
              return false;
            }
            break;
          case VariableType.select:
            if (variable.options != null && !variable.options!.contains(value)) {
              return false;
            }
            break;
          default:
            break;
        }
      }
    }
    
    return true;
  }
  
  // Get default values for variables
  Map<String, String> getDefaultValues(List<TemplateVariable> variables) {
    final defaults = <String, String>{};
    for (final variable in variables) {
      if (variable.defaultValue != null && variable.defaultValue!.isNotEmpty) {
        defaults[variable.name] = variable.defaultValue!;
      }
    }
    return defaults;
  }
}

