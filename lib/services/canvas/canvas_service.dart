import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/canvas_domain.dart';
import '../../models/canvas_objects/canvas_object.dart';
import '../../models/canvas_objects/document_block.dart';
import '../../models/canvas_objects/connector.dart';
import '../../models/documents/document_content.dart';
import 'canvas_persistence_service.dart';
import 'canvas_tools_service.dart';
import 'canvas_connector_service.dart';
import 'canvas_document_service.dart';
import 'canvas_transform_service.dart';

// ===== MAIN CANVAS SERVICE =====

class CanvasService extends ChangeNotifier {
  // Global switch to disable autosave and autosave loading during tests
  static bool globalAutoSaveEnabled = true;
  late final InMemoryCanvasRepository _repository;
  late final CommandHistory _commandHistory;
  late final SelectObjectUseCase _selectObjectUseCase;
  late final HitTestUseCase _hitTestUseCase;

  // Delegate services
  late final CanvasPersistenceService _persistenceService;
  late final CanvasToolsService _toolsService;
  late final CanvasConnectorService _connectorService;
  late final CanvasDocumentService _documentService;
  late final CanvasTransformService _transformService;

  // Callback for opening document editor (set by canvas screen)
  void Function(DocumentBlock)? onOpenDocumentEditor;

  // Core state
  ToolType _currentTool = ToolType

  // Auto-save state
  Timer? _autoSaveTimer;
  bool _autoSaveEnabled = true;

  CanvasService() {
    // Initialize core services
    final spatialIndex = QuadTree(
      bounds: const Rect.fromLTWH(-10000, -10000, 20000, 20000),
      capacity: 4,
      maxDepth: 8,
    );
    _repository = InMemoryCanvasRepository(spatialIndex);
    _commandHistory = CommandHistory(maxHistorySize: 100);
    _selectObjectUseCase = SelectObjectUseCase(_repository);
    _hitTestUseCase = HitTestUseCase(_repository);

    // Initialize delegate services
    _persistenceService = CanvasPersistenceService(_repository, _commandHistory);
    _connectorService = CanvasConnectorService(_repository, _commandHistory, _hitTestUseCase);
    _toolsService = CanvasToolsService(_repository, _commandHistory, _selectObjectUseCase, _hitTestUseCase, _connectorService);
    _documentService = CanvasDocumentService(_repository, _commandHistory);
    _transformService = CanvasTransformService();

    // Wire up callbacks
    _toolsService.onToolChanged = (tool) {
      _currentTool = tool;
      notifyListeners();
    };
    _toolsService.onTransformChanged = (transform) {
      _transformService.updateTransform(transform);
      notifyListeners();
    };
    _toolsService.onSelectionChanged = () => notifyListeners();
    _toolsService.onObjectCreated = () => notifyListeners();
    _toolsService.onObjectModified = () => notifyListeners();
    
    _connectorService.onConnectorStateChanged = () => notifyListeners();
    _documentService.onOpenDocumentEditor = onOpenDocumentEditor;
    _documentService.onDocumentChanged = () => notifyListeners();

    // Respect global flag for tests
    _autoSaveEnabled = globalAutoSaveEnabled;

    // Start auto-save timer (every 30 seconds)
    if (_autoSaveEnabled) {
      _startAutoSave();
    }

    // Try to load last autosaved canvas
    if (_autoSaveEnabled) {
      _loadAutoSave();
    }
  }

  // ===== PUBLIC API =====

  // Getters
  List<CanvasObject> get objects => _repository.getAll();
  ToolType get currentTool => _currentTool;
  Color get strokeColor => _strokeColor;
  Color get fillColor => _fillColor;
  double get strokeWidth => _strokeWidth;
  Transform2D get transform => _transformService.transform;
  bool get canUndo => _commandHistory.canUndo();
  bool get canRedo => _commandHistory.canRedo();
  CanvasObject? get connectorSourceObject => _connectorService.connectorSourceObject;
  FreehandConnector? get currentFreehandConnector => _connectorService.currentFreehandConnector;
  bool get showConnectorConfirmation => _connectorService.showConnectorConfirmation;
  ConnectorAnalysis? get currentConnectorAnalysis => _connectorService.currentConnectorAnalysis;
  CanvasObject? get connectorHoverTarget => _connectorService.connectorHoverTarget;
  Offset? get lastWorldPoint => _toolsService.lastWorldPoint;
  CanvasObject? get tempObject => _toolsService.tempObject;

  // Tool management
  void setTool(ToolType tool) {
    _currentTool = tool;
    _toolsService.clearSelection();
    notifyListeners();
  }

  // Style management
  void setStrokeColor(Color color) {
    _strokeColor = color;
    _toolsService.updateSelectedObjectsStrokeColor(color);
    notifyListeners();
  }

  void setFillColor(Color color) {
    _fillColor = color;
    _toolsService.updateSelectedObjectsFillColor(color);
    notifyListeners();
  }

  void setStickyNoteBackgroundColor(Color color) {
    _toolsService.updateSelectedStickyNoteBackgroundColor(color);
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    _toolsService.updateSelectedObjectsStrokeWidth(width);
    notifyListeners();
  }

  // Command history
  void undo() {
    _commandHistory.undo();
    notifyListeners();
  }

  void redo() {
    _commandHistory.redo();
    notifyListeners();
  }

  void deleteSelected() {
    _toolsService.deleteSelected();
    notifyListeners();
  }

  // Delete all objects on the canvas
  void deleteAll() {
    // Work on a copy to avoid concurrent modification
    final all = List<CanvasObject>.from(objects);
    for (final obj in all) {
      // Select and delete each to ensure proper command history integration
      _selectObjectUseCase.execute(obj.id, multiSelect: false);
      _toolsService.deleteSelected();
    }
    notifyListeners();
  }

  // Rename / set a human-friendly label for an object
  void setObjectLabel(String objectId, String? newLabel) {
    for (var obj in objects) {
      if (obj.id == objectId) {
        obj.label = (newLabel == null || newLabel.trim().isEmpty) ? null : newLabel.trim();
        break;
      }
    }
    notifyListeners();
  }

  void selectObjectById(String objectId) {
    _selectObjectUseCase.execute(objectId, multiSelect: false);
    notifyListeners();
  }

  // Transform management
  void updateTransform(Offset pan, double newScale) {
    _transformService.updateTransform(Transform2D(
      translation: pan,
      scale: newScale.clamp(0.1, 10.0),
    ));
    notifyListeners();
  }

  // Interaction events
  void onPanStart(Offset screenPoint) {
    _toolsService.onPanStart(screenPoint, _currentTool, _transformService.transform, _strokeColor, _fillColor, _strokeWidth);
  }

  void onPanUpdate(Offset screenPoint, Offset delta) {
    _toolsService.onPanUpdate(screenPoint, delta, _currentTool, _transformService.transform);
  }

  void onPanEnd() {
    _toolsService.onPanEnd(_currentTool);
  }

  void onTap(Offset screenPoint) {
    _toolsService.onTap(screenPoint, _transformService.transform);
  }

  // Document editing
  void updateDocumentBlockContent(String documentBlockId, DocumentContent newContent) {
    _documentService.updateDocumentBlockContent(documentBlockId, newContent);
  }

  void updateStickyNoteText(String newText) {
    _documentService.updateStickyNoteText(newText);
  }

  void stopEditingStickyNote() {
    _documentService.stopEditingStickyNote();
  }

  // Connector methods
  void confirmFreehandConnection() {
    _connectorService.confirmFreehandConnection();
  }

  void cancelFreehandConnection() {
    _connectorService.cancelFreehandConnection();
  }

  // Persistence
  Future<void> saveCanvasToFile({required String fileName}) async {
    await _persistenceService.saveCanvasToFile(objects, _transformService.transform, fileName);
  }

  Future<void> loadCanvasFromFile({required String fileName}) async {
    final data = await _persistenceService.loadCanvasFromFile(fileName);
    if (data != null) {
      _repository.clear();
      for (var obj in data.objects) {
        _repository.add(obj);
      }
      _transformService.updateTransform(data.transform);
      notifyListeners();
    }
  }

  Future<List<FileSystemEntity>> getSavedCanvases() async {
    return await _persistenceService.getSavedCanvases();
  }

  Future<bool> deleteCanvas(String fileName) async {
    return await _persistenceService.deleteCanvas(fileName);
  }

  // Auto-save control
  void setAutoSaveEnabled(bool enabled) {
    _autoSaveEnabled = enabled;
    if (enabled) {
      _startAutoSave();
    } else {
      _autoSaveTimer?.cancel();
    }
    notifyListeners();
  }

  bool get isAutoSaveEnabled => _autoSaveEnabled;

  // ===== PRIVATE METHODS =====

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (!_autoSaveEnabled || objects.isEmpty) return;

    try {
      await _persistenceService.autoSave(objects, _transformService.transform);
    } catch (e) {
      print('❌ Auto-save failed: $e');
    }
  }

  Future<void> _loadAutoSave() async {
    try {
      final data = await _persistenceService.loadAutoSave();
      if (data != null) {
        _repository.clear();
        for (var obj in data.objects) {
          _repository.add(obj);
        }
        _transformService.updateTransform(data.transform);
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Could not load autosave: $e');
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _toolsService.dispose();
    _connectorService.dispose();
    _documentService.dispose();
    _persistenceService.dispose();
    super.dispose();
  }
}
