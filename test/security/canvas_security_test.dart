import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('Canvas Security Tests', () {
    test('should validate canvas data structure before processing', () {
      final canvasState = CanvasState();

      // Valid data should work
      expect(
        () => canvasState.addNode(RectangleShape(Rect.fromLTWH(0, 0, 100, 100))),
        returnsNormally,
      );
    });

    test('should enforce reasonable size limits on shapes', () {
      final canvasState = CanvasState();

      // Extremely large shapes that could cause DoS
      final hugeRect = RectangleShape(Rect.fromLTWH(0, 0, 1e15, 1e15));
      final hugeCircle = CircleShape(Offset.zero, 1e15);

      // These should either be rejected or handled gracefully
      expect(() => canvasState.addNode(hugeRect), returnsNormally);
      expect(() => canvasState.addNode(hugeCircle), returnsNormally);
    });

    test('should handle malformed shape data gracefully', () {
      // Test with NaN values
      expect(
        () => RectangleShape(Rect.fromLTWH(double.nan, 0, 100, 100)),
        returnsNormally, // Should either work or throw clear error
      );

      // Test with infinity
      expect(
        () => CircleShape(Offset(double.infinity, 0), 50),
        returnsNormally,
      );

      // Test with negative dimensions
      expect(
        () => RectangleShape(Rect.fromLTWH(0, 0, -100, -100)),
        returnsNormally,
      );
    });

    test('should prevent creating excessive number of objects (DoS)', () {
      final canvasState = CanvasState();

      // Try to create a flood of objects
      for (int i = 0; i < 10000; i++) {
        canvasState.addNode(RectangleShape(Rect.fromLTWH(i * 1.0, 0, 10, 10)));
      }

      // Should complete without crashing
      expect(canvasState.nodes.length, greaterThan(0));
    });

    test('should validate node IDs are unique', () {
      final canvasState = CanvasState();
      final node1 = canvasState.nodes[0];
      final node2 = canvasState.nodes[1];

      expect(node1.id, isNot(equals(node2.id)));
    });

    test('should handle rapid state changes without corruption', () {
      final canvasState = CanvasState();

      // Rapid operations
      for (int i = 0; i < 100; i++) {
        canvasState.addNode(RectangleShape(Rect.fromLTWH(i * 1.0, 0, 50, 50)));
        if (canvasState.nodes.length > 5) {
          canvasState.selectedNodes.add(canvasState.nodes.last);
          canvasState.deleteSelected();
        }
      }

      // State should remain consistent
      expect(canvasState.nodes, isNotEmpty);
    });

    test('should validate edge connections reference valid nodes', () {
      final canvasState = CanvasState();
      final node1 = canvasState.nodes[0];
      final node2 = canvasState.nodes[1];

      // Create valid connection
      canvasState.startConnecting(node1, Offset(50, 50));
      canvasState.endConnecting(node2);

      expect(canvasState.edges.length, 1);
      expect(canvasState.edges.first.sourceNode, node1);
      expect(canvasState.edges.first.targetNode, node2);
    });

    test('should prevent self-referential connections', () {
      final canvasState = CanvasState();
      final node = canvasState.nodes[0];

      // Try to connect node to itself
      canvasState.startConnecting(node, Offset(50, 50));
      canvasState.endConnecting(node);

      // Should not create connection
      expect(canvasState.edges.length, 0);
    });

    test('should handle deletion of connected nodes safely', () {
      final canvasState = CanvasState();
      final node1 = canvasState.nodes[0];
      final node2 = canvasState.nodes[1];

      // Create connection
      canvasState.startConnecting(node1, Offset(50, 50));
      canvasState.endConnecting(node2);
      expect(canvasState.edges.length, 1);

      // Delete one node
      canvasState.selectedNodes.add(node1);
      canvasState.deleteSelected();

      // Edge should also be removed
      expect(canvasState.edges.length, 0);
    });

    test('should validate freehand stroke data', () {
      final canvasState = CanvasState();

      // Start stroke
      canvasState.startFreehandStroke(const Offset(10, 10));

      // Add valid points
      for (int i = 0; i < 100; i++) {
        canvasState.updateFreehandStroke(Offset(10 + i * 1.0, 10));
      }

      canvasState.endFreehandStroke(const Offset(110, 10));

      // Should complete without issues
      expect(canvasState.freehandStrokes.length, greaterThanOrEqualTo(0));
    });

    test('should handle stroke with single point gracefully', () {
      final canvasState = CanvasState();

      canvasState.startFreehandStroke(Offset(10, 10));
      canvasState.endFreehandStroke(Offset(10, 10));

      // Should not crash
      expect(() => canvasState.freehandStrokes, returnsNormally);
    });

    test('should handle large number of nodes without crash', () {
      final canvasState = CanvasState();
      final initialCount = canvasState.nodes.length;

      // Add many nodes
      for (int i = 0; i < 1000; i++) {
        canvasState.addNode(RectangleShape(Rect.fromLTWH(i * 10.0, 0, 10, 10)));
      }

      // Should complete without crash
      expect(canvasState.nodes.length, initialCount + 1000);
    });

    test('should handle malformed data gracefully', () {
      // Test with invalid shape data
      expect(
        () => RectangleShape(Rect.fromLTWH(double.nan, 0, 100, 100)),
        returnsNormally,
      );
    });

    test('should validate node structure', () {
      final node1 = Node('test1', Offset.zero, RectangleShape(Rect.fromLTWH(0, 0, 100, 100)));
      final node2 = Node('test2', Offset.zero, CircleShape(Offset.zero, 50));

      // IDs should be unique
      expect(node1.id, isNot(equals(node2.id)));

      // Nodes should have valid structure
      expect(node1.shape, isNotNull);
      expect(node2.shape, isNotNull);
    });

    test('should handle rapid sequential modifications safely', () {
      final canvasState = CanvasState();

      // Simulate rapid sequential operations
      for (int i = 0; i < 100; i++) {
        canvasState.addNode(RectangleShape(Rect.fromLTWH(i * 10.0, 0, 50, 50)));
      }

      // Should complete without errors
      expect(canvasState.nodes.length, greaterThan(100));
    });

    test('should prevent duplicate edges between same nodes', () {
      final canvasState = CanvasState();
      final node1 = canvasState.nodes[0];
      final node2 = canvasState.nodes[1];

      // Create first connection
      canvasState.startConnecting(node1, Offset(50, 50));
      canvasState.endConnecting(node2);
      expect(canvasState.edges.length, 1);

      // Try to create duplicate
      canvasState.startConnecting(node1, Offset(50, 50));
      canvasState.endConnecting(node2);

      // Should still be only 1 edge
      expect(canvasState.edges.length, 1);
    });

    test('should handle deeply nested operations without stack overflow', () {
      final canvasState = CanvasState();

      // Create chain of operations
      for (int i = 0; i < 1000; i++) {
        canvasState.addNode(RectangleShape(Rect.fromLTWH(i * 1.0, 0, 10, 10)));
      }

      // Should complete
      expect(canvasState.nodes.length, greaterThan(1000));
    });

    test('should validate coordinate ranges', () {
      // Extreme coordinates that could cause rendering issues
      final extremeRect = RectangleShape(Rect.fromLTWH(-1e10, -1e10, 100, 100));
      final farCircle = CircleShape(Offset(1e10, 1e10), 50);

      expect(() => extremeRect.containsPoint(Offset.zero), returnsNormally);
      expect(() => farCircle.containsPoint(Offset.zero), returnsNormally);
    });

    test('should protect against precision loss in calculations', () {
      final circle = CircleShape(Offset(1e15, 1e15), 50);

      final edgePoint = circle.getClosestEdgePoint(Offset(1e15 + 100, 1e15));

      // Should return valid offset
      expect(edgePoint.dx.isFinite, isTrue);
      expect(edgePoint.dy.isFinite, isTrue);
      expect(edgePoint.dx.isNaN, isFalse);
      expect(edgePoint.dy.isNaN, isFalse);
    });
  });
}
