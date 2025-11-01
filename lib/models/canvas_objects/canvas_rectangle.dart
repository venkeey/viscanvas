import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasRectangle extends CanvasObject {
  Size size;
  String text;
  double fontSize;
  Color textColor;

  CanvasRectangle({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.fillColor,
    super.strokeWidth,
    super.isSelected,
    required this.size,
    this.text = '',
    this.fontSize = 16.0,
    this.textColor = Colors.black,
  });

  @override
  Rect calculateBoundingRect() =>
      Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);

  @override
  bool hitTest(Offset worldPoint) {
    // Inflate bounds for easier hit detection - larger inflation for better selection
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.inflate(16); // Increased from 10 to 16
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

    // Draw centered text if text is not empty
    if (text.isNotEmpty && size.width > 16 && size.height > 16) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      final maxWidth = (size.width - 16).clamp(1.0, double.infinity);

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

      // Calculate center of rectangle
      final center = worldPosition + Offset(size.width / 2, size.height / 2);
      final textOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
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

  /// Expands the rectangle to fit the text content
  void expandToFitText() {
    if (text.isEmpty) return;

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
    final maxWidth = (size.width - 16).clamp(1.0, double.infinity);
    textPainter.layout(maxWidth: maxWidth);

    // Check if we need to expand
    final requiredWidth = textPainter.width + 16;
    final requiredHeight = textPainter.height + 16;

    if (requiredWidth > size.width || requiredHeight > size.height) {
      size = Size(
        max(size.width, requiredWidth),
        max(size.height, requiredHeight),
      );
      invalidateCache();
    }
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
      text: text,
      fontSize: fontSize,
      textColor: textColor,
    );
  }
}