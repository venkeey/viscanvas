import 'dart:math';
import 'package:flutter/material.dart';
import '../models/canvas_objects/canvas_object.dart';
import '../models/canvas_objects/canvas_circle.dart';

// Edge enum for smart anchor system
enum NodeEdge { left, right, top, bottom }

// Extension for Offset normalization
extension OffsetExtension on Offset {
  Offset normalize() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return this / length;
  }
}

// Anchor point with smart positioning
class AnchorPoint {
  final Offset position;
  final NodeEdge edge;
  final double edgePosition; // 0.0 to 1.0 along the edge

  AnchorPoint({
    required this.position,
    required this.edge,
    this.edgePosition = 0.5, // Default to center of edge
  });

  // Get the normal vector for this edge (direction pointing outward)
  Offset get normal {
    switch (edge) {
      case NodeEdge.right:
        return const Offset(1, 0);
      case NodeEdge.left:
        return const Offset(-1, 0);
      case NodeEdge.bottom:
        return const Offset(0, 1);
      case NodeEdge.top:
        return const Offset(0, -1);
    }
  }
}

// ConnectorCalculator - Utility for creating curved connector paths
class ConnectorCalculator {
  // Smart edge detection based on relative positions
  static AnchorPoint getSmartAnchorPoint(
    CanvasObject sourceObject,
    CanvasObject targetObject,
    {bool isSource = true}
  ) {
    final sourceBounds = sourceObject.getBoundingRect();
    final targetBounds = targetObject.getBoundingRect();
    final sourceCenter = sourceBounds.center;
    final targetCenter = targetBounds.center;

    // Calculate direction vector from source to target
    final dx = targetCenter.dx - sourceCenter.dx;
    final dy = targetCenter.dy - sourceCenter.dy;

    // Determine which edges should connect based on relative positions
    NodeEdge edge;
    Offset position;

    if (isSource) {
      // Choose source edge based on where target is
      if (dx.abs() > dy.abs()) {
        // Target is more horizontal
        if (dx > 0) {
          // Target is to the right
          edge = NodeEdge.right;
          position = _getMagneticPoint(sourceBounds, edge, dy / dx.abs());
        } else {
          // Target is to the left
          edge = NodeEdge.left;
          position = _getMagneticPoint(sourceBounds, edge, dy / dx.abs());
        }
      } else {
        // Target is more vertical
        if (dy > 0) {
          // Target is below
          edge = NodeEdge.bottom;
          position = _getMagneticPoint(sourceBounds, edge, dx / dy.abs());
        } else {
          // Target is above
          edge = NodeEdge.top;
          position = _getMagneticPoint(sourceBounds, edge, dx / dy.abs());
        }
      }
    } else {
      // Choose target edge (opposite of source direction)
      if (dx.abs() > dy.abs()) {
        // Source is more horizontal
        if (dx > 0) {
          // Source is to the left of target
          edge = NodeEdge.left;
          position = _getMagneticPoint(targetBounds, edge, dy / dx.abs());
        } else {
          // Source is to the right of target
          edge = NodeEdge.right;
          position = _getMagneticPoint(targetBounds, edge, dy / dx.abs());
        }
      } else {
        // Source is more vertical
        if (dy > 0) {
          // Source is above target
          edge = NodeEdge.top;
          position = _getMagneticPoint(targetBounds, edge, dx / dy.abs());
        } else {
          // Source is below target
          edge = NodeEdge.bottom;
          position = _getMagneticPoint(targetBounds, edge, dx / dy.abs());
        }
      }
    }

    // Handle circles specially
    if ((isSource && sourceObject is CanvasCircle) || (!isSource && targetObject is CanvasCircle)) {
      final circle = isSource ? sourceObject as CanvasCircle : targetObject as CanvasCircle;
      final circleCenter = circle.getBoundingRect().center;
      final otherCenter = isSource ? targetCenter : sourceCenter;
      final angle = atan2(otherCenter.dy - circleCenter.dy, otherCenter.dx - circleCenter.dx);
      position = Offset(
        circleCenter.dx + circle.radius * cos(angle),
        circleCenter.dy + circle.radius * sin(angle),
      );
    }

    return AnchorPoint(position: position, edge: edge);
  }

  // Magnetic snap points (center, quarter positions)
  static Offset _getMagneticPoint(Rect bounds, NodeEdge edge, double bias) {
    // bias is -1 to 1, indicating vertical/horizontal offset preference
    final clampedBias = bias.clamp(-1.0, 1.0);

    // Calculate position along edge (0.5 = center, 0.25/0.75 = quarter points)
    double edgePosition = 0.5 + (clampedBias * 0.25);
    edgePosition = edgePosition.clamp(0.25, 0.75); // Keep within reasonable bounds

    switch (edge) {
      case NodeEdge.right:
        return Offset(
          bounds.right,
          bounds.top + (bounds.height * edgePosition),
        );
      case NodeEdge.left:
        return Offset(
          bounds.left,
          bounds.top + (bounds.height * edgePosition),
        );
      case NodeEdge.bottom:
        return Offset(
          bounds.left + (bounds.width * edgePosition),
          bounds.bottom,
        );
      case NodeEdge.top:
        return Offset(
          bounds.left + (bounds.width * edgePosition),
          bounds.top,
        );
    }
  }

  static Path createCurvedPath(
    Offset start,
    Offset end,
    String startDirection,
    String endDirection,
  ) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate control points based on direction
    final distance = (end - start).distance;
    final controlPointOffset = distance * 0.3;

    Offset cp1, cp2;

    switch (startDirection) {
      case 'right':
        cp1 = Offset(start.dx + controlPointOffset, start.dy);
        break;
      case 'left':
        cp1 = Offset(start.dx - controlPointOffset, start.dy);
        break;
      case 'bottom':
        cp1 = Offset(start.dx, start.dy + controlPointOffset);
        break;
      case 'top':
        cp1 = Offset(start.dx, start.dy - controlPointOffset);
        break;
      default:
        cp1 = Offset(start.dx + controlPointOffset, start.dy);
    }

    switch (endDirection) {
      case 'right':
        cp2 = Offset(end.dx + controlPointOffset, end.dy);
        break;
      case 'left':
        cp2 = Offset(end.dx - controlPointOffset, end.dy);
        break;
      case 'bottom':
        cp2 = Offset(end.dx, end.dy + controlPointOffset);
        break;
      case 'top':
        cp2 = Offset(end.dx, end.dy - controlPointOffset);
        break;
      default:
        cp2 = Offset(end.dx - controlPointOffset, end.dy);
    }

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }

  // New method for creating paths with AnchorPoints
  static Path createSmartCurvedPath(AnchorPoint start, AnchorPoint end) {
    final path = Path();
    path.moveTo(start.position.dx, start.position.dy);

    final distance = (end.position - start.position).distance;

    // Use S-curves for long connections, C-curves for short
    if (distance > 300) {
      _createSCurve(path, start, end, distance);
    } else {
      _createCCurve(path, start, end, distance);
    }

    return path;
  }

  // C-Curve: Simple curved path for short distances
  static void _createCCurve(Path path, AnchorPoint start, AnchorPoint end, double distance) {
    final controlPointOffset = distance * 0.35;

    // Calculate control points using anchor normals
    final cp1 = start.position + (start.normal * controlPointOffset);
    final cp2 = end.position + (end.normal * controlPointOffset);

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.position.dx, end.position.dy);
  }

  // S-Curve: More natural flowing path for long distances
  static void _createSCurve(Path path, AnchorPoint start, AnchorPoint end, double distance) {
    // For S-curves, we create two segments:
    // 1. First segment curves away from source
    // 2. Second segment curves toward target

    final midPoint = Offset(
      (start.position.dx + end.position.dx) / 2,
      (start.position.dy + end.position.dy) / 2,
    );

    // Control points for first segment (source to mid)
    final cp1Distance = distance * 0.25;
    final cp1 = start.position + (start.normal * cp1Distance);

    // Control point at midpoint (reduced influence for smoother transition)
    final cp2Distance = distance * 0.15;
    final midDirection = (end.position - start.position);
    final midNormal = Offset(-midDirection.dy, midDirection.dx).normalize();
    final cp2 = midPoint + (midNormal * cp2Distance);

    // Control points for second segment (mid to target)
    final cp3 = midPoint - (midNormal * cp2Distance);
    final cp4Distance = distance * 0.25;
    final cp4 = end.position + (end.normal * cp4Distance);

    // Create the S-curve with two cubic segments
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, midPoint.dx, midPoint.dy);
    path.cubicTo(cp3.dx, cp3.dy, cp4.dx, cp4.dy, end.position.dx, end.position.dy);
  }

  static Offset getClosestEdgePoint(CanvasObject object, Offset fromPoint) {
    final bounds = object.getBoundingRect();
    final center = bounds.center;
    final dx = fromPoint.dx - center.dx;
    final dy = fromPoint.dy - center.dy;

    if (object is CanvasCircle) {
      // For circles, calculate point on edge based on angle
      final angle = atan2(dy, dx);
      return Offset(
        center.dx + object.radius * cos(angle),
        center.dy + object.radius * sin(angle),
      );
    } else {
      // For rectangles and other shapes
      if (dx.abs() > dy.abs()) {
        return dx > 0
            ? Offset(bounds.right, center.dy)
            : Offset(bounds.left, center.dy);
      } else {
        return dy > 0
            ? Offset(center.dx, bounds.bottom)
            : Offset(center.dx, bounds.top);
      }
    }
  }

  static String estimateEdgeDirection(Offset point, Offset center) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? 'right' : 'left';
    } else {
      return dy > 0 ? 'bottom' : 'top';
    }
  }

  static double distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final normalLength = sqrt(pow(lineEnd.dx - lineStart.dx, 2) + pow(lineEnd.dy - lineStart.dy, 2));
    if (normalLength == 0.0) return (point - lineStart).distance;

    return ((point.dx - lineStart.dx) * (lineEnd.dy - lineStart.dy) -
            (point.dy - lineStart.dy) * (lineEnd.dx - lineStart.dx))
            .abs() / normalLength;
  }
}