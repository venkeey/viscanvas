import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/models/canvas_objects/document_block.dart';
import 'package:viscanvas/models/canvas_objects/canvas_object.dart';
import 'package:viscanvas/models/documents/document_content.dart';
import 'package:viscanvas/models/documents/block_types.dart';

void main() {
  group('DocumentBlock Tests', () {
    late DocumentBlock documentBlock;
    late DocumentContent sampleContent;

    setUp(() {
      // Create sample document content
      sampleContent = DocumentContent(
        id: 'test_doc',
        blocks: [
          BasicBlock(
            id: 'block1',
            type: BlockType.heading1,
            content: {'text': 'Test Document'},
          ),
          BasicBlock(
            id: 'block2',
            type: BlockType.paragraph,
            content: {'text': 'This is a test paragraph.'},
          ),
        ],
        hierarchy: BlockHierarchy(),
      );

      documentBlock = DocumentBlock(
        id: 'doc_block_1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        documentId: 'test_doc',
        content: sampleContent,
        viewMode: DocumentViewMode.preview,
        size: const Size(400, 300),
      );
    });

    test('should create DocumentBlock with default values', () {
      final block = DocumentBlock(
        id: 'test_id',
        worldPosition: Offset.zero,
        strokeColor: Colors.blue,
        documentId: 'doc1',
      );

      expect(block.id, 'test_id');
      expect(block.worldPosition, Offset.zero);
      expect(block.strokeColor, Colors.blue);
      expect(block.documentId, 'doc1');
      expect(block.viewMode, DocumentViewMode.preview);
      expect(block.isSelected, false);
      expect(block.isExpanded, false);
      expect(block.isEditing, false);
    });

    test('should calculate bounding rect correctly', () {
      final rect = documentBlock.calculateBoundingRect();
      expect(rect.left, 100);
      expect(rect.top, 100);
      expect(rect.width, 400);
      expect(rect.height, 300);
    });

    test('should perform hit test correctly', () {
      // Inside bounds
      expect(documentBlock.hitTest(const Offset(200, 200)), true);
      expect(documentBlock.hitTest(const Offset(100, 100)), true);
      expect(documentBlock.hitTest(const Offset(499, 399)), true);

      // Outside bounds
      expect(documentBlock.hitTest(const Offset(50, 50)), false);
      expect(documentBlock.hitTest(const Offset(600, 400)), false);
      expect(documentBlock.hitTest(const Offset(200, 500)), false);
    });

    test('should switch view modes', () {
      // Start in preview mode
      expect(documentBlock.viewMode, DocumentViewMode.preview);

      // Switch to collapsed
      documentBlock.viewMode = DocumentViewMode.collapsed;
      expect(documentBlock.viewMode, DocumentViewMode.collapsed);

      // Switch to expanded
      documentBlock.viewMode = DocumentViewMode.expanded;
      expect(documentBlock.viewMode, DocumentViewMode.expanded);
    });

    test('should toggle expanded state', () {
      expect(documentBlock.isExpanded, false);
      expect(documentBlock.viewMode, DocumentViewMode.preview);

      documentBlock.toggleExpanded();
      expect(documentBlock.isExpanded, true);
      expect(documentBlock.viewMode, DocumentViewMode.expanded);

      documentBlock.toggleExpanded();
      expect(documentBlock.isExpanded, false);
      expect(documentBlock.viewMode, DocumentViewMode.preview);
    });

    test('should enter and exit edit mode', () {
      expect(documentBlock.isEditing, false);
      expect(documentBlock.viewMode, DocumentViewMode.preview);

      documentBlock.enterEditMode();
      expect(documentBlock.isEditing, true);
      expect(documentBlock.viewMode, DocumentViewMode.expanded);

      documentBlock.exitEditMode();
      expect(documentBlock.isEditing, false);
      expect(documentBlock.viewMode, DocumentViewMode.preview);
    });

    test('should move correctly', () {
      final initialPos = documentBlock.worldPosition;
      final delta = const Offset(50, -25);

      documentBlock.move(delta);

      expect(documentBlock.worldPosition, initialPos + delta);
    });

    test('should add canvas references', () {
      expect(documentBlock.canvasReferences, isEmpty);

      // Mock canvas object
      final mockObject = _MockCanvasObject('canvas_obj_1');

      documentBlock.addCanvasReference(mockObject);

      expect(documentBlock.canvasReferences.length, 1);
      expect(documentBlock.canvasReferences.first.canvasObjectId, 'canvas_obj_1');
      expect(documentBlock.canvasReferences.first.documentBlockId, 'test_doc');
      expect(documentBlock.canvasReferences.first.type, ReferenceType.mention);
    });

    test('should clone correctly', () {
      final clone = documentBlock.clone();

      expect(clone.id, 'doc_block_1_copy');
      expect(clone.worldPosition, documentBlock.worldPosition);
      expect(clone.strokeColor, documentBlock.strokeColor);
      expect(clone.documentId, documentBlock.documentId);
      expect(clone.viewMode, documentBlock.viewMode);
      expect(clone.size, documentBlock.size);
      expect(clone.isExpanded, documentBlock.isExpanded);
      expect(clone.isEditing, documentBlock.isEditing);

      // Should be different instances
      expect(identical(clone, documentBlock), false);
    });

    test('should serialize to JSON', () {
      final json = documentBlock.toJson();

      expect(json['id'], 'doc_block_1');
      expect(json['worldPosition']['dx'], 100);
      expect(json['worldPosition']['dy'], 100);
      expect(json['strokeColor'], Colors.black.value);
      expect(json['documentId'], 'test_doc');
      expect(json['viewMode'], 'DocumentViewMode.preview');
      expect(json['size']['width'], 400);
      expect(json['size']['height'], 300);
      expect(json['isExpanded'], false);
      expect(json['isEditing'], false);
    });

    test('should deserialize from JSON', () {
      final json = documentBlock.toJson();
      final deserialized = DocumentBlock.fromJson(json);

      expect(deserialized.id, documentBlock.id);
      expect(deserialized.worldPosition, documentBlock.worldPosition);
      expect(deserialized.strokeColor, documentBlock.strokeColor);
      expect(deserialized.documentId, documentBlock.documentId);
      expect(deserialized.viewMode, documentBlock.viewMode);
      expect(deserialized.size, documentBlock.size);
      expect(deserialized.isExpanded, documentBlock.isExpanded);
      expect(deserialized.isEditing, documentBlock.isEditing);
    });

    test('should handle null content gracefully', () {
      final blockWithoutContent = DocumentBlock(
        id: 'empty_doc',
        worldPosition: Offset.zero,
        strokeColor: Colors.black,
        documentId: 'empty',
      );

      expect(blockWithoutContent.content, isNull);
      expect(() => blockWithoutContent.content?.getTitle(), returnsNormally);
    });

    test('should get title from content', () {
      expect(documentBlock.content?.getTitle(), 'Test Document');
    });


    test('should invalidate cache when moved', () {
      // This tests that cache invalidation methods exist and are callable
      expect(() => documentBlock.invalidateCache(), returnsNormally);
      expect(() => documentBlock.invalidateThumbnail(), returnsNormally);
    });

    test('should update content and reflect changes', () {
      final block = DocumentBlock(
        id: 'content_test_block',
        worldPosition: Offset.zero,
        strokeColor: Colors.black,
        documentId: 'content_test_doc',
        content: DocumentContent(
          id: 'content_test_doc',
          blocks: [BasicBlock(id: 'b1', type: BlockType.paragraph, content: {'text': 'Original content'})],
          hierarchy: BlockHierarchy(),
        ),
      );

      // Verify initial content
      expect(block.content?.blocks[0].getPlainText(), 'Original content');

      // Update content (simulating edit in document editor)
      final updatedContent = DocumentContent(
        id: 'content_test_doc',
        blocks: [BasicBlock(id: 'b1', type: BlockType.paragraph, content: {'text': 'Updated content'})],
        hierarchy: BlockHierarchy(),
      );
      block.content = updatedContent;

      // Verify content was updated
      expect(block.content?.blocks[0].getPlainText(), 'Updated content');

      // Verify the block can still calculate bounds and has content for rendering
      final rect = block.calculateBoundingRect();
      expect(rect, isNotNull);
      expect(block.content, isNotNull);
      expect(block.content!.blocks.isNotEmpty, true);

      // Simulate what happens after editing (switch to expanded mode)
      block.viewMode = DocumentViewMode.expanded;
      expect(block.viewMode, DocumentViewMode.expanded);
    });

    test('should serialize and deserialize content correctly for persistence', () {
      // Create a DocumentBlock with content (simulating what gets saved)
      final originalContent = DocumentContent(
        id: 'persistence_test_content',
        blocks: [
          BasicBlock(
            id: 'block_1',
            type: BlockType.paragraph,
            content: {'text': 'This content should persist'},
          ),
          BasicBlock(
            id: 'block_2',
            type: BlockType.heading1,
            content: {'text': 'Persistent Heading'},
          ),
        ],
        hierarchy: BlockHierarchy(),
      );

      final originalBlock = DocumentBlock(
        id: 'persistence_test_block',
        worldPosition: const Offset(150, 250),
        strokeColor: Colors.black,
        strokeWidth: 2.0,
        documentId: 'persistence_test_doc',
        content: originalContent,
        viewMode: DocumentViewMode.expanded,
        size: const Size(400, 300),
      );

      // Simulate CanvasService serialization (what happens during save)
      final serializedData = <String, dynamic>{
        'id': originalBlock.id,
        'worldPosition': <String, dynamic>{'dx': originalBlock.worldPosition.dx, 'dy': originalBlock.worldPosition.dy},
        'strokeColor': originalBlock.strokeColor.value,
        'fillColor': originalBlock.fillColor?.value,
        'strokeWidth': originalBlock.strokeWidth,
        'isSelected': originalBlock.isSelected,
        'type': originalBlock.runtimeType.toString(),
        'documentId': originalBlock.documentId,
        'viewMode': originalBlock.viewMode.toString(),
        'size': <String, dynamic>{'width': originalBlock.size.width, 'height': originalBlock.size.height},
        'content': originalBlock.content?.toJson(), // This is the critical part
        'canvasReferences': originalBlock.canvasReferences.map((ref) => ref.toJson()).toList(),
        'isExpanded': originalBlock.isExpanded,
        'isEditing': originalBlock.isEditing,
        'style': <String, dynamic>{
          'backgroundColor': originalBlock.style.backgroundColor.value,
          'titleStyle': <String, dynamic>{
            'fontSize': originalBlock.style.titleStyle.fontSize,
            'fontWeight': originalBlock.style.titleStyle.fontWeight?.index,
          },
          'borderRadius': originalBlock.style.borderRadius,
          'padding': originalBlock.style.padding,
        },
      };

      // Verify serialization includes content
      expect(serializedData['content'], isNotNull);
      final contentData = serializedData['content'] as Map<String, dynamic>;
      expect(contentData['blocks'], isNotNull);
      expect((contentData['blocks'] as List).length, 2);

      // Simulate CanvasService deserialization (what happens during load)
      final deserializedContent = serializedData['content'] != null
          ? DocumentContent.fromJson(serializedData['content'] as Map<String, dynamic>)
          : null;

      final deserializedBlock = DocumentBlock(
        id: serializedData['id'] as String,
        worldPosition: Offset(
          (serializedData['worldPosition'] as Map<String, dynamic>)['dx'] as double,
          (serializedData['worldPosition'] as Map<String, dynamic>)['dy'] as double,
        ),
        strokeColor: Color(serializedData['strokeColor'] as int),
        strokeWidth: (serializedData['strokeWidth'] as num).toDouble(),
        fillColor: serializedData['fillColor'] != null ? Color(serializedData['fillColor'] as int) : Colors.white,
        isSelected: serializedData['isSelected'] as bool,
        documentId: serializedData['documentId'] as String,
        content: deserializedContent, // This should restore the content
        viewMode: DocumentViewMode.values.firstWhere(
          (mode) => mode.toString() == serializedData['viewMode'],
          orElse: () => DocumentViewMode.preview,
        ),
        size: Size(
          ((serializedData['size'] as Map<String, dynamic>)['width'] as num).toDouble(),
          ((serializedData['size'] as Map<String, dynamic>)['height'] as num).toDouble(),
        ),
        canvasReferences: (serializedData['canvasReferences'] as List?)
            ?.map((ref) => CanvasReference.fromJson(ref as Map<String, dynamic>))
            .toList() ?? [],
        isExpanded: serializedData['isExpanded'] as bool,
        isEditing: serializedData['isEditing'] as bool,
        style: DocumentBlockStyle(
          backgroundColor: Color((serializedData['style'] as Map<String, dynamic>)['backgroundColor'] as int),
          titleStyle: TextStyle(
            fontSize: (((serializedData['style'] as Map<String, dynamic>)['titleStyle'] as Map<String, dynamic>)['fontSize'] as num).toDouble(),
            fontWeight: FontWeight.values[((serializedData['style'] as Map<String, dynamic>)['titleStyle'] as Map<String, dynamic>)['fontWeight'] as int],
          ),
          borderRadius: ((serializedData['style'] as Map<String, dynamic>)['borderRadius'] as num).toDouble(),
          padding: ((serializedData['style'] as Map<String, dynamic>)['padding'] as num).toDouble(),
        ),
      );

      // Verify the deserialized block has the same content as the original
      expect(deserializedBlock.content, isNotNull, reason: 'Content should be restored after deserialization');
      expect(deserializedBlock.content!.blocks.length, 2, reason: 'Should have 2 blocks after deserialization');
      expect(deserializedBlock.content!.blocks[0].getPlainText(), 'This content should persist');
      expect(deserializedBlock.content!.blocks[1].getPlainText(), 'Persistent Heading');
      expect(deserializedBlock.content!.id, 'persistence_test_content');

      // Verify other properties are preserved
      expect(deserializedBlock.id, originalBlock.id);
      expect(deserializedBlock.viewMode, DocumentViewMode.expanded);
      expect(deserializedBlock.documentId, originalBlock.documentId);
    });
  });

  group('DocumentViewMode Tests', () {
    test('should have correct enum values', () {
      expect(DocumentViewMode.collapsed.index, 0);
      expect(DocumentViewMode.preview.index, 1);
      expect(DocumentViewMode.expanded.index, 2);
    });
  });

  group('DocumentBlockStyle Tests', () {
    test('should create with default values', () {
      final style = DocumentBlockStyle();

      expect(style.backgroundColor, Colors.white);
      expect(style.titleStyle.fontSize, 18);
      expect(style.titleStyle.fontWeight, FontWeight.w600);
      expect(style.borderRadius, 8.0);
      expect(style.padding, 16.0);
    });

    test('should create with custom values', () {
      final style = DocumentBlockStyle(
        backgroundColor: Colors.blue,
        titleStyle: const TextStyle(fontSize: 24, color: Colors.red),
        borderRadius: 12.0,
        padding: 20.0,
      );

      expect(style.backgroundColor, Colors.blue);
      expect(style.titleStyle.fontSize, 24);
      expect(style.borderRadius, 12.0);
      expect(style.padding, 20.0);
    });
  });
}

// Mock canvas object for testing
class _MockCanvasObject {
  final String id;
  _MockCanvasObject(this.id);
}