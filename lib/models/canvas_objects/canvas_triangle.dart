import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasTriangle extends CanvasObject {
  List<Offset> vertices; // 3 vertices: [top, bottomLeft, bottomRight] - relative to worldPosition
  String text;
  double fontSize;
  Color textColor;

  CanvasTriangle({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.fillColor,
    super.strokeWidth,
    super.isSelected,
    required this.vertices,
    this.text = '',
    this.fontSize = 16.0,
    this.textColor = Colors.black,
  }) {
    // Ensure we have exactly 3 vertices
    if (vertices.length != 3) {
      throw ArgumentError('CanvasTriangle must have exactly 3 vertices');
    }
  }

  @override
  Rect calculateBoundingRect() {
    if (vertices.length != 3) return Rect.zero;

    final worldVertices = vertices.map((v) => worldPosition + v).toList();
    
    double minX = worldVertices[0].dx;
    double minY = worldVertices[0].dy;
    double maxX = worldVertices[0].dx;
    double maxY = worldVertices[0].dy;

    for (final vertex in worldVertices) {
      minX = min(minX, vertex.dx);
      minY = min(minY, vertex.dy);
      maxX = max(maxX, vertex.dx);
      maxY = max(maxY, vertex.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool hitTest(Offset worldPoint) {
    // Inflate bounds for easier hit detection
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.inflate(16);
    return inflatedBounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    if (vertices.length != 3) return;

    final path = Path()
      ..moveTo((worldPosition + vertices[0]).dx, (worldPosition + vertices[0]).dy)
      ..lineTo((worldPosition + vertices[1]).dx, (worldPosition + vertices[1]).dy)
      ..lineTo((worldPosition + vertices[2]).dx, (worldPosition + vertices[2]).dy)
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

    // Draw centered text if text is not empty
    if (text.isNotEmpty) {
      final bounds = getBoundingRect();
      if (bounds.width > 16 && bounds.height > 16) {
        final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
        final maxWidth = (bounds.width - 16).clamp(1.0, double.infinity);

        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: textColor,
              fontSize: scaledFontSize.clamp(8.0, 72.0),
              fontFamily: 'Arial',
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: null,
        );

        textPainter.layout(maxWidth: maxWidth);

        // Calculate centroid of triangle
        final worldVertices = vertices.map((v) => worldPosition + v).toList();
        final centroid = Offset(
          (worldVertices[0].dx + worldVertices[1].dx + worldVertices[2].dx) / 3,
          (worldVertices[0].dy + worldVertices[1].dy + worldVertices[2].dy) / 3,
        );

        final textOffset = Offset(
          centroid.dx - textPainter.width / 2,
          centroid.dy - textPainter.height / 2,
        );

        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  void move(Offset delta) {
    worldPosition += delta;
    invalidateCache();
  }

  @override
  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds) {
    if (vertices.length != 3) return;

    double newX = initialBounds.left;
    double newY = initialBounds.top;
    double newWidth = initialBounds.width;
    double newHeight = initialBounds.height;

    // Calculate scale factors
    final originalWidth = initialBounds.width;
    final originalHeight = initialBounds.height;
    
    if (originalWidth == 0 || originalHeight == 0) return;

    switch (handle) {
      case ResizeHandle.topLeft:
        newX += delta.dx;
        newY += delta.dy;
        newWidth -= delta.dx;
        newHeight -= delta.dy;
        break;
      case ResizeHandle.topCenter:
        newY += delta.dy;
        newHeight -= delta.dy;
        break;
      case ResizeHandle.topRight:
        newY += delta.dy;
        newWidth += delta.dx;
        newHeight -= delta.dy;
        break;
      case ResizeHandle.centerLeft:
        newX += delta.dx;
        newWidth -= delta.dx;
        break;
      case ResizeHandle.centerRight:
        newWidth += delta.dx;
        break;
      case ResizeHandle.bottomLeft:
        newX += delta.dx;
        newWidth -= delta.dx;
        newHeight += delta.dy;
        break;
      case ResizeHandle.bottomCenter:
        newHeight += delta.dy;
        break;
      case ResizeHandle.bottomRight:
        newWidth += delta.dx;
        newHeight += delta.dy;
        break;
      case ResizeHandle.none:
        return;
      default:
        return;
    }

    // Apply minimum size constraints
    newWidth = max(10.0, newWidth);
    newHeight = max(10.0, newHeight);

    final scaleX = newWidth / originalWidth;
    final scaleY = newHeight / originalHeight;

    // Scale vertices relative to their original position
    final originalCenter = initialBounds.center;
    
    vertices = vertices.map((v) {
      final originalWorldVertex = initialWorldPosition + v;
      final relativeToCenter = originalWorldVertex - originalCenter;
      final scaled = Offset(relativeToCenter.dx * scaleX, relativeToCenter.dy * scaleY);
      final newWorldVertex = originalCenter + scaled;
      return newWorldVertex - Offset(newX, newY); // Convert back to relative
    }).toList();

    worldPosition = Offset(newX, newY);
    invalidateCache();
  }

  /// Expands the triangle to fit the text content
  void expandToFitText() {
    if (text.isEmpty || vertices.length != 3) return;

    final bounds = getBoundingRect();
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: null,
    );

    // Measure text with current width constraint
    final maxWidth = (bounds.width - 16).clamp(1.0, double.infinity);
    textPainter.layout(maxWidth: maxWidth);

    // Calculate required dimensions
    final requiredWidth = textPainter.width + 16;
    final requiredHeight = textPainter.height + 16;

    if (requiredWidth > bounds.width || requiredHeight > bounds.height) {
      // Calculate scale factors
      final scaleX = requiredWidth / max(bounds.width, 1.0);
      final scaleY = requiredHeight / max(bounds.height, 1.0);
      final scale = max(scaleX, scaleY);

      // Calculate centroid of triangle (world coordinates)
      final worldVertices = vertices.map((v) => worldPosition + v).toList();
      final centroid = Offset(
        (worldVertices[0].dx + worldVertices[1].dx + worldVertices[2].dx) / 3,
        (worldVertices[0].dy + worldVertices[1].dy + worldVertices[2].dy) / 3,
      );

      // Scale vertices relative to centroid
      vertices = vertices.map((v) {
        final worldVertex = worldPosition + v;
        final relativeToCentroid = worldVertex - centroid;
        final scaled = Offset(relativeToCentroid.dx * scale, relativeToCentroid.dy * scale);
        final newWorldVertex = centroid + scaled;
        return newWorldVertex - worldPosition; // Convert back to relative
      }).toList();

      // Adjust worldPosition to maintain approximate top-left position
      final newBounds = calculateBoundingRect();
      final offsetX = bounds.left - newBounds.left;
      final offsetY = bounds.top - newBounds.top;
      worldPosition = worldPosition + Offset(offsetX, offsetY);
      
      invalidateCache();
    }
  }

  @override
  CanvasObject clone() {
    return CanvasTriangle(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      isSelected: false,
      vertices: List.from(vertices),
      text: text,
      fontSize: fontSize,
      textColor: textColor,
    );
  }
}
