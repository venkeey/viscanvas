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
  
  // Curvature parameters for editing
  double curvatureScale = 1.0;
  Offset? _midNormalOverride;
  
  // Cached control points for extrema calculation
  Offset? _cachedCp1;
  Offset? _cachedCp2;
  
  // Public methods to invalidate cache
  void invalidatePathCache() {
    _cachedPath = null;
    _cachedCp1 = null;
    _cachedCp2 = null;
    invalidateCache();
  }

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
    _cachedCp1 = null;
    _cachedCp2 = null;
    invalidateCache();
  }
  
  // Handle positions for editing - split path into 4 equal parts
  Offset get startHandle => sourcePoint;
  Offset get endHandle => targetPoint;
  
  Offset get firstQuarterHandle => _getPathPointAt(0.25);
  Offset get thirdQuarterHandle => _getPathPointAt(0.75);
  
  Offset _getPathPointAt(double t) {
    // Sample the path at parameter t (0.0 to 1.0)
    if (_cachedCp1 != null && _cachedCp2 != null) {
      return _evaluateCubic(t);
    }
    
    // Fallback: linear interpolation between source and target
    return Offset.lerp(sourcePoint, targetPoint, t)!;
  }
  
  Offset _evaluateCubic(double t) {
    // Evaluate cubic bezier at parameter t
    final p0 = sourcePoint;
    final p1 = _cachedCp1!;
    final p2 = _cachedCp2!;
    final p3 = targetPoint;
    
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;
    
    return Offset(
      uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx,
      uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy,
    );
  }
  
  
  

  Path get path {
    _cachedPath ??= _computePath();
    return _cachedPath!;
  }

  Path _computePath() {
    // Use smart curved path if we have anchors
    if (_sourceAnchor != null && _targetAnchor != null) {
      final path = ConnectorCalculator.createSmartCurvedPath(_sourceAnchor!, _targetAnchor!);
      _cacheControlPoints();
      return path;
    }
    // Fallback to old method
    final startDir = ConnectorCalculator.estimateEdgeDirection(sourcePoint, sourceObject.getBoundingRect().center);
    final endDir = ConnectorCalculator.estimateEdgeDirection(targetPoint, targetObject.getBoundingRect().center);
    final path = ConnectorCalculator.createCurvedPath(sourcePoint, targetPoint, startDir, endDir);
    _cacheControlPoints();
    return path;
  }
  
  void _cacheControlPoints() {
    // Calculate control points for extrema calculation
    final distance = (targetPoint - sourcePoint).distance;
    final controlPointOffset = distance * 0.35 * curvatureScale;
    
    final dx = targetPoint.dx - sourcePoint.dx;
    final dy = targetPoint.dy - sourcePoint.dy;
    
    _cachedCp1 = Offset(
      sourcePoint.dx + (dx.abs() > dy.abs() ? (dx > 0 ? controlPointOffset : -controlPointOffset) : 0),
      sourcePoint.dy + (dy.abs() > dx.abs() ? (dy > 0 ? controlPointOffset : -controlPointOffset) : 0),
    );
    
    _cachedCp2 = Offset(
      targetPoint.dx + (dx.abs() > dy.abs() ? (dx > 0 ? -controlPointOffset : controlPointOffset) : 0),
      targetPoint.dy + (dy.abs() > dx.abs() ? (dy > 0 ? -controlPointOffset : controlPointOffset) : 0),
    );
  }

  @override
  Rect calculateBoundingRect() {
    return Rect.fromPoints(sourcePoint, targetPoint);
  }

  @override
  bool hitTest(Offset worldPoint) {
    return ConnectorCalculator.distanceToLine(worldPoint, sourcePoint, targetPoint) < 20.0; // Increased from 10 to 20 for easier selection
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
    final cloned = Connector(
      id: '${id}_copy',
      sourceObject: sourceObject,
      targetObject: targetObject,
      sourcePoint: sourcePoint,
      targetPoint: targetPoint,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      showArrow: showArrow,
    );
    cloned.curvatureScale = curvatureScale;
    cloned._midNormalOverride = _midNormalOverride;
    return cloned;
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