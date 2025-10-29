import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/domain/canvas_domain.dart';
import 'package:viscanvas/models/canvas_objects/canvas_rectangle.dart';

void main() {
  group('QuadTree Spatial Index Tests', () {
    late QuadTree quadTree;

    setUp(() {
      // Create QuadTree for 1000x1000 space
      quadTree = QuadTree(
        bounds: Rect.fromLTWH(0, 0, 1000, 1000),
        capacity: 4,
        maxDepth: 8,
      );
    });

    test('should insert objects into quadtree', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      quadTree.insert(rect);

      final results = quadTree.query(Rect.fromLTWH(0, 0, 1000, 1000));
      expect(results, contains(rect));
    });

    test('should subdivide when capacity exceeded', () {
      // Add more than capacity
      for (int i = 0; i < 10; i++) {
        final rect = CanvasRectangle(
          id: 'rect$i',
          worldPosition: Offset(i * 10.0, i * 10.0),
          strokeColor: Colors.black,
          size: const Size(5, 5),
        );
        quadTree.insert(rect);
      }

      // Tree should have subdivided
      expect(quadTree.isDivided, isTrue);
    });

    test('should query objects in specific region', () {
      // Add objects in different regions
      final rect1 = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      final rect2 = CanvasRectangle(
        id: 'rect2',
        worldPosition: const Offset(800, 800),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      quadTree.insert(rect1);
      quadTree.insert(rect2);

      // Query only top-left region
      final topLeft = quadTree.query(Rect.fromLTWH(0, 0, 400, 400));
      expect(topLeft, contains(rect1));
      expect(topLeft, isNot(contains(rect2)));

      // Query only bottom-right region
      final bottomRight = quadTree.query(Rect.fromLTWH(600, 600, 400, 400));
      expect(bottomRight, contains(rect2));
      expect(bottomRight, isNot(contains(rect1)));
    });

    test('should remove objects from quadtree', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      quadTree.insert(rect);
      expect(quadTree.query(Rect.fromLTWH(0, 0, 1000, 1000)), contains(rect));

      quadTree.remove('rect1');
      expect(quadTree.query(Rect.fromLTWH(0, 0, 1000, 1000)), isNot(contains(rect)));
    });

    test('should update object position', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      quadTree.insert(rect);

      // Move object
      rect.move(const Offset(700, 700));
      quadTree.update(rect);

      // Should now be in bottom-right region
      final topLeft = quadTree.query(Rect.fromLTWH(0, 0, 400, 400));
      expect(topLeft, isNot(contains(rect)));

      final bottomRight = quadTree.query(Rect.fromLTWH(600, 600, 400, 400));
      expect(bottomRight, contains(rect));
    });

    test('should perform hit test efficiently', () {
      // Add many objects
      for (int i = 0; i < 100; i++) {
        final rect = CanvasRectangle(
          id: 'rect$i',
          worldPosition: Offset(i * 50.0, i * 5.0),
          strokeColor: Colors.black,
          size: const Size(40, 40),
        );
        quadTree.insert(rect);
      }

      // Hit test at specific point
      final hit = quadTree.hitTest(const Offset(100, 20));
      expect(hit, isNotNull);
      expect(hit!.id, 'rect2'); // Should hit rect2
    });

    test('should handle objects outside bounds gracefully', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(2000, 2000), // Outside bounds
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      // Should not crash
      expect(() => quadTree.insert(rect), returnsNormally);

      // Should not be found in queries
      final results = quadTree.query(Rect.fromLTWH(0, 0, 1000, 1000));
      expect(results, isEmpty);
    });

    test('should clear all objects', () {
      for (int i = 0; i < 20; i++) {
        final rect = CanvasRectangle(
          id: 'rect$i',
          worldPosition: Offset(i * 30.0, i * 30.0),
          strokeColor: Colors.black,
          size: const Size(20, 20),
        );
        quadTree.insert(rect);
      }

      expect(quadTree.query(Rect.fromLTWH(0, 0, 1000, 1000)), isNotEmpty);

      quadTree.clear();

      expect(quadTree.query(Rect.fromLTWH(0, 0, 1000, 1000)), isEmpty);
    });

    test('should handle maximum depth limit', () {
      final deepTree = QuadTree(
        bounds: Rect.fromLTWH(0, 0, 1000, 1000),
        capacity: 1,
        maxDepth: 2, // Very shallow
      );

      // Add many objects in same area
      for (int i = 0; i < 10; i++) {
        final rect = CanvasRectangle(
          id: 'rect$i',
          worldPosition: Offset(100 + i * 0.1, 100 + i * 0.1),
          strokeColor: Colors.black,
          size: const Size(5, 5),
        );
        deepTree.insert(rect);
      }

      // Should not crash even at max depth
      final results = deepTree.query(Rect.fromLTWH(90, 90, 30, 30));
      expect(results.length, 10);
    });

    test('should handle overlapping objects', () {
      final rect1 = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(100, 100),
      );

      final rect2 = CanvasRectangle(
        id: 'rect2',
        worldPosition: const Offset(150, 150),
        strokeColor: Colors.black,
        size: const Size(100, 100),
      );

      quadTree.insert(rect1);
      quadTree.insert(rect2);

      // Query overlapping region
      final results = quadTree.query(Rect.fromLTWH(125, 125, 50, 50));
      expect(results, containsAll([rect1, rect2]));
    });

    test('performance: should handle 1000 objects efficiently', () {
      final stopwatch = Stopwatch()..start();

      // Insert 1000 objects
      for (int i = 0; i < 1000; i++) {
        final rect = CanvasRectangle(
          id: 'rect$i',
          worldPosition: Offset((i % 50) * 20.0, (i ~/ 50) * 20.0),
          strokeColor: Colors.black,
          size: const Size(15, 15),
        );
        quadTree.insert(rect);
      }

      stopwatch.stop();

      // Should insert quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Query should also be fast
      stopwatch.reset();
      stopwatch.start();

      final results = quadTree.query(Rect.fromLTWH(200, 200, 100, 100));

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(results, isNotEmpty);
    });

    test('should return correct objects in reversed hit test order', () {
      // Add objects on top of each other
      final rect1 = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      final rect2 = CanvasRectangle(
        id: 'rect2',
        worldPosition: const Offset(110, 110),
        strokeColor: Colors.blue,
        size: const Size(50, 50),
      );

      quadTree.insert(rect1);
      quadTree.insert(rect2);

      // Hit test in overlap region - should return last inserted (top)
      final hit = quadTree.hitTest(const Offset(120, 120));
      expect(hit?.id, 'rect2'); // rect2 is on top
    });
  });

  group('InMemoryCanvasRepository Tests', () {
    late QuadTree quadTree;
    late InMemoryCanvasRepository repository;

    setUp(() {
      quadTree = QuadTree(bounds: Rect.fromLTWH(0, 0, 1000, 1000));
      repository = InMemoryCanvasRepository(quadTree);
    });

    test('should add objects to repository', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      repository.add(rect);

      expect(repository.getAll(), contains(rect));
      expect(repository.getById('rect1'), equals(rect));
    });

    test('should update objects in repository', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      repository.add(rect);

      // Modify object
      rect.move(const Offset(50, 50));
      repository.update(rect);

      final updated = repository.getById('rect1');
      expect(updated?.worldPosition, const Offset(150, 150));
    });

    test('should remove objects from repository', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      repository.add(rect);
      expect(repository.getAll(), contains(rect));

      repository.remove('rect1');
      expect(repository.getAll(), isNot(contains(rect)));
      expect(repository.getById('rect1'), isNull);
    });

    test('should get selected objects', () {
      final rect1 = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
        isSelected: true,
      );

      final rect2 = CanvasRectangle(
        id: 'rect2',
        worldPosition: const Offset(200, 200),
        strokeColor: Colors.black,
        size: const Size(50, 50),
        isSelected: false,
      );

      repository.add(rect1);
      repository.add(rect2);

      final selected = repository.getSelected();
      expect(selected, contains(rect1));
      expect(selected, isNot(contains(rect2)));
    });

    test('should perform hit test via repository', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      repository.add(rect);

      final hit = repository.hitTest(const Offset(120, 120));
      expect(hit, equals(rect));

      final miss = repository.hitTest(const Offset(500, 500));
      expect(miss, isNull);
    });

    test('should clear repository', () {
      for (int i = 0; i < 10; i++) {
        repository.add(CanvasRectangle(
          id: 'rect$i',
          worldPosition: Offset(i * 50.0, i * 50.0),
          strokeColor: Colors.black,
          size: const Size(40, 40),
        ));
      }

      expect(repository.getAll(), hasLength(10));

      repository.clear();

      expect(repository.getAll(), isEmpty);
    });

    test('should return immutable list from getAll', () {
      final rect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        strokeColor: Colors.black,
        size: const Size(50, 50),
      );

      repository.add(rect);

      final list1 = repository.getAll();
      final list2 = repository.getAll();

      // Should be different instances
      expect(identical(list1, list2), isFalse);

      // But same contents
      expect(list1, equals(list2));
    });
  });
}
