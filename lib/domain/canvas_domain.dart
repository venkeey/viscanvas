// ===== DOMAIN LAYER =====

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/canvas_objects/canvas_object.dart';

enum ToolType {
  select,
  pan,
  freehand,
  rectangle,
  circle,
  line,
  text,
  // Miro-style tools
  ai_templates,
  frame,
  sticky_note,
  shapes,
  pen,
  connector,
  comment,
  table,
  upload,
  add_more,
  document_block,
}

// Value Objects - Immutable data structures
class Transform2D {
  final Offset translation;
  final double scale;
  final Matrix4 _matrix;

  Transform2D({required this.translation, required this.scale})
      : _matrix = Matrix4.identity()
          ..translate(translation.dx, translation.dy)
          ..scale(scale);

  Matrix4 get matrix => _matrix;

  Offset worldToScreen(Offset worldPoint) {
    return MatrixUtils.transformPoint(_matrix, worldPoint);
  }

  Offset screenToWorld(Offset screenPoint) {
    final inverse = Matrix4.inverted(_matrix);
    return MatrixUtils.transformPoint(inverse, screenPoint);
  }

  Transform2D copyWith({Offset? translation, double? scale}) {
    return Transform2D(
      translation: translation ?? this.translation,
      scale: scale ?? this.scale,
    );
  }
}

class _CanvasData {
  final List<CanvasObject> objects;
  final Transform2D transform;

  _CanvasData({required this.objects, required this.transform});
}

// Domain Events for event sourcing
abstract class CanvasEvent {
  final DateTime timestamp;
  CanvasEvent() : timestamp = DateTime.now();
}

class ObjectCreatedEvent extends CanvasEvent {
  final CanvasObject object;
  ObjectCreatedEvent(this.object);
}

class ObjectModifiedEvent extends CanvasEvent {
  final String objectId;
  final Map<String, dynamic> changes;
  ObjectModifiedEvent(this.objectId, this.changes);
}

class ObjectDeletedEvent extends CanvasEvent {
  final String objectId;
  ObjectDeletedEvent(this.objectId);
}

// Spatial Index Interface for performance
abstract class SpatialIndex {
  void insert(CanvasObject object);
  void remove(String objectId);
  void update(CanvasObject object);
  List<CanvasObject> query(Rect bounds);
  CanvasObject? hitTest(Offset point);
  void clear();
}

// Simple QuadTree implementation for spatial indexing
class QuadTree implements SpatialIndex {
  final Rect bounds;
  final int capacity;
  final int maxDepth;
  final int depth;

  final List<CanvasObject> _objects = [];
  List<QuadTree>? _children;

  QuadTree({
    required this.bounds,
    this.capacity = 4,
    this.maxDepth = 8,
    this.depth = 0,
  });

  bool get isDivided => _children != null;

  void _subdivide() {
    final x = bounds.left;
    final y = bounds.top;
    final w = bounds.width / 2;
    final h = bounds.height / 2;

    _children = [
      QuadTree(bounds: Rect.fromLTWH(x, y, w, h), capacity: capacity, maxDepth: maxDepth, depth: depth + 1),
      QuadTree(bounds: Rect.fromLTWH(x + w, y, w, h), capacity: capacity, maxDepth: maxDepth, depth: depth + 1),
      QuadTree(bounds: Rect.fromLTWH(x, y + h, w, h), capacity: capacity, maxDepth: maxDepth, depth: depth + 1),
      QuadTree(bounds: Rect.fromLTWH(x + w, y + h, w, h), capacity: capacity, maxDepth: maxDepth, depth: depth + 1),
    ];
  }

  @override
  void insert(CanvasObject object) {
    if (!bounds.overlaps(object.getBoundingRect())) return;

    if (_objects.length < capacity || depth >= maxDepth) {
      _objects.add(object);
      return;
    }

    if (!isDivided) _subdivide();
    for (var child in _children!) {
      child.insert(object);
    }
  }

  @override
  void remove(String objectId) {
    _objects.removeWhere((obj) => obj.id == objectId);
    if (isDivided) {
      for (var child in _children!) {
        child.remove(objectId);
      }
    }
  }

  @override
  void update(CanvasObject object) {
    remove(object.id);
    insert(object);
  }

  @override
  List<CanvasObject> query(Rect range) {
    final found = <CanvasObject>[];
    if (!bounds.overlaps(range)) return found;

    for (var obj in _objects) {
      if (range.overlaps(obj.getBoundingRect())) {
        found.add(obj);
      }
    }

    if (isDivided) {
      for (var child in _children!) {
        found.addAll(child.query(range));
      }
    }

    return found;
  }

  @override
  CanvasObject? hitTest(Offset point) {
    if (!bounds.contains(point)) return null;

    for (var obj in _objects.reversed) {
      if (obj.hitTest(point)) return obj;
    }

    if (isDivided) {
      for (var child in _children!.reversed) {
        final hit = child.hitTest(point);
        if (hit != null) return hit;
      }
    }

    return null;
  }

  @override
  void clear() {
    _objects.clear();
    _children = null;
  }
}

// Repository Pattern for object management
abstract class CanvasRepository {
  List<CanvasObject> getAll();
  CanvasObject? getById(String id);
  void add(CanvasObject object);
  void update(CanvasObject object);
  void remove(String id);
  List<CanvasObject> getSelected();
  void clear();
}

class InMemoryCanvasRepository implements CanvasRepository {
  final List<CanvasObject> _objects = [];
  final SpatialIndex _spatialIndex;

  InMemoryCanvasRepository(this._spatialIndex);

  @override
  List<CanvasObject> getAll() => List.unmodifiable(_objects);

  @override
  CanvasObject? getById(String id) {
    try {
      return _objects.firstWhere((obj) => obj.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void add(CanvasObject object) {
    _objects.add(object);
    _spatialIndex.insert(object);
  }

  @override
  void update(CanvasObject object) {
    final index = _objects.indexWhere((obj) => obj.id == object.id);
    if (index != -1) {
      _objects[index] = object;
      _spatialIndex.update(object);
    }
  }

  @override
  void remove(String id) {
    _objects.removeWhere((obj) => obj.id == id);
    _spatialIndex.remove(id);
  }

  @override
  List<CanvasObject> getSelected() {
    return _objects.where((obj) => obj.isSelected).toList();
  }

  @override
  void clear() {
    _objects.clear();
    _spatialIndex.clear();
  }

  CanvasObject? hitTest(Offset point) => _spatialIndex.hitTest(point);
  List<CanvasObject> queryRegion(Rect bounds) => _spatialIndex.query(bounds);
}

// ===== 2. APPLICATION LAYER - COMMANDS =====

// Command Pattern for Undo/Redo
abstract class Command {
  void execute();
  void undo();
  String get description;
}

class CreateObjectCommand implements Command {
  final CanvasRepository repository;
  final CanvasObject object;

  CreateObjectCommand(this.repository, this.object);

  @override
  void execute() => repository.add(object);

  @override
  void undo() => repository.remove(object.id);

  @override
  String get description => 'Create ${object.runtimeType}';
}

class DeleteObjectCommand implements Command {
  final CanvasRepository repository;
  final CanvasObject object;

  DeleteObjectCommand(this.repository, this.object);

  @override
  void execute() => repository.remove(object.id);

  @override
  void undo() => repository.add(object);

  @override
  String get description => 'Delete ${object.runtimeType}';
}

class ModifyObjectCommand implements Command {
  final CanvasRepository repository;
  final String objectId;
  final CanvasObject oldState;
  final CanvasObject newState;

  ModifyObjectCommand(this.repository, this.objectId, this.oldState, this.newState);

  @override
  void execute() => repository.update(newState);

  @override
  void undo() => repository.update(oldState);

  @override
  String get description => 'Modify object';
}

class CommandHistory {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final int maxHistorySize;
  
  // Callback for when objects change
  void Function()? onObjectsChanged;

  CommandHistory({this.maxHistorySize = 100});

  void execute(Command command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
    onObjectsChanged?.call();
  }

  bool canUndo() => _undoStack.isNotEmpty;
  bool canRedo() => _redoStack.isNotEmpty;

  void undo() {
    if (!canUndo()) return;
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    onObjectsChanged?.call();
  }

  void redo() {
    if (!canRedo()) return;
    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
    onObjectsChanged?.call();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

// Use Cases
class SelectObjectUseCase {
  final CanvasRepository repository;

  SelectObjectUseCase(this.repository);

  void execute(String objectId, {bool multiSelect = false}) {
    if (!multiSelect) {
      for (var obj in repository.getAll()) {
        obj.isSelected = false;
      }
    }

    final object = repository.getById(objectId);
    if (object != null) {
      object.isSelected = true;
      repository.update(object);
    }
  }
}

class HitTestUseCase {
  final InMemoryCanvasRepository repository;

  HitTestUseCase(this.repository);

  CanvasObject? execute(Offset worldPoint) {
    return repository.hitTest(worldPoint);
  }
}

// ===== DOMAIN OBJECTS =====

extension Matrix4ScaleFactor on Matrix4 {
  double getScaleFactor() => storage[0];
}