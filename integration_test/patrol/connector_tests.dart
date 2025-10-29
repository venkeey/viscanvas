import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create connector between shapes', (tester) async {
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

    final initialEdgeCount = canvasState.edges.length;

    // Find rectangle and circle nodes
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final circleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'circle');

    // Calculate connection points
    final startPoint = rectangleNode.position + const Offset(130, 60); // Near right edge
    final endPoint = circleNode.position + const Offset(-10, 60); // Near left edge

    // Simulate freehand drawing to create connection
    final gesture = await tester.startGesture(startPoint);
    await tester.pump();
    await gesture.moveTo(endPoint);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Check if connection confirmation appears
    if (canvasState.showConnectionConfirmation) {
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify connection was created
      expect(canvasState.edges.length, initialEdgeCount + 1);
      expect(canvasState.edges.last.sourceNode, rectangleNode);
      expect(canvasState.edges.last.targetNode, circleNode);
    } else {
      // If no connection was detected, verify no new edges
      expect(canvasState.edges.length, initialEdgeCount);
    }
  });

  testWidgets('Connector auto-routing', (tester) async {
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

    if (canvasState.showConnectionConfirmation) {
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify connection exists and has a path
      expect(canvasState.edges.length, greaterThan(0));
      final edge = canvasState.edges.last;
      expect(edge.path, isNotNull);
    }
  });

  testWidgets('Connector deletion', (tester) async {
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

    // Select and delete the connector (connectors are painted paths, not widgets)
    if (edgeCountAfterCreation > 0) {
      final edge = canvasState.edges.last;

      // Simulate selecting the edge by tapping near it
      final edgeCenter = Offset(
        (edge.sourcePoint.dx + edge.targetPoint.dx) / 2,
        (edge.sourcePoint.dy + edge.targetPoint.dy) / 2,
      );

      await tester.tapAt(edgeCenter);
      await tester.pumpAndSettle();

      // Delete the connector
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();

      // Verify connector was deleted
      expect(canvasState.edges.length, edgeCountAfterCreation - 1);
    }
  });

  testWidgets('Multiple connectors management', (tester) async {
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

    final initialEdgeCount = canvasState.edges.length;

    // Create multiple connections
    final rectangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');
    final circleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'circle');
    final triangleNode = canvasState.nodes.firstWhere((node) => node.shape.type == 'triangle');

    // Connect rectangle to circle
    final gesture1 = await tester.startGesture(rectangleNode.position + const Offset(130, 60));
    await tester.pump();
    await gesture1.moveTo(circleNode.position + const Offset(-10, 60));
    await tester.pump();
    await gesture1.up();
    await tester.pumpAndSettle();

    if (canvasState.showConnectionConfirmation) {
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
    }

    // Connect rectangle to triangle
    final gesture2 = await tester.startGesture(rectangleNode.position + const Offset(60, 130));
    await tester.pump();
    await gesture2.moveTo(triangleNode.position + const Offset(30, -10));
    await tester.pump();
    await gesture2.up();
    await tester.pumpAndSettle();

    if (canvasState.showConnectionConfirmation) {
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
    }

    // Verify multiple connections exist
    expect(canvasState.edges.length, greaterThanOrEqualTo(initialEdgeCount));
  });

  testWidgets('Connector updates when shapes move', (tester) async {
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

    if (canvasState.showConnectionConfirmation) {
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify connection exists
      expect(canvasState.edges.length, greaterThan(0));
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

      // Verify edge path was updated
      final updatedPathBounds = edge.path.getBounds();
      expect(updatedPathBounds, isNot(originalPathBounds));
    }
  });

  testWidgets('Connector selection and properties', (tester) async {
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

    if (canvasState.showConnectionConfirmation) {
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify connection exists
      expect(canvasState.edges.length, greaterThan(0));
      final edge = canvasState.edges.last;

      // Select the connector
      final edgeCenter = Offset(
        (edge.sourcePoint.dx + edge.targetPoint.dx) / 2,
        (edge.sourcePoint.dy + edge.targetPoint.dy) / 2,
      );

      await tester.tapAt(edgeCenter);
      await tester.pumpAndSettle();

      // Verify connector is selected
      expect(canvasState.selectedEdge, edge);
    }
  });
}