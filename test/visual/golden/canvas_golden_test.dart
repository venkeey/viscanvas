import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('Canvas Golden Tests', () {
    testGoldens('Empty canvas state', (tester) async {
      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider(
          create: (context) => CanvasState(),
          child: const NodeCanvas(),
        ),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'empty_canvas');
    });

    testGoldens('Canvas with single rectangle shape', (tester) async {
      final canvasState = CanvasState();

      // Clear existing nodes and add a specific rectangle
      canvasState.nodes.clear();
      final rectangleShape = RectangleShape(Rect.fromLTWH(0, 0, 150, 80));
      canvasState.addNode(rectangleShape);

      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const NodeCanvas(),
        ),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'canvas_with_rectangle');
    });

    testGoldens('Canvas with multiple shapes', (tester) async {
      final canvasState = CanvasState();

      // Clear existing nodes and add specific shapes
      canvasState.nodes.clear();

      final rectangleShape = RectangleShape(Rect.fromLTWH(0, 0, 100, 80));
      final circleShape = CircleShape(Offset(60, 60), 40);
      final triangleShape = TriangleShape(Offset(60, 60), 50);

      canvasState.addNode(rectangleShape);
      canvasState.addNode(circleShape);
      canvasState.addNode(triangleShape);

      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const NodeCanvas(),
        ),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'canvas_with_multiple_shapes');
    });

    testGoldens('Canvas with connectors', (tester) async {
      final canvasState = CanvasState();

      // Clear existing nodes and add specific shapes with connectors
      canvasState.nodes.clear();

      final rectangleShape = RectangleShape(Rect.fromLTWH(0, 0, 100, 80));
      final circleShape = CircleShape(Offset(60, 60), 40);

      canvasState.addNode(rectangleShape);
      canvasState.addNode(circleShape);

      // Create a connector between the shapes
      if (canvasState.nodes.length >= 2) {
        final sourceNode = canvasState.nodes[0];
        final targetNode = canvasState.nodes[1];

        final sourcePoint = sourceNode.getClosestConnectionPoint(targetNode.position);
        final targetPoint = targetNode.getClosestConnectionPoint(sourceNode.position);

        final edge = Edge(
          sourceNode: sourceNode,
          targetNode: targetNode,
          sourcePoint: sourcePoint,
          targetPoint: targetPoint,
        );

        canvasState.edges.add(edge);
      }

      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const NodeCanvas(),
        ),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'canvas_with_connectors');
    });

    testGoldens('Canvas with freehand drawing', (tester) async {
      final canvasState = CanvasState();

      // Add a freehand stroke
      final stroke = FreehandStroke(color: Colors.blue, strokeWidth: 3.0);
      stroke.addPoint(const Offset(100, 100));
      stroke.addPoint(const Offset(120, 110));
      stroke.addPoint(const Offset(140, 120));
      stroke.addPoint(const Offset(160, 130));
      stroke.addPoint(const Offset(180, 125));
      stroke.addPoint(const Offset(200, 120));

      canvasState.freehandStrokes.add(stroke);

      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const NodeCanvas(),
        ),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'canvas_with_freehand_drawing');
    });
  });
}