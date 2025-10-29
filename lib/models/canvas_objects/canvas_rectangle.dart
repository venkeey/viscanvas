import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasRectangle extends CanvasObject {
  Size size;

  CanvasRectangle({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.fillColor,
    super.strokeWidth,
    super.isSelected,
    required this.size,
  });

  @override
  Rect calculateBoundingRect() =>
      Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);

  @override
  bool hitTest(Offset worldPoint) {
    // Inflate bounds slightly for easier hit detection of small shapes
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.width < 20 || bounds.height < 20
        ? bounds.inflate(10)
        : bounds;
    return inflatedBounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final rect = Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);

    if (fillColor != null && fillColor != Colors.transparent) {
      canvas.drawRect(rect, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    canvas.drawRect(
      rect,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth / worldToScreen.getScaleFactor(),
    );
  }

  @override
  void move(Offset delta) {
    worldPosition += delta;
    invalidateCache();
  }

  @override
  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds) {
    double newX = initialBounds.left, newY = initialBounds.top;
    double newWidth = initialBounds.width, newHeight = initialBounds.height;

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

    worldPosition = Offset(newX, newY);
    size = Size(max(10.0, newWidth), max(10.0, newHeight));
    invalidateCache();
  }

  @override
  CanvasObject clone() {
    return CanvasRectangle(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      size: size,
    );
  }
}