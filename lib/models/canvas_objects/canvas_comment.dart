import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../../domain/canvas_domain.dart';

class CanvasComment extends CanvasObject {
  String text;
  String? author;
  DateTime createdAt;
  List<CanvasComment> replies;
  String? parentCommentId;
  Size size;
  Color backgroundColor;
  double fontSize;
  bool isResolved;
  bool isEditing;
  Offset? anchorPoint;

  CanvasComment({
    required super.id,
    required super.worldPosition,
    required super.strokeColor,
    super.strokeWidth,
    super.isSelected,
    this.text = '',
    this.author,
    DateTime? createdAt,
    List<CanvasComment>? replies,
    this.parentCommentId,
    required this.size,
    this.backgroundColor = const Color(0xFFE3F2FD), // Light blue
    this.fontSize = 14.0,
    this.isResolved = false,
    this.isEditing = false,
    this.anchorPoint,
  })  : createdAt = createdAt ?? DateTime.now(),
        replies = replies ?? [];

  @override
  Rect calculateBoundingRect() {
    // Calculate bounds including replies
    double totalHeight = size.height;
    if (replies.isNotEmpty) {
      const replySpacing = 8.0;
      for (var reply in replies) {
        totalHeight += reply.size.height + replySpacing;
      }
    }
    
    return Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, totalHeight);
  }

  @override
  bool hitTest(Offset worldPoint) {
    final bounds = getBoundingRect();
    final inflatedBounds = bounds.inflate(16);
    return inflatedBounds.contains(worldPoint);
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final rect = Rect.fromLTWH(worldPosition.dx, worldPosition.dy, size.width, size.height);

    // Draw comment bubble with shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(2, 2)), const Radius.circular(8)),
      shadowPaint,
    );

    // Draw main background
    final backgroundPaint = Paint()
      ..color = isResolved 
          ? backgroundColor.withOpacity(0.5)
          : backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      backgroundPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = isResolved 
          ? strokeColor.withOpacity(0.5)
          : strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / worldToScreen.getScaleFactor();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // Draw resolved indicator
    if (isResolved) {
      final checkmarkPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / worldToScreen.getScaleFactor();

      final checkmarkPath = Path()
        ..moveTo(rect.left + 12, rect.top + size.height / 2)
        ..lineTo(rect.left + 16, rect.top + size.height / 2 + 4)
        ..lineTo(rect.left + 22, rect.top + size.height / 2 - 4);

      canvas.drawPath(checkmarkPath, checkmarkPaint);
    }

    // Draw text
    if (text.isNotEmpty && size.width > 16 && size.height > 16) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      final maxWidth = (size.width - 24).clamp(1.0, double.infinity);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: isResolved ? Colors.grey : Colors.black87,
            fontSize: scaledFontSize.clamp(8.0, 72.0),
            fontFamily: 'Arial',
            decoration: isResolved ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      textPainter.layout(maxWidth: maxWidth);

      final textOffset = Offset(
        worldPosition.dx + 12,
        worldPosition.dy + 12,
      );

      textPainter.paint(canvas, textOffset);
    }

    // Draw author and timestamp if available
    if (author != null && size.height > 40) {
      final scaledFontSize = (fontSize * 0.85) / worldToScreen.getScaleFactor();
      final infoTextPainter = TextPainter(
        text: TextSpan(
          text: author ?? '',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: scaledFontSize.clamp(6.0, 60.0),
            fontFamily: 'Arial',
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      infoTextPainter.layout();
      infoTextPainter.paint(
        canvas,
        Offset(
          worldPosition.dx + 12,
          worldPosition.dy + size.height - 16,
        ),
      );
    }

    // Draw anchor line if anchor point is set
    if (anchorPoint != null) {
      final anchorPaint = Paint()
        ..color = strokeColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 / worldToScreen.getScaleFactor()
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(rect.left, rect.top + rect.height / 2),
        anchorPoint!,
        anchorPaint,
      );
    }

    // Draw replies
    if (replies.isNotEmpty) {
      double currentY = worldPosition.dy + size.height + 8;
      for (var reply in replies) {
        reply.worldPosition = Offset(worldPosition.dx + 20, currentY);
        reply.size = Size(size.width - 20, reply.size.height);
        reply.draw(canvas, worldToScreen);
        currentY += reply.size.height + 8;
      }
    }

    // Draw editing cursor
    if (isEditing && size.width > 16 && size.height > 16) {
      final scaledFontSize = fontSize / worldToScreen.getScaleFactor();
      final cursorPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0 / worldToScreen.getScaleFactor();

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: scaledFontSize,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      final maxWidth = (size.width - 24).clamp(1.0, double.infinity);
      textPainter.layout(maxWidth: maxWidth);

      final cursorX = worldPosition.dx + 12 + textPainter.width;
      final cursorY = worldPosition.dy + 12;
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
    if (anchorPoint != null) {
      anchorPoint = anchorPoint! + delta;
    }
    // Move all replies with the parent
    for (var reply in replies) {
      reply.move(delta);
    }
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
    size = Size(max(150.0, newWidth), max(60.0, newHeight));
    invalidateCache();
  }

  void addReply(CanvasComment reply) {
    reply.parentCommentId = id;
    replies.add(reply);
    invalidateCache();
  }

  @override
  CanvasObject clone() {
    return CanvasComment(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      text: text,
      author: author,
      createdAt: createdAt,
      replies: replies.map((r) => r.clone() as CanvasComment).toList(),
      parentCommentId: parentCommentId,
      size: size,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      isResolved: isResolved,
      isEditing: false,
      anchorPoint: anchorPoint,
    );
  }
}

