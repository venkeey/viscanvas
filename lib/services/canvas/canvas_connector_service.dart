import 'package:flutter/material.dart';
import '../../domain/canvas_domain.dart';
import '../../domain/connector_system.dart';
import '../../models/canvas_objects/canvas_object.dart';
import '../../models/canvas_objects/connector.dart';
import '../../utils/logger.dart';

class CanvasConnectorService {
  final InMemoryCanvasRepository _repository;
  final CommandHistory _commandHistory;
  final HitTestUseCase _hitTestUseCase;

  // Callbacks
  void Function()? onConnectorStateChanged;

  // Connector state
  CanvasObject? _connectorSourceObject;
  FreehandConnector? _currentFreehandConnector;
  ConnectorAnalysis? _currentConnectorAnalysis;
  bool _showConnectorConfirmation = false;
  Offset? _lastWorldPoint;
  CanvasObject? _connectorHoverTarget; // For highlighting potential target

  CanvasConnectorService(
    this._repository,
    this._commandHistory,
    this._hitTestUseCase,
  );

  // ===== PUBLIC API =====

  CanvasObject? get connectorSourceObject => _connectorSourceObject;
  FreehandConnector? get currentFreehandConnector => _currentFreehandConnector;
  bool get showConnectorConfirmation => _showConnectorConfirmation;
  ConnectorAnalysis? get currentConnectorAnalysis => _currentConnectorAnalysis;
  CanvasObject? get connectorHoverTarget => _connectorHoverTarget;
  Offset? get lastWorldPoint => _lastWorldPoint;

  void startDragConnection(CanvasObject sourceObject, Offset worldPoint) {
    _connectorSourceObject = sourceObject;
    CanvasLogger.canvasService('Connector drag start from ${sourceObject.runtimeType}(${sourceObject.id}) at $worldPoint');
    onConnectorStateChanged?.call();
  }

  void updateDragConnection(Offset worldPoint) {
    if (_connectorSourceObject != null) {
      // Detect hover target for visual feedback
      final hitObj = _hitTestUseCase.execute(worldPoint);
      if (hitObj != null && hitObj != _connectorSourceObject && hitObj is! Connector) {
        _connectorHoverTarget = hitObj;
        CanvasLogger.canvasService('Connector hover over ${hitObj.runtimeType}(${hitObj.id})');
      } else {
        _connectorHoverTarget = null;
      }

      onConnectorStateChanged?.call();
    }
  }

  void endDragConnection(Offset worldPoint) {
    if (_connectorSourceObject == null) {
      CanvasLogger.canvasService('Connector drag end with no source');
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
      CanvasLogger.canvasService('Connector drag end: creating connector to ${targetObject.runtimeType}(${targetObject.id})');
      _createConnector(_connectorSourceObject!, targetObject);
    }

    _connectorSourceObject = null;
    _connectorHoverTarget = null;
    onConnectorStateChanged?.call();
  }

  void startFreehandConnection(Offset worldPoint, Color strokeColor, double strokeWidth) {
    _currentFreehandConnector = FreehandConnector(color: strokeColor, strokeWidth: strokeWidth);
    _currentFreehandConnector!.addPoint(worldPoint);
    _showConnectorConfirmation = false;
    CanvasLogger.canvasService('Freehand connector start at $worldPoint');
    onConnectorStateChanged?.call();
  }

  void updateFreehandConnection(Offset worldPoint) {
    if (_currentFreehandConnector != null) {
      _currentFreehandConnector!.addPoint(worldPoint);
      CanvasLogger.canvasService('Freehand connector point added: $worldPoint (count=${_currentFreehandConnector!.path.computeMetrics().length})');
      onConnectorStateChanged?.call();
    }
  }

  void endFreehandConnection(Offset worldPoint) {
    if (_currentFreehandConnector != null) {
      _currentFreehandConnector!.addPoint(worldPoint);

      // Analyze the stroke for connection intent
      _currentConnectorAnalysis = _currentFreehandConnector!.analyzeStroke(_repository.getAll());
      CanvasLogger.canvasService('Freehand connector analysis: valid=${_currentConnectorAnalysis!.isValidConnection} source=${_currentConnectorAnalysis!.sourceObject?.id} target=${_currentConnectorAnalysis!.targetObject?.id}');

      if (_currentConnectorAnalysis!.isValidConnection) {
        _showConnectorConfirmation = true;
        CanvasLogger.canvasService('Freehand connection valid – awaiting confirmation');
      } else {
        // If not a valid connection, discard it
        _currentFreehandConnector = null;
        _currentConnectorAnalysis = null;
        CanvasLogger.canvasService('Freehand connection invalid – discarded');
      }

      onConnectorStateChanged?.call();
    }
  }

  void confirmFreehandConnection() {
    if (_currentConnectorAnalysis != null &&
        _currentConnectorAnalysis!.isValidConnection &&
        _currentFreehandConnector != null) {
      final sourceObj = _currentConnectorAnalysis!.sourceObject!;
      final targetObj = _currentConnectorAnalysis!.targetObject!;

      CanvasLogger.canvasService('Confirming freehand connector ${sourceObj.id} -> ${targetObj.id}');
      _createConnector(sourceObj, targetObj);
      _cleanupFreehandConnection();
    }
  }

  void cancelFreehandConnection() {
    CanvasLogger.canvasService('Cancelling freehand connector');
    _cleanupFreehandConnection();
  }

  void updateConnectors({Set<String>? movedObjectIds}) {
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

  // ===== PRIVATE METHODS =====

  void _cleanupFreehandConnection() {
    _currentFreehandConnector = null;
    _currentConnectorAnalysis = null;
    _showConnectorConfirmation = false;
    CanvasLogger.canvasService('Freehand connector state cleaned up');
    onConnectorStateChanged?.call();
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
      strokeColor: Colors.black, // Default color, should be passed from service
      strokeWidth: 2.0, // Default width, should be passed from service
    );

    _commandHistory.execute(CreateObjectCommand(_repository, connector));
    CanvasLogger.canvasService('Connector created $id: ${sourceObj.id} -> ${targetObj.id}');
    onConnectorStateChanged?.call();
  }

  void dispose() {
    // Cleanup if needed
  }
}
