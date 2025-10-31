import 'dart:math';
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasText extends CanvasObject {
  String text;
  Size size;
  double fontSize;
  TextAlign textAlign;
  FontWeight fontWeight;
  Color textColor;
  bool isEditing;
  double? maxWidth;

  CanvasText({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.strokeWidth,
    super.isSelected,
    this.text = '',
    required this.size,
    this.fontSize = 16.0,
    this.textAlign = TextAlign.left,
    this.fontWeight = FontWeight.normal,
    this.textColor = Colors.black,
    this.isEditing = false,
    this.maxWidth,
  });

  @override
  Rect calculateBoundingRect() {
    // Calculate actual text bounds based on content (no padding inside)
    if (text.isEmpty) {
      return Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);
    }

    // Use text painter to calculate actual text dimensions
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    final constrainedWidth = maxWidth ?? size.width;
    textPainter.layout(maxWidth: constrainedWidth);

    // Text bounds without internal padding - padding will be outside
    final actualHeight = max(size.height, textPainter.height);
    final actualWidth = max(constrainedWidth, min(textPainter.width, constrainedWidth));

    return Rect.fromLTWH(worldPosition.dx, worldPosition.dy, actualWidth, actualHeight);
  }

  @override
  bool hitTest(Offset worldPoint) {
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.inflate(16);
    return inflatedBounds.contains(worldPoint);
  }

  /// Check if a point is near the edge of the text object
  /// Used to determine if dragging should move the object
  bool isOnEdge(Offset worldPoint, {double edgeWidth = 20.0}) {
    final bounds = getBoundingRect();
    if (!bounds.contains(worldPoint)) {
      return false;
    }

    // Check if point is within edgeWidth pixels of any edge
    final left = bounds.left;
    final right = bounds.right;
    final top = bounds.top;
    final bottom = bounds.bottom;

    final pointX = worldPoint.dx;
    final pointY = worldPoint.dy;

    // Check if near left or right edge
    final nearLeftEdge = (pointX - left) <= edgeWidth;
    final nearRightEdge = (right - pointX) <= edgeWidth;

    // Check if near top or bottom edge
    final nearTopEdge = (pointY - top) <= edgeWidth;
    final nearBottomEdge = (bottom - pointY) <= edgeWidth;

    return nearLeftEdge || nearRightEdge || nearTopEdge || nearBottomEdge;
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final rect = getBoundingRect();

    // Draw text
    if (rect.width > 0 && rect.height > 0) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      // Use full width since padding is outside
      final constrainedWidth = maxWidth ?? size.width;
      final maxTextWidth = constrainedWidth.clamp(1.0, double.infinity);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text.isEmpty ? 'Text' : text,
          style: TextStyle(
            color: textColor,
            fontSize: scaledFontSize.clamp(8.0, 72.0),
            fontWeight: fontWeight,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        maxLines: null,
      );

      textPainter.layout(maxWidth: maxTextWidth);

      // Calculate text position based on alignment (no internal offset)
      double textX = worldPosition.dx;
      if (textAlign == TextAlign.center) {
        textX = worldPosition.dx + (rect.width / 2) - (textPainter.width / 2);
      } else if (textAlign == TextAlign.right) {
        textX = worldPosition.dx + rect.width - textPainter.width;
      }

      final textOffset = Offset(
        textX,
        worldPosition.dy,
      );

      textPainter.paint(canvas, textOffset);
    }

    // Draw editing cursor
    if (isEditing && rect.width > 0 && rect.height > 0) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      final cursorPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0 / worldToScreen.getScaleFactor();

      // Calculate cursor position (simplified - at end of text for now)
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: scaledFontSize,
            fontWeight: fontWeight,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      // Use full width since padding is outside
      final constrainedWidth = maxWidth ?? size.width;
      textPainter.layout(maxWidth: constrainedWidth.clamp(1.0, double.infinity));

      double cursorX = worldPosition.dx;
      if (textAlign == TextAlign.center) {
        cursorX = worldPosition.dx + (rect.width / 2) - (textPainter.width / 2) + textPainter.width;
      } else if (textAlign == TextAlign.right) {
        cursorX = worldPosition.dx + rect.width - textPainter.width + textPainter.width;
      } else {
        cursorX = worldPosition.dx + textPainter.width;
      }

      final cursorY = worldPosition.dy;
      canvas.drawLine(
        Offset(cursorX, cursorY),
        Offset(cursorX, cursorY + scaledFontSize.clamp(8.0, 72.0)),
        cursorPaint,
      );
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

    worldPosition = Offset(newX, newY);
    size = Size(max(50.0, newWidth), max(20.0, newHeight));
    maxWidth = max(50.0, newWidth);
    invalidateCache();
  }

  @override
  CanvasObject clone() {
    return CanvasText(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      text: text,
      size: size,
      fontSize: fontSize,
      textAlign: textAlign,
      fontWeight: fontWeight,
      textColor: textColor,
      isEditing: false,
      maxWidth: maxWidth,
    );
  }
}

