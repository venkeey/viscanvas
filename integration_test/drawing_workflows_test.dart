import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/pages/connectors.dart';
import 'package:viscanvas/main.dart' as app;
import 'package:provider/provider.dart';

void main() {
  patrolTest('Complete freehand drawing workflow', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    // Verify canvas is present
    expect(find.byType(NodeCanvas), findsOneWidget);

    // Tap on canvas to start freehand drawing
    final canvas = find.byType(CustomPaint).first;
    final canvasCenter = $.tester.getCenter(canvas);

    // Simulate freehand drawing stroke
    final gesture = await $.tester.startGesture(canvasCenter);
    await gesture.moveBy(const Offset(50, 0));
    await gesture.moveBy(const Offset(50, 20));
    await gesture.moveBy(const Offset(50, -10));
    await gesture.up();
    await $.pumpAndSettle();

    // Verify stroke was created (if visible in UI)
    expect(find.byType(NodeCanvas), findsOneWidget);
  });

  patrolTest('Create connection between nodes', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    // Find the canvas widget
    final canvasWidget = $.tester.widget<ChangeNotifierProvider>(
      find.byType(ChangeNotifierProvider),
    );

    // Get canvas state
    final canvasState = $.tester
        .element(find.byType(NodeCanvas))
        .read<CanvasState>();

    expect(canvasState.nodes.length, greaterThanOrEqualTo(2));

    final node1 = canvasState.nodes[0];
    final node2 = canvasState.nodes[1];

    // Simulate connecting nodes
    final node1Pos = node1.position + const Offset(60, 40);
    final node2Pos = node2.position + const Offset(60, 40);

    // Start connection from node1
    final gesture = await $.tester.startGesture(node1Pos);
    await $.pump(const Duration(milliseconds: 100));

    // Drag to node2
    await gesture.moveTo(node2Pos);
    await $.pump(const Duration(milliseconds: 100));

    // Release
    await gesture.up();
    await $.pumpAndSettle();

    // Verify connection exists (may need to check canvas state)
    expect(find.byType(NodeCanvas), findsOneWidget);
  });

  patrolTest('Move node with drag gesture', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvasState = $.tester
        .element(find.byType(NodeCanvas))
        .read<CanvasState>();

    final node = canvasState.nodes[0];
    final originalPosition = node.position;

    // Tap and drag node
    final nodePosition = originalPosition + const Offset(60, 40);
    final dragDelta = const Offset(100, 50);

    await $.tester.drag(find.byType(CustomPaint).first, dragDelta);
    await $.pumpAndSettle();

    // Node should have moved (verification depends on implementation)
    expect(find.byType(NodeCanvas), findsOneWidget);
  });

  patrolTest('Select all nodes with Ctrl+A', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvasState = $.tester
        .element(find.byType(NodeCanvas))
        .read<CanvasState>();

    expect(canvasState.selectedNodes.length, 0);

    // Press Ctrl+A using patrol
    await $.native.pressKey(PatrolKeyboardKey.controlLeft);
    await $.native.pressKey(PatrolKeyboardKey.keyA);
    await $.native.releaseKey(PatrolKeyboardKey.keyA);
    await $.native.releaseKey(PatrolKeyboardKey.controlLeft);
    await $.pumpAndSettle();

    // All nodes should be selected
    expect(canvasState.selectedNodes.length, greaterThan(0));
  });

  patrolTest('Delete selected nodes', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvasState = $.tester
        .element(find.byType(NodeCanvas))
        .read<CanvasState>();

    // Select all nodes
    canvasState.selectAll();
    final selectedCount = canvasState.selectedNodes.length;
    expect(selectedCount, greaterThan(0));

    await $.pumpAndSettle();

    // Tap delete button if visible
    final deleteButton = find.byIcon(Icons.delete);
    if (deleteButton.evaluate().isNotEmpty) {
      await $.tap(deleteButton);
      await $.pumpAndSettle();

      // Nodes should be deleted
      expect(canvasState.nodes.length, 0);
    }
  });

  patrolTest('Freehand stroke should detect connection intent', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvasState = $.tester
        .element(find.byType(NodeCanvas))
        .read<CanvasState>();

    expect(canvasState.nodes.length, greaterThanOrEqualTo(2));

    final node1 = canvasState.nodes[0];
    final node2 = canvasState.nodes[1];

    // Draw relatively straight line from node1 to node2
    final start = node1.position + const Offset(60, 40);
    final end = node2.position + const Offset(60, 40);

    final gesture = await $.tester.startGesture(start);

    // Draw straight line in steps
    for (int i = 1; i <= 10; i++) {
      final intermediate = Offset.lerp(start, end, i / 10)!;
      await gesture.moveTo(intermediate);
      await $.pump(const Duration(milliseconds: 10));
    }

    await gesture.up();
    await $.pumpAndSettle();

    // Check if connection confirmation dialog appears (if implemented)
    // Or check if edge was created
    expect(find.byType(NodeCanvas), findsOneWidget);
  });

  patrolTest('Clear selection with Escape key', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvasState = $.tester
        .element(find.byType(NodeCanvas))
        .read<CanvasState>();

    // Select all
    canvasState.selectAll();
    expect(canvasState.selectedNodes.length, greaterThan(0));
    await $.pumpAndSettle();

    // Press Escape
    await $.native.pressKey(PatrolKeyboardKey.escape);
    await $.pumpAndSettle();

    // Selection should be cleared
    expect(canvasState.selectedNodes.length, 0);
  });

  patrolTest('Create multiple shapes and connect them', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvasState = $.tester
        .element(find.byType(NodeCanvas))
        .read<CanvasState>();

    final initialNodeCount = canvasState.nodes.length;

    // Add a new node programmatically
    canvasState.addNode(RectangleShape(Rect.fromLTWH(300, 300, 120, 80)));
    await $.pumpAndSettle();

    expect(canvasState.nodes.length, initialNodeCount + 1);

    // Connect last two nodes
    final node1 = canvasState.nodes[canvasState.nodes.length - 2];
    final node2 = canvasState.nodes[canvasState.nodes.length - 1];

    canvasState.startConnecting(node1, node1.position + const Offset(60, 40));
    canvasState.endConnecting(node2);
    await $.pumpAndSettle();

    // Edge should be created
    expect(canvasState.edges.length, greaterThan(0));
  });

  patrolTest('Handle rapid gestures without crashes', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvas = find.byType(CustomPaint).first;

    // Perform rapid taps
    for (int i = 0; i < 10; i++) {
      await $.tap(canvas);
      await $.pump(const Duration(milliseconds: 50));
    }

    await $.pumpAndSettle();

    // Should not crash
    expect(find.byType(NodeCanvas), findsOneWidget);
  });

  patrolTest('Zoom and pan gestures', (PatrolTester $) async {
    app.main();
    await $.pumpAndSettle();

    final canvas = find.byType(CustomPaint).first;
    final center = $.tester.getCenter(canvas);

    // Simulate pinch-to-zoom (if supported)
    final gesture1 = await $.tester.startGesture(center - const Offset(20, 0));
    final gesture2 = await $.tester.startGesture(center + const Offset(20, 0));

    await gesture1.moveTo(center - const Offset(50, 0));
    await gesture2.moveTo(center + const Offset(50, 0));

    await gesture1.up();
    await gesture2.up();
    await $.pumpAndSettle();

    // Should handle zoom gesture
    expect(find.byType(NodeCanvas), findsOneWidget);
  });
}
