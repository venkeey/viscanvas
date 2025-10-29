import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class FreehandPath extends CanvasObject {
  List<Offset> points;
  Path _path = Path();

  FreehandPath({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.strokeWidth,
    super.isSelected,
    required this.points,
  }) {
    _rebuildPath();
  }

  void addPoint(Offset point) {
    points.add(point);
    _rebuildPath();
  }

  void _rebuildPath() {
    _path = Path();
    if (points.isNotEmpty) {
      _path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        _path.lineTo(points[i].dx, points[i].dy);
      }
    }
    invalidateCache();
  }

  @override
  Rect calculateBoundingRect() {
    if (points.isEmpty) return Rect.zero;
    return _path.shift(worldPosition).getBounds();
  }

  @override
  bool hitTest(Offset worldPoint) {
    final pathBounds = _path.shift(worldPosition).getBounds().inflate(strokeWidth / 2 + 16); // Added 16px for easier selection
    return pathBounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth / worldToScreen.getScaleFactor();

    canvas.drawPath(_path.shift(worldPosition), paint);
  }

  @override
  void move(Offset delta) {
    worldPosition += delta;
    invalidateCache();
  }

  @override
  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds) {
    if (points.isEmpty) return;
    final originalWidth = initialBounds.width;
    final originalHeight = initialBounds.height;
    if (originalWidth == 0 || originalHeight == 0) return;

    double newX = initialBounds.left, newY = initialBounds.top;
    double newWidth = originalWidth, newHeight = originalHeight;

    switch (handle) {
      case ResizeHandle.topLeft:
        newX += delta.dx; newY += delta.dy;
        newWidth -= delta.dx; newHeight -= delta.dy;
        break;
      case ResizeHandle.topCenter:
        newY += delta.dy; newHeight -= delta.dy;
        break;
      case ResizeHandle.topRight:
        newY += delta.dy; newWidth += delta.dx; newHeight -= delta.dy;
        break;
      case ResizeHandle.centerLeft:
        newX += delta.dx; newWidth -= delta.dx;
        break;
      case ResizeHandle.centerRight:
        newWidth += delta.dx;
        break;
      case ResizeHandle.bottomLeft:
        newX += delta.dx; newWidth -= delta.dx; newHeight += delta.dy;
        break;
      case ResizeHandle.bottomCenter:
        newHeight += delta.dy;
        break;
      case ResizeHandle.bottomRight:
        newWidth += delta.dx; newHeight += delta.dy;
        break;
      case ResizeHandle.none:
        return;
      default:
        return;
    }

    newWidth = max(10.0, newWidth);
    newHeight = max(10.0, newHeight);

    final scaleX = newWidth / originalWidth;
    final scaleY = newHeight / originalHeight;

    points = points.map((p) => Offset(p.dx * scaleX, p.dy * scaleY)).toList();
    worldPosition = Offset(newX, newY);
    _rebuildPath();
  }

  @override
  CanvasObject clone() {
    return FreehandPath(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      isSelected: false,
      points: List.from(points),
    );
  }
}