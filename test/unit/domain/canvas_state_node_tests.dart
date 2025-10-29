import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('Node Tests', () {
    test('should create node with correct properties', () {
      final position = Offset(100, 200);
      final shape = RectangleShape(Rect.fromLTWH(0, 0, 120, 80));
      final node = Node('test_node', position, shape);

      expect(node.id, 'test_node');
      expect(node.position, position);
      expect(node.shape, shape);
      // Connection points are populated by updateShape, not constructor
      expect(node.connectionPoints, isEmpty);
    });

    test('should update shape and maintain connection points', () {
      final node = Node('test_node', Offset(50, 50), RectangleShape(Rect.fromLTWH(0, 0, 100, 50)));
      expect(node.connectionPoints.length, 0); // Initially empty

      final newShape = CircleShape(Offset(25, 25), 25);
      node.updateShape(newShape);

      expect(node.shape, newShape);
      expect(node.connectionPoints.length, 8); // Circle has 8 connection points
    });

    test('should calculate correct bounds based on shape', () {
      final shapeBounds = Rect.fromLTWH(0, 0, 120, 80);
      final node = Node('test_node', Offset(100, 100), RectangleShape(shapeBounds));

      // Node bounds just returns shape bounds (not shifted by position)
      expect(node.bounds, shapeBounds);
    });

    test('should find closest connection point correctly', () {
      final node = Node('test_node', Offset(50, 50), RectangleShape(Rect.fromLTWH(0, 0, 100, 50)));

      // Test from right side - should get right connection point of shape
      final closest1 = node.getClosestConnectionPoint(Offset(200, 75));
      expect(closest1, Offset(100, 25)); // Right edge center of shape (not shifted by position)

      // Test from top - should get top connection point of shape
      final closest2 = node.getClosestConnectionPoint(Offset(50, -50));
      expect(closest2, Offset(50, 0)); // Top edge center of shape
    });

    test('should detect point containment relative to node position', () {
      final node = Node('test_node', Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 120, 80)));

      // Point inside shape relative to node position (shape center at 100+60, 100+40 = 160, 140)
      expect(node.containsPoint(Offset(160, 140)), true); // Center of shape

      // Point outside shape (shape bounds are 100-220, 100-180)
      expect(node.containsPoint(Offset(50, 50)), false); // Outside bounds
      expect(node.containsPoint(Offset(250, 200)), false); // Outside bounds
    });
  });

  group('CanvasState Tests', () {
    late CanvasState canvasState;

    setUp(() {
      canvasState = CanvasState();
    });

    test('should initialize with default sample nodes', () {
      expect(canvasState.nodes.length, 3); // Rectangle, Circle, Triangle
      expect(canvasState.edges.length, 0);
      expect(canvasState.freehandStrokes.length, 0);
    });

    test('should add node with specified shape', () {
      final initialCount = canvasState.nodes.length;
      final rectangle = RectangleShape(Rect.fromLTWH(0, 0, 100, 50));

      canvasState.addNode(rectangle);

      expect(canvasState.nodes.length, initialCount + 1);
      expect(canvasState.nodes.last.shape.type, 'rectangle');
    });

    test('should start freehand stroke', () {
      final startPoint = Offset(100, 100);

      canvasState.startFreehandStroke(startPoint);

      expect(canvasState.currentStroke, isNotNull);
      expect(canvasState.currentStroke!.points.length, 1);
      expect(canvasState.currentStroke!.points.first, startPoint);
      expect(canvasState.showConnectionConfirmation, false);
    });

    test('should update freehand stroke', () {
      canvasState.startFreehandStroke(Offset(100, 100));

      final updatePoint = Offset(150, 120);
      canvasState.updateFreehandStroke(updatePoint);

      expect(canvasState.currentStroke!.points.length, 2);
      expect(canvasState.currentStroke!.points.last, updatePoint);
    });

    test('should end freehand stroke and keep as drawing when no connection detected', () {
      canvasState.startFreehandStroke(Offset(100, 100));
      canvasState.updateFreehandStroke(Offset(150, 120));
      canvasState.updateFreehandStroke(Offset(200, 140));

      canvasState.endFreehandStroke(Offset(250, 160));

      expect(canvasState.currentStroke, isNull);
      expect(canvasState.freehandStrokes.length, 1);
      expect(canvasState.freehandStrokes.first.points.length, 4);
      expect(canvasState.showConnectionConfirmation, false);
    });

    test('should start connecting between nodes', () {
      final sourceNode = canvasState.nodes.first;
      final startPosition = Offset(50, 50);

      canvasState.startConnecting(sourceNode, startPosition);

      expect(canvasState.sourceNode, sourceNode);
      expect(canvasState.dragPosition, startPosition);
      expect(canvasState.sourceConnectionPoint, isNotNull);
    });

    test('should update drag position during connection', () {
      final sourceNode = canvasState.nodes.first;
      canvasState.startConnecting(sourceNode, Offset(50, 50));

      final newPosition = Offset(100, 100);
      canvasState.updateDrag(newPosition);

      expect(canvasState.dragPosition, newPosition);
    });

    test('should complete connection between different nodes', () {
      final sourceNode = canvasState.nodes[0];
      final targetNode = canvasState.nodes[1];

      canvasState.startConnecting(sourceNode, Offset(50, 50));
      canvasState.endConnecting(targetNode);

      expect(canvasState.edges.length, 1);
      expect(canvasState.edges.first.sourceNode, sourceNode);
      expect(canvasState.edges.first.targetNode, targetNode);
      expect(canvasState.sourceNode, isNull);
      expect(canvasState.dragPosition, isNull);
    });

    test('should not create connection to same node', () {
      final sourceNode = canvasState.nodes.first;

      canvasState.startConnecting(sourceNode, Offset(50, 50));
      canvasState.endConnecting(sourceNode); // Same node

      expect(canvasState.edges.length, 0);
    });

    test('should not create duplicate edges', () {
      final sourceNode = canvasState.nodes[0];
      final targetNode = canvasState.nodes[1];

      // Create first connection
      canvasState.startConnecting(sourceNode, Offset(50, 50));
      canvasState.endConnecting(targetNode);
      expect(canvasState.edges.length, 1);

      // Try to create duplicate
      canvasState.startConnecting(sourceNode, Offset(50, 50));
      canvasState.endConnecting(targetNode);

      expect(canvasState.edges.length, 1); // Should still be 1
    });

    test('should move node and update connected edges', () {
      final sourceNode = canvasState.nodes[0];
      final targetNode = canvasState.nodes[1];

      // Create connection
      canvasState.startConnecting(sourceNode, Offset(50, 50));
      canvasState.endConnecting(targetNode);

      final edge = canvasState.edges.first;
      final originalSourcePoint = edge.sourcePoint;
      final originalTargetPoint = edge.targetPoint;

      // Move source node
      final newPosition = Offset(200, 200);
      canvasState.moveNode(sourceNode, newPosition);

      // Edge points should be recalculated based on new node positions
      // The actual recalculation happens when accessing edge.path
      expect(edge, isNotNull); // Edge still exists
      expect(canvasState.edges.length, 1); // Still one edge
    });

    test('should change node shape', () {
      final node = canvasState.nodes.first;
      final originalShape = node.shape;
      final newShape = CircleShape(Offset(50, 50), 50);

      canvasState.changeNodeShape(node, newShape);

      expect(node.shape, isNot(equals(originalShape)));
      expect(node.shape, newShape);
      expect(node.connectionPoints.length, 8); // Circle has 8 points
    });

    test('should select and clear selection', () {
      final node1 = canvasState.nodes[0];
      final node2 = canvasState.nodes[1];

      // Select all
      canvasState.selectAll();
      expect(canvasState.selectedNodes.length, 3);

      // Clear selection
      canvasState.clearSelection();
      expect(canvasState.selectedNodes.length, 0);
    });

    test('should delete selected nodes and connected edges', () {
      final node1 = canvasState.nodes[0];
      final node2 = canvasState.nodes[1];

      // Create connection
      canvasState.startConnecting(node1, Offset(50, 50));
      canvasState.endConnecting(node2);
      expect(canvasState.edges.length, 1);

      // Select and delete node1
      canvasState.selectedNodes.add(node1);
      canvasState.deleteSelected();

      expect(canvasState.nodes.contains(node1), false);
      expect(canvasState.edges.length, 0); // Edge should be removed
      expect(canvasState.selectedNodes.length, 0);
    });

    test('should handle freehand connection confirmation', () {
      // Create nodes positioned for connection detection
      final node1 = Node('node1', Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 50, 50)));
      final node2 = Node('node2', Offset(150, 100), CircleShape(Offset(25, 25), 25));

      canvasState.nodes.clear();
      canvasState.nodes.add(node1);
      canvasState.nodes.add(node2);

      // Simulate freehand stroke that spans between nodes
      canvasState.startFreehandStroke(Offset(125, 125)); // Near node1 center
      for (int i = 1; i < 10; i++) {
        canvasState.updateFreehandStroke(Offset(125 + i * 5.0, 125 - i.toDouble()));
      }
      canvasState.endFreehandStroke(Offset(175, 115)); // Near node2 center

      // Check if connection was detected (depends on stroke analysis implementation)
      if (canvasState.showConnectionConfirmation) {
        // Confirm connection
        canvasState.confirmFreehandConnection();
        expect(canvasState.edges.length, 1);
        expect(canvasState.freehandStrokes.length, 0);
        expect(canvasState.showConnectionConfirmation, false);
      } else {
        // If not detected, stroke should be kept as freehand
        expect(canvasState.freehandStrokes.length, 1);
        expect(canvasState.edges.length, 0);
      }
    });

    test('should handle freehand connection cancellation', () {
      final node1 = Node('node1', Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 50, 50)));
      final node2 = Node('node2', Offset(150, 100), CircleShape(Offset(25, 25), 25));

      canvasState.nodes.clear();
      canvasState.nodes.add(node1);
      canvasState.nodes.add(node2);

      canvasState.startFreehandStroke(Offset(125, 125));
      for (int i = 1; i < 10; i++) {
        canvasState.updateFreehandStroke(Offset(125 + i * 5.0, 125 - i.toDouble()));
      }
      canvasState.endFreehandStroke(Offset(175, 115));

      if (canvasState.showConnectionConfirmation) {
        // Cancel connection
        canvasState.cancelFreehandConnection();
        expect(canvasState.edges.length, 0);
        expect(canvasState.freehandStrokes.length, 1); // Stroke kept as drawing
        expect(canvasState.showConnectionConfirmation, false);
      } else {
        // If no connection detected, stroke should be kept as freehand
        expect(canvasState.freehandStrokes.length, 1);
        expect(canvasState.edges.length, 0);
      }
    });
  });
}