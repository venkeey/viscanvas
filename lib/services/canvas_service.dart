import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart' show File;
import '../domain/canvas_domain.dart';
import '../domain/connector_system.dart';
import '../models/canvas_objects/canvas_object.dart';
import '../models/canvas_objects/freehand_path.dart';
import '../models/canvas_objects/canvas_rectangle.dart';
import '../models/canvas_objects/canvas_circle.dart';
import '../models/canvas_objects/sticky_note.dart';
import '../models/canvas_objects/document_block.dart';
import '../models/canvas_objects/connector.dart';
import '../pages/drawing_persistence_service.dart';
import '../models/documents/document_content.dart';
import '../models/documents/block_types.dart';
import '../utils/logger.dart';

// Canvas data structure for serialization
class _CanvasData {
  final List<CanvasObject> objects;
  final Transform2D transform;

  _CanvasData({required this.objects, required this.transform});
}

// ===== 3. APPLICATION SERVICE =====

class CanvasService extends ChangeNotifier {
  late final InMemoryCanvasRepository _repository;
  late final CommandHistory _commandHistory;
  late final SelectObjectUseCase _selectObjectUseCase;
  late final HitTestUseCase _hitTestUseCase;

  // Callback for opening document editor (set by canvas screen)
  void Function(DocumentBlock)? onOpenDocumentEditor;

  // Hybrid canvas-document bridge
  // TODO: Re-enable when bridge interfaces are properly defined
  // late final HybridCanvasDocumentBridge _bridge;
  // late final DocumentService _documentService;
  // late final CrossReferenceManager _refManager;
  // late final CanvasDocumentSyncService _syncService;

  Timer? _autoSaveTimer;
  bool _autoSaveEnabled = true;

  // In-memory web storage simulation
  static final Map<String, String> _webStorage = {};

  ToolType _currentTool = ToolType.select;
  Color _strokeColor = Colors.black;
  Color _fillColor = Colors.transparent;
  double _strokeWidth = 2.0;
  Transform2D _transform = Transform2D(translation: Offset.zero, scale: 1.0);


  // Drawing state
  CanvasObject? _tempObject;
  Offset? _dragStart;
  ResizeHandle _resizeHandle = ResizeHandle.none;
  Offset? _initialWorldPosition;
  Rect? _initialBounds;
  Map<String, CanvasObject>? _preMoveState;

  // Text editing state
  StickyNote? _editingStickyNote;
  Timer? _doubleTapTimer;
  Offset? _lastTapPosition;

  // Connector state
  CanvasObject? _connectorSourceObject;
  FreehandConnector? _currentFreehandConnector;
  ConnectorAnalysis? _currentConnectorAnalysis;
  bool _showConnectorConfirmation = false;
  Offset? _lastWorldPoint;
  CanvasObject? _connectorHoverTarget; // For highlighting potential target

  CanvasService() {
    final spatialIndex = QuadTree(
      bounds: const Rect.fromLTWH(-10000, -10000, 20000, 20000),
      capacity: 4,
      maxDepth: 8,
    );
    _repository = InMemoryCanvasRepository(spatialIndex);
    _commandHistory = CommandHistory(maxHistorySize: 100);
    _selectObjectUseCase = SelectObjectUseCase(_repository);
    _hitTestUseCase = HitTestUseCase(_repository);

    // Initialize hybrid canvas-document services
    // TODO: Re-enable when bridge interfaces are properly defined
    // _documentService = DocumentServiceImpl();
    // _refManager = CrossReferenceManagerImpl();
    // _syncService = CanvasDocumentSyncService(
    //   canvasService: this,
    //   documentService: _documentService,
    //   refManager: _refManager,
    // );

    // // Initialize the bridge
    // _bridge = HybridCanvasDocumentBridge(
    //   canvasService: this,
    //   documentService: _documentService,
    //   refManager: _refManager,
    // );

    // Start auto-save timer (every 30 seconds)
    _startAutoSave();

    // Try to load last autosaved canvas
    _loadAutoSave();
  }

  // Getters
  List<CanvasObject> get objects => _repository.getAll();
  ToolType get currentTool => _currentTool;
  Color get strokeColor => _strokeColor;
  Color get fillColor => _fillColor;
  double get strokeWidth => _strokeWidth;
  Transform2D get transform => _transform;
  bool get canUndo => _commandHistory.canUndo();
  bool get canRedo => _commandHistory.canRedo();
  CanvasObject? get connectorSourceObject => _connectorSourceObject;
  FreehandConnector? get currentFreehandConnector => _currentFreehandConnector;
  bool get showConnectorConfirmation => _showConnectorConfirmation;
  ConnectorAnalysis? get currentConnectorAnalysis => _currentConnectorAnalysis;
  CanvasObject? get connectorHoverTarget => _connectorHoverTarget;
  Offset? get lastWorldPoint => _lastWorldPoint;

  void setTool(ToolType tool) {
    _currentTool = tool;
    _clearSelection();
    notifyListeners();
  }

  void setStrokeColor(Color color) {
    _strokeColor = color;
    for (var obj in _repository.getSelected()) {
      final oldState = obj.clone();
      obj.strokeColor = color;
      _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
    }
    notifyListeners();
  }

  void setFillColor(Color color) {
    _fillColor = color;
    for (var obj in _repository.getSelected()) {
      final oldState = obj.clone();
      obj.fillColor = color;
      _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
    }
    notifyListeners();
  }

  void setStickyNoteBackgroundColor(Color color) {
    for (var obj in _repository.getSelected()) {
      if (obj is StickyNote) {
        final oldState = obj.clone();
        obj.backgroundColor = color;
        _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
      }
    }
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    for (var obj in _repository.getSelected()) {
      final oldState = obj.clone();
      obj.strokeWidth = width;
      _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
    }
    notifyListeners();
  }

  void _clearSelection() {
    for (var obj in objects) {
      obj.isSelected = false;
    }
  }

  void undo() {
    _commandHistory.undo();
    notifyListeners();
  }

  void redo() {
    _commandHistory.redo();
    notifyListeners();
  }

  void deleteSelected() {
    final selected = _repository.getSelected();
    for (var obj in selected) {
      _commandHistory.execute(DeleteObjectCommand(_repository, obj));
    }
    notifyListeners();
  }

  void updateTransform(Offset pan, double newScale) {
    _transform = Transform2D(
      translation: pan,
      scale: newScale.clamp(0.1, 10.0),
    );
    notifyListeners();
  }

  void onPanStart(Offset screenPoint) {
    final worldPoint = _transform.screenToWorld(screenPoint);
    _dragStart = worldPoint;

    if (_currentTool == ToolType.connector) {
      // Connector tool: check if starting from an object OR start freehand
      final hitObj = _hitTestUseCase.execute(worldPoint);

      if (hitObj != null && hitObj is! Connector) {
        // Start drag connection from object
        startDragConnection(hitObj, worldPoint);
      } else {
        // Start freehand connection
        startFreehandConnection(worldPoint);
      }
      return;
    }

    if (_currentTool == ToolType.select) {
      for (var obj in _repository.getSelected()) {
        _resizeHandle = _getResizeHandle(obj, screenPoint);
        if (_resizeHandle != ResizeHandle.none) {
          _initialWorldPosition = obj.worldPosition;
          _initialBounds = obj.getBoundingRect();
          return;
        }
      }

      final hitObj = _hitTestUseCase.execute(worldPoint);
      if (hitObj != null) {
        _clearSelection();
        _selectObjectUseCase.execute(hitObj.id);
        _preMoveState = {hitObj.id: hitObj.clone()};
        notifyListeners();
        return;
      }
      _clearSelection();
      notifyListeners();
    } else if (_currentTool != ToolType.pan) {
      _tempObject = _createObject(worldPoint);
      if (_tempObject != null) {
        _commandHistory.execute(CreateObjectCommand(_repository, _tempObject!));
        // After creating an object, switch back to select mode so user can immediately interact with it
        _currentTool = ToolType.select;
        notifyListeners();
      }
    }
  }

  void onTap(Offset screenPoint) {
    final worldPoint = _transform.screenToWorld(screenPoint);

    if (_currentTool == ToolType.select) {
      _handleDoubleTap(worldPoint);
    }
  }

  void _handleDoubleTap(Offset worldPoint) {
    final hitObj = _hitTestUseCase.execute(worldPoint);

    if (hitObj is StickyNote) {
      if (_lastTapPosition != null &&
          (worldPoint - _lastTapPosition!).distance < 10) {
        // Double tap detected
        _startEditingStickyNote(hitObj);
        _doubleTapTimer?.cancel();
        _lastTapPosition = null;
      } else {
        // First tap
        _lastTapPosition = worldPoint;
        _doubleTapTimer?.cancel();
        _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
          _lastTapPosition = null;
        });
      }
    } else if (hitObj is DocumentBlock) {
      if (_lastTapPosition != null &&
          (worldPoint - _lastTapPosition!).distance < 10) {
        // Double tap detected on document block
        _openDocumentEditor(hitObj);
        _doubleTapTimer?.cancel();
        _lastTapPosition = null;
      } else {
        // First tap
        _lastTapPosition = worldPoint;
        _doubleTapTimer?.cancel();
        _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
          _lastTapPosition = null;
        });
      }
    } else {
      _lastTapPosition = null;
      _doubleTapTimer?.cancel();
    }
  }

  void _startEditingStickyNote(StickyNote stickyNote) {
    _editingStickyNote = stickyNote;
    stickyNote.isEditing = true;
    notifyListeners();
  }

  void stopEditingStickyNote() {
    if (_editingStickyNote != null) {
      _editingStickyNote!.isEditing = false;
      _editingStickyNote = null;
      notifyListeners();
    }
  }

  void updateStickyNoteText(String newText) {
    if (_editingStickyNote != null) {
      final oldState = _editingStickyNote!.clone();
      _editingStickyNote!.text = newText;
      _commandHistory.execute(ModifyObjectCommand(_repository, _editingStickyNote!.id, oldState, _editingStickyNote!));
      notifyListeners();
    }
  }

  void updateDocumentBlockContent(String documentBlockId, DocumentContent newContent) {
    print('🔄 updateDocumentBlockContent called for ID: $documentBlockId');
    CanvasLogger.canvasService('Updating document block content for ID: $documentBlockId');
    final documentBlock = _repository.getById(documentBlockId);
    if (documentBlock is DocumentBlock) {
      print('✅ Found DocumentBlock, old content: ${documentBlock.content?.blocks.length ?? 0} blocks');
      CanvasLogger.canvasService('Found document block, updating content');
      CanvasLogger.canvasService('Old content blocks: ${documentBlock.content?.blocks.length ?? 0}');
      CanvasLogger.canvasService('New content blocks: ${newContent.blocks.length}');

      final oldState = documentBlock.clone();
      documentBlock.content = newContent;
      documentBlock.invalidateCache(); // Clear cached rendering
      print('📝 Set new content: ${documentBlock.content?.blocks.length ?? 0} blocks');
      CanvasLogger.canvasService('Invalidated cache');

      _commandHistory.execute(ModifyObjectCommand(_repository, documentBlock.id, oldState, documentBlock));
      print('💾 Executed modify command');
      CanvasLogger.canvasService('Executed modify command');

      notifyListeners();
      print('🔔 Notified listeners - should trigger autosave');
      CanvasLogger.canvasService('Notified listeners - canvas should redraw');
    } else {
      print('❌ DocumentBlock not found with ID: $documentBlockId');
      CanvasLogger.canvasService('Document block not found with ID: $documentBlockId');
    }
  }

  void _openDocumentEditor(DocumentBlock documentBlock) {
    // Call the callback set by the canvas screen
    onOpenDocumentEditor?.call(documentBlock);
  }

  // ===== Connector Methods =====

  void startDragConnection(CanvasObject sourceObject, Offset worldPoint) {
    _connectorSourceObject = sourceObject;
    _dragStart = worldPoint;
    notifyListeners();
  }

  void updateDragConnection(Offset worldPoint) {
    if (_connectorSourceObject != null) {
      _dragStart = worldPoint;

      // Detect hover target for visual feedback
      final hitObj = _hitTestUseCase.execute(worldPoint);
      if (hitObj != null && hitObj != _connectorSourceObject && hitObj is! Connector) {
        _connectorHoverTarget = hitObj;
      } else {
        _connectorHoverTarget = null;
      }

      notifyListeners();
    }
  }

  void endDragConnection(Offset worldPoint) {
    if (_connectorSourceObject == null) {
      return;
    }

    // Use the hover target if we have one (from dragging over an object)
    // This provides better UX - if they were hovering over a target, use that
    CanvasObject? targetObject = _connectorHoverTarget;

    // If no hover target, try hit test at exact position
    if (targetObject == null) {
      targetObject = _hitTestUseCase.execute(worldPoint);
    }

    if (targetObject != null && targetObject != _connectorSourceObject && targetObject is! Connector) {
      _createConnector(_connectorSourceObject!, targetObject);
    }

    _connectorSourceObject = null;
    _connectorHoverTarget = null;
    _dragStart = null;
    notifyListeners();
  }

  void startFreehandConnection(Offset worldPoint) {
    _currentFreehandConnector = FreehandConnector(color: _strokeColor, strokeWidth: _strokeWidth);
    _currentFreehandConnector!.addPoint(worldPoint);
    _showConnectorConfirmation = false;
    notifyListeners();
  }

  void updateFreehandConnection(Offset worldPoint) {
    if (_currentFreehandConnector != null) {
      _currentFreehandConnector!.addPoint(worldPoint);
      notifyListeners();
    }
  }

  void endFreehandConnection(Offset worldPoint) {
    if (_currentFreehandConnector != null) {
      _currentFreehandConnector!.addPoint(worldPoint);

      // Analyze the stroke for connection intent
      _currentConnectorAnalysis = _currentFreehandConnector!.analyzeStroke(objects);

      if (_currentConnectorAnalysis!.isValidConnection) {
        _showConnectorConfirmation = true;
      } else {
        // If not a valid connection, discard it
        _currentFreehandConnector = null;
        _currentConnectorAnalysis = null;
      }

      notifyListeners();
    }
  }

  void confirmFreehandConnection() {
    if (_currentConnectorAnalysis != null &&
        _currentConnectorAnalysis!.isValidConnection &&
        _currentFreehandConnector != null) {
      final sourceObj = _currentConnectorAnalysis!.sourceObject!;
      final targetObj = _currentConnectorAnalysis!.targetObject!;

      _createConnector(sourceObj, targetObj);
      _cleanupFreehandConnection();
    }
  }

  void cancelFreehandConnection() {
    _cleanupFreehandConnection();
  }

  void _cleanupFreehandConnection() {
    _currentFreehandConnector = null;
    _currentConnectorAnalysis = null;
    _showConnectorConfirmation = false;
    notifyListeners();
  }

  void _createConnector(CanvasObject sourceObj, CanvasObject targetObj) {
    final id = 'connector_${DateTime.now().millisecondsSinceEpoch}';
    final sourcePoint = ConnectorCalculator.getClosestEdgePoint(sourceObj, targetObj.getBoundingRect().center);
    final targetPoint = ConnectorCalculator.getClosestEdgePoint(targetObj, sourceObj.getBoundingRect().center);

    final connector = Connector(
      id: id,
      sourceObject: sourceObj,
      targetObject: targetObj,
      sourcePoint: sourcePoint,
      targetPoint: targetPoint,
      strokeColor: _strokeColor,
      strokeWidth: _strokeWidth,
    );

    _commandHistory.execute(CreateObjectCommand(_repository, connector));
    notifyListeners();
  }

  void updateConnectors({Set<String>? movedObjectIds}) {
    // Optimized: Only update connectors connected to moved objects
    if (movedObjectIds != null && movedObjectIds.isNotEmpty) {
      for (var obj in objects) {
        if (obj is Connector) {
          // Check if this connector is connected to any moved object
          if (movedObjectIds.contains(obj.sourceObject.id) ||
              movedObjectIds.contains(obj.targetObject.id)) {
            obj.updatePoints();
          }
        }
      }
    } else {
      // Fallback: Update all connectors (used when moving multiple objects)
      for (var obj in objects) {
        if (obj is Connector) {
          obj.updatePoints();
        }
      }
    }
  }

  void onPanUpdate(Offset screenPoint, Offset delta) {
    final worldPoint = _transform.screenToWorld(screenPoint);
    _lastWorldPoint = worldPoint; // Track last world point for onPanEnd

    if (_currentTool == ToolType.connector) {
      // Update connector drawing
      if (_connectorSourceObject != null) {
        updateDragConnection(worldPoint);
      } else if (_currentFreehandConnector != null) {
        updateFreehandConnection(worldPoint);
      }
      return;
    }

    if (_currentTool == ToolType.pan) {
      _transform = _transform.copyWith(translation: _transform.translation + delta);
    } else if (_currentTool == ToolType.select) {
      if (_resizeHandle != ResizeHandle.none) {
        final selectedObj = _repository.getSelected().first;
        final worldDelta = worldPoint - _dragStart!;
        selectedObj.resize(_resizeHandle, worldDelta, _initialWorldPosition!, _initialBounds!);
        // Update connectors for resized object
        updateConnectors(movedObjectIds: {selectedObj.id});
      } else {
        final worldDelta = worldPoint - _dragStart!;
        final movedIds = <String>{};
        for (var obj in _repository.getSelected()) {
          obj.move(worldDelta);
          movedIds.add(obj.id);
        }
        // Optimized: Only update connectors connected to moved objects
        updateConnectors(movedObjectIds: movedIds);
        _dragStart = worldPoint;
      }
    } else if (_tempObject != null) {
      _updateTempObject(worldPoint);
    }
    notifyListeners();
  }

  void onPanEnd() {
    if (_currentTool == ToolType.connector) {
      // End connector drawing using last tracked world point
      if (_connectorSourceObject != null && _lastWorldPoint != null) {
        endDragConnection(_lastWorldPoint!);
      } else if (_currentFreehandConnector != null && _lastWorldPoint != null) {
        endFreehandConnection(_lastWorldPoint!);
      }
      _lastWorldPoint = null;
      return;
    }

    if (_preMoveState != null) {
      for (var entry in _preMoveState!.entries) {
        final newState = _repository.getById(entry.key);
        if (newState != null) {
          _commandHistory.execute(ModifyObjectCommand(_repository, entry.key, entry.value, newState.clone()));
        }
      }
      _preMoveState = null;
    }

    _tempObject = null;
    _dragStart = null;
    _resizeHandle = ResizeHandle.none;
    _initialWorldPosition = null;
    _initialBounds = null;
    _lastWorldPoint = null;
  }

  CanvasObject? _createObject(Offset worldPoint) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    switch (_currentTool) {
      case ToolType.freehand:
        return FreehandPath(
          id: id,
          worldPosition: worldPoint,
          strokeColor: _strokeColor,
          strokeWidth: _strokeWidth,
          points: [Offset.zero],
        );
      case ToolType.rectangle:
        return CanvasRectangle(
          id: id,
          worldPosition: worldPoint,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          size: const Size(10, 10), // Start with minimum size for hit detection
        );
      case ToolType.circle:
        return CanvasCircle(
          id: id,
          worldPosition: worldPoint,
          strokeColor: _strokeColor,
          fillColor: _fillColor,
          strokeWidth: _strokeWidth,
          radius: 5, // Start with minimum radius for hit detection
        );
      case ToolType.sticky_note:
        return StickyNote(
          id: id,
          worldPosition: worldPoint,
          strokeColor: _strokeColor,
          strokeWidth: _strokeWidth,
          size: const Size(200, 120),
          backgroundColor: _getStickyNoteColor(),
        );
      case ToolType.document_block:
        return DocumentBlock(
          id: id,
          worldPosition: worldPoint,
          strokeColor: _strokeColor,
          strokeWidth: _strokeWidth,
          documentId: 'doc_${DateTime.now().millisecondsSinceEpoch}',
          size: const Size(400, 300),
        );
      default:
        return null;
    }
  }

  Color _getStickyNoteColor() {
    // Cycle through common sticky note colors
    final colors = [
      Colors.yellow,
      Colors.pink,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.orange,
      Colors.purple,
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  void _updateTempObject(Offset worldPoint) {
    if (_tempObject == null || _dragStart == null) return;

    final delta = worldPoint - _dragStart!;

    if (_tempObject is FreehandPath) {
      (_tempObject as FreehandPath).addPoint(delta);
    } else if (_tempObject is CanvasRectangle) {
      (_tempObject as CanvasRectangle).size = Size(delta.dx.abs(), delta.dy.abs());
    } else if (_tempObject is CanvasCircle) {
      (_tempObject as CanvasCircle).radius = sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
    } else if (_tempObject is StickyNote) {
      (_tempObject as StickyNote).size = Size(
        max(100.0, delta.dx.abs()),
        max(60.0, delta.dy.abs())
      );
    }
  }

  ResizeHandle _getResizeHandle(CanvasObject obj, Offset screenPoint) {
    final bounds = obj.getBoundingRect();
    final path = Path()..addRect(bounds);
    final transformedPath = path.transform(_transform.matrix.storage);
    final rect = transformedPath.getBounds();

    const handleSize = 12.0;

    final handles = {
      ResizeHandle.topLeft: rect.topLeft,
      ResizeHandle.topCenter: rect.topCenter,
      ResizeHandle.topRight: rect.topRight,
      ResizeHandle.centerLeft: rect.centerLeft,
      ResizeHandle.centerRight: rect.centerRight,
      ResizeHandle.bottomLeft: rect.bottomLeft,
      ResizeHandle.bottomCenter: rect.bottomCenter,
      ResizeHandle.bottomRight: rect.bottomRight,
    };

    for (var entry in handles.entries) {
      final handleRect = Rect.fromCenter(center: entry.value, width: handleSize, height: handleSize);
      if (handleRect.contains(screenPoint)) {
        return entry.key;
      }
    }

    return ResizeHandle.none;
  }

  // Auto-save functionality
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (!_autoSaveEnabled || objects.isEmpty) return;

    // Debug: Log what we're saving
    final documentBlocks = objects.whereType<DocumentBlock>().toList();
    print('💾 Auto-saving ${objects.length} objects, ${documentBlocks.length} DocumentBlocks');
    for (final docBlock in documentBlocks) {
      print('   📄 DocumentBlock ${docBlock.id}: content=${docBlock.content?.blocks.length ?? 0} blocks');
    }

    try {
      if (kIsWeb) {
        await _saveToWebStorage('autosave_canvas');
      } else {
        await _saveToFile(objects, _transform, 'autosave_canvas');
      }
      print('✅ Auto-save completed');
    } catch (e) {
      print('❌ Auto-save failed: $e');
    }
  }

  Future<void> _loadAutoSave() async {
    try {
      if (kIsWeb) {
        final data = await _loadFromWebStorage('autosave_canvas');
        if (data != null) {
          _repository.clear();
          for (var obj in data.objects) {
            _repository.add(obj);
          }
          _transform = data.transform;

          // Debug: Log what we loaded
          final documentBlocks = data.objects.whereType<DocumentBlock>().toList();
          print('📂 Loaded ${data.objects.length} objects from web storage, ${documentBlocks.length} DocumentBlocks');
          for (final docBlock in documentBlocks) {
            print('   📄 Loaded DocumentBlock ${docBlock.id}: content=${docBlock.content?.blocks.length ?? 0} blocks');
          }

          notifyListeners();
          print('✅ Restored from web storage');
        }
      } else {
        final data = await _loadFromFile('autosave_canvas');
        if (data != null) {
          _repository.clear();
          for (var obj in data.objects) {
            _repository.add(obj);
          }
          _transform = data.transform;

          // Debug: Log what we loaded
          final documentBlocks = data.objects.whereType<DocumentBlock>().toList();
          print('📂 Loaded ${data.objects.length} objects from file, ${documentBlocks.length} DocumentBlocks');
          for (final docBlock in documentBlocks) {
            print('   📄 Loaded DocumentBlock ${docBlock.id}: content=${docBlock.content?.blocks.length ?? 0} blocks');
          }

          notifyListeners();
          print('✅ Restored from autosave');
        }
      }
    } catch (e) {
      print('⚠️ Could not load autosave: $e');
    }
  }

  // Manual save functionality
  Future<void> saveCanvasToFile({required String fileName}) async {
    try {
      if (kIsWeb) {
        await _saveToWebStorage(fileName);
        print('✅ Canvas saved to web storage as: $fileName');
      } else {
        await _saveToFile(objects, _transform, fileName);
        print('✅ Canvas saved as: $fileName');
      }
    } catch (e) {
      print('❌ Save failed: $e');
      rethrow;
    }
  }

  Future<void> loadCanvasFromFile({required String fileName}) async {
    try {
      if (kIsWeb) {
        final data = await _loadFromWebStorage(fileName);
        if (data != null) {
          _repository.clear();
          for (var obj in data.objects) {
            _repository.add(obj);
          }
          _transform = data.transform;
          notifyListeners();
          print('✅ Canvas loaded from web storage: $fileName');
        }
      } else {
        final data = await _loadFromFile(fileName);
        if (data != null) {
          _repository.clear();
          for (var obj in data.objects) {
            _repository.add(obj);
          }
          _transform = data.transform;
          notifyListeners();
          print('✅ Canvas loaded: $fileName');
        }
      }
    } catch (e) {
      print('❌ Load failed: $e');
      rethrow;
    }
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

  void dispose() {
    _autoSaveTimer?.cancel();
  }

  // Get list of saved canvases for UI
  Future<List<FileInfo>> getSavedCanvases() async {
    try {
      if (kIsWeb) {
        return await _listWebStorageFiles();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final files = directory
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.canvas.json'))
            .toList();

        final fileInfos = <FileInfo>[];
        for (var file in files) {
          final stat = await file.stat();
          final name = file.path.split('/').last.replaceAll('.canvas.json', '');
          fileInfos.add(FileInfo(
            name: name,
            path: file.path,
            lastModified: stat.modified,
            size: stat.size,
          ));
        }

        fileInfos.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        return fileInfos;
      }
    } catch (e) {
      print('❌ List files error: $e');
      return [];
    }
  }

  // Delete canvas file
  Future<bool> deleteCanvas(String fileName) async {
    try {
      if (kIsWeb) {
        return await _deleteFromWebStorage(fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName.canvas.json';
        final file = File(filePath);

        if (await file.exists()) {
          await file.delete();
          print('✅ Deleted: $fileName');
          return true;
        }
        return false;
      }
    } catch (e) {
      print('❌ Delete error: $e');
      return false;
    }
  }

  // Helper methods for file operations
  Future<void> _saveToFile(List<CanvasObject> objects, Transform2D transform, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.canvas.json';
      final file = File(filePath);

      final data = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transform': {
          'translation': {
            'dx': transform.translation.dx,
            'dy': transform.translation.dy,
          },
          'scale': transform.scale,
        },
        'objects': objects.map((obj) => _serializeObject(obj)).toList(),
      };

      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      print('❌ File save error: $e');
      rethrow;
    }
  }

  Future<_CanvasData?> _loadFromFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.canvas.json';
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Deserialize transform
      final transformData = data['transform'];
      final transform = Transform2D(
        translation: Offset(
          transformData['translation']['dx'],
          transformData['translation']['dy'],
        ),
        scale: transformData['scale'],
      );

      // Two-pass deserialization for objects with references
      final objectsData = data['objects'] as List;
      final objects = <CanvasObject>[];
      final objectMap = <String, CanvasObject>{};

      // First pass: deserialize non-Connector objects
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type != 'Connector') {
          final obj = _deserializeObject(objJson as Map<String, dynamic>);
          objects.add(obj);
          objectMap[obj.id] = obj;
        }
      }

      // Second pass: deserialize Connectors with object references
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type == 'Connector') {
          try {
            final connector = _deserializeObject(objJson as Map<String, dynamic>, objectMap);
            objects.add(connector);
          } catch (e) {
            // Skip connectors with missing object references
            print('⚠️ Skipping connector with missing references: ${objJson['id']}');
          }
        }
      }

      return _CanvasData(objects: objects, transform: transform);
    } catch (e) {
      print('❌ File load error: $e');
      return null;
    }
  }

  Map<String, dynamic> _serializeObject(CanvasObject obj) {
    return {
      'id': obj.id,
      'worldPosition': {'dx': obj.worldPosition.dx, 'dy': obj.worldPosition.dy},
      'strokeColor': obj.strokeColor.value,
      'fillColor': obj.fillColor?.value,
      'strokeWidth': obj.strokeWidth,
      'isSelected': obj.isSelected,
      'type': obj.runtimeType.toString(),
      // Add specific properties based on object type
      if (obj is FreehandPath) 'points': obj.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      if (obj is CanvasRectangle) 'size': {'width': obj.size.width, 'height': obj.size.height},
      if (obj is CanvasCircle) 'radius': obj.radius,
      if (obj is StickyNote) ...{
        'text': obj.text,
        'size': {'width': obj.size.width, 'height': obj.size.height},
        'backgroundColor': obj.backgroundColor.value,
        'fontSize': obj.fontSize,
        'isEditing': obj.isEditing,
      },
      if (obj is Connector) ...{
        'sourceObjectId': obj.sourceObject.id,
        'targetObjectId': obj.targetObject.id,
        'sourcePoint': {'dx': obj.sourcePoint.dx, 'dy': obj.sourcePoint.dy},
        'targetPoint': {'dx': obj.targetPoint.dx, 'dy': obj.targetPoint.dy},
        'showArrow': obj.showArrow,
      },
      if (obj is DocumentBlock) ...{
        'documentId': obj.documentId,
        'viewMode': obj.viewMode.toString(),
        'size': {'width': obj.size.width, 'height': obj.size.height},
        'content': obj.content?.toJson(), // Serialize the document content
        'canvasReferences': obj.canvasReferences.map((ref) => ref.toJson()).toList(),
        'isExpanded': obj.isExpanded,
        'isEditing': obj.isEditing,
        'style': {
          'backgroundColor': obj.style.backgroundColor.value,
          'titleStyle': {
            'fontSize': obj.style.titleStyle.fontSize,
            'fontWeight': obj.style.titleStyle.fontWeight?.index,
          },
          'borderRadius': obj.style.borderRadius,
          'padding': obj.style.padding,
        },
      } ..addAll({'debug_content_blocks': (obj.content?.blocks.length ?? 0)}), // Debug: add content block count
    };
  }

  CanvasObject _deserializeObject(Map<String, dynamic> json, [Map<String, CanvasObject>? objectMap]) {
    final type = json['type'];

    switch (type) {
      case 'FreehandPath':
        return FreehandPath(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          points: (json['points'] as List).map((p) => Offset(p['dx'], p['dy'])).toList(),
        );
      case 'CanvasRectangle':
        return CanvasRectangle(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.transparent,
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          size: Size(json['size']['width'], json['size']['height']),
        );
      case 'CanvasCircle':
        return CanvasCircle(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.transparent,
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          radius: json['radius'],
        );
      case 'StickyNote':
        return StickyNote(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          text: json['text'] ?? 'Double tap to edit',
          size: Size(json['size']['width'], json['size']['height']),
          backgroundColor: json['backgroundColor'] != null ? Color(json['backgroundColor']) : Colors.yellow,
          fontSize: json['fontSize'] ?? 14.0,
          isEditing: json['isEditing'] ?? false,
        );
      case 'Connector':
        if (objectMap == null) {
          throw Exception('Connector deserialization requires objectMap');
        }
        final sourceObj = objectMap[json['sourceObjectId']];
        final targetObj = objectMap[json['targetObjectId']];
        if (sourceObj == null || targetObj == null) {
          throw Exception('Connector references missing objects');
        }
        return Connector(
          id: json['id'],
          sourceObject: sourceObj,
          targetObject: targetObj,
          sourcePoint: Offset(json['sourcePoint']['dx'], json['sourcePoint']['dy']),
          targetPoint: Offset(json['targetPoint']['dx'], json['targetPoint']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          showArrow: json['showArrow'] ?? true,
        );
      case 'DocumentBlock':
        return DocumentBlock(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth']?.toDouble() ?? 1.0,
          fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.white,
          isSelected: json['isSelected'] ?? false,
          documentId: json['documentId'] ?? 'doc_legacy_${json['id']}', // Provide default for legacy saves
          content: json['content'] != null ? DocumentContent.fromJson(json['content']) : null, // Restore content
          viewMode: DocumentViewMode.values.firstWhere(
            (mode) => mode.toString() == json['viewMode'],
            orElse: () => DocumentViewMode.preview,
          ),
          size: json['size'] != null
              ? Size(json['size']['width'].toDouble(), json['size']['height'].toDouble())
              : const Size(400, 300),
          canvasReferences: (json['canvasReferences'] as List?)
              ?.map((ref) => CanvasReference.fromJson(ref))
              .toList() ?? [],
          isExpanded: json['isExpanded'] ?? false,
          isEditing: json['isEditing'] ?? false,
          style: DocumentBlockStyle(
            backgroundColor: json['style']?['backgroundColor'] != null
                ? Color(json['style']['backgroundColor'])
                : Colors.white,
            titleStyle: TextStyle(
              fontSize: json['style']?['titleStyle']?['fontSize']?.toDouble() ?? 18.0,
              fontWeight: json['style']?['titleStyle']?['fontWeight'] != null
                  ? FontWeight.values[json['style']['titleStyle']['fontWeight']]
                  : FontWeight.w600,
            ),
            borderRadius: json['style']?['borderRadius']?.toDouble() ?? 8.0,
            padding: json['style']?['padding']?.toDouble() ?? 16.0,
          ),
        );
      default:
        throw Exception('Unknown object type: $type');
    }
  }

  // Web storage implementation using localStorage
  Future<void> _saveToWebStorage(String fileName) async {
    try {
      final data = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transform': {
          'translation': {
            'dx': _transform.translation.dx,
            'dy': _transform.translation.dy,
          },
          'scale': _transform.scale,
        },
        'objects': objects.map((obj) => _serializeObject(obj)).toList(),
      };

      final jsonString = jsonEncode(data);
      // Use html window.localStorage (requires dart:html)
      // For now, we'll use a simple in-memory storage simulation
      _webStorage[fileName] = jsonString;
    } catch (e) {
      print('❌ Web storage save error: $e');
      rethrow;
    }
  }

  Future<_CanvasData?> _loadFromWebStorage(String fileName) async {
    try {
      final jsonString = _webStorage[fileName];
      if (jsonString == null) {
        return null;
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Deserialize transform
      final transformData = data['transform'];
      final transform = Transform2D(
        translation: Offset(
          transformData['translation']['dx'],
          transformData['translation']['dy'],
        ),
        scale: transformData['scale'],
      );

      // Two-pass deserialization for objects with references
      final objectsData = data['objects'] as List;
      final objects = <CanvasObject>[];
      final objectMap = <String, CanvasObject>{};

      // First pass: deserialize non-Connector objects
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type != 'Connector') {
          final obj = _deserializeObject(objJson as Map<String, dynamic>);
          objects.add(obj);
          objectMap[obj.id] = obj;
        }
      }

      // Second pass: deserialize Connectors with object references
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type == 'Connector') {
          final connector = _deserializeObject(objJson as Map<String, dynamic>, objectMap);
          objects.add(connector);
        }
      }

      return _CanvasData(objects: objects, transform: transform);
    } catch (e) {
      print('❌ Web storage load error: $e');
      return null;
    }
  }

  Future<List<FileInfo>> _listWebStorageFiles() async {
    try {
      final fileInfos = <FileInfo>[];
      _webStorage.forEach((fileName, content) {
        fileInfos.add(FileInfo(
          name: fileName,
          path: 'web://$fileName',
          lastModified: DateTime.now(), // Web storage doesn't track modification time
          size: content.length,
        ));
      });

      fileInfos.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return fileInfos;
    } catch (e) {
      print('❌ Web storage list error: $e');
      return [];
    }
  }

  Future<bool> _deleteFromWebStorage(String fileName) async {
    try {
      _webStorage.remove(fileName);
      print('✅ Deleted from web storage: $fileName');
      return true;
    } catch (e) {
      print('❌ Web storage delete error: $e');
      return false;
    }
  }
}