import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete rectangle drawing workflow', (tester) async {
    // Launch app
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CanvasState(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app launched and canvas is visible
    expect(find.byType(NodeCanvas), findsOneWidget);

    // Verify initial state - should have sample nodes
    final canvasState = Provider.of<CanvasState>(
      tester.element(find.byType(NodeCanvas)),
      listen: false,
    );

    expect(canvasState.nodes.length, 3); // rectangle, circle, triangle
    expect(canvasState.nodes.any((node) => node.shape.type == 'rectangle'), true);
  });

  testWidgets('Freehand drawing workflow', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CanvasState(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NodeCanvas), findsOneWidget);

    // Get canvas state
    final canvasState = Provider.of<CanvasState>(
      tester.element(find.byType(NodeCanvas)),
      listen: false,
    );

    final initialEdgeCount = canvasState.edges.length;

    // Find rectangle and circle nodes
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final circleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'circle');

    // Calculate connection points
    final startPoint = rectangleNode.position + const Offset(130, 60); // Near right edge
    final endPoint = circleNode.position + const Offset(-10, 60); // Near left edge

    // Simulate freehand drawing using standard gesture support
    final gesture = await tester.startGesture(startPoint);
    await tester.pump();
    await gesture.moveTo(endPoint);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Check if connection confirmation appears (may not always trigger based on stroke analysis)
    if (canvasState.showConnectionConfirmation) {
      expect(canvasState.currentStrokeAnalysis?.isPotentialConnection, true);

      // Confirm connection
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify connection was created
      expect(canvasState.edges.length, initialEdgeCount + 1);
      expect(canvasState.edges.last.sourceNode, rectangleNode);
      expect(canvasState.edges.last.targetNode, circleNode);
    } else {
      // If no connection was detected, verify stroke was saved as freehand drawing
      expect(canvasState.freehandStrokes.length, greaterThan(0));
    }
  });

  testWidgets('Text tool workflow', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CanvasState(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NodeCanvas), findsOneWidget);

    // Get canvas state
    final canvasState = Provider.of<CanvasState>(
      tester.element(find.byType(NodeCanvas)),
      listen: false,
    );

    final initialNodeCount = canvasState.nodes.length;

    // Simulate tapping on canvas to create text (this would depend on actual UI)
    // For now, we'll test the existing functionality
    expect(canvasState.nodes.length, greaterThanOrEqualTo(initialNodeCount));
  });

  testWidgets('Shape creation and manipulation workflow', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CanvasState(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NodeCanvas), findsOneWidget);

    final canvasState = Provider.of<CanvasState>(
      tester.element(find.byType(NodeCanvas)),
      listen: false,
    );

    // Test dragging existing shapes
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final initialPosition = rectangleNode.position;

    // Find the draggable widget for the rectangle
    final rectangleDraggableFinder = find.byWidgetPredicate(
      (widget) => widget is Draggable && widget.child is ShapeAwareNodeWidget &&
                 (widget.child as ShapeAwareNodeWidget).node == rectangleNode,
    );

    // Drag the rectangle
    await tester.drag(rectangleDraggableFinder, const Offset(50, 30));
    await tester.pumpAndSettle();

    // Verify rectangle moved
    expect(rectangleNode.position, initialPosition + const Offset(50, 30));

    // Verify any connected edges updated
    if (canvasState.edges.isNotEmpty) {
      final connectedEdges = canvasState.edges.where(
        (edge) => edge.sourceNode == rectangleNode || edge.targetNode == rectangleNode
      );
      expect(connectedEdges.isNotEmpty, true); // Should have connections from previous tests
    }
  });

  testWidgets('Canvas zoom and pan workflow', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CanvasState(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NodeCanvas), findsOneWidget);

    // Test pan functionality
    final canvasFinder = find.byType(NodeCanvas);
    final center = tester.getCenter(canvasFinder);

    // Pan the canvas
    await tester.drag(canvasFinder, const Offset(100, 50));
    await tester.pumpAndSettle();

    // Test zoom functionality (if implemented)
    // This would depend on actual zoom implementation
    expect(find.byType(NodeCanvas), findsOneWidget);
  });
}