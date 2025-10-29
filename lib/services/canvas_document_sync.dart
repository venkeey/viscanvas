import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/hybrid_canvas_document_bridge.dart';
import '../models/canvas_objects/canvas_object.dart';
import '../models/canvas_objects/document_block.dart';
import '../models/documents/document_content.dart';

/// Service for synchronizing changes between canvas and document systems
class CanvasDocumentSyncService {
  final CanvasService _canvasService;
  final DocumentService _documentService;
  final CrossReferenceManager _refManager;

  final StreamController<SyncEvent> _syncController = StreamController<SyncEvent>.broadcast();

  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 16); // ~60 FPS

  // Track pending changes
  final Set<String> _pendingCanvasChanges = {};
  final Set<String> _pendingDocumentChanges = {};

  Stream<SyncEvent> get syncEvents => _syncController.stream;

  CanvasDocumentSyncService({
    required CanvasService canvasService,
    required DocumentService documentService,
    required CrossReferenceManager refManager,
  }) : _canvasService = canvasService,
       _documentService = documentService,
       _refManager = refManager {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen to canvas events
    _canvasService.events.listen(_onCanvasEvent);

    // Listen to document events
    _documentService.events.listen(_onDocumentEvent);

    // Listen to reference events
    _refManager.events.listen(_onReferenceEvent);
  }

  void _onCanvasEvent(CanvasEvent event) {
    switch (event.type) {
      case CanvasEventType.objectAdded:
        _handleCanvasObjectAdded(event.objectId);
        break;
      case CanvasEventType.objectRemoved:
        _handleCanvasObjectRemoved(event.objectId);
        break;
      case CanvasEventType.objectModified:
        _handleCanvasObjectModified(event.objectId, event.changes);
        break;
      default:
        break;
    }
  }

  void _onDocumentEvent(DocumentEvent event) {
    switch (event.type) {
      case DocumentEventType.documentModified:
        _handleDocumentModified(event.documentId);
        break;
      case DocumentEventType.documentDeleted:
        _handleDocumentDeleted(event.documentId);
        break;
      default:
        break;
    }
  }

  void _onReferenceEvent(ReferenceEvent event) {
    // Handle reference changes that might affect sync
    _syncController.add(SyncEvent(SyncEventType.referenceChanged, event.referenceId));
  }

  void _handleCanvasObjectAdded(String objectId) {
    _pendingCanvasChanges.add(objectId);
    _debounceSync();
  }

  void _handleCanvasObjectRemoved(String objectId) {
    // Clean up references
    _refManager.removeReferencesForCanvasObject(objectId);
    _pendingCanvasChanges.remove(objectId);
    _debounceSync();
  }

  void _handleCanvasObjectModified(String objectId, Map<String, dynamic>? changes) {
    if (changes != null && changes.containsKey('position')) {
      // Position changes might affect references
      _pendingCanvasChanges.add(objectId);
      _debounceSync();
    }
  }

  void _handleDocumentModified(String documentId) {
    _pendingDocumentChanges.add(documentId);
    _debounceSync();
  }

  void _handleDocumentDeleted(String documentId) {
    // Remove document blocks from canvas
    // This would be handled by the bridge, but we emit sync event
    _refManager.removeReferencesForDocument(documentId);
    _pendingDocumentChanges.remove(documentId);
    _debounceSync();
  }

  void _debounceSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _performSync);
  }

  Future<void> _performSync() async {
    try {
      // Sync canvas changes to documents
      for (final objectId in _pendingCanvasChanges) {
        await _syncCanvasObjectToDocuments(objectId);
      }
      _pendingCanvasChanges.clear();

      // Sync document changes to canvas
      for (final documentId in _pendingDocumentChanges) {
        await _syncDocumentToCanvas(documentId);
      }
      _pendingDocumentChanges.clear();

      _syncController.add(SyncEvent(SyncEventType.syncCompleted, null));
    } catch (e) {
      debugPrint('Sync error: $e');
      _syncController.add(SyncEvent(SyncEventType.syncError, e.toString()));
    }
  }

  Future<void> _syncCanvasObjectToDocuments(String objectId) async {
    // Find document blocks that reference this canvas object
    final refs = _refManager.findByCanvasObject(objectId);

    for (final ref in refs) {
      // Update document with canvas object changes
      // This is a placeholder - actual implementation would depend on the reference type
      _syncController.add(SyncEvent(SyncEventType.canvasToDocument, ref.documentBlockId));
    }
  }

  Future<void> _syncDocumentToCanvas(String documentId) async {
    // Find canvas objects that display this document
    final canvasObjects = _canvasService.objects.whereType<DocumentBlock>();

    for (final docBlock in canvasObjects) {
      if (docBlock.documentId == documentId) {
        // Update canvas preview
        docBlock.invalidateThumbnail();
        _canvasService.updateObject(docBlock.id, {'preview': 'updated'});
        _syncController.add(SyncEvent(SyncEventType.documentToCanvas, docBlock.id));
      }
    }
  }

  // Manual sync methods
  Future<void> forceSync() async {
    _debounceTimer?.cancel();
    await _performSync();
  }

  Future<void> syncCanvasToDocuments() async {
    final allObjects = _canvasService.objects.map((obj) => obj.id).toSet();
    _pendingCanvasChanges.addAll(allObjects);
    await forceSync();
  }

  Future<void> syncDocumentsToCanvas() async {
    final allDocuments = _documentService.documents.keys.toSet();
    _pendingDocumentChanges.addAll(allDocuments);
    await forceSync();
  }

  // Conflict resolution
  Future<bool> resolveConflict(String canvasObjectId, String documentId, ConflictResolution resolution) async {
    // Placeholder for conflict resolution logic
    // In a real implementation, this would handle merge conflicts
    switch (resolution.resolution) {
      case ResolutionType.keepCanvas:
        // Keep canvas version, update document
        await _syncCanvasObjectToDocuments(canvasObjectId);
        break;
      case ResolutionType.keepDocument:
        // Keep document version, update canvas
        await _syncDocumentToCanvas(documentId);
        break;
      case ResolutionType.manualMerge:
        // Show manual merge UI (not implemented)
        break;
    }
    return true;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _syncController.close();
  }
}

/// Sync event types
enum SyncEventType {
  canvasToDocument,
  documentToCanvas,
  referenceChanged,
  syncCompleted,
  syncError,
}

/// Sync event class
class SyncEvent {
  final SyncEventType type;
  final String? data;

  SyncEvent(this.type, this.data);
}

/// Conflict resolution types
enum ResolutionType {
  keepCanvas,
  keepDocument,
  manualMerge,
}

/// Conflict resolution data
class ConflictResolution {
  final ResolutionType resolution;
  final String? message;

  ConflictResolution({
    required this.resolution,
    this.message,
  });
}