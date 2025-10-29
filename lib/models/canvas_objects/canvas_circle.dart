import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasCircle extends CanvasObject {
  double radius;

  CanvasCircle({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.fillColor,
    super.strokeWidth,
    super.isSelected,
    required this.radius,
  });

  @override
  Rect calculateBoundingRect() =>
      Rect.fromCircle(center: worldPosition + Offset(radius, radius), radius: radius);

  @override
  bool hitTest(Offset worldPoint) {
    // Inflate bounds for easier hit detection - larger inflation for better selection
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.inflate(16); // Increased from 10 to 16
    return inflatedBounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final center = worldPosition + Offset(radius, radius);

    if (fillColor != null && fillColor != Colors.transparent) {
      canvas.drawCircle(center, radius, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    canvas.drawCircle(
      center,
      radius,
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
    final newDiameter = max(20.0, min(
      initialBounds.width + (handle.toString().contains('Right') ? delta.dx : -delta.dx),
      initialBounds.height + (handle.toString().contains('bottom') ? delta.dy : -delta.dy),
    ));

    radius = newDiameter / 2;
    worldPosition = initialBounds.center - Offset(radius, radius);
    invalidateCache();
  }

  @override
  CanvasObject clone() {
    return CanvasCircle(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      radius: radius,
    );
  }
}