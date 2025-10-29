import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('Canvas UX Test', () {
    testWidgets('should create rectangle and circle, connect them, and drag rectangle',
        (WidgetTester tester) async {
      // Launch the connectors app using its own main app structure
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => CanvasState(),
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the canvas has loaded and contains the sample nodes
      final canvasState = Provider.of<CanvasState>(
        tester.element(find.byType(NodeCanvas)),
        listen: false,
      );

      // Check that we have the expected sample nodes (rectangle and circle)
      expect(canvasState.nodes.length, 3); // rectangle, circle, triangle
      expect(canvasState.nodes.any((node) => node.shape.type == 'rectangle'), true);
      expect(canvasState.nodes.any((node) => node.shape.type == 'circle'), true);

      // Find the rectangle and circle nodes
      final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
      final circleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'circle');

      // Verify initial positions
      expect(rectangleNode.position, const Offset(100, 200));
      expect(circleNode.position, const Offset(400, 200));

      // Simulate freehand connection between rectangle and circle
      // Start drawing from near the rectangle's right edge
      final startPoint = rectangleNode.position + const Offset(130, 60); // Near right edge of rectangle
      final endPoint = circleNode.position + const Offset(-10, 60); // Near left edge of circle

      // Find the NodeCanvas widget and simulate pan gesture on it
      final nodeCanvasFinder = find.byType(NodeCanvas);
      expect(nodeCanvasFinder, findsOneWidget);

      // Simulate pan gesture for freehand drawing (this triggers onPanStart, onPanUpdate, onPanEnd)
      final gesture = await tester.startGesture(startPoint);
      await tester.pump(); // Allow onPanStart to be called

      // Move to end point
      await gesture.moveTo(endPoint);
      await tester.pump(); // Allow onPanUpdate to be called

      // End the gesture
      await gesture.up();
      await tester.pump(); // Allow onPanEnd to be called

      // The stroke should be analyzed and connection confirmation should appear
      expect(canvasState.showConnectionConfirmation, true);
      expect(canvasState.currentStrokeAnalysis?.isPotentialConnection, true);

      // Confirm the connection by tapping the "Yes" button
      await tester.tap(find.text('Yes'));
      await tester.pump();

      // Verify connection was created
      expect(canvasState.edges.length, 1);
      expect(canvasState.edges.first.sourceNode, rectangleNode);
      expect(canvasState.edges.first.targetNode, circleNode);

      // Now drag the rectangle to a new position using the Draggable widget
      final dragTarget = rectangleNode.position + const Offset(50, 50);

      // Find the draggable widget for the rectangle
      final rectangleDraggableFinder = find.byWidgetPredicate(
        (widget) => widget is Draggable && widget.child is ShapeAwareNodeWidget &&
                   (widget.child as ShapeAwareNodeWidget).node == rectangleNode,
      );
      expect(rectangleDraggableFinder, findsOneWidget);

      // Simulate drag using the Draggable's onDragEnd callback
      await tester.drag(rectangleDraggableFinder, const Offset(50, 50));
      await tester.pump();

      // Verify rectangle moved
      expect(rectangleNode.position, dragTarget);

      // Verify connection updated (edge should follow the moved node)
      expect(canvasState.edges.length, 1);
      final updatedEdge = canvasState.edges.first;
      expect(updatedEdge.sourceNode, rectangleNode);
      expect(updatedEdge.targetNode, circleNode);

      // The edge points should have been updated
      expect(updatedEdge.sourcePoint != updatedEdge.targetPoint, true);

      print('✅ UX Test completed successfully!');
      print('📊 Final state:');
      print('   - Rectangle position: ${rectangleNode.position}');
      print('   - Circle position: ${circleNode.position}');
      print('   - Connections: ${canvasState.edges.length}');
      print('   - Connection source: ${updatedEdge.sourcePoint}');
      print('   - Connection target: ${updatedEdge.targetPoint}');
    });
  });
}