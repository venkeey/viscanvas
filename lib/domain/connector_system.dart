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
  static Path createSmartCurvedPath(AnchorPoint start, AnchorPoint end, {List<CanvasObject>? obstacles}) {
    final path = Path();
    path.moveTo(start.position.dx, start.position.dy);

    final distance = (end.position - start.position).distance;

    // COLLISION INTELLIGENCE DISABLED - Using simple curved paths
    // If obstacles are present, create intelligent curved path that avoids them
    // if (obstacles != null && obstacles.isNotEmpty) {
    //   return _createIntelligentCurvedPath(start, end, obstacles);
    // }

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
  
  // Create an anchor point from a specific position on an object
  static AnchorPoint createAnchorFromPoint(CanvasObject object, Offset point) {
    final bounds = object.getBoundingRect();
    final center = bounds.center;
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    
    NodeEdge edge;
    double edgePosition = 0.5; // Default to center
    
    if (object is CanvasCircle) {
      // For circles, determine edge based on angle
      final angle = atan2(dy, dx);
      // Normalize angle to 0-2π
      final normalizedAngle = angle < 0 ? angle + 2 * pi : angle;
      
      if (normalizedAngle >= pi / 4 && normalizedAngle < 3 * pi / 4) {
        edge = NodeEdge.bottom;
      } else if (normalizedAngle >= 3 * pi / 4 && normalizedAngle < 5 * pi / 4) {
        edge = NodeEdge.left;
      } else if (normalizedAngle >= 5 * pi / 4 && normalizedAngle < 7 * pi / 4) {
        edge = NodeEdge.top;
      } else {
        edge = NodeEdge.right;
      }
    } else {
      // For rectangles, determine which edge
      if (dx.abs() > dy.abs()) {
        edge = dx > 0 ? NodeEdge.right : NodeEdge.left;
        // Calculate position along the edge (0.0 to 1.0)
        final edgeLength = bounds.height;
        final distanceFromTop = point.dy - bounds.top;
        edgePosition = edgeLength > 0 ? (distanceFromTop / edgeLength).clamp(0.0, 1.0) : 0.5;
      } else {
        edge = dy > 0 ? NodeEdge.bottom : NodeEdge.top;
        // Calculate position along the edge (0.0 to 1.0)
        final edgeLength = bounds.width;
        final distanceFromLeft = point.dx - bounds.left;
        edgePosition = edgeLength > 0 ? (distanceFromLeft / edgeLength).clamp(0.0, 1.0) : 0.5;
      }
    }
    
    return AnchorPoint(
      position: point,
      edge: edge,
      edgePosition: edgePosition,
    );
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

  // COLLISION INTELLIGENCE DISABLED - Commented out intelligent curved path
  // Create intelligent curved path that avoids obstacles while maintaining curves
  // static Path _createIntelligentCurvedPath(AnchorPoint start, AnchorPoint end, List<CanvasObject> obstacles) {
  //   final path = Path();
  //   path.moveTo(start.position.dx, start.position.dy);

  //   final distance = (end.position - start.position).distance;
  //   final direction = (end.position - start.position).normalize();
  //   final perpendicular = Offset(-direction.dy, direction.dx);

  //   // Find obstacles in the direct path
  //   final blockingObstacles = obstacles.where((obj) {
  //     final bounds = obj.getBoundingRect();
  //     return _lineIntersectsRect(start.position, end.position, bounds);
  //   }).toList();

  //   if (blockingObstacles.isEmpty) {
  //     // No obstacles, use normal curved path
  //     if (distance > 300) {
  //       _createSCurve(path, start, end, distance);
  //     } else {
  //       _createCCurve(path, start, end, distance);
  //     }
  //     return path;
  //   }

  //   // Create intelligent S-curve that goes around obstacles
  //   _createIntelligentSCurve(path, start, end, obstacles, distance, direction, perpendicular);

  //   return path;
  // }

  // COLLISION INTELLIGENCE DISABLED - Commented out intelligent S-curve
  // Create intelligent S-curve that avoids obstacles
  // static void _createIntelligentSCurve(Path path, AnchorPoint start, AnchorPoint end, 
  //     List<CanvasObject> obstacles, double distance, Offset direction, Offset perpendicular) {
  //   // For S-curves, we create two segments with a mid-point
  //   final midPoint = Offset.lerp(start.position, end.position, 0.5)!;
  //   final controlPointOffset = distance * 0.35;

  //   // Find control points that create collision-free path segments
  //   final cp1 = _findSmartControlPointWithPathCheck(start, end, obstacles, controlPointOffset, true, perpendicular);
  //   final cp2 = _findSmartControlPointForMidpointWithPathCheck(start, end, obstacles, controlPointOffset, midPoint, perpendicular, cp1, start.position);
    
  //   final cp3 = _findSmartControlPointForMidpointWithPathCheck(start, end, obstacles, controlPointOffset, midPoint, perpendicular, end.position, midPoint);
  //   final cp4 = _findSmartControlPointWithPathCheck(start, end, obstacles, controlPointOffset, false, perpendicular);

  //   // Create the S-curve with two cubic segments
  //   path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, midPoint.dx, midPoint.dy);
  //   path.cubicTo(cp3.dx, cp3.dy, cp4.dx, cp4.dy, end.position.dx, end.position.dy);
  // }

  // COLLISION INTELLIGENCE DISABLED - Commented out smart control point methods
  // Find smart control point for midpoint in S-curve
  // static Offset _findSmartControlPointForMidpoint(AnchorPoint start, AnchorPoint end, 
  //     List<CanvasObject> obstacles, double offset, Offset midPoint, Offset perpendicular) {
    
  //   final direction = (end.position - start.position).normalize();
  //   final positions = <Offset>[];
    
  //   // Add direct midpoint
  //   positions.add(midPoint);
    
  //   // Try positions at different distances and angles around midpoint
  //   for (double distanceFactor = 0.3; distanceFactor <= 2.0; distanceFactor += 0.2) {
  //     final currentOffset = offset * distanceFactor;
      
  //     // Try perpendicular offsets
  //     for (double perpFactor = 0.1; perpFactor <= 2.0; perpFactor += 0.2) {
  //       positions.add(midPoint + (perpendicular * currentOffset * perpFactor));
  //       positions.add(midPoint - (perpendicular * currentOffset * perpFactor));
  //     }
      
  //     // Try diagonal offsets
  //     final diagonal1 = Offset(perpendicular.dx + direction.dx, perpendicular.dy + direction.dy).normalize();
  //     final diagonal2 = Offset(perpendicular.dx - direction.dx, perpendicular.dy - direction.dy).normalize();
      
  //     for (double diagFactor = 0.2; diagFactor <= 1.5; diagFactor += 0.2) {
  //       positions.add(midPoint + (diagonal1 * currentOffset * diagFactor));
  //       positions.add(midPoint + (diagonal2 * currentOffset * diagFactor));
  //       positions.add(midPoint - (diagonal1 * currentOffset * diagFactor));
  //       positions.add(midPoint - (diagonal2 * currentOffset * diagFactor));
  //     }
  //   }

  //   // Find the best position that avoids obstacles and is furthest from them
  //   Offset bestPos = midPoint;
  //   double bestScore = 0.0;
    
  //   for (final pos in positions) {
  //     if (!_pointCollidesWithObjects(pos, obstacles, startPoint: start.position, endPoint: end.position)) {
  //       // Calculate score based on distance from obstacles
  //       double minDistance = double.infinity;
  //       for (final obstacle in obstacles) {
  //         final bounds = obstacle.getBoundingRect();
  //         final distance = _distanceToRect(pos, bounds);
  //         if (distance < minDistance) {
  //           minDistance = distance;
  //         }
  //       }
        
  //       // Prefer positions that are further from obstacles
  //       if (minDistance > bestScore) {
  //         bestScore = minDistance;
  //         bestPos = pos;
  //       }
  //     }
  //   }

  //   return bestPos;
  // }

  // COLLISION INTELLIGENCE DISABLED - Commented out all remaining collision detection methods
  // Find smart control points that avoid obstacles while maintaining curves
  // static Offset _findSmartControlPoint(AnchorPoint start, AnchorPoint end, List<CanvasObject> obstacles, 
  //     double offset, bool isFirst, Offset perpendicular) {
  // final direction = (end.position - start.position).normalize();
    
  // // Base control point position
  // Offset basePos = isFirst 
  //     ? start.position + (direction * offset)
  //     : end.position - (direction * offset);
    
  // // Try many more positions to find a clear path
  // final positions = <Offset>[];
    
  // // Add base position
  // positions.add(basePos);
    
  // // Try positions at different distances and angles
  // for (double distanceFactor = 0.5; distanceFactor <= 2.0; distanceFactor += 0.2) {
  //   final currentOffset = offset * distanceFactor;
  //   final currentPos = isFirst 
  //       ? start.position + (direction * currentOffset)
  //       : end.position - (direction * currentOffset);
      
  //   // Try perpendicular offsets
  //   for (double perpFactor = 0.0; perpFactor <= 2.0; perpFactor += 0.2) {
  //     positions.add(currentPos + (perpendicular * currentOffset * perpFactor));
  //     positions.add(currentPos - (perpendicular * currentOffset * perpFactor));
  //   }
      
  //   // Try diagonal offsets
  //   final diagonal1 = Offset(perpendicular.dx + direction.dx, perpendicular.dy + direction.dy).normalize();
  //   final diagonal2 = Offset(perpendicular.dx - direction.dx, perpendicular.dy - direction.dy).normalize();
      
  //   for (double diagFactor = 0.2; diagFactor <= 1.5; diagFactor += 0.2) {
  //     positions.add(currentPos + (diagonal1 * currentOffset * diagFactor));
  //     positions.add(currentPos + (diagonal2 * currentOffset * diagFactor));
  //     positions.add(currentPos - (diagonal1 * currentOffset * diagFactor));
  //     positions.add(currentPos - (diagonal2 * currentOffset * diagFactor));
  //   }
  // }

  // // Find the best position that avoids obstacles and is furthest from them
  // Offset bestPos = basePos;
  // double bestScore = 0.0;
    
  // for (final pos in positions) {
  //   if (!_pointCollidesWithObjects(pos, obstacles, startPoint: start.position, endPoint: end.position)) {
  //     // Calculate score based on distance from obstacles
  //     double minDistance = double.infinity;
  //     for (final obstacle in obstacles) {
  //       final bounds = obstacle.getBoundingRect();
  //       final distance = _distanceToRect(pos, bounds);
  //       if (distance < minDistance) {
  //         minDistance = distance;
  //       }
  //     }
        
  //     // Prefer positions that are further from obstacles
  //     if (minDistance > bestScore) {
  //       bestScore = minDistance;
  //       bestPos = pos;
  //     }
  //   }
  // }

  // return bestPos;
  // }

  // // Calculate distance from a point to a rectangle
  // static double _distanceToRect(Offset point, Rect rect) {
  //   final dx = max(0.0, max(rect.left - point.dx, point.dx - rect.right));
  //   final dy = max(0.0, max(rect.top - point.dy, point.dy - rect.bottom));
  //   return sqrt(dx * dx + dy * dy);
  // }

  // // Find smart control point with path segment collision checking
  // static Offset _findSmartControlPointWithPathCheck(AnchorPoint start, AnchorPoint end, List<CanvasObject> obstacles, 
  //     double offset, bool isFirst, Offset perpendicular) {
  //   final direction = (end.position - start.position).normalize();
    
  //   // Base control point position
  //   Offset basePos = isFirst 
  //       ? start.position + (direction * offset)
  //       : end.position - (direction * offset);
    
  //   // Try many positions to find a clear path
  //   final positions = <Offset>[];
    
  //   // Add base position
  //   positions.add(basePos);
    
  //   // Try positions at different distances and angles
  //   for (double distanceFactor = 0.5; distanceFactor <= 2.0; distanceFactor += 0.2) {
  //     final currentOffset = offset * distanceFactor;
  //     final currentPos = isFirst 
  //         ? start.position + (direction * currentOffset)
  //         : end.position - (direction * currentOffset);
      
  //     // Try perpendicular offsets
  //     for (double perpFactor = 0.0; perpFactor <= 2.0; perpFactor += 0.2) {
  //       positions.add(currentPos + (perpendicular * currentOffset * perpFactor));
  //       positions.add(currentPos - (perpendicular * currentOffset * perpFactor));
  //     }
      
  //     // Try diagonal offsets
  //     final diagonal1 = Offset(perpendicular.dx + direction.dx, perpendicular.dy + direction.dy).normalize();
  //     final diagonal2 = Offset(perpendicular.dx - direction.dx, perpendicular.dy - direction.dy).normalize();
      
  //     for (double diagFactor = 0.2; diagFactor <= 1.5; diagFactor += 0.2) {
  //       positions.add(currentPos + (diagonal1 * currentOffset * diagFactor));
  //       positions.add(currentPos + (diagonal2 * currentOffset * diagFactor));
  //       positions.add(currentPos - (diagonal1 * currentOffset * diagFactor));
  //       positions.add(currentPos - (diagonal2 * currentOffset * diagFactor));
  //     }
  //   }

  //   // Find the best position that avoids obstacles and creates collision-free path
  //   Offset bestPos = basePos;
  //   double bestScore = 0.0;
    
  //   for (final pos in positions) {
  //     if (!_pointCollidesWithObjects(pos, obstacles, startPoint: start.position, endPoint: end.position)) {
  //       // Check if the path segment from start to this control point is collision-free
  //       if (isFirst) {
  //         if (!_cubicSegmentCollidesWithObjects(start.position, pos, obstacles)) {
  //           double minDistance = _getMinDistanceFromObstacles(pos, obstacles);
  //           if (minDistance > bestScore) {
  //             bestScore = minDistance;
  //             bestPos = pos;
  //           }
  //         }
  //       } else {
  //         if (!_cubicSegmentCollidesWithObjects(pos, end.position, obstacles)) {
  //           double minDistance = _getMinDistanceFromObstacles(pos, obstacles);
  //           if (minDistance > bestScore) {
  //             bestScore = minDistance;
  //             bestPos = pos;
  //           }
  //         }
  //       }
  //     }
  //   }

  //   return bestPos;
  // }

  // // Find smart control point for midpoint with path segment collision checking
  // static Offset _findSmartControlPointForMidpointWithPathCheck(AnchorPoint start, AnchorPoint end, 
  //     List<CanvasObject> obstacles, double offset, Offset midPoint, Offset perpendicular, 
  //     Offset otherCp, Offset segmentStart) {
    
  //   final direction = (end.position - start.position).normalize();
  //   final positions = <Offset>[];
    
  //   // Add direct midpoint
  //   positions.add(midPoint);
    
  //   // Try positions at different distances and angles around midpoint
  //   for (double distanceFactor = 0.3; distanceFactor <= 2.0; distanceFactor += 0.2) {
  //     final currentOffset = offset * distanceFactor;
      
  //     // Try perpendicular offsets
  //     for (double perpFactor = 0.1; perpFactor <= 2.0; perpFactor += 0.2) {
  //       positions.add(midPoint + (perpendicular * currentOffset * perpFactor));
  //       positions.add(midPoint - (perpendicular * currentOffset * perpFactor));
  //     }
      
  //     // Try diagonal offsets
  //     final diagonal1 = Offset(perpendicular.dx + direction.dx, perpendicular.dy + direction.dy).normalize();
  //     final diagonal2 = Offset(perpendicular.dx - direction.dx, perpendicular.dy - direction.dy).normalize();
      
  //     for (double diagFactor = 0.2; diagFactor <= 1.5; diagFactor += 0.2) {
  //       positions.add(midPoint + (diagonal1 * currentOffset * diagFactor));
  //       positions.add(midPoint + (diagonal2 * currentOffset * diagFactor));
  //       positions.add(midPoint - (diagonal1 * currentOffset * diagFactor));
  //       positions.add(midPoint - (diagonal2 * currentOffset * diagFactor));
  //     }
  //   }

  //   // Find the best position that avoids obstacles and creates collision-free path segment
  //   Offset bestPos = midPoint;
  //   double bestScore = 0.0;
    
  //   for (final pos in positions) {
  //     if (!_pointCollidesWithObjects(pos, obstacles, startPoint: start.position, endPoint: end.position)) {
  //       // Check if the cubic segment from segmentStart through this control point to otherCp is collision-free
  //       if (!_cubicSegmentCollidesWithObjects(segmentStart, pos, obstacles) && 
  //           !_cubicSegmentCollidesWithObjects(pos, otherCp, obstacles)) {
  //         double minDistance = _getMinDistanceFromObstacles(pos, obstacles);
  //         if (minDistance > bestScore) {
  //           bestScore = minDistance;
  //           bestPos = pos;
  //         }
  //       }
  //     }
  //   }

  //   return bestPos;
  // }

  // // Check if a cubic segment collides with obstacles
  // static bool _cubicSegmentCollidesWithObjects(Offset start, Offset end, List<CanvasObject> obstacles) {
  //   // Sample points along a straight line between start and end
  //   for (int i = 0; i <= 20; i++) {
  //     final t = i / 20.0;
  //     final point = Offset.lerp(start, end, t)!;
  //     if (_pointCollidesWithObjects(point, obstacles)) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  // // Get minimum distance from a point to all obstacles
  // static double _getMinDistanceFromObstacles(Offset point, List<CanvasObject> obstacles) {
  //   double minDistance = double.infinity;
  //   for (final obstacle in obstacles) {
  //     final bounds = obstacle.getBoundingRect();
  //     final distance = _distanceToRect(point, bounds);
  //     if (distance < minDistance) {
  //       minDistance = distance;
  //     }
  //   }
  //   return minDistance;
  // }

  // // Check if a line intersects with a rectangle
  // static bool _lineIntersectsRect(Offset start, Offset end, Rect rect) {
  //   // Check if any of the line endpoints are inside the rectangle
  //   if (rect.contains(start) || rect.contains(end)) return true;

  //   // Check if the line intersects any of the rectangle's edges
  //   final edges = [
  //     [rect.topLeft, rect.topRight],
  //     [rect.topRight, rect.bottomRight],
  //     [rect.bottomRight, rect.bottomLeft],
  //     [rect.bottomLeft, rect.topLeft],
  //   ];

  //   for (final edge in edges) {
  //     if (_linesIntersect(start, end, edge[0], edge[1])) {
  //       return true;
  //     }
  //   }

  //   return false;
  // }

  // // Check if two lines intersect
  // static bool _linesIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
  //   final o1 = _orientation(p1, q1, p2);
  //   final o2 = _orientation(p1, q1, q2);
  //   final o3 = _orientation(p2, q2, p1);
  //   final o4 = _orientation(p2, q2, q1);

  //   return (o1 != o2 && o3 != o4) || 
  //          (o1 == 0 && _onSegment(p1, p2, q1)) ||
  //          (o2 == 0 && _onSegment(p1, q2, q1)) ||
  //          (o3 == 0 && _onSegment(p2, p1, q2)) ||
  //          (o4 == 0 && _onSegment(p2, q1, q2));
  // }

  // // Helper for line intersection
  // static int _orientation(Offset p, Offset q, Offset r) {
  //   final val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
  //   if (val == 0) return 0;
  //   return val > 0 ? 1 : 2;
  // }

  // // Helper for line intersection
  // static bool _onSegment(Offset p, Offset q, Offset r) {
  //   return q.dx <= max(p.dx, r.dx) && q.dx >= min(p.dx, r.dx) &&
  //          q.dy <= max(p.dy, r.dy) && q.dy >= min(p.dy, r.dy);
  // }

  // // Check if a point collides with any objects (excluding connection points)
  // static bool _pointCollidesWithObjects(Offset point, List<CanvasObject> obstacles, {Offset? startPoint, Offset? endPoint}) {
  //   for (final obstacle in obstacles) {
  //     final bounds = obstacle.getBoundingRect();
  //     if (bounds.contains(point)) {
  //       // Allow the point if it's very close to the start or end connection points
  //       if (startPoint != null && (point - startPoint).distance < 5.0) {
  //         continue;
  //       }
  //       if (endPoint != null && (point - endPoint).distance < 5.0) {
  //         continue;
  //       }
  //       return true;
  //     }
  //   }
  //   return false;
  // }
}