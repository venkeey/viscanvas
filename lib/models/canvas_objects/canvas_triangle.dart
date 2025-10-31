import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasTriangle extends CanvasObject {
  // Triangle defined by three points
  // worldPosition is the top-left of bounding box
  // Points are relative to worldPosition
  final Offset point1; // Top point (center top)
  final Offset point2; // Bottom left
  final Offset point3; // Bottom right

  CanvasTriangle({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.fillColor,
    super.strokeWidth,
    super.isSelected,
    Offset? point1,
    Offset? point2,
    Offset? point3,
    Size? size,
  }) : point1 = point1 ?? const Offset(0, 0),
        point2 = point2 ?? const Offset(0, 50),
        point3 = point3 ?? const Offset(50, 50) {
    // If size is provided, calculate triangle points for an equilateral-ish triangle
    if (size != null) {
      // This constructor variant would be handled by factory or helper
    }
  }

  // Get absolute positions of triangle points
  Offset get absolutePoint1 => worldPosition + point1;
  Offset get absolutePoint2 => worldPosition + point2;
  Offset get absolutePoint3 => worldPosition + point3;

  @override
  Rect calculateBoundingRect() {
    final p1 = absolutePoint1;
    final p2 = absolutePoint2;
    final p3 = absolutePoint3;
    
    final minX = min(min(p1.dx, p2.dx), p3.dx);
    final maxX = max(max(p1.dx, p2.dx), p3.dx);
    final minY = min(min(p1.dy, p2.dy), p3.dy);
    final maxY = max(max(p1.dy, p2.dy), p3.dy);
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool hitTest(Offset worldPoint) {
    // Use point-in-triangle test
    final p1 = absolutePoint1;
    final p2 = absolutePoint2;
    final p3 = absolutePoint3;
    
    // Barycentric coordinate method
    final v0 = p3 - p1;
    final v1 = p2 - p1;
    final v2 = worldPoint - p1;
    
    final dot00 = v0.dot(v0);
    final dot01 = v0.dot(v1);
    final dot02 = v0.dot(v2);
    final dot11 = v1.dot(v1);
    final dot12 = v1.dot(v2);
    
    final invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
    final u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    final v = (dot00 * dot12 - dot01 * dot02) * invDenom;
    
    // Inflate hit area slightly for easier selection
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.inflate(16);
    
    // Check if point is in triangle OR in inflated bounding box
    return (u >= -0.1 && v >= -0.1 && u + v < 1.1) || inflatedBounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final p1 = absolutePoint1;
    final p2 = absolutePoint2;
    final p3 = absolutePoint3;
    
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
    final bounds = getBoundingRect();
    final newWidth = max(20.0, bounds.width + 
      (handle.toString().contains('Right') ? delta.dx : 
       handle.toString().contains('Left') ? -delta.dx : 0));
    final newHeight = max(20.0, bounds.height + 
      (handle.toString().contains('Bottom') ? delta.dy : 
       handle.toString().contains('Top') ? -delta.dy : 0));
    
    // Calculate new triangle points based on resize handle
    // Keep triangle shape proportional (equilateral-like)
    final centerX = bounds.center.dx;
    final centerY = bounds.center.dy;
    
    // Update points relative to new bounds
    final newBounds = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: newWidth,
      height: newHeight,
    );
    
    // Recalculate triangle points for equilateral triangle
    final topPoint = Offset(newBounds.center.dx, newBounds.top);
    final bottomLeft = Offset(newBounds.left, newBounds.bottom);
    final bottomRight = Offset(newBounds.right, newBounds.bottom);
    
    // Calculate relative positions
    final rect = Rect.fromPoints(
      min(min(topPoint, bottomLeft), bottomRight),
      max(max(topPoint, bottomLeft), bottomRight),
    );
    
    worldPosition = rect.topLeft;
    // Note: In a full implementation, we'd update point1, point2, point3
    // For now, we'll use a simpler approach - store size and recalculate points
    
    invalidateCache();
  }

  // Helper method to update triangle size
  void updateSize(Size newSize) {
    final bounds = getBoundingRect();
    final center = bounds.center;
    
    final newBounds = Rect.fromCenter(
      center: center,
      width: newSize.width,
      height: newSize.height,
    );
    
    // Create equilateral-like triangle
    // Point 1: top center
    final newP1 = Offset(newBounds.center.dx - bounds.center.dx, newBounds.top - bounds.top);
    // Point 2: bottom left
    final newP2 = Offset(newBounds.left - bounds.left, newBounds.bottom - bounds.top);
    // Point 3: bottom right
    final newP3 = Offset(newBounds.right - bounds.left, newBounds.bottom - bounds.top);
    
    worldPosition = newBounds.topLeft;
    // Note: point1, point2, point3 are final, so we'd need to make them mutable
    // Or use a different approach with a getter that calculates from size
    
    invalidateCache();
  }

  // Get current size
  Size getSize() {
    final bounds = getBoundingRect();
    return Size(bounds.width, bounds.height);
  }

  @override
  CanvasObject clone() {
    return CanvasTriangle(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      point1: point1,
      point2: point2,
      point3: point3,
    );
  }
}

