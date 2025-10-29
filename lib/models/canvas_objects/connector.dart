import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/connector_system.dart';
import '../../domain/canvas_domain.dart';

// Connector - Represents a connection between two objects
class Connector extends CanvasObject {
  CanvasObject sourceObject;
  CanvasObject targetObject;
  Offset sourcePoint;
  Offset targetPoint;
  Path? _cachedPath;
  AnchorPoint? _sourceAnchor;
  AnchorPoint? _targetAnchor;
  bool showArrow;

  Connector({
    required super.id,
    required this.sourceObject,
    required this.targetObject,
    required this.sourcePoint,
    required this.targetPoint,
    required super.strokeColor,
    super.strokeWidth,
    super.isSelected,
    this.showArrow = true,
  }) : super(worldPosition: sourcePoint, fillColor: Colors.transparent) {
    // Calculate initial smart anchors
    _updateSmartAnchors();
  }

  void _updateSmartAnchors() {
    _sourceAnchor = ConnectorCalculator.getSmartAnchorPoint(
      sourceObject,
      targetObject,
      isSource: true,
    );
    _targetAnchor = ConnectorCalculator.getSmartAnchorPoint(
      sourceObject,
      targetObject,
      isSource: false,
    );
    sourcePoint = _sourceAnchor!.position;
    targetPoint = _targetAnchor!.position;
  }

  void updatePoints() {
    _updateSmartAnchors();
    _cachedPath = null;
    invalidateCache();
  }

  Path get path {
    _cachedPath ??= _computePath();
    return _cachedPath!;
  }

  Path _computePath() {
    // Use smart curved path if we have anchors
    if (_sourceAnchor != null && _targetAnchor != null) {
      return ConnectorCalculator.createSmartCurvedPath(_sourceAnchor!, _targetAnchor!);
    }
    // Fallback to old method
    final startDir = ConnectorCalculator.estimateEdgeDirection(sourcePoint, sourceObject.getBoundingRect().center);
    final endDir = ConnectorCalculator.estimateEdgeDirection(targetPoint, targetObject.getBoundingRect().center);
    return ConnectorCalculator.createCurvedPath(sourcePoint, targetPoint, startDir, endDir);
  }

  @override
  Rect calculateBoundingRect() {
    return Rect.fromPoints(sourcePoint, targetPoint);
  }

  @override
  bool hitTest(Offset worldPoint) {
    return ConnectorCalculator.distanceToLine(worldPoint, sourcePoint, targetPoint) < 10.0;
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / worldToScreen.getScaleFactor()
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Draw arrow at end
    if (showArrow) {
      _drawArrowHead(canvas, targetPoint, sourcePoint, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Offset fromPoint, Paint paint) {
    const arrowSize = 12.0;
    final direction = (tip - fromPoint);
    final angle = atan2(direction.dy, direction.dx);

    final arrowPath = Path();
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(
      tip.dx - arrowSize * cos(angle - pi / 6),
      tip.dy - arrowSize * sin(angle - pi / 6),
    );
    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(
      tip.dx - arrowSize * cos(angle + pi / 6),
      tip.dy - arrowSize * sin(angle + pi / 6),
    );

    canvas.drawPath(arrowPath, paint);
  }

  @override
  void move(Offset delta) {
    // Connectors don't move independently, they follow their connected objects
  }

  @override
  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds) {
    // Connectors don't resize
  }

  @override
  CanvasObject clone() {
    return Connector(
      id: '${id}_copy',
      sourceObject: sourceObject,
      targetObject: targetObject,
      sourcePoint: sourcePoint,
      targetPoint: targetPoint,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      showArrow: showArrow,
    );
  }
}

// FreehandConnector - For hand-drawn connections
class FreehandConnector {
  final List<Offset> points = [];
  final Paint paint;

  FreehandConnector({Color color = Colors.blue, double strokeWidth = 3.0})
      : paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

  void addPoint(Offset point) {
    points.add(point);
  }

  Path get path {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  ConnectorAnalysis analyzeStroke(List<CanvasObject> objects) {
    if (points.length < 5) return ConnectorAnalysis();

    final startPoint = points.first;
    final endPoint = points.last;

    final startObj = _findClosestObject(startPoint, objects);
    final endObj = _findClosestObject(endPoint, objects);

    return ConnectorAnalysis(
      sourceObject: startObj,
      targetObject: endObj,
      confidence: _calculateConfidence(startObj, endObj, points),
    );
  }

  CanvasObject? _findClosestObject(Offset point, List<CanvasObject> objects) {
    for (final obj in objects) {
      if (obj is Connector) continue; // Skip existing connectors
      final expandedBounds = obj.getBoundingRect().inflate(30.0);
      if (expandedBounds.contains(point)) {
        return obj;
      }
    }
    return null;
  }

  double _calculateConfidence(CanvasObject? startObj, CanvasObject? endObj, List<Offset> points) {
    if (startObj == null || endObj == null || startObj == endObj) return 0.0;

    double totalDeviation = 0.0;
    for (final point in points) {
      totalDeviation += ConnectorCalculator.distanceToLine(point, points.first, points.last);
    }

    final avgDeviation = totalDeviation / points.length;
    final straightness = 1.0 / (1.0 + avgDeviation * 0.1);

    return straightness.clamp(0.0, 1.0);
  }
}

class ConnectorAnalysis {
  final CanvasObject? sourceObject;
  final CanvasObject? targetObject;
  final double confidence;

  ConnectorAnalysis({this.sourceObject, this.targetObject, this.confidence = 0.0});

  bool get isValidConnection => sourceObject != null && targetObject != null &&
                                sourceObject != targetObject && confidence > 0.3;
}