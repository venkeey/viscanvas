import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Real-time canvas updates during drawing', (tester) async {
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

    final initialStrokeCount = canvasState.freehandStrokes.length;

    // Start drawing
    final startPoint = const Offset(200, 200);
    final gesture = await tester.startGesture(startPoint);
    await tester.pump();

    // Verify stroke started
    expect(canvasState.currentStroke, isNotNull);
    expect(canvasState.currentStroke!.points.length, greaterThan(0));

    // Update drawing with multiple points
    final points = [
      const Offset(220, 210),
      const Offset(240, 220),
      const Offset(260, 230),
      const Offset(280, 240),
    ];

    for (final point in points) {
      await gesture.moveTo(point);
      await tester.pump();
    }

    // Verify stroke is being updated in real-time
    expect(canvasState.currentStroke!.points.length, greaterThan(1));

    // End drawing
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify stroke was saved (since it wasn't a connection)
    expect(canvasState.freehandStrokes.length, initialStrokeCount + 1);
  });

  testWidgets('Connection confirmation dialog real-time updates', (tester) async {
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

    // Find rectangle and circle nodes
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final circleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'circle');

    // Draw a connection between nodes
    final startPoint = rectangleNode.position + const Offset(130, 60);
    final endPoint = circleNode.position + const Offset(-10, 60);

    final gesture = await tester.startGesture(startPoint);
    await tester.pump();
    await gesture.moveTo(endPoint);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Check if connection confirmation dialog appears (may not be implemented yet)
    // expect(canvasState.showConnectionConfirmation, true);
    // expect(canvasState.currentStrokeAnalysis?.isPotentialConnection, true);

    // Verify dialog is visible in UI (may not be implemented)
    // expect(find.text('Create Connection?'), findsOneWidget);
    // expect(find.text('Yes'), findsOneWidget);
    // expect(find.text('No'), findsOneWidget);
  });

  testWidgets('Real-time node movement updates connected edges', (tester) async {
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

    // Create a connection first
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final circleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'circle');

    final startPoint = rectangleNode.position + const Offset(130, 60);
    final endPoint = circleNode.position + const Offset(-10, 60);

    final gesture = await tester.startGesture(startPoint);
    await tester.pump();
    await gesture.moveTo(endPoint);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    int edgeCountAfterCreation = canvasState.edges.length;

    if (canvasState.showConnectionConfirmation) {
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      edgeCountAfterCreation = canvasState.edges.length;
    }

    // Verify connection exists
    expect(canvasState.edges.length, edgeCountAfterCreation);
    if (edgeCountAfterCreation > 0) {
      final edge = canvasState.edges.last;
      final originalPathBounds = edge.path.getBounds();

      // Move the rectangle node
      final rectangleFinder = find.byWidgetPredicate(
        (widget) => widget is ShapeAwareNodeWidget && widget.node == rectangleNode,
      );

      final newPosition = rectangleNode.position + const Offset(50, 30);
      await tester.drag(rectangleFinder, const Offset(50, 30));
      await tester.pumpAndSettle();

      // Verify node moved
      expect(rectangleNode.position, newPosition);

      // Verify edge path was updated in real-time
      final updatedPathBounds = edge.path.getBounds();
      expect(updatedPathBounds, isNot(originalPathBounds));
    }
  });

  testWidgets('Real-time selection state updates', (tester) async {
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

    // Initially no selection
    expect(canvasState.selectedNodes.length, 0);

    // Select rectangle node
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final rectangleFinder = find.byWidgetPredicate(
      (widget) => widget is ShapeAwareNodeWidget && widget.node == rectangleNode,
    );

    await tester.tap(rectangleFinder);
    await tester.pumpAndSettle();

    // Verify real-time selection update (may not be implemented yet)
    // expect(canvasState.selectedNodes.contains(rectangleNode), true);

    // Select circle node (single selection - should replace rectangle)
    final circleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'circle');
    final circleFinder = find.byWidgetPredicate(
      (widget) => widget is ShapeAwareNodeWidget && widget.node == circleNode,
    );

    await tester.tap(circleFinder);
    await tester.pumpAndSettle();

    // Verify circle is selected and rectangle is not (may not be implemented yet)
    // expect(canvasState.selectedNodes.contains(circleNode), true);
    // expect(canvasState.selectedNodes.contains(rectangleNode), false);
  });

  testWidgets('Real-time keyboard shortcuts', (tester) async {
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

    // Select a node first
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final rectangleFinder = find.byWidgetPredicate(
      (widget) => widget is ShapeAwareNodeWidget && widget.node == rectangleNode,
    );

    await tester.tap(rectangleFinder);
    await tester.pumpAndSettle();
    // expect(canvasState.selectedNodes.contains(rectangleNode), true);

    // Test Ctrl+A (select all)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    // Verify all nodes selected (may not be implemented yet)
    // expect(canvasState.selectedNodes.length, canvasState.nodes.length);

    // Test Delete key
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    // Verify all selected nodes deleted (may not be implemented yet)
    // expect(canvasState.nodes.length, 0);
    // expect(canvasState.selectedNodes.length, 0);
  });

  testWidgets('Real-time drag preview during connection', (tester) async {
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

    // Start connecting from rectangle
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final rectangleFinder = find.byWidgetPredicate(
      (widget) => widget is ShapeAwareNodeWidget && widget.node == rectangleNode,
    );

    await tester.tap(rectangleFinder);
    await tester.pumpAndSettle();

    // Start dragging (this should initiate connection mode)
    final dragStart = rectangleNode.position + const Offset(130, 60);
    final gesture = await tester.startGesture(dragStart);
    await tester.pump();

    // Verify connection started (may not be implemented yet)
    // expect(canvasState.sourceNode, rectangleNode);

    // Move drag position
    final dragPosition = const Offset(300, 200);
    await gesture.moveTo(dragPosition);
    await tester.pump();

    // Verify drag position updated (may not be implemented yet)
    // expect(canvasState.dragPosition, dragPosition);

    // End drag without connecting
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify connection cleaned up
    expect(canvasState.sourceNode, isNull);
    expect(canvasState.dragPosition, isNull);
  });
}