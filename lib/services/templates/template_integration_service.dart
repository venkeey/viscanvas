import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/documents/document_content.dart';
import '../../models/canvas_objects/document_block.dart';
import '../../services/canvas/canvas_service.dart' as canvas_service;
import '../../services/document_service.dart';
import 'template_service.dart';
import '../../ui/template_library_screen.dart';
import '../../widgets/create_template_dialog.dart';
import '../../models/templates/template_category.dart';

class TemplateIntegrationService {
  final TemplateService templateService;
  final canvas_service.CanvasService canvasService;
  final DocumentServiceImpl documentService;
  
  TemplateIntegrationService({
    required this.templateService,
    required this.canvasService,
    required this.documentService,
  });
  
  /// Open template library and create document block from selected template
  Future<void> openTemplateLibrary(BuildContext context, Offset? canvasPosition) async {
    final position = canvasPosition ?? Offset.zero;
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateLibraryScreen(
          templateService: templateService,
          onTemplateSelected: (content) async {
            await _createDocumentBlockFromContent(context, content, position);
          },
        ),
      ),
    );
  }
  
  /// Create document block from template-instantiated content
  Future<void> createDocumentBlockFromTemplate(
    String templateId,
    Map<String, String> variableValues,
    Offset position,
  ) async {
    try {
      // Instantiate template
      final content = await templateService.instantiateTemplate(
        templateId,
        variableValues,
      );
      
      // Create document block
      await _createDocumentBlockFromContent(null, content, position);
    } catch (e) {
      debugPrint('Error creating document block from template: $e');
      rethrow;
    }
  }
  
  /// Create document block from document content
  Future<void> _createDocumentBlockFromContent(
    BuildContext? context,
    DocumentContent content,
    Offset position,
  ) async {
    try {
      // Store document content in document service
      final documentId = content.id;
      // Use updateDocument to set the content, then save it
      documentService.updateDocument(documentId, content);
      await documentService.saveDocument(documentId);
      
      // Create document block on canvas
      final docBlock = DocumentBlock(
        id: 'block_$documentId',
        worldPosition: position,
        strokeColor: Colors.blue,
        documentId: documentId,
        content: content,
        viewMode: DocumentViewMode.preview,
        size: const Size(400, 300),
      );
      
      // Add to canvas using the tools service's create object method
      // We need to add it through the repository
      // For now, we'll access the repository via reflection or use a public method
      // This is a workaround - the canvas service should expose an addObject method
      // Use the canvas service to add the object
      // Add document block to canvas
      canvasService.addObject(docBlock);
      
      // Optionally open editor
      if (context != null) {
        canvasService.onOpenDocumentEditor?.call(docBlock);
      }
      
      debugPrint('Document block created: $documentId at $position');
    } catch (e) {
      debugPrint('Error creating document block: $e');
      rethrow;
    }
  }
  
  /// Create template from existing document block
  Future<String?> createTemplateFromDocumentBlock(
    BuildContext context,
    DocumentBlock documentBlock,
  ) async {
    if (documentBlock.content == null) {
      return null;
    }
    
    // Show create template dialog
    String? name;
    String? description;
    TemplateCategory? category;
    
    await showDialog(
      context: context,
      builder: (context) => CreateTemplateDialog(
        document: documentBlock.content,
        onCreate: (n, d, c) {
          name = n;
          description = d;
          category = c;
        },
      ),
    );
    
    if (name == null || description == null || category == null) {
      return null;
    }
    
    try {
      // Create template from document
      final template = await templateService.createTemplate(
        documentBlock.content!,
        name!,
        description!,
        category!,
      );
      
      return template.id;
    } catch (e) {
      debugPrint('Error creating template from document block: $e');
      return null;
    }
  }
}

