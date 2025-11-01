import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasCircle extends CanvasObject {
  double radius;
  String text;
  double fontSize;
  Color textColor;

  CanvasCircle({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.fillColor,
    super.strokeWidth,
    super.isSelected,
    required this.radius,
    this.text = '',
    this.fontSize = 16.0,
    this.textColor = Colors.black,
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

    // Draw centered text if text is not empty
    if (text.isNotEmpty && radius > 8) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      final diameter = radius * 2;
      final maxWidth = (diameter - 16).clamp(1.0, double.infinity);

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

      // Text is centered at circle center
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
    final newDiameter = max(20.0, min(
      initialBounds.width + (handle.toString().contains('Right') ? delta.dx : -delta.dx),
      initialBounds.height + (handle.toString().contains('bottom') ? delta.dy : -delta.dy),
    ));

    radius = newDiameter / 2;
    worldPosition = initialBounds.center - Offset(radius, radius);
    invalidateCache();
  }

  /// Expands the circle to fit the text content
  void expandToFitText() {
    if (text.isEmpty) return;

    final diameter = radius * 2;
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
    final maxWidth = (diameter - 16).clamp(1.0, double.infinity);
    textPainter.layout(maxWidth: maxWidth);

    // Calculate required radius to fit text
    final textWidth = textPainter.width + 16;
    final textHeight = textPainter.height + 16;
    final requiredRadius = sqrt(textWidth * textWidth + textHeight * textHeight) / 2 + 8;

    if (requiredRadius > radius) {
      radius = requiredRadius;
      invalidateCache();
    }
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
      text: text,
      fontSize: fontSize,
      textColor: textColor,
    );
  }
}