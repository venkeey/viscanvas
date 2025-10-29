import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/domain/canvas_domain.dart';

void main() {
  group('Transform2D Tests', () {
    test('should convert world to screen coordinates with translation', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 1.0,
      );

      final worldPoint = Offset(10, 20);
      final screenPoint = transform.worldToScreen(worldPoint);

      expect(screenPoint.dx, closeTo(110, 0.01)); // 10 + 100
      expect(screenPoint.dy, closeTo(70, 0.01)); // 20 + 50
    });

    test('should convert world to screen coordinates with scale', () {
      final transform = Transform2D(
        translation: Offset.zero,
        scale: 2.0,
      );

      final worldPoint = Offset(10, 20);
      final screenPoint = transform.worldToScreen(worldPoint);

      expect(screenPoint.dx, closeTo(20, 0.01)); // 10 * 2
      expect(screenPoint.dy, closeTo(40, 0.01)); // 20 * 2
    });

    test('should convert world to screen coordinates with both translation and scale', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );

      final worldPoint = Offset(10, 20);
      final screenPoint = transform.worldToScreen(worldPoint);

      expect(screenPoint.dx, closeTo(120, 0.01)); // 10 * 2 + 100
      expect(screenPoint.dy, closeTo(90, 0.01)); // 20 * 2 + 50
    });

    test('should convert screen to world coordinates with translation', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 1.0,
      );

      final screenPoint = Offset(110, 70);
      final worldPoint = transform.screenToWorld(screenPoint);

      expect(worldPoint.dx, closeTo(10, 0.01)); // (110 - 100)
      expect(worldPoint.dy, closeTo(20, 0.01)); // (70 - 50)
    });

    test('should convert screen to world coordinates with scale', () {
      final transform = Transform2D(
        translation: Offset.zero,
        scale: 2.0,
      );

      final screenPoint = Offset(20, 40);
      final worldPoint = transform.screenToWorld(screenPoint);

      expect(worldPoint.dx, closeTo(10, 0.01)); // 20 / 2
      expect(worldPoint.dy, closeTo(20, 0.01)); // 40 / 2
    });

    test('should convert screen to world coordinates with both translation and scale', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );

      final screenPoint = Offset(120, 90);
      final worldPoint = transform.screenToWorld(screenPoint);

      expect(worldPoint.dx, closeTo(10, 0.01)); // (120 - 100) / 2
      expect(worldPoint.dy, closeTo(20, 0.01)); // (90 - 50) / 2
    });

    test('should handle scale < 1 (zoom out)', () {
      final transform = Transform2D(
        translation: Offset.zero,
        scale: 0.5,
      );

      final worldPoint = Offset(100, 200);
      final screenPoint = transform.worldToScreen(worldPoint);

      expect(screenPoint.dx, closeTo(50, 0.01)); // 100 * 0.5
      expect(screenPoint.dy, closeTo(100, 0.01)); // 200 * 0.5
    });

    test('should handle negative coordinates', () {
      final transform = Transform2D(
        translation: Offset(100, 100),
        scale: 1.0,
      );

      final worldPoint = Offset(-50, -75);
      final screenPoint = transform.worldToScreen(worldPoint);

      expect(screenPoint.dx, closeTo(50, 0.01)); // -50 + 100
      expect(screenPoint.dy, closeTo(25, 0.01)); // -75 + 100
    });

    test('should be inverse operations (world -> screen -> world)', () {
      final transform = Transform2D(
        translation: Offset(123.45, 67.89),
        scale: 1.75,
      );

      final originalPoint = Offset(42.5, 88.3);
      final screenPoint = transform.worldToScreen(originalPoint);
      final backToWorld = transform.screenToWorld(screenPoint);

      expect(backToWorld.dx, closeTo(originalPoint.dx, 0.01));
      expect(backToWorld.dy, closeTo(originalPoint.dy, 0.01));
    });

    test('should be inverse operations (screen -> world -> screen)', () {
      final transform = Transform2D(
        translation: Offset(200, 150),
        scale: 0.8,
      );

      final originalPoint = Offset(300, 450);
      final worldPoint = transform.screenToWorld(originalPoint);
      final backToScreen = transform.worldToScreen(worldPoint);

      expect(backToScreen.dx, closeTo(originalPoint.dx, 0.01));
      expect(backToScreen.dy, closeTo(originalPoint.dy, 0.01));
    });

    test('should handle identity transform', () {
      final transform = Transform2D(
        translation: Offset.zero,
        scale: 1.0,
      );

      final point = Offset(123, 456);
      final screenPoint = transform.worldToScreen(point);
      final worldPoint = transform.screenToWorld(point);

      expect(screenPoint, equals(point));
      expect(worldPoint, equals(point));
    });

    test('should create copy with modified translation', () {
      final original = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );

      final modified = original.copyWith(translation: Offset(200, 100));

      expect(modified.translation, Offset(200, 100));
      expect(modified.scale, 2.0);
      expect(original.translation, Offset(100, 50)); // Original unchanged
    });

    test('should create copy with modified scale', () {
      final original = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );

      final modified = original.copyWith(scale: 3.0);

      expect(modified.translation, Offset(100, 50));
      expect(modified.scale, 3.0);
      expect(original.scale, 2.0); // Original unchanged
    });

    test('should create copy with both modified', () {
      final original = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );

      final modified = original.copyWith(
        translation: Offset(200, 100),
        scale: 3.0,
      );

      expect(modified.translation, Offset(200, 100));
      expect(modified.scale, 3.0);
    });

    test('should handle very large scale values', () {
      final transform = Transform2D(
        translation: Offset.zero,
        scale: 1000.0,
      );

      final worldPoint = Offset(1, 1);
      final screenPoint = transform.worldToScreen(worldPoint);

      expect(screenPoint.dx, closeTo(1000, 0.01));
      expect(screenPoint.dy, closeTo(1000, 0.01));
    });

    test('should handle very small scale values', () {
      final transform = Transform2D(
        translation: Offset.zero,
        scale: 0.001,
      );

      final worldPoint = Offset(1000, 1000);
      final screenPoint = transform.worldToScreen(worldPoint);

      expect(screenPoint.dx, closeTo(1, 0.01));
      expect(screenPoint.dy, closeTo(1, 0.01));
    });

    test('should maintain precision with multiple transformations', () {
      final transform1 = Transform2D(translation: Offset(100, 100), scale: 2.0);
      final transform2 = Transform2D(translation: Offset(50, 50), scale: 0.5);

      final point = Offset(25, 75);

      // Apply first transform
      final intermediate = transform1.worldToScreen(point);
      // Apply second transform
      final final1 = transform2.worldToScreen(intermediate);

      // Should be able to reverse
      final back1 = transform2.screenToWorld(final1);
      final back2 = transform1.screenToWorld(back1);

      expect(back2.dx, closeTo(point.dx, 0.01));
      expect(back2.dy, closeTo(point.dy, 0.01));
    });

    test('should handle zero point transformation', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );

      final screenPoint = transform.worldToScreen(Offset.zero);
      final worldPoint = transform.screenToWorld(Offset.zero);

      expect(screenPoint.dx, closeTo(100, 0.01));
      expect(screenPoint.dy, closeTo(50, 0.01));
      expect(worldPoint.dx, closeTo(-50, 0.01)); // (0 - 100) / 2
      expect(worldPoint.dy, closeTo(-25, 0.01)); // (0 - 50) / 2
    });

    test('should provide access to underlying matrix', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );

      final matrix = transform.matrix;

      expect(matrix, isNotNull);
      expect(matrix, isA<Matrix4>());
    });
  });
}
