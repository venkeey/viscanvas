import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('Degenerate Shape Edge Cases', () {
    test('zero-size rectangle should handle gracefully', () {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 0, 0));

      expect(() => rect.suggestedConnectionPoints, returnsNormally);
      expect(() => rect.containsPoint(Offset(100, 100)), returnsNormally);
      expect(() => rect.getClosestEdgePoint(Offset(150, 150)), returnsNormally);
      expect(rect.bounds.width, 0);
      expect(rect.bounds.height, 0);
    });

    test('zero-width rectangle should handle gracefully', () {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 0, 50));

      expect(() => rect.suggestedConnectionPoints, returnsNormally);
      expect(() => rect.containsPoint(Offset(100, 125)), returnsNormally);
      expect(() => rect.getClosestEdgePoint(Offset(150, 125)), returnsNormally);
      expect(rect.bounds.width, 0);
      expect(rect.bounds.height, 50);
    });

    test('zero-height rectangle should handle gracefully', () {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 50, 0));

      expect(() => rect.suggestedConnectionPoints, returnsNormally);
      expect(() => rect.containsPoint(Offset(125, 100)), returnsNormally);
      expect(() => rect.getClosestEdgePoint(Offset(125, 150)), returnsNormally);
      expect(rect.bounds.width, 50);
      expect(rect.bounds.height, 0);
    });

    test('negative rectangle dimensions should be normalized', () {
      // User might drag from bottom-right to top-left
      final rect = RectangleShape(Rect.fromPoints(
        Offset(200, 200),
        Offset(100, 100),
      ));

      expect(rect.bounds.width, greaterThanOrEqualTo(0));
      expect(rect.bounds.height, greaterThanOrEqualTo(0));
      expect(rect.bounds.left, 100);
      expect(rect.bounds.top, 100);
      expect(rect.bounds.right, 200);
      expect(rect.bounds.bottom, 200);
    });

    test('zero-radius circle should not crash', () {
      final circle = CircleShape(Offset(100, 100), 0);

      expect(() => circle.getClosestEdgePoint(Offset(150, 150)), returnsNormally);
      expect(() => circle.suggestedConnectionPoints, returnsNormally);
      expect(() => circle.containsPoint(Offset(100, 100)), returnsNormally);
      expect(circle.radius, 0);
    });

    test('extremely large rectangle should not cause overflow', () {
      final rect = RectangleShape(Rect.fromLTWH(0, 0, 1e10, 1e10));

      expect(() => rect.getClosestEdgePoint(Offset(1e9, 1e9)), returnsNormally);
      expect(() => rect.containsPoint(Offset(1e8, 1e8)), returnsNormally);
      expect(() => rect.suggestedConnectionPoints, returnsNormally);
    });

    test('extremely large circle should not cause overflow', () {
      final circle = CircleShape(Offset(0, 0), 1e10);

      expect(() => circle.getClosestEdgePoint(Offset(1e9, 1e9)), returnsNormally);
      expect(() => circle.containsPoint(Offset(1e8, 1e8)), returnsNormally);
      expect(() => circle.suggestedConnectionPoints, returnsNormally);
    });

    test('extremely small shapes should handle gracefully', () {
      final tinyRect = RectangleShape(Rect.fromLTWH(100, 100, 0.001, 0.001));
      final tinyCircle = CircleShape(Offset(100, 100), 0.001);

      expect(() => tinyRect.getClosestEdgePoint(Offset(100, 100)), returnsNormally);
      expect(() => tinyCircle.getClosestEdgePoint(Offset(100, 100)), returnsNormally);
    });

    test('rectangle with extreme aspect ratio should work', () {
      final tallRect = RectangleShape(Rect.fromLTWH(100, 100, 1, 1000));
      final wideRect = RectangleShape(Rect.fromLTWH(100, 100, 1000, 1));

      expect(() => tallRect.getClosestEdgePoint(Offset(150, 600)), returnsNormally);
      expect(() => wideRect.getClosestEdgePoint(Offset(600, 150)), returnsNormally);

      expect(tallRect.suggestedConnectionPoints.length, 4);
      expect(wideRect.suggestedConnectionPoints.length, 4);
    });

    test('triangle with zero size should not crash', () {
      final triangle = TriangleShape(Offset(100, 100), 0);

      expect(() => triangle.getClosestEdgePoint(Offset(150, 150)), returnsNormally);
      expect(() => triangle.suggestedConnectionPoints, returnsNormally);
      expect(() => triangle.containsPoint(Offset(100, 100)), returnsNormally);
    });

    test('extremely large triangle should not cause overflow', () {
      final triangle = TriangleShape(Offset(0, 0), 1e10);

      expect(() => triangle.getClosestEdgePoint(Offset(1e9, 1e9)), returnsNormally);
      expect(() => triangle.containsPoint(Offset(1e8, 1e8)), returnsNormally);
    });

    test('rectangle at extreme coordinates should work', () {
      final farRect = RectangleShape(Rect.fromLTWH(1e8, 1e8, 100, 100));

      expect(() => farRect.getClosestEdgePoint(Offset(1e8 + 50, 1e8 + 50)), returnsNormally);
      expect(() => farRect.containsPoint(Offset(1e8 + 50, 1e8 + 50)), returnsNormally);
    });

    test('negative coordinate shapes should work', () {
      final negativeRect = RectangleShape(Rect.fromLTWH(-1000, -1000, 100, 100));
      final negativeCircle = CircleShape(Offset(-500, -500), 50);

      expect(() => negativeRect.getClosestEdgePoint(Offset(-950, -950)), returnsNormally);
      expect(() => negativeCircle.getClosestEdgePoint(Offset(-450, -450)), returnsNormally);
    });

    test('circle containsPoint should handle point exactly on edge', () {
      final circle = CircleShape(Offset(100, 100), 50);
      final pointOnEdge = Offset(150, 100); // Exactly on right edge

      final distance = (pointOnEdge - circle.center).distance;
      expect(distance, closeTo(circle.radius, 0.01));

      // Point on edge should be contained
      expect(circle.containsPoint(pointOnEdge), isTrue);
    });

    test('rectangle containsPoint should handle point exactly on edge', () {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 100, 100));

      // Points exactly on edges (Rect.contains() excludes right and bottom edges)
      expect(rect.containsPoint(Offset(100, 150)), isTrue); // Left edge - included
      expect(rect.containsPoint(Offset(199.9, 150)), isTrue); // Near right edge - included
      expect(rect.containsPoint(Offset(150, 100)), isTrue); // Top edge - included
      expect(rect.containsPoint(Offset(150, 199.9)), isTrue); // Near bottom edge - included
    });

    test('getClosestEdgePoint with point already on edge', () {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 100, 100));
      final pointOnEdge = Offset(200, 150); // On right edge

      final closestPoint = rect.getClosestEdgePoint(pointOnEdge);

      // Should return a point very close to or exactly the input point
      expect((closestPoint - pointOnEdge).distance, lessThan(50));
    });

    test('getClosestEdgePoint with point at center should return edge', () {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 100, 100));
      final center = rect.bounds.center;

      final closestPoint = rect.getClosestEdgePoint(center);

      // Should return one of the edges
      final isOnEdge =
        closestPoint.dx == rect.bounds.left ||
        closestPoint.dx == rect.bounds.right ||
        closestPoint.dy == rect.bounds.top ||
        closestPoint.dy == rect.bounds.bottom;

      expect(isOnEdge, isTrue);
    });

    test('circle at origin should work', () {
      final circle = CircleShape(Offset.zero, 50);

      expect(() => circle.getClosestEdgePoint(Offset(100, 0)), returnsNormally);
      expect(circle.containsPoint(Offset.zero), isTrue);
      expect(circle.suggestedConnectionPoints.length, 8);
    });

    test('rectangle at origin should work', () {
      final rect = RectangleShape(Rect.fromLTWH(0, 0, 100, 100));

      expect(() => rect.getClosestEdgePoint(Offset(150, 50)), returnsNormally);
      expect(rect.containsPoint(Offset(50, 50)), isTrue);
      expect(rect.suggestedConnectionPoints.length, 4);
    });

    test('overlapping shapes should be handled independently', () {
      final rect1 = RectangleShape(Rect.fromLTWH(0, 0, 100, 100));
      final rect2 = RectangleShape(Rect.fromLTWH(50, 50, 100, 100));

      final point = Offset(75, 75); // Inside both

      expect(rect1.containsPoint(point), isTrue);
      expect(rect2.containsPoint(point), isTrue);
    });

    test('NaN and infinity should be handled or cause clear errors', () {
      // These should either work gracefully or throw clear exceptions
      expect(
        () => RectangleShape(Rect.fromLTWH(double.nan, 0, 100, 100)),
        returnsNormally, // Or throwsA if you prefer strict validation
      );

      expect(
        () => CircleShape(Offset(double.infinity, 0), 50),
        returnsNormally,
      );
    });
  });
}
