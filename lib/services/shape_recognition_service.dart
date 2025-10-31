import 'dart:math';
import 'package:flutter/material.dart';

/// Enum representing recognized shape types
enum RecognizedShape {
  circle,
  rectangle,
  triangle,
  unknown
}

/// Result of shape recognition with confidence score and fitted parameters
class ShapeRecognitionResult {
  final RecognizedShape type;
  final double confidence; // 0.0 to 1.0
  final Offset? center; // For circles
  final double? radius; // For circles
  final Rect? bounds; // For rectangles
  final List<Offset>? vertices; // For triangles (3 vertices)
  final List<Offset> smoothedPoints; // Smoothed version of original path

  ShapeRecognitionResult({
    required this.type,
    required this.confidence,
    this.center,
    this.radius,
    this.bounds,
    this.vertices,
    required this.smoothedPoints,
  });
}

/// Service for recognizing shapes from freehand paths
class ShapeRecognitionService {
  static const double DEFAULT_CONFIDENCE_THRESHOLD = 0.7;
  static const int MIN_POINTS_FOR_RECOGNITION = 8;
  static const double SMOOTHING_TOLERANCE = 2.0;
  static const double CIRCLE_ROUNDNESS_THRESHOLD = 0.85;
  static const double RECTANGLE_ASPECT_RATIO_MAX = 5.0;
  static const double TRIANGLE_ANGLE_TOLERANCE = 10.0;
  static const double MIN_RADIUS = 5.0;
  static const double MIN_SHAPE_SIZE = 10.0;
  static const double MIN_TRIANGLE_AREA = 10.0;

  /// Main recognition method - analyzes points and returns best match
  ShapeRecognitionResult recognizeShape(List<Offset> points) {
    // Edge cases: too few points or invalid
    if (points.length < MIN_POINTS_FOR_RECOGNITION) {
      return ShapeRecognitionResult(
        type: RecognizedShape.unknown,
        confidence: 0.0,
        smoothedPoints: points,
      );
    }

    // Step 1: Smooth the path
    final smoothedPoints = smoothPath(points, alpha: 0.5);

    // Step 2: Simplify to reduce noise
    final simplifiedPoints = simplifyPath(smoothedPoints, SMOOTHING_TOLERANCE);

    // Step 3: Try to detect each shape type
    final results = <ShapeRecognitionResult>[];

    final circleResult = detectCircle(simplifiedPoints);
    if (circleResult != null) {
      results.add(circleResult);
    }

    final rectangleResult = detectRectangle(simplifiedPoints);
    if (rectangleResult != null) {
      results.add(rectangleResult);
    }

    final triangleResult = detectTriangle(simplifiedPoints);
    if (triangleResult != null) {
      results.add(triangleResult);
    }

    // Step 4: Return best match (highest confidence)
    if (results.isNotEmpty) {
      results.sort((a, b) => b.confidence.compareTo(a.confidence));
      final bestMatch = results.first;

      // Only return if confidence is above threshold
      if (bestMatch.confidence >= DEFAULT_CONFIDENCE_THRESHOLD) {
        return bestMatch;
      }
    }

    return ShapeRecognitionResult(
      type: RecognizedShape.unknown,
      confidence: 0.0,
      smoothedPoints: smoothedPoints,
    );
  }

  /// Detect circular shapes
  ShapeRecognitionResult? detectCircle(List<Offset> points) {
    if (points.length < 10) return null;

    final bounds = _calculateBoundingBox(points);
    
    // Degenerate shape check
    if (bounds.width < MIN_SHAPE_SIZE || bounds.height < MIN_SHAPE_SIZE) {
      return null;
    }

    final center = bounds.center;

    // Calculate distances from center
    final distances = <double>[];
    for (final point in points) {
      distances.add(_distanceBetween(point, center));
    }

    final avgRadius = distances.reduce((a, b) => a + b) / distances.length;

    // Invalid circle check
    if (avgRadius < MIN_RADIUS) {
      return null;
    }

    // Calculate variance (roundness check)
    double variance = 0.0;
    for (final dist in distances) {
      variance += pow(dist - avgRadius, 2);
    }
    variance = variance / distances.length;

    // Calculate roundness ratio
    final roundness = avgRadius / (avgRadius + sqrt(variance));

    // Check if path is roughly circular
    if (roundness > CIRCLE_ROUNDNESS_THRESHOLD) {
      final confidence = roundness * 0.95; // Slight penalty for variance
      return ShapeRecognitionResult(
        type: RecognizedShape.circle,
        center: center,
        radius: avgRadius,
        confidence: confidence,
        smoothedPoints: points,
      );
    }

    return null;
  }

  /// Detect rectangular shapes
  ShapeRecognitionResult? detectRectangle(List<Offset> points) {
    if (points.length < 10) return null;

    final bounds = _calculateBoundingBox(points);

    // Degenerate shape check
    if (bounds.width < MIN_SHAPE_SIZE || bounds.height < MIN_SHAPE_SIZE) {
      return null;
    }

    final aspectRatio = max(bounds.width, bounds.height) / min(bounds.width, bounds.height);

    // Too elongated - probably not a rectangle
    if (aspectRatio > RECTANGLE_ASPECT_RATIO_MAX) {
      return null;
    }

    // Check if points align with bounding box edges
    final threshold = min(bounds.width, bounds.height) * 0.15; // 15% of smaller dimension
    int alignedPoints = 0;

    for (final point in points) {
      // Check if point is close to any edge
      final distToTop = (point.dy - bounds.top).abs();
      final distToBottom = (point.dy - bounds.bottom).abs();
      final distToLeft = (point.dx - bounds.left).abs();
      final distToRight = (point.dx - bounds.right).abs();

      if (distToTop < threshold || distToBottom < threshold ||
          distToLeft < threshold || distToRight < threshold) {
        alignedPoints++;
      }
    }

    final alignmentRatio = alignedPoints / points.length;

    // Detect corners (sharp angle changes)
    final corners = <Offset>[];
    for (int i = 1; i < points.length - 1; i++) {
      final angle = _calculateAngle(points[i - 1], points[i], points[i + 1]);
      if (angle < 120.0 * pi / 180.0) { // Sharp corner (< 120°)
        corners.add(points[i]);
      }
    }

    // Check if we have approximately 4 corners (3-5 is acceptable)
    if (corners.length >= 3 && corners.length <= 5 && alignmentRatio > 0.6) {
      final confidence = alignmentRatio * 0.9;
      return ShapeRecognitionResult(
        type: RecognizedShape.rectangle,
        bounds: bounds,
        confidence: confidence,
        smoothedPoints: points,
      );
    }

    return null;
  }

  /// Detect triangular shapes
  ShapeRecognitionResult? detectTriangle(List<Offset> points) {
    if (points.length < 8) return null;

    final bounds = _calculateBoundingBox(points);

    // Degenerate shape check
    if (bounds.width < MIN_SHAPE_SIZE || bounds.height < MIN_SHAPE_SIZE) {
      return null;
    }

    // Compute convex hull
    final hull = _computeConvexHull(points);
    if (hull.length < 3) return null;

    // Find 3 points with maximum area
    List<Offset>? bestTriangle;
    double maxArea = 0.0;

    for (int i = 0; i < hull.length - 2; i++) {
      for (int j = i + 1; j < hull.length - 1; j++) {
        for (int k = j + 1; k < hull.length; k++) {
          final area = _triangleArea(hull[i], hull[j], hull[k]);
          if (area > maxArea) {
            maxArea = area;
            bestTriangle = [hull[i], hull[j], hull[k]];
          }
        }
      }
    }

    if (bestTriangle == null || bestTriangle.length != 3) return null;

    // Invalid triangle check
    if (maxArea < MIN_TRIANGLE_AREA) {
      return null;
    }

    // Check if most points are close to triangle edges
    final threshold = min(bounds.width, bounds.height) * 0.2;
    int pointsOnEdges = 0;

    for (final point in points) {
      final dist1 = _pointToLineDistance(point, bestTriangle[0], bestTriangle[1]);
      final dist2 = _pointToLineDistance(point, bestTriangle[1], bestTriangle[2]);
      final dist3 = _pointToLineDistance(point, bestTriangle[2], bestTriangle[0]);
      final minDist = min(dist1, min(dist2, dist3));

      if (minDist < threshold) {
        pointsOnEdges++;
      }
    }

    final coverageRatio = pointsOnEdges / points.length;

    // Calculate angles
    final angles = [
      _calculateAngle(bestTriangle[1], bestTriangle[0], bestTriangle[2]),
      _calculateAngle(bestTriangle[0], bestTriangle[1], bestTriangle[2]),
      _calculateAngle(bestTriangle[0], bestTriangle[2], bestTriangle[1]),
    ];

    final angleSum = (angles[0] + angles[1] + angles[2]) * 180.0 / pi;

    // Validate triangle (angles sum to ~180°)
    if ((angleSum - 180.0).abs() < TRIANGLE_ANGLE_TOLERANCE) {
      final confidence = coverageRatio * 0.85;
      return ShapeRecognitionResult(
        type: RecognizedShape.triangle,
        vertices: bestTriangle,
        confidence: confidence,
        smoothedPoints: points,
      );
    }

    return null;
  }

  /// Smooth path using Catmull-Rom interpolation
  List<Offset> smoothPath(List<Offset> points, {double alpha = 0.5}) {
    if (points.length <= 2) return points;

    final smoothed = <Offset>[points.first]; // Keep first point

    for (int i = 1; i < points.length - 1; i++) {
      // Get 4 control points for Catmull-Rom
      final p0 = i > 0 ? points[i - 1] : points.first;
      final p1 = points[i - 1];
      final p2 = points[i];
      final p3 = i < points.length - 1 ? points[i + 1] : points.last;

      // Generate smooth curve between p1 and p2
      for (double t = 0.0; t < 1.0; t += 0.1) {
        final smoothPoint = _catmullRom(p0, p1, p2, p3, t, alpha);
        smoothed.add(smoothPoint);
      }
    }

    smoothed.add(points.last); // Keep last point
    return smoothed;
  }

  /// Simplify path using Douglas-Peucker algorithm
  List<Offset> simplifyPath(List<Offset> points, double tolerance) {
    if (points.length <= 2) return points;

    // Find point with maximum distance from line between first and last
    double maxDistance = 0.0;
    int maxIndex = 0;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _pointToLineDistance(points[i], points.first, points.last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance > tolerance, recursively simplify
    if (maxDistance > tolerance) {
      // Recursive call for left and right segments
      final left = simplifyPath(points.sublist(0, maxIndex + 1), tolerance);
      final right = simplifyPath(points.sublist(maxIndex), tolerance);

      // Combine results (avoid duplicate point at maxIndex)
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // No points need simplification
      return [points.first, points.last];
    }
  }

  // === Helper Methods ===

  Rect _calculateBoundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.dx;
    double minY = points.first.dy;
    double maxX = points.first.dx;
    double maxY = points.first.dy;

    for (final point in points) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _distanceBetween(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    // Perpendicular distance from point to line segment
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) {
      return _distanceBetween(point, lineStart);
    }

    final param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      xx = lineStart.dx;
      yy = lineStart.dy;
    } else if (param > 1) {
      xx = lineEnd.dx;
      yy = lineEnd.dy;
    } else {
      xx = lineStart.dx + param * C;
      yy = lineStart.dy + param * D;
    }

    final dx = point.dx - xx;
    final dy = point.dy - yy;
    return sqrt(dx * dx + dy * dy);
  }

  double _calculateAngle(Offset p1, Offset p2, Offset p3) {
    // Calculate angle at p2 (in radians)
    final v1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final v2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);

    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final det = v1.dx * v2.dy - v1.dy * v2.dx;
    final angle = atan2(det, dot);
    return angle.abs();
  }

  double _triangleArea(Offset v1, Offset v2, Offset v3) {
    return ((v1.dx * (v2.dy - v3.dy) +
                v2.dx * (v3.dy - v1.dy) +
                v3.dx * (v1.dy - v2.dy))
            .abs() /
        2.0);
  }

  List<Offset> _computeConvexHull(List<Offset> points) {
    if (points.length <= 3) return points;

    // Graham scan algorithm
    // Find bottom-left point
    int bottomIndex = 0;
    for (int i = 1; i < points.length; i++) {
      if (points[i].dy < points[bottomIndex].dy ||
          (points[i].dy == points[bottomIndex].dy && points[i].dx < points[bottomIndex].dx)) {
        bottomIndex = i;
      }
    }

    // Sort by polar angle
    final sorted = List<Offset>.from(points);
    sorted.swap(0, bottomIndex);
    sorted.sort((a, b) {
      if (a == sorted.first || b == sorted.first) {
        if (a == sorted.first) return -1;
        return 1;
      }

      final angleA = atan2(a.dy - sorted.first.dy, a.dx - sorted.first.dx);
      final angleB = atan2(b.dy - sorted.first.dy, b.dx - sorted.first.dx);

      if (angleA != angleB) {
        return angleA.compareTo(angleB);
      }

      // If same angle, sort by distance
      final distA = _distanceBetween(a, sorted.first);
      final distB = _distanceBetween(b, sorted.first);
      return distA.compareTo(distB);
    });

    // Build convex hull
    final hull = <Offset>[sorted[0], sorted[1]];

    for (int i = 2; i < sorted.length; i++) {
      while (hull.length > 1 &&
          _isCounterClockwise(hull[hull.length - 2], hull[hull.length - 1], sorted[i]) <= 0) {
        hull.removeLast();
      }
      hull.add(sorted[i]);
    }

    return hull;
  }

  double _isCounterClockwise(Offset p1, Offset p2, Offset p3) {
    return (p2.dx - p1.dx) * (p3.dy - p1.dy) - (p2.dy - p1.dy) * (p3.dx - p1.dx);
  }

  Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t, double alpha) {
    // Uniform Catmull-Rom spline
    final t2 = t * t;
    final t3 = t2 * t;

    final m1x = alpha * (p2.dx - p0.dx);
    final m1y = alpha * (p2.dy - p0.dy);
    final m2x = alpha * (p3.dx - p1.dx);
    final m2y = alpha * (p3.dy - p1.dy);

    final a = 2 * t3 - 3 * t2 + 1;
    final b = t3 - 2 * t2 + t;
    final c = -2 * t3 + 3 * t2;
    final d = t3 - t2;

    return Offset(
      a * p1.dx + b * m1x + c * p2.dx + d * m2x,
      a * p1.dy + b * m1y + c * p2.dy + d * m2y,
    );
  }
}

// Extension for list swap (since Dart doesn't have it built-in)
extension ListSwap<T> on List<T> {
  void swap(int i, int j) {
    final temp = this[i];
    this[i] = this[j];
    this[j] = temp;
  }
}

