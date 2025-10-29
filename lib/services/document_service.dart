import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/hybrid_canvas_document_bridge.dart';
import '../models/documents/document_content.dart';
import '../models/documents/block_types.dart';

// Simple Block implementation for document service
class _SimpleBlock extends Block {
  _SimpleBlock({
    required super.id,
    required super.type,
    required super.content,
    super.properties,
  });

  @override
  String getPlainText() {
    return content['text'] ?? '';
  }

  @override
  Widget render() {
    return Text(getPlainText());
  }

  @override
  Block clone() {
    return _SimpleBlock(
      id: '${id}_copy',
      type: type,
      content: Map.from(content),
      properties: Map.from(properties),
    );
  }
}

/// Implementation of DocumentService for file-based storage
class DocumentServiceImpl implements DocumentService {
  final Map<String, DocumentContent> _documents = {};
  final StreamController<DocumentEvent> _eventController = StreamController<DocumentEvent>.broadcast();

  Timer? _autoSaveTimer;
  final Map<String, Timer> _documentTimers = {};

  DocumentServiceImpl() {
    _startAutoSaveTimer();
    _loadExistingDocuments();
  }

  @override
  Map<String, DocumentContent> get documents => Map.unmodifiable(_documents);

  @override
  Stream<DocumentEvent> get events => _eventController.stream;

  @override
  Future<DocumentContent> loadDocument(String documentId) async {
    if (_documents.containsKey(documentId)) {
      return _documents[documentId]!;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/documents/$documentId.json';
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final document = DocumentContent.fromJson(data);

        _documents[documentId] = document;
        _eventController.add(DocumentEvent(documentId, DocumentEventType.documentLoaded));
        return document;
      } else {
        // Create new empty document
        final document = DocumentContent(
          id: documentId,
          blocks: [],
          hierarchy: BlockHierarchy(),
        );
        _documents[documentId] = document;
        return document;
      }
    } catch (e) {
      debugPrint('Error loading document $documentId: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveDocument(String documentId) async {
    final document = _documents[documentId];
    if (document == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final docDir = Directory('${directory.path}/documents');
      await docDir.create(recursive: true);

      final filePath = '${docDir.path}/$documentId.json';
      final tempFilePath = '$filePath.tmp';

      // Write to temp file first (atomic write)
      final tempFile = File(tempFilePath);
      final jsonString = jsonEncode(document.toJson());
      await tempFile.writeAsString(jsonString);

      // Atomic rename
      await tempFile.rename(filePath);

      document.markClean();
      _eventController.add(DocumentEvent(documentId, DocumentEventType.documentSaved));

      // Generate thumbnail
      await _generateThumbnail(documentId, document);
    } catch (e) {
      debugPrint('Error saving document $documentId: $e');
      rethrow;
    }
  }

  @override
  Future<void> createDocument(String title) async {
    final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final document = DocumentContent(
      id: documentId,
      blocks: [
        // Create a simple block - will need to be replaced with proper Block implementation
        _SimpleBlock(
          id: 'block_${DateTime.now().millisecondsSinceEpoch}',
          type: BlockType.heading1,
          content: {'text': title},
        ),
      ],
      hierarchy: BlockHierarchy(),
    );

    _documents[documentId] = document;
    await saveDocument(documentId);
    _eventController.add(DocumentEvent(documentId, DocumentEventType.documentCreated));
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    _documents.remove(documentId);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/documents/$documentId.json';
      final thumbnailPath = '${directory.path}/thumbnails/$documentId.png';

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }

      _eventController.add(DocumentEvent(documentId, DocumentEventType.documentDeleted));
    } catch (e) {
      debugPrint('Error deleting document $documentId: $e');
    }
  }

  @override
  void scrollToBlock(String blockId) {
    // Implementation depends on UI - for now just emit event
    _eventController.add(DocumentEvent('', DocumentEventType.blockModified, {'blockId': blockId, 'action': 'scrollTo'}));
  }

  @override
  void highlightBlock(String blockId, {Duration duration = const Duration(seconds: 2)}) {
    _eventController.add(DocumentEvent('', DocumentEventType.blockModified, {'blockId': blockId, 'action': 'highlight', 'duration': duration}));
  }

  Future<void> _loadExistingDocuments() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final docDir = Directory('${directory.path}/documents');

      if (!await docDir.exists()) return;

      final files = docDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));

      for (final file in files) {
        try {
          final jsonString = await file.readAsString();
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          final document = DocumentContent.fromJson(data);
          _documents[document.id] = document;
        } catch (e) {
          debugPrint('Error loading document from ${file.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading existing documents: $e');
    }
  }

  Future<void> _generateThumbnail(String documentId, DocumentContent document) async {
    // TODO: Implement thumbnail generation
    // For now, just create a placeholder
    try {
      final directory = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory('${directory.path}/thumbnails');
      await thumbnailDir.create(recursive: true);

      // Simple placeholder - in real implementation, render document to image
      final thumbnailPath = '${thumbnailDir.path}/$documentId.png';
      // TODO: Generate actual thumbnail image
    } catch (e) {
      debugPrint('Error generating thumbnail for $documentId: $e');
    }
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _autoSaveDirtyDocuments();
    });
  }

  Future<void> _autoSaveDirtyDocuments() async {
    final dirtyDocs = _documents.entries.where((entry) => entry.value.isDirty).toList();

    for (final entry in dirtyDocs) {
      try {
        await saveDocument(entry.key);
      } catch (e) {
        debugPrint('Auto-save failed for ${entry.key}: $e');
      }
    }
  }

  void updateDocument(String documentId, DocumentContent updatedDocument) {
    _documents[documentId] = updatedDocument;
    _eventController.add(DocumentEvent(documentId, DocumentEventType.documentModified));
  }

  void dispose() {
    _autoSaveTimer?.cancel();
    for (final timer in _documentTimers.values) {
      timer.cancel();
    }
    _eventController.close();
  }
}