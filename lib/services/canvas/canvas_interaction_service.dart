import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/canvas_domain.dart';
import '../../models/canvas_objects/canvas_object.dart';
import '../../models/canvas_objects/freehand_path.dart';
import '../../models/canvas_objects/canvas_rectangle.dart';
import '../../models/canvas_objects/canvas_circle.dart';
import '../../models/canvas_objects/sticky_note.dart';
import '../../models/canvas_objects/document_block.dart';
import '../../models/canvas_objects/connector.dart';

class CanvasInteractionService {
  final InMemoryCanvasRepository _repository;
  final CommandHistory _commandHistory;
  final SelectObjectUseCase _selectObjectUseCase;
  final HitTestUseCase _hitTestUseCase;

  // Callbacks
  void Function(ToolType)? onToolChanged;
  void Function(Transform2D)? onTransformChanged;
  void Function()? onSelectionChanged;
  void Function()? onObjectCreated;
  void Function()? onObjectModified;

  // Drawing state
  CanvasObject? _tempObject;
  Offset? _dragStart;
  ResizeHandle _resizeHandle = ResizeHandle.none;
  Offset? _initialWorldPosition;
  Rect? _initialBounds;
  Map<String, CanvasObject>? _preMoveState;
  Offset? _lastWorldPoint;

  // Text editing state
  StickyNote? _editingStickyNote;
  Timer? _doubleTapTimer;
  Offset? _lastTapPosition;

  CanvasInteractionService(
    this._repository,
    this._commandHistory,
    this._selectObjectUseCase,
    this._hitTestUseCase,
  );

  // ===== PUBLIC API =====

  Offset? get lastWorldPoint => _lastWorldPoint;

  void onPanStart(Offset screenPoint, ToolType currentTool, Transform2D transform, Color strokeColor, Color fillColor, double strokeWidth) {
    final worldPoint = transform.screenToWorld(screenPoint);
    _dragStart = worldPoint;

    if (currentTool == ToolType.connector) {
      // Connector tool: check if starting from an object OR start freehand
      final hitObj = _hitTestUseCase.execute(worldPoint);

      if (hitObj != null && hitObj is! Connector) {
        // Start drag connection from object - delegate to connector service
        onToolChanged?.call(ToolType.connector);
        return;
      } else {
        // Start freehand connection - delegate to connector service
        onToolChanged?.call(ToolType.connector);
        return;
      }
    }

    if (currentTool == ToolType.select) {
      for (var obj in _repository.getSelected()) {
        _resizeHandle = _getResizeHandle(obj, screenPoint, transform);
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
        onSelectionChanged?.call();
        return;
      }
      _clearSelection();
      onSelectionChanged?.call();
    } else if (currentTool != ToolType.pan) {
      _tempObject = _createObject(worldPoint, currentTool, strokeColor, fillColor, strokeWidth);
      if (_tempObject != null) {
        _commandHistory.execute(CreateObjectCommand(_repository, _tempObject!));
        // After creating an object, switch back to select mode so user can immediately interact with it
        onToolChanged?.call(ToolType.select);
        onObjectCreated?.call();
      }
    }
  }

  void onPanUpdate(Offset screenPoint, Offset delta, ToolType currentTool, Transform2D transform) {
    final worldPoint = transform.screenToWorld(screenPoint);
    _lastWorldPoint = worldPoint; // Track last world point for onPanEnd

    if (currentTool == ToolType.connector) {
      // Update connector drawing - delegate to connector service
      return;
    }

    if (currentTool == ToolType.pan) {
      final newTransform = transform.copyWith(translation: transform.translation + delta);
      onTransformChanged?.call(newTransform);
    } else if (currentTool == ToolType.select) {
      if (_resizeHandle != ResizeHandle.none) {
        final selectedObj = _repository.getSelected().first;
        final worldDelta = worldPoint - _dragStart!;
        selectedObj.resize(_resizeHandle, worldDelta, _initialWorldPosition!, _initialBounds!);
        // Update connectors for resized object
        _updateConnectors(movedObjectIds: {selectedObj.id});
        onObjectModified?.call();
      } else {
        final worldDelta = worldPoint - _dragStart!;
        final movedIds = <String>{};
        for (var obj in _repository.getSelected()) {
          obj.move(worldDelta);
          movedIds.add(obj.id);
        }
        // Optimized: Only update connectors connected to moved objects
        _updateConnectors(movedObjectIds: movedIds);
        _dragStart = worldPoint;
        onObjectModified?.call();
      }
    } else if (_tempObject != null) {
      _updateTempObject(worldPoint);
      onObjectModified?.call();
    }
  }

  void onPanEnd(ToolType currentTool) {
    if (currentTool == ToolType.connector) {
      // End connector drawing - delegate to connector service
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

  void onTap(Offset screenPoint, Transform2D transform) {
    final worldPoint = transform.screenToWorld(screenPoint);
    _handleDoubleTap(worldPoint);
  }

  void clearSelection() {
    _clearSelection();
    onSelectionChanged?.call();
  }

  void deleteSelected() {
    final selected = _repository.getSelected();
    for (var obj in selected) {
      _commandHistory.execute(DeleteObjectCommand(_repository, obj));
    }
    onObjectModified?.call();
  }

  void updateSelectedObjectsStrokeColor(Color color) {
    for (var obj in _repository.getSelected()) {
      final oldState = obj.clone();
      obj.strokeColor = color;
      _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
    }
    onObjectModified?.call();
  }

  void updateSelectedObjectsFillColor(Color color) {
    for (var obj in _repository.getSelected()) {
      final oldState = obj.clone();
      obj.fillColor = color;
      _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
    }
    onObjectModified?.call();
  }

  void updateSelectedStickyNoteBackgroundColor(Color color) {
    for (var obj in _repository.getSelected()) {
      if (obj is StickyNote) {
        final oldState = obj.clone();
        obj.backgroundColor = color;
        _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
      }
    }
    onObjectModified?.call();
  }

  void updateSelectedObjectsStrokeWidth(double width) {
    for (var obj in _repository.getSelected()) {
      final oldState = obj.clone();
      obj.strokeWidth = width;
      _commandHistory.execute(ModifyObjectCommand(_repository, obj.id, oldState, obj));
    }
    onObjectModified?.call();
  }

  // ===== PRIVATE METHODS =====

  void _clearSelection() {
    for (var obj in _repository.getAll()) {
      obj.isSelected = false;
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
    onObjectModified?.call();
  }

  void _openDocumentEditor(DocumentBlock documentBlock) {
    // This will be handled by the document service
    onObjectModified?.call();
  }

  CanvasObject? _createObject(Offset worldPoint, ToolType tool, Color strokeColor, Color fillColor, double strokeWidth) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    switch (tool) {
      case ToolType.freehand:
        return FreehandPath(
          id: id,
          worldPosition: worldPoint,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          points: [Offset.zero],
        );
      case ToolType.rectangle:
        return CanvasRectangle(
          id: id,
          worldPosition: worldPoint,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          size: const Size(10, 10), // Start with minimum size for hit detection
        );
      case ToolType.circle:
        return CanvasCircle(
          id: id,
          worldPosition: worldPoint,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          radius: 5, // Start with minimum radius for hit detection
        );
      case ToolType.sticky_note:
        return StickyNote(
          id: id,
          worldPosition: worldPoint,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          size: const Size(200, 120),
          backgroundColor: _getStickyNoteColor(),
        );
      case ToolType.document_block:
        return DocumentBlock(
          id: id,
          worldPosition: worldPoint,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
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

  ResizeHandle _getResizeHandle(CanvasObject obj, Offset screenPoint, Transform2D transform) {
    final bounds = obj.getBoundingRect();
    final path = Path()..addRect(bounds);
    final transformedPath = path.transform(transform.matrix.storage);
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

  void _updateConnectors({Set<String>? movedObjectIds}) {
    // Optimized: Only update connectors connected to moved objects
    if (movedObjectIds != null && movedObjectIds.isNotEmpty) {
      for (var obj in _repository.getAll()) {
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
      for (var obj in _repository.getAll()) {
        if (obj is Connector) {
          obj.updatePoints();
        }
      }
    }
  }

  void dispose() {
    _doubleTapTimer?.cancel();
  }
}
