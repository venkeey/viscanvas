import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';

// TestCanvasWrapper provides consistent test environment for canvas tests
class TestCanvasWrapper extends StatelessWidget {
  final Widget child;
  final Size? canvasSize;

  const TestCanvasWrapper({
    Key? key,
    required this.child,
    this.canvasSize = const Size(800, 600),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SizedBox.fromSize(
          size: canvasSize,
          child: child,
        ),
      ),
    );
  }
}

// CanvasTestHelper provides utilities for canvas-specific testing
class CanvasTestHelper {
  // Create a canvas state with predefined shapes for testing
  static CanvasState createCanvasWithShapes({
    List<NodeShape>? shapes,
    List<Edge>? edges,
  }) {
    final canvasState = CanvasState();

    // Clear default nodes first
    canvasState.nodes.clear();
    canvasState.edges.clear();

    if (shapes != null) {
      for (int i = 0; i < shapes.length; i++) {
        final shape = shapes[i];
        // Use the public addNode method but we need to modify it to accept position
        // For now, we'll create nodes manually and add them
        final position = Offset(100 + i * 150.0, 100 + i * 100.0);
        final node = Node('test_node_$i', position, shape);
        canvasState.nodes.add(node);
      }
    }

    if (edges != null) {
      canvasState.edges.addAll(edges);
    }

    return canvasState;
  }

  // Create standard test shapes
  static RectangleShape createTestRectangle({
    double width = 100,
    double height = 80,
  }) {
    return RectangleShape(Rect.fromLTWH(0, 0, width, height));
  }

  static CircleShape createTestCircle({
    double radius = 50,
  }) {
    return CircleShape(Offset(radius, radius), radius);
  }

  static TriangleShape createTestTriangle({
    double size = 60,
  }) {
    return TriangleShape(Offset(size, size), size);
  }

  // Create test edges
  static Edge createTestEdge({
    required Node sourceNode,
    required Node targetNode,
    Offset? sourcePoint,
    Offset? targetPoint,
  }) {
    final srcPoint = sourcePoint ?? sourceNode.getClosestConnectionPoint(targetNode.position);
    final tgtPoint = targetPoint ?? targetNode.getClosestConnectionPoint(sourceNode.position);

    return Edge(
      sourceNode: sourceNode,
      targetNode: targetNode,
      sourcePoint: srcPoint,
      targetPoint: tgtPoint,
    );
  }

  // Simulate user gestures for testing
  static Future<void> simulateDragGesture(
    WidgetTester tester,
    Offset startPoint,
    Offset endPoint, {
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    final gesture = await tester.startGesture(startPoint);
    await tester.pump();
    await gesture.moveTo(endPoint);
    await tester.pump(duration);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  static Future<void> simulateFreehandDrawing(
    WidgetTester tester,
    List<Offset> points, {
    Duration pointDelay = const Duration(milliseconds: 50),
  }) async {
    if (points.isEmpty) return;

    final gesture = await tester.startGesture(points.first);
    await tester.pump();

    for (int i = 1; i < points.length; i++) {
      await gesture.moveTo(points[i]);
      await tester.pump(pointDelay);
    }

    await gesture.up();
    await tester.pumpAndSettle();
  }

  // Canvas state assertions
  static void expectCanvasState(
    CanvasState state, {
    int? nodeCount,
    int? edgeCount,
    int? freehandStrokeCount,
    List<String>? nodeTypes,
    bool? hasSelectedNodes,
  }) {
    if (nodeCount != null) {
      expect(state.nodes.length, nodeCount, reason: 'Node count mismatch');
    }

    if (edgeCount != null) {
      expect(state.edges.length, edgeCount, reason: 'Edge count mismatch');
    }

    if (freehandStrokeCount != null) {
      expect(state.freehandStrokes.length, freehandStrokeCount, reason: 'Freehand stroke count mismatch');
    }

    if (nodeTypes != null) {
      final actualTypes = state.nodes.map((node) => node.shape.type).toList();
      expect(actualTypes, nodeTypes, reason: 'Node types mismatch');
    }

    if (hasSelectedNodes != null) {
      final hasSelection = state.selectedNodes.isNotEmpty;
      expect(hasSelection, hasSelectedNodes, reason: 'Selection state mismatch');
    }
  }

  // Shape-specific assertions
  static void expectShapeProperties(
    NodeShape shape, {
    String? type,
    Rect? bounds,
    List<Offset>? connectionPoints,
  }) {
    if (type != null) {
      expect(shape.type, type, reason: 'Shape type mismatch');
    }

    if (bounds != null) {
      expect(shape.bounds, bounds, reason: 'Shape bounds mismatch');
    }

    if (connectionPoints != null) {
      expect(shape.suggestedConnectionPoints, connectionPoints, reason: 'Connection points mismatch');
    }
  }

  // Point-in-shape testing utilities
  static void expectPointInShape(NodeShape shape, Offset point, {bool shouldBeInside = true}) {
    final result = shape.containsPoint(point);
    expect(result, shouldBeInside,
      reason: 'Point ${point.toString()} should ${shouldBeInside ? '' : 'not '}be inside ${shape.type}');
  }

  static void expectPointNotInShape(NodeShape shape, Offset point) {
    expectPointInShape(shape, point, shouldBeInside: false);
  }

  // Edge testing utilities
  static void expectEdgeConnection(Edge edge, {Node? sourceNode, Node? targetNode}) {
    if (sourceNode != null) {
      expect(edge.sourceNode, sourceNode, reason: 'Edge source node mismatch');
    }

    if (targetNode != null) {
      expect(edge.targetNode, targetNode, reason: 'Edge target node mismatch');
    }
  }

  static void expectEdgeContainsPoint(Edge edge, Offset point, {bool shouldContain = true, double tolerance = 5.0}) {
    final result = edge.containsPoint(point, tolerance);
    expect(result, shouldContain,
      reason: 'Edge should ${shouldContain ? '' : 'not '}contain point ${point.toString()}');
  }
}

// Test data factories for consistent test data
class CanvasTestDataFactory {
  static Node createTestNode({
    required String id,
    required Offset position,
    required NodeShape shape,
  }) {
    return Node(id, position, shape);
  }

  static List<Node> createConnectedNodes({
    int count = 2,
    double spacing = 200.0,
  }) {
    final nodes = <Node>[];

    for (int i = 0; i < count; i++) {
      final position = Offset(100 + i * spacing, 100.0);
      final shape = i % 2 == 0
        ? createTestRectangle()
        : createTestCircle();

      nodes.add(createTestNode(
        id: 'node_$i',
        position: position,
        shape: shape,
      ));
    }

    return nodes;
  }

  static RectangleShape createTestRectangle({
    double width = 120,
    double height = 80,
  }) {
    return RectangleShape(Rect.fromLTWH(0, 0, width, height));
  }

  static CircleShape createTestCircle({
    double radius = 60,
  }) {
    return CircleShape(Offset(radius, radius), radius);
  }

  static TriangleShape createTestTriangle({
    double size = 60,
  }) {
    return TriangleShape(Offset(size, size), size);
  }
}

// Mock services for testing
class MockCanvasServices {
  // Mock persistence service
  static final mockPersistenceService = MockCanvasPersistenceService();

  // Mock collaboration service
  static final mockCollaborationService = MockCollaborationService();
}

// Placeholder mock classes (implement as needed)
class MockCanvasPersistenceService {
  // Mock implementation
}

class MockCollaborationService {
  // Mock implementation
}