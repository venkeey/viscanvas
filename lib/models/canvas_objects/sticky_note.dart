import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class StickyNote extends CanvasObject {
  String text;
  Size size;
  Color backgroundColor;
  double fontSize;
  bool isEditing;

  StickyNote({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.strokeWidth,
    super.isSelected,
    this.text = 'Double tap to edit',
    required this.size,
    this.backgroundColor = Colors.yellow,
    this.fontSize = 14.0,
    this.isEditing = false,
  });

  @override
  Rect calculateBoundingRect() =>
      Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);

  @override
  bool hitTest(Offset worldPoint) {
    // StickyNote already has reasonable default size, but still allow for slight inflation
    final bounds = getBoundingRect();
    return bounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final rect = Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);

    // Draw background with shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRect(
      rect.shift(const Offset(2, 2)),
      shadowPaint,
    );

    // Draw main background
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / worldToScreen.getScaleFactor();

    canvas.drawRect(rect, borderPaint);

    // Draw text
    if (text.isNotEmpty && size.width > 16 && size.height > 16) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      final maxWidth = (size.width - 16).clamp(1.0, double.infinity);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.black,
            fontSize: scaledFontSize.clamp(8.0, 72.0), // Reasonable font size bounds
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      textPainter.layout(maxWidth: maxWidth);

      final textOffset = Offset(
        worldPosition.dx + 8,
        worldPosition.dy + 8,
      );

      textPainter.paint(canvas, textOffset);
    }

    // Draw editing indicator
    if (isEditing && size.width > 16 && size.height > 16) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      final cursorPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0 / worldToScreen.getScaleFactor();

      final cursorX = worldPosition.dx + 8;
      final cursorY = worldPosition.dy + 8;
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
    size = Size(max(100.0, newWidth), max(60.0, newHeight));
    invalidateCache();
  }

  @override
  CanvasObject clone() {
    return StickyNote(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      text: text,
      size: size,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
    );
  }
}