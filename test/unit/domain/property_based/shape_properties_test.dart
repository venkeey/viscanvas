import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('Shape Property-Based Tests', () {
    final random = Random(42); // Fixed seed for reproducibility

    test('Property: any point inside rectangle bounds should be detected', () {
      // Run 100 iterations with different rectangles and points
      for (int i = 0; i < 100; i++) {
        final rect = _generateRandomRectangle(random);
        final pointInside = _generatePointInsideRect(random, rect.bounds);

        expect(
          rect.containsPoint(pointInside),
          isTrue,
          reason: 'Point $pointInside should be inside ${rect.bounds}',
        );
      }
    });

    test('Property: closest edge point should always be on rectangle perimeter', () {
      for (int i = 0; i < 100; i++) {
        final rect = _generateRandomRectangle(random);
        final arbitraryPoint = _generateArbitraryPoint(random);

        final edgePoint = rect.getClosestEdgePoint(arbitraryPoint);

        // Property: edge point must be on the rectangle perimeter
        final isOnEdge =
          (edgePoint.dx - rect.bounds.left).abs() < 0.01 ||
          (edgePoint.dx - rect.bounds.right).abs() < 0.01 ||
          (edgePoint.dy - rect.bounds.top).abs() < 0.01 ||
          (edgePoint.dy - rect.bounds.bottom).abs() < 0.01;

        expect(
          isOnEdge,
          isTrue,
          reason: 'Edge point $edgePoint must be on perimeter of ${rect.bounds}',
        );
      }
    });

    test('Property: closest edge point should be closest to given point', () {
      for (int i = 0; i < 100; i++) {
        final rect = _generateRandomRectangle(random);
        final point = _generateArbitraryPoint(random);

        final closestPoint = rect.getClosestEdgePoint(point);

        // Verify it's closer than any corner
        final corners = [
          rect.bounds.topLeft,
          rect.bounds.topRight,
          rect.bounds.bottomLeft,
          rect.bounds.bottomRight,
        ];

        final closestDistance = (closestPoint - point).distance;

        // At least one corner should be farther (unless point is exactly at a corner)
        final someCornerFarther = corners.any(
          (corner) => (corner - point).distance >= closestDistance - 0.01
        );

        expect(someCornerFarther, isTrue);
      }
    });

    test('Property: circle closest edge point should be at exactly radius distance', () {
      for (int i = 0; i < 100; i++) {
        final circle = _generateRandomCircle(random);
        final fromPoint = _generateArbitraryPoint(random);

        final edgePoint = circle.getClosestEdgePoint(fromPoint);
        final distanceFromCenter = (edgePoint - circle.center).distance;

        expect(
          distanceFromCenter,
          closeTo(circle.radius, 0.01),
          reason: 'Edge point must be exactly on circle radius',
        );
      }
    });

    test('Property: connection point calculation should be deterministic', () {
      for (int i = 0; i < 50; i++) {
        final rect = _generateRandomRectangle(random);
        final point = _generateArbitraryPoint(random);

        final connectionPoint1 = rect.getClosestEdgePoint(point);
        final connectionPoint2 = rect.getClosestEdgePoint(point);

        // Property: same input should always give same output
        expect(connectionPoint1, equals(connectionPoint2));
      }
    });

    test('Property: suggested connection points should be within bounds', () {
      for (int i = 0; i < 100; i++) {
        final rect = _generateRandomRectangle(random);

        for (final point in rect.suggestedConnectionPoints) {
          // Points should be on or very close to bounds
          final expandedBounds = rect.bounds.inflate(1.0);
          expect(
            expandedBounds.contains(point),
            isTrue,
            reason: 'Connection point $point should be within ${rect.bounds}',
          );
        }
      }
    });

    test('Property: triangle edge points should be on triangle perimeter', () {
      for (int i = 0; i < 100; i++) {
        final triangle = _generateRandomTriangle(random);
        final fromPoint = _generateArbitraryPoint(random);

        final edgePoint = triangle.getClosestEdgePoint(fromPoint);

        // Point should be close to the triangle bounds
        final expandedBounds = triangle.bounds.inflate(1.0);
        expect(
          expandedBounds.contains(edgePoint),
          isTrue,
          reason: 'Edge point $edgePoint should be near triangle',
        );
      }
    });

    test('Property: containsPoint should be inverse of point outside shape', () {
      for (int i = 0; i < 50; i++) {
        final rect = _generateRandomRectangle(random);
        final point = _generateArbitraryPoint(random);

        final contains = rect.containsPoint(point);
        final boundsContains = rect.bounds.contains(point);

        expect(contains, equals(boundsContains));
      }
    });

    test('Property: circle contains point if distance <= radius', () {
      for (int i = 0; i < 100; i++) {
        final circle = _generateRandomCircle(random);
        final point = _generateArbitraryPoint(random);

        final distance = (point - circle.center).distance;
        final shouldContain = distance <= circle.radius;
        final doesContain = circle.containsPoint(point);

        expect(
          doesContain,
          equals(shouldContain),
          reason: 'Distance: $distance, Radius: ${circle.radius}',
        );
      }
    });

    test('Property: rectangle with zero/negative dimensions should handle gracefully', () {
      final degenerateRects = [
        RectangleShape(Rect.fromLTWH(100, 100, 0, 0)), // Zero size
        RectangleShape(Rect.fromLTWH(100, 100, 0, 50)), // Zero width
        RectangleShape(Rect.fromLTWH(100, 100, 50, 0)), // Zero height
        RectangleShape(Rect.fromPoints(Offset(200, 200), Offset(100, 100))), // Negative
      ];

      for (final rect in degenerateRects) {
        expect(() => rect.suggestedConnectionPoints, returnsNormally);
        expect(() => rect.containsPoint(Offset(100, 100)), returnsNormally);
        expect(() => rect.getClosestEdgePoint(Offset(150, 150)), returnsNormally);
      }
    });

    test('Property: extremely large shapes should not cause overflow', () {
      final largeRect = RectangleShape(Rect.fromLTWH(0, 0, 1e10, 1e10));
      final largeCircle = CircleShape(Offset(0, 0), 1e10);

      expect(() => largeRect.getClosestEdgePoint(Offset(1e9, 1e9)), returnsNormally);
      expect(() => largeCircle.getClosestEdgePoint(Offset(1e9, 1e9)), returnsNormally);
      expect(() => largeRect.containsPoint(Offset(1e9, 1e9)), returnsNormally);
    });

    test('Property: shape bounds should always contain all connection points', () {
      for (int i = 0; i < 100; i++) {
        final shapes = [
          _generateRandomRectangle(random) as NodeShape,
          _generateRandomCircle(random) as NodeShape,
          _generateRandomTriangle(random) as NodeShape,
        ];

        for (final shape in shapes) {
          final expandedBounds = shape.bounds.inflate(1.0); // Allow 1px tolerance

          for (final point in shape.suggestedConnectionPoints) {
            expect(
              expandedBounds.contains(point),
              isTrue,
              reason: '${shape.type} connection point $point should be within bounds ${shape.bounds}',
            );
          }
        }
      }
    });
  });
}

// Test data generators
RectangleShape _generateRandomRectangle(Random random) {
  final left = random.nextDouble() * 500;
  final top = random.nextDouble() * 500;
  final width = random.nextDouble() * 200 + 50;
  final height = random.nextDouble() * 200 + 50;

  return RectangleShape(Rect.fromLTWH(left, top, width, height));
}

CircleShape _generateRandomCircle(Random random) {
  final centerX = random.nextDouble() * 500 + 50;
  final centerY = random.nextDouble() * 500 + 50;
  final radius = random.nextDouble() * 100 + 25;

  return CircleShape(Offset(centerX, centerY), radius);
}

TriangleShape _generateRandomTriangle(Random random) {
  final centerX = random.nextDouble() * 500 + 50;
  final centerY = random.nextDouble() * 500 + 50;
  final size = random.nextDouble() * 100 + 25;

  return TriangleShape(Offset(centerX, centerY), size);
}

Offset _generatePointInsideRect(Random random, Rect bounds) {
  return Offset(
    bounds.left + random.nextDouble() * bounds.width,
    bounds.top + random.nextDouble() * bounds.height,
  );
}

Offset _generateArbitraryPoint(Random random) {
  return Offset(
    random.nextDouble() * 1000 - 500,
    random.nextDouble() * 1000 - 500,
  );
}
