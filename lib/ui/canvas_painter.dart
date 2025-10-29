import 'package:flutter/material.dart';
import '../services/canvas/canvas_service.dart';
import '../domain/canvas_domain.dart';
import '../models/canvas_objects/canvas_object.dart';
import '../models/canvas_objects/canvas_circle.dart';
import '../models/canvas_objects/connector.dart';

// ===== CANVAS PAINTER =====

class AdvancedCanvasPainter extends CustomPainter {
  final CanvasService service;

  AdvancedCanvasPainter(this.service) : super(repaint: service);

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    canvas.save();
    canvas.transform(service.transform.matrix.storage);

    // Highlight hover target with glow effect
    if (service.connectorHoverTarget != null) {
      _drawTargetHighlight(canvas, service.connectorHoverTarget!);
    }

    for (var obj in service.objects) {
      obj.draw(canvas, service.transform.matrix);
    }

    // Draw temporary object during creation
    if (service.tempObject != null) {
      service.tempObject!.draw(canvas, service.transform.matrix);
    }

    // Draw ghost line preview during drag connection
    if (service.connectorSourceObject != null && service.lastWorldPoint != null) {
      _drawGhostLine(canvas, service.connectorSourceObject!, service.lastWorldPoint!);
    }

    // Draw freehand connector preview
    if (service.currentFreehandConnector != null) {
      final freehandPaint = service.currentFreehandConnector!.paint;
      canvas.drawPath(service.currentFreehandConnector!.path, freehandPaint);
    }

    canvas.restore();

    for (var obj in service.objects.where((o) => o.isSelected)) {
      if (obj is Connector) {
        _drawConnectorHandles(canvas, obj, service.transform);
      } else {
        obj.drawBoundingBox(canvas, service.transform.matrix);
      }
    }
  }

  void _drawTargetHighlight(Canvas canvas, CanvasObject target) {
    final bounds = target.getBoundingRect();

    // Draw outer glow
    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Draw inner highlight
    final highlightPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (target is CanvasCircle) {
      canvas.drawCircle(bounds.center, target.radius + 4, glowPaint);
      canvas.drawCircle(bounds.center, target.radius + 2, highlightPaint);
    } else {
      final highlightRect = bounds.inflate(4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
        glowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds.inflate(2), const Radius.circular(6)),
        highlightPaint,
      );
    }
  }

  void _drawGhostLine(Canvas canvas, CanvasObject source, Offset targetPoint) {
    // Calculate smart anchor points for preview
    final sourceBounds = source.getBoundingRect();
    final sourceCenter = sourceBounds.center;

    // Create temporary object for anchor calculation
    final dx = targetPoint.dx - sourceCenter.dx;
    final dy = targetPoint.dy - sourceCenter.dy;

    Offset sourceAnchorPos;
    Offset targetAnchorPos = targetPoint;

    // Determine source anchor based on direction to target
    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        sourceAnchorPos = Offset(sourceBounds.right, sourceCenter.dy);
      } else {
        sourceAnchorPos = Offset(sourceBounds.left, sourceCenter.dy);
      }
    } else {
      if (dy > 0) {
        sourceAnchorPos = Offset(sourceCenter.dx, sourceBounds.bottom);
      } else {
        sourceAnchorPos = Offset(sourceCenter.dx, sourceBounds.top);
      }
    }

    // If hovering over a valid target, snap to its edge
    if (service.connectorHoverTarget != null) {
      final targetBounds = service.connectorHoverTarget!.getBoundingRect();
      final targetCenter = targetBounds.center;

      if (dx.abs() > dy.abs()) {
        if (dx > 0) {
          targetAnchorPos = Offset(targetBounds.left, targetCenter.dy);
        } else {
          targetAnchorPos = Offset(targetBounds.right, targetCenter.dy);
        }
      } else {
        if (dy > 0) {
          targetAnchorPos = Offset(targetCenter.dx, targetBounds.top);
        } else {
          targetAnchorPos = Offset(targetCenter.dx, targetBounds.bottom);
        }
      }
    }

    // Draw ghost line with curve
    final ghostPaint = Paint()
      ..color = service.connectorHoverTarget != null
          ? Colors.blue.withOpacity(0.6)
          : service.strokeColor.withOpacity(0.4)
      ..strokeWidth = service.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Note: dashPaint was defined but not used - removed for now

    // Create curved path
    final path = Path();
    path.moveTo(sourceAnchorPos.dx, sourceAnchorPos.dy);

    final distance = (targetAnchorPos - sourceAnchorPos).distance;
    final controlPointOffset = distance * 0.35;

    final cp1 = Offset(
      sourceAnchorPos.dx + (dx.abs() > dy.abs() ? (dx > 0 ? controlPointOffset : -controlPointOffset) : 0),
      sourceAnchorPos.dy + (dy.abs() > dx.abs() ? (dy > 0 ? controlPointOffset : -controlPointOffset) : 0),
    );

    final cp2 = Offset(
      targetAnchorPos.dx + (dx.abs() > dy.abs() ? (dx > 0 ? -controlPointOffset : controlPointOffset) : 0),
      targetAnchorPos.dy + (dy.abs() > dx.abs() ? (dy > 0 ? -controlPointOffset : controlPointOffset) : 0),
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, targetAnchorPos.dx, targetAnchorPos.dy);

    canvas.drawPath(path, ghostPaint);

    // Draw anchor dots
    final anchorPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(sourceAnchorPos, 4, anchorPaint);

    if (service.connectorHoverTarget != null) {
      canvas.drawCircle(targetAnchorPos, 4, anchorPaint);
    }
  }

  void _drawConnectorHandles(Canvas canvas, Connector connector, Transform2D transform) {
    const handleSize = 14.0;
    
    // Transform handle positions to screen coordinates
    final startScreen = transform.worldToScreen(connector.startHandle);
    final endScreen = transform.worldToScreen(connector.endHandle);
    final firstQuarterScreen = transform.worldToScreen(connector.firstQuarterHandle);
    final thirdQuarterScreen = transform.worldToScreen(connector.thirdQuarterHandle);
    
    // Draw start and end handles (blue)
    final startEndPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    final startEndBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(startScreen, handleSize / 2, startEndPaint);
    canvas.drawCircle(startScreen, handleSize / 2, startEndBorderPaint);
    
    canvas.drawCircle(endScreen, handleSize / 2, startEndPaint);
    canvas.drawCircle(endScreen, handleSize / 2, startEndBorderPaint);
    
    // Draw quarter handles (orange)
    final quarterPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    
    final quarterBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(firstQuarterScreen, handleSize / 2, quarterPaint);
    canvas.drawCircle(firstQuarterScreen, handleSize / 2, quarterBorderPaint);
    
    canvas.drawCircle(thirdQuarterScreen, handleSize / 2, quarterPaint);
    canvas.drawCircle(thirdQuarterScreen, handleSize / 2, quarterBorderPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    const gridSize = 50.0;
    final transformedGridSize = gridSize * service.transform.scale;

    if (transformedGridSize < 5) return;

    final offsetX = service.transform.translation.dx % transformedGridSize;
    final offsetY = service.transform.translation.dy % transformedGridSize;

    for (double x = offsetX; x < size.width; x += transformedGridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = offsetY; y < size.height; y += transformedGridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final origin = service.transform.worldToScreen(Offset.zero);
    final originPaint = Paint()..color = Colors.red..strokeWidth = 2;

    canvas.drawLine(Offset(origin.dx - 10, origin.dy), Offset(origin.dx + 10, origin.dy), originPaint);
    canvas.drawLine(Offset(origin.dx, origin.dy - 10), Offset(origin.dx, origin.dy + 10), originPaint);
  }

  @override
  bool shouldRepaint(AdvancedCanvasPainter oldDelegate) => true;
}