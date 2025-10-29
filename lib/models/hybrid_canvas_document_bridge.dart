import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'canvas_objects/canvas_object.dart';
import 'canvas_objects/document_block.dart';
import 'documents/document_content.dart';

/// Service interfaces for canvas and document systems
/// These would be implemented by the actual canvas and document services

enum HybridMode {
  canvasOnly,      // Pure canvas interaction
  documentOnly,    // Full-screen document editing
  overlay,         // Document floats over canvas
  splitView,       // Side-by-side canvas and document
  hybrid,          // Document editing + canvas panning (two-finger)
}

enum GestureType {
  tap,
  pan,
  pinch,
  longPress,
}

abstract class CanvasService {
  List<CanvasObject> get objects;
  Stream<CanvasEvent> get events;
  void addObject(CanvasObject object);
  void removeObject(String objectId);
  void updateObject(String objectId, Map<String, dynamic> changes);
  void panToObject(String objectId);
  void highlightObject(String objectId, {Duration duration = const Duration(seconds: 2)});
  Future<void> saveCanvas();
  Future<void> loadCanvas();
}

abstract class DocumentService {
  Map<String, DocumentContent> get documents;
  Stream<DocumentEvent> get events;
  Future<DocumentContent> loadDocument(String documentId);
  Future<void> saveDocument(String documentId);
  Future<void> createDocument(String title);
  Future<void> deleteDocument(String documentId);
  void scrollToBlock(String blockId);
  void highlightBlock(String blockId, {Duration duration = const Duration(seconds: 2)});
}

abstract class CrossReferenceManager {
  List<CanvasReference> get references;
  Stream<ReferenceEvent> get events;
  CanvasReference create(String canvasObjectId, String documentBlockId);
  void remove(String referenceId);
  List<CanvasReference> findByCanvasObject(String canvasObjectId);
  List<CanvasReference> findByDocument(String documentId);
  bool validateReference(CanvasReference ref);
  void removeReferencesForCanvasObject(String canvasObjectId);
  void removeReferencesForDocument(String documentId);
}

/// Event classes for system communication

abstract class HybridEvent {
  final DateTime timestamp;
  HybridEvent() : timestamp = DateTime.now();
}

class CanvasEvent extends HybridEvent {
  final String objectId;
  final CanvasEventType type;
  final Map<String, dynamic>? changes;

  CanvasEvent(this.objectId, this.type, [this.changes]);
}

enum CanvasEventType {
  objectAdded,
  objectRemoved,
  objectModified,
  objectSelected,
  objectMoved,
}

class DocumentEvent extends HybridEvent {
  final String documentId;
  final DocumentEventType type;
  final Map<String, dynamic>? changes;

  DocumentEvent(this.documentId, this.type, [this.changes]);
}

enum DocumentEventType {
  documentLoaded,
  documentSaved,
  documentModified,
  documentCreated,
  documentDeleted,
  blockAdded,
  blockRemoved,
  blockModified,
}

class ReferenceEvent extends HybridEvent {
  final String referenceId;
  final ReferenceEventType type;

  ReferenceEvent(this.referenceId, this.type);
}

enum ReferenceEventType {
  referenceCreated,
  referenceRemoved,
  referenceInvalidated,
}

/// Main bridge class for coordinating canvas and document systems

class HybridCanvasDocumentBridge extends ChangeNotifier {
  final CanvasService canvasService;
  final DocumentService documentService;
  final CrossReferenceManager refManager;

  // State management
  HybridMode _currentMode = HybridMode.canvasOnly;
  String? _activeDocumentId;
  DocumentBlock? _activeDocumentBlock;

  // Gesture state
  bool _canPanCanvas = true;
  bool _canEditDocument = false;
  int _fingerCount = 0;

  // Auto-save timers
  Timer? _canvasSaveTimer;
  Timer? _documentSaveTimer;

  // Event subscriptions
  StreamSubscription<CanvasEvent>? _canvasSubscription;
  StreamSubscription<DocumentEvent>? _documentSubscription;
  StreamSubscription<ReferenceEvent>? _referenceSubscription;

  HybridCanvasDocumentBridge({
    required this.canvasService,
    required this.documentService,
    required this.refManager,
  }) {
    _setupEventListeners();
    _startAutoSaveTimers();
  }

  // Getters
  HybridMode get currentMode => _currentMode;
  String? get activeDocumentId => _activeDocumentId;
  DocumentBlock? get activeDocumentBlock => _activeDocumentBlock;
  bool get canPanCanvas => _canPanCanvas;
  bool get canEditDocument => _canEditDocument;
  bool get isHybridMode => _currentMode == HybridMode.hybrid;

  // Mode transitions
  void enterCanvasMode() {
    _currentMode = HybridMode.canvasOnly;
    _activeDocumentId = null;
    _activeDocumentBlock = null;
    _canPanCanvas = true;
    _canEditDocument = false;
    notifyListeners();
  }

  void enterDocumentMode(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.documentOnly;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = false;
    _canEditDocument = true;
    notifyListeners();
  }

  void enterOverlayMode(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.overlay;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = true;
    _canEditDocument = true;
    notifyListeners();
  }

  void enterSplitView(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.splitView;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = true;
    _canEditDocument = true;
    notifyListeners();
  }

  void enterHybridMode(String documentId, DocumentBlock docBlock) {
    _currentMode = HybridMode.hybrid;
    _activeDocumentId = documentId;
    _activeDocumentBlock = docBlock;
    _canPanCanvas = false; // Will be enabled with two-finger gesture
    _canEditDocument = true;
    notifyListeners();
  }

  void exitHybridMode() {
    enterCanvasMode();
  }

  // Gesture handling
  void handleGesture(GestureType type, {int fingerCount = 1}) {
    _fingerCount = fingerCount;

    switch (_currentMode) {
      case HybridMode.canvasOnly:
        _canPanCanvas = true;
        _canEditDocument = false;
        break;

      case HybridMode.documentOnly:
        _canPanCanvas = false;
        _canEditDocument = true;
        break;

      case HybridMode.overlay:
        _canPanCanvas = type != GestureType.tap;
        _canEditDocument = true;
        break;

      case HybridMode.splitView:
        _canPanCanvas = true;
        _canEditDocument = true;
        break;

      case HybridMode.hybrid:
        // Two-finger pan for canvas, one-finger for document
        _canPanCanvas = fingerCount >= 2;
        _canEditDocument = fingerCount == 1;
        break;
    }

    notifyListeners();
  }

  // Keyboard shortcuts
  void handleKeyPress(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      if (_currentMode != HybridMode.canvasOnly) {
        exitHybridMode();
      }
    } else if (key == LogicalKeyboardKey.space && _currentMode == HybridMode.hybrid) {
      // Hold space to enable canvas pan
      _canPanCanvas = true;
      notifyListeners();
    }
  }

  void handleKeyRelease(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space && _currentMode == HybridMode.hybrid) {
      _canPanCanvas = false;
      notifyListeners();
    }
  }

  // User actions
  Future<void> openDocumentEditor(String documentId) async {
    try {
      // Load document content
      final content = await documentService.loadDocument(documentId);

      // Find the document block on canvas
      final docBlock = canvasService.objects
          .whereType<DocumentBlock>()
          .firstWhere((block) => block.documentId == documentId);

      // Enter hybrid mode
      enterHybridMode(documentId, docBlock);
    } catch (e) {
      debugPrint('Error opening document editor: $e');
    }
  }

  Future<void> closeDocumentEditor() async {
    if (_activeDocumentId != null) {
      await documentService.saveDocument(_activeDocumentId!);
    }
    exitHybridMode();
  }

  Future<void> createNewDocument(Offset position) async {
    try {
      // Create new document
      final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      await documentService.createDocument('Untitled Document');

      // Create document block on canvas
      final docBlock = DocumentBlock(
        id: 'block_${documentId}',
        worldPosition: position,
        strokeColor: Colors.blue,
        documentId: documentId,
        content: DocumentContent(
          id: documentId,
          blocks: [],
          hierarchy: BlockHierarchy(),
        ),
      );

      canvasService.addObject(docBlock);

      // Open editor
      await openDocumentEditor(documentId);
    } catch (e) {
      debugPrint('Error creating new document: $e');
    }
  }

  // Cross-reference management
  void createReference(String canvasObjectId, String documentBlockId) {
    final ref = refManager.create(canvasObjectId, documentBlockId);
    // Add to document and canvas
    // Implementation depends on actual service interfaces
  }

  void navigateToReference(CanvasReference ref) {
    // Navigate based on reference type
    switch (ref.type) {
      case ReferenceType.mention:
      case ReferenceType.link:
        enterCanvasMode();
        canvasService.panToObject(ref.canvasObjectId);
        canvasService.highlightObject(ref.canvasObjectId);
        break;
      case ReferenceType.embed:
        if (_activeDocumentId != null) {
          documentService.scrollToBlock(ref.documentBlockId);
          documentService.highlightBlock(ref.documentBlockId);
        }
        break;
    }
  }

  // Event handling
  void _setupEventListeners() {
    _canvasSubscription = canvasService.events.listen(_onCanvasEvent);
    _documentSubscription = documentService.events.listen(_onDocumentEvent);
    _referenceSubscription = refManager.events.listen(_onReferenceEvent);
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
    // Handle reference changes
    notifyListeners();
  }

  void _handleCanvasObjectAdded(String objectId) {
    final objects = canvasService.objects;
    final obj = objects.firstWhere((o) => o.id == objectId);
    if (obj is DocumentBlock) {
      // Update document previews if needed
      _updateDocumentPreviews();
    }
  }

  void _handleCanvasObjectRemoved(String objectId) {
    // Clean up references
    final refs = refManager.findByCanvasObject(objectId);
    for (final ref in refs) {
      refManager.remove(ref.id);
    }
  }

  void _handleCanvasObjectModified(String objectId, Map<String, dynamic>? changes) {
    if (changes != null && changes.containsKey('position')) {
      // Update position-based references
      _updatePositionReferences(objectId);
    }
  }

  void _handleDocumentModified(String documentId) {
    // Update canvas preview
    _updateDocumentPreviews();
  }

  void _handleDocumentDeleted(String documentId) {
    // Remove document blocks from canvas
    final blocksToRemove = canvasService.objects
        .whereType<DocumentBlock>()
        .where((block) => block.documentId == documentId)
        .toList();

    for (final block in blocksToRemove) {
      canvasService.removeObject(block.id);
    }
  }

  void _updateDocumentPreviews() {
    // Trigger canvas redraw to update document previews
    notifyListeners();
  }

  void _updatePositionReferences(String objectId) {
    // Update any position-based references
    final refs = refManager.findByCanvasObject(objectId);
    for (final ref in refs) {
      // Update reference positions if needed
    }
  }

  // Auto-save functionality
  void _startAutoSaveTimers() {
    // Canvas auto-save every 30 seconds
    _canvasSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      canvasService.saveCanvas();
    });

    // Document auto-save every 10 seconds
    _documentSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _autoSaveDocuments();
    });
  }

  Future<void> _autoSaveDocuments() async {
    for (final docId in documentService.documents.keys) {
      final doc = documentService.documents[docId];
      if (doc != null && doc.isDirty) {
        await documentService.saveDocument(docId);
      }
    }
  }

  @override
  void dispose() {
    _canvasSubscription?.cancel();
    _documentSubscription?.cancel();
    _referenceSubscription?.cancel();
    _canvasSaveTimer?.cancel();
    _documentSaveTimer?.cancel();
    super.dispose();
  }
}