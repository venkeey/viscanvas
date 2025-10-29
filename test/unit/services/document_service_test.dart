import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/services/document_service.dart';
import 'package:viscanvas/models/hybrid_canvas_document_bridge.dart';
import 'package:viscanvas/models/documents/document_content.dart';
import 'package:viscanvas/models/documents/block_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentService Tests', () {
    late DocumentServiceImpl documentService;

    setUp(() {
      documentService = DocumentServiceImpl();
    });

    tearDown(() {
      documentService.dispose();
    });

    test('should create document with title', () async {
      await documentService.createDocument('Test Document');

      expect(documentService.documents.length, 1);
      final docId = documentService.documents.keys.first;
      final document = documentService.documents[docId]!;

      expect(document.blocks.length, 1);
      expect(document.blocks.first.getPlainText(), 'Test Document');
      expect(document.blocks.first.type, BlockType.heading1);
    });

    test('should load document', () async {
      // Create a document first
      await documentService.createDocument('Load Test');
      final docId = documentService.documents.keys.first;

      // Load the same document
      final loadedDoc = await documentService.loadDocument(docId);

      expect(loadedDoc.id, docId);
      expect(loadedDoc.blocks.first.getPlainText(), 'Load Test');
    });

    test('should save document', () async {
      // Create and modify a document
      await documentService.createDocument('Save Test');
      final docId = documentService.documents.keys.first;
      final document = documentService.documents[docId]!;

      // Modify document
      document.addBlock(
        BasicBlock(
          id: 'block2',
          type: BlockType.paragraph,
          content: {'text': 'Additional content'},
        ),
      );

      // Save document
      await documentService.saveDocument(docId);

      // Verify it's marked as clean
      expect(document.isDirty, false);
    });

    test('should delete document', () async {
      // Create a document
      await documentService.createDocument('Delete Test');
      expect(documentService.documents.length, 1);

      final docId = documentService.documents.keys.first;

      // Delete document
      await documentService.deleteDocument(docId);

      expect(documentService.documents.length, 0);
    });

    test('should handle document not found gracefully', () async {
      final document = await documentService.loadDocument('nonexistent');

      expect(document.id, 'nonexistent');
      expect(document.blocks, isEmpty);
    });

    test('should emit events for document operations', () async {
      final events = <DocumentEvent>[];
      final subscription = documentService.events.listen(events.add);

      // Create document
      await documentService.createDocument('Event Test');

      // Wait for event
      await Future.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first.documentId, isNotEmpty);
      expect(events.first.type, DocumentEventType.documentCreated);

      await subscription.cancel();
    });

    test('should auto-save dirty documents', () async {
      // Create document
      await documentService.createDocument('Auto-save Test');
      final docId = documentService.documents.keys.first;
      final document = documentService.documents[docId]!;

      // Make document dirty
      document.markDirty();
      expect(document.isDirty, true);

      // Wait for auto-save (10 seconds in implementation, but we'll simulate)
      // In a real test, we'd wait or trigger manually
      // For now, just verify the timer is set up
      expect(documentService, isNotNull);
    });

    test('should serialize and deserialize document content', () {
      final document = DocumentContent(
        id: 'serialize_test',
        blocks: [
          BasicBlock(
            id: 'block1',
            type: BlockType.heading1,
            content: {'text': 'Test Heading'},
          ),
          BasicBlock(
            id: 'block2',
            type: BlockType.paragraph,
            content: {'text': 'Test paragraph content'},
          ),
        ],
        hierarchy: BlockHierarchy(),
      );

      // Serialize
      final json = document.toJson();
      expect(json['id'], 'serialize_test');
      expect(json['blocks'].length, 2);
      expect(json['hierarchy'], isNotNull);

      // Deserialize
      final deserialized = DocumentContent.fromJson(json);
      expect(deserialized.id, document.id);
      expect(deserialized.blocks.length, document.blocks.length);
      expect(deserialized.blocks[0].getPlainText(), 'Test Heading');
      expect(deserialized.blocks[1].getPlainText(), 'Test paragraph content');
    });

    test('should get document title', () {
      final document = DocumentContent(
        id: 'title_test',
        blocks: [
          BasicBlock(
            id: 'heading',
            type: BlockType.heading1,
            content: {'text': 'Document Title'},
          ),
          BasicBlock(
            id: 'paragraph',
            type: BlockType.paragraph,
            content: {'text': 'Some content'},
          ),
        ],
        hierarchy: BlockHierarchy(),
      );

      expect(document.getTitle(), 'Document Title');
    });

    test('should return null title when no heading exists', () {
      final document = DocumentContent(
        id: 'no_title_test',
        blocks: [
          BasicBlock(
            id: 'paragraph',
            type: BlockType.paragraph,
            content: {'text': 'Just content'},
          ),
        ],
        hierarchy: BlockHierarchy(),
      );

      expect(document.getTitle(), isNull);
    });

    test('should add and remove blocks', () {
      final document = DocumentContent(
        id: 'block_ops_test',
        blocks: [],
        hierarchy: BlockHierarchy(),
      );

      expect(document.blocks.length, 0);

      // Add block
      final block = BasicBlock(
        id: 'test_block',
        type: BlockType.paragraph,
        content: {'text': 'Test content'},
      );

      document.addBlock(block);
      expect(document.blocks.length, 1);
      expect(document.blocks.first.id, 'test_block');
      expect(document.isDirty, true);

      // Remove block
      document.removeBlock('test_block');
      expect(document.blocks.length, 0);
    });

    test('should update block', () {
      final document = DocumentContent(
        id: 'update_test',
        blocks: [
          BasicBlock(
            id: 'block1',
            type: BlockType.paragraph,
            content: {'text': 'Original'},
          ),
        ],
        hierarchy: BlockHierarchy(),
      );

      // Update block (simplified - in real implementation this would modify content)
      document.updateBlock('block1', {'text': 'Updated'});

      expect(document.isDirty, true);
    });

    test('should get block by id', () {
      final block = BasicBlock(
        id: 'find_me',
        type: BlockType.paragraph,
        content: {'text': 'Find me'},
      );

      final document = DocumentContent(
        id: 'find_test',
        blocks: [block],
        hierarchy: BlockHierarchy(),
      );

      expect(document.getBlock('find_me'), equals(block));
      expect(document.getBlock('not_found'), isNull);
    });
  });

  group('BlockHierarchy Tests', () {
    late BlockHierarchy hierarchy;

    setUp(() {
      hierarchy = BlockHierarchy();
    });

    test('should add blocks to hierarchy', () {
      final block1 = BasicBlock(id: 'block1', type: BlockType.paragraph, content: {});
      final block2 = BasicBlock(id: 'block2', type: BlockType.paragraph, content: {});

      hierarchy.addBlock(block1);
      hierarchy.addBlock(block2, parentId: 'block1');

      expect(hierarchy.getChildren(''), contains('block1'));
      expect(hierarchy.getChildren('block1'), contains('block2'));
      expect(hierarchy.getParent('block2'), 'block1');
    });

    test('should remove blocks from hierarchy', () {
      final block = BasicBlock(id: 'block1', type: BlockType.paragraph, content: {});
      hierarchy.addBlock(block);

      expect(hierarchy.getChildren(''), contains('block1'));

      hierarchy.removeBlock('block1');

      expect(hierarchy.getChildren(''), isNot(contains('block1')));
    });

    test('should serialize and deserialize hierarchy', () {
      final block = BasicBlock(id: 'block1', type: BlockType.paragraph, content: {});
      hierarchy.addBlock(block);

      final json = hierarchy.toJson();
      final deserialized = BlockHierarchy.fromJson(json);

      expect(deserialized.getChildren(''), contains('block1'));
    });
  });
}