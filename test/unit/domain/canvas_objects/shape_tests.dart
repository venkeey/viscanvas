import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('RectangleShape Tests', () {
    test('should create rectangle with correct bounds', () {
      final bounds = Rect.fromLTWH(10, 20, 100, 80);
      final rectangle = RectangleShape(bounds);

      expect(rectangle.type, 'rectangle');
      expect(rectangle.bounds, bounds);
    });

    test('should calculate correct connection points', () {
      final rectangle = RectangleShape(Rect.fromLTWH(0, 0, 100, 50));
      final points = rectangle.suggestedConnectionPoints;

      expect(points.length, 4);
      expect(points[0], Offset(50, 0));   // Top center
      expect(points[1], Offset(100, 25)); // Right center
      expect(points[2], Offset(50, 50));  // Bottom center
      expect(points[3], Offset(0, 25));   // Left center
    });

    test('should find closest edge point correctly', () {
      final rectangle = RectangleShape(Rect.fromLTWH(0, 0, 100, 50));

      // Test from top-left quadrant
      final closest1 = rectangle.getClosestEdgePoint(Offset(-10, -10));
      expect(closest1, Offset(0, 25)); // Left edge

      // Test from bottom-right quadrant
      final closest2 = rectangle.getClosestEdgePoint(Offset(110, 60));
      expect(closest2, Offset(100, 25)); // Right edge

      // Test from top
      final closest3 = rectangle.getClosestEdgePoint(Offset(50, -10));
      expect(closest3, Offset(50, 0)); // Top edge

      // Test from bottom
      final closest4 = rectangle.getClosestEdgePoint(Offset(50, 60));
      expect(closest4, Offset(50, 50)); // Bottom edge
    });

    test('should detect point containment', () {
      final rectangle = RectangleShape(Rect.fromLTWH(10, 10, 100, 50));

      expect(rectangle.containsPoint(Offset(50, 30)), true);  // Inside
      expect(rectangle.containsPoint(Offset(5, 30)), false);  // Outside left
      expect(rectangle.containsPoint(Offset(50, 5)), false);  // Outside top
      expect(rectangle.containsPoint(Offset(115, 30)), false); // Outside right
      expect(rectangle.containsPoint(Offset(50, 65)), false);  // Outside bottom
    });

    test('should create correct path', () {
      final rectangle = RectangleShape(Rect.fromLTWH(10, 20, 100, 50));
      final path = rectangle.path;

      expect(path, isNotNull);
      expect(path.getBounds(), Rect.fromLTWH(10, 20, 100, 50));
    });
  });

  group('CircleShape Tests', () {
    test('should create circle with correct center and radius', () {
      final center = Offset(50, 50);
      final radius = 25.0;
      final circle = CircleShape(center, radius);

      expect(circle.type, 'circle');
      expect(circle.center, center);
      expect(circle.radius, radius);
      expect(circle.bounds, Rect.fromCircle(center: center, radius: radius));
    });

    test('should calculate correct connection points', () {
      final circle = CircleShape(Offset(50, 50), 25);
      final points = circle.suggestedConnectionPoints;

      expect(points.length, 8); // 8 points around the circle

      // Check that all points are on the circle circumference
      for (final point in points) {
        final distance = (point - circle.center).distance;
        expect(distance, closeTo(circle.radius, 0.1));
      }
    });

    test('should find closest edge point correctly', () {
      final circle = CircleShape(Offset(50, 50), 25);

      // Test from right side
      final closest1 = circle.getClosestEdgePoint(Offset(100, 50));
      expect(closest1, Offset(75, 50)); // Right edge of circle

      // Test from top
      final closest2 = circle.getClosestEdgePoint(Offset(50, 0));
      expect(closest2, Offset(50, 25)); // Top edge of circle

      // Test from diagonal
      final closest3 = circle.getClosestEdgePoint(Offset(100, 0));
      final expectedAngle = atan2(0 - 50, 100 - 50);
      expect(closest3.dx, closeTo(50 + 25 * cos(expectedAngle), 0.1));
      expect(closest3.dy, closeTo(50 + 25 * sin(expectedAngle), 0.1));
    });

    test('should detect point containment', () {
      final circle = CircleShape(Offset(50, 50), 25);

      expect(circle.containsPoint(Offset(50, 50)), true); // Center
      expect(circle.containsPoint(Offset(60, 50)), true); // Inside
      expect(circle.containsPoint(Offset(76, 50)), false); // Outside (right)
      expect(circle.containsPoint(Offset(50, 76)), false); // Outside (bottom)
      expect(circle.containsPoint(Offset(24, 50)), false); // Outside (left)
      expect(circle.containsPoint(Offset(50, 24)), false); // Outside (top)
    });

    test('should create correct path', () {
      final circle = CircleShape(Offset(50, 50), 25);
      final path = circle.path;

      expect(path, isNotNull);
      expect(path.getBounds(), Rect.fromCircle(center: Offset(50, 50), radius: 25));
    });
  });

  group('TriangleShape Tests', () {
    test('should create triangle with correct center and size', () {
      final center = Offset(50, 50);
      final size = 30.0;
      final triangle = TriangleShape(center, size);

      expect(triangle.type, 'triangle');
      expect(triangle.center, center);
      expect(triangle.size, size);
    });

    test('should calculate correct bounds', () {
      final triangle = TriangleShape(Offset(50, 50), 30);
      final bounds = triangle.bounds;

      expect(bounds.center, Offset(50, 50));
      expect(bounds.width, 60); // size * 2
      expect(bounds.height, 60); // size * 2
    });

    test('should calculate correct connection points', () {
      final triangle = TriangleShape(Offset(50, 50), 30);
      final points = triangle.suggestedConnectionPoints;

      expect(points.length, 4);

      // Top vertex
      expect(points[0], Offset(50, 20)); // center.dx, center.dy - size

      // Right side midpoint
      expect(points[1].dx, closeTo(71, 1)); // center.dx + size * 0.7 = 50 + 21
      expect(points[1].dy, closeTo(59, 1)); // center.dy + size * 0.3 = 50 + 9

      // Left side midpoint
      expect(points[2].dx, closeTo(29, 1)); // center.dx - size * 0.7 = 50 - 21
      expect(points[2].dy, closeTo(59, 1)); // center.dy + size * 0.3 = 50 + 9

      // Bottom center
      expect(points[3], Offset(50, 68)); // center.dx, center.dy + size * 0.6 = 50 + 18
    });

    test('should find closest edge point correctly', () {
      final triangle = TriangleShape(Offset(50, 50), 30);

      // Test from above (should hit top vertex)
      final closest1 = triangle.getClosestEdgePoint(Offset(50, 0));
      expect(closest1, Offset(50, 20));

      // Test from far right (should hit right edge)
      final closest2 = triangle.getClosestEdgePoint(Offset(100, 50));
      expect(closest2.dx, greaterThan(50)); // On right side
      expect(closest2.dy, allOf(greaterThan(20), lessThan(80))); // Between top and bottom
    });

    test('should detect point containment', () {
      final triangle = TriangleShape(Offset(50, 50), 30);

      expect(triangle.containsPoint(Offset(50, 35)), true); // Inside (near top)
      expect(triangle.containsPoint(Offset(50, 50)), true); // Inside (center)
      expect(triangle.containsPoint(Offset(50, 65)), true); // Inside (bottom vertex)
      expect(triangle.containsPoint(Offset(40, 55)), true); // Inside (left side)
      expect(triangle.containsPoint(Offset(60, 55)), true); // Inside (right side)

      expect(triangle.containsPoint(Offset(50, 15)), false); // Outside (above)
      expect(triangle.containsPoint(Offset(50, 85)), false); // Outside (below)
      expect(triangle.containsPoint(Offset(20, 50)), false); // Outside (left)
      expect(triangle.containsPoint(Offset(80, 50)), false); // Outside (right)
    });

    test('should create correct path', () {
      final triangle = TriangleShape(Offset(50, 50), 30);
      final path = triangle.path;

      expect(path, isNotNull);
      // Path should have 4 points (triangle + close)
      expect(path.getBounds(), triangle.bounds);
    });
  });

  group('Shape Comparison Tests', () {
    test('different shapes should have different types', () {
      final rectangle = RectangleShape(Rect.fromLTWH(0, 0, 100, 50));
      final circle = CircleShape(Offset(50, 50), 25);
      final triangle = TriangleShape(Offset(50, 50), 30);

      expect(rectangle.type, isNot(equals(circle.type)));
      expect(circle.type, isNot(equals(triangle.type)));
      expect(rectangle.type, isNot(equals(triangle.type)));
    });

    test('shapes should have reasonable bounds', () {
      final shapes = [
        RectangleShape(Rect.fromLTWH(10, 20, 100, 50)),
        CircleShape(Offset(50, 50), 25),
        TriangleShape(Offset(50, 50), 30),
      ];

      for (final shape in shapes) {
        expect(shape.bounds.width, greaterThan(0));
        expect(shape.bounds.height, greaterThan(0));
        expect(shape.bounds.left, isNot(double.nan));
        expect(shape.bounds.top, isNot(double.nan));
      }
    });

    test('all shapes should have connection points', () {
      final shapes = [
        RectangleShape(Rect.fromLTWH(0, 0, 100, 50)),
        CircleShape(Offset(50, 50), 25),
        TriangleShape(Offset(50, 50), 30),
      ];

      for (final shape in shapes) {
        final points = shape.suggestedConnectionPoints;
        expect(points.length, greaterThan(0));
        expect(points, everyElement(isA<Offset>()));
      }
    });
  });
}