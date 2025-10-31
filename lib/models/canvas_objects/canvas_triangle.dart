import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasTriangle extends CanvasObject {
  Size size;

  CanvasTriangle({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.fillColor,
    super.strokeWidth,
    super.isSelected,
    required this.size,
  });

  // Calculate triangle points from position and size
  // Creates an equilateral-like triangle (pointing up)
  Offset get point1 => Offset(worldPosition.dx + size.width / 2, worldPosition.dy); // Top
  Offset get point2 => Offset(worldPosition.dx, worldPosition.dy + size.height); // Bottom left
  Offset get point3 => Offset(worldPosition.dx + size.width, worldPosition.dy + size.height); // Bottom right

  @override
  Rect calculateBoundingRect() =>
      Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);

  @override
  bool hitTest(Offset worldPoint) {
    // Use point-in-triangle test for accurate hit detection
    final p1 = point1;
    final p2 = point2;
    final p3 = point3;
    
    // Barycentric coordinate method for point-in-triangle test
    final v0 = p3 - p1;
    final v1 = p2 - p1;
    final v2 = worldPoint - p1;
    
    // Dot product helper
    double dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;
    
    final dot00 = dot(v0, v0);
    final dot01 = dot(v0, v1);
    final dot02 = dot(v0, v2);
    final dot11 = dot(v1, v1);
    final dot12 = dot(v1, v2);
    
    final invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
    final u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    final v = (dot00 * dot12 - dot01 * dot02) * invDenom;
    
    // Inflate bounds for easier hit detection
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.inflate(16);
    
    // Check if point is in triangle OR in inflated bounding box
    return (u >= -0.1 && v >= -0.1 && u + v < 1.1) || inflatedBounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final p1 = point1;
    final p2 = point2;
    final p3 = point3;
    
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    if (fillColor != null && fillColor != Colors.transparent) {
      canvas.drawPath(path, Paint()..color = fillColor!..style = PaintingStyle.fill);
    }

    canvas.drawPath(
      path,
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
    size = Size(max(20.0, newWidth), max(20.0, newHeight));
    invalidateCache();
  }

  @override
  CanvasObject clone() {
    return CanvasTriangle(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      size: size,
    );
  }
}

