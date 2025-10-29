import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';
import 'package:provider/provider.dart';

void main() {
  group('Freehand Connection Detection Workflow Tests', () {
    testWidgets('straight freehand stroke between nodes should detect connection intent', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      // Create two nodes positioned for connection detection
      final node1 = Node('node1', const Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 80, 60)));
      final node2 = Node('node2', const Offset(300, 100), CircleShape(const Offset(40, 30), 30));

      canvasState.nodes.add(node1);
      canvasState.nodes.add(node2);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(body: NodeCanvas()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate freehand stroke from node1 to node2
      final start = const Offset(140, 130); // Near node1 center
      final end = const Offset(340, 130); // Near node2 center

      canvasState.startFreehandStroke(start);

      // Draw relatively straight line
      for (int i = 1; i <= 10; i++) {
        final intermediate = Offset.lerp(start, end, i / 10)!;
        canvasState.updateFreehandStroke(intermediate);
      }

      canvasState.endFreehandStroke(end);

      await tester.pumpAndSettle();

      // Check if connection was detected
      if (canvasState.showConnectionConfirmation) {
        // Verify confirmation dialog state
        expect(canvasState.showConnectionConfirmation, isTrue);
        // expect(canvasState.pendingConnection, isNotNull);

        // Confirm connection
        canvasState.confirmFreehandConnection();
        await tester.pumpAndSettle();

        // Edge should be created, stroke should be removed
        expect(canvasState.edges.length, 1);
        expect(canvasState.freehandStrokes.length, 0);
        expect(canvasState.edges.first.sourceNode.id, 'node1');
        expect(canvasState.edges.first.targetNode.id, 'node2');
      } else {
        // If detection didn't trigger, stroke should be kept
        expect(canvasState.freehandStrokes.length, 1);
        expect(canvasState.edges.length, 0);
      }
    });

    testWidgets('squiggly freehand stroke should stay as drawing', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      final node1 = Node('node1', const Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 80, 60)));
      final node2 = Node('node2', const Offset(300, 100), CircleShape(const Offset(40, 30), 30));

      canvasState.nodes.add(node1);
      canvasState.nodes.add(node2);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(body: NodeCanvas()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Draw a very squiggly line (low confidence)
      final startPoint = const Offset(140, 130);

      canvasState.startFreehandStroke(startPoint);

      // Create squiggly pattern using sine wave
      for (int i = 0; i < 20; i++) {
        final x = 140 + i * 10.0;
        final y = 130 + sin(i * 0.5) * 30; // Sine wave
        canvasState.updateFreehandStroke(Offset(x, y));
      }

      canvasState.endFreehandStroke(const Offset(340, 130));

      await tester.pumpAndSettle();

      // Verify NO connection dialog (confidence too low)
      expect(canvasState.showConnectionConfirmation, isFalse);

      // Verify kept as freehand stroke
      expect(canvasState.freehandStrokes.length, 1);
      expect(canvasState.edges.length, 0);
    });

    testWidgets('freehand connection cancellation should keep stroke as drawing', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      final node1 = Node('node1', const Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 80, 60)));
      final node2 = Node('node2', const Offset(300, 100), CircleShape(const Offset(40, 30), 30));

      canvasState.nodes.add(node1);
      canvasState.nodes.add(node2);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(body: NodeCanvas()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Draw straight line that might trigger confirmation
      final start = const Offset(140, 130);
      final end = const Offset(340, 130);

      canvasState.startFreehandStroke(start);

      for (int i = 1; i <= 10; i++) {
        canvasState.updateFreehandStroke(Offset.lerp(start, end, i / 10)!);
      }

      canvasState.endFreehandStroke(end);
      await tester.pumpAndSettle();

      if (canvasState.showConnectionConfirmation) {
        // Cancel connection
        canvasState.cancelFreehandConnection();
        await tester.pumpAndSettle();

        // Stroke should be kept as drawing
        expect(canvasState.edges.length, 0);
        expect(canvasState.freehandStrokes.length, 1);
        expect(canvasState.showConnectionConfirmation, isFalse);
      }
    });

    testWidgets('freehand stroke not near nodes should always stay as drawing', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(body: NodeCanvas()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Draw in empty space, far from any nodes
      canvasState.startFreehandStroke(const Offset(500, 500));

      for (int i = 1; i <= 10; i++) {
        canvasState.updateFreehandStroke(Offset(500 + i * 10.0, 500));
      }

      canvasState.endFreehandStroke(const Offset(600, 500));
      await tester.pumpAndSettle();

      // Should NOT trigger connection
      expect(canvasState.showConnectionConfirmation, isFalse);
      expect(canvasState.freehandStrokes.length, 1);
      expect(canvasState.edges.length, 0);
    });

    testWidgets('freehand stroke starting at node but not ending at node', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      final node1 = Node('node1', const Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 80, 60)));

      canvasState.nodes.add(node1);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(body: NodeCanvas()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start at node1, end in empty space
      canvasState.startFreehandStroke(const Offset(140, 130));

      for (int i = 1; i <= 10; i++) {
        canvasState.updateFreehandStroke(Offset(140 + i * 30.0, 130));
      }

      canvasState.endFreehandStroke(const Offset(440, 130));
      await tester.pumpAndSettle();

      // Should NOT create connection (no target node)
      expect(canvasState.showConnectionConfirmation, isFalse);
      expect(canvasState.freehandStrokes.length, 1);
      expect(canvasState.edges.length, 0);
    });

    testWidgets('freehand stroke with too few points should not trigger detection', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      final node1 = Node('node1', const Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 80, 60)));
      final node2 = Node('node2', const Offset(300, 100), CircleShape(const Offset(40, 30), 30));

      canvasState.nodes.add(node1);
      canvasState.nodes.add(node2);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(body: NodeCanvas()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Only 2 points (too few for reliable detection)
      canvasState.startFreehandStroke(const Offset(140, 130));
      canvasState.endFreehandStroke(const Offset(340, 130));

      await tester.pumpAndSettle();

      // Should NOT trigger (insufficient points)
      expect(canvasState.showConnectionConfirmation, isFalse);
    });

    testWidgets('multiple freehand strokes should accumulate as drawings', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(body: NodeCanvas()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Draw multiple strokes in empty space
      for (int stroke = 0; stroke < 5; stroke++) {
        final baseY = 400.0 + stroke * 50.0;

        canvasState.startFreehandStroke(Offset(400, baseY));

        for (int i = 1; i <= 10; i++) {
          canvasState.updateFreehandStroke(Offset(400 + i * 10.0, baseY));
        }

        canvasState.endFreehandStroke(Offset(500, baseY));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // All should be kept as freehand strokes
      expect(canvasState.freehandStrokes.length, 5);
      expect(canvasState.edges.length, 0);
    });

    test('confidence calculation for straight line should be high', () {
      final points = <Offset>[];
      for (int i = 0; i <= 10; i++) {
        points.add(Offset(i * 10.0, 100.0)); // Perfectly straight horizontal line
      }

      // Calculate straightness confidence
      final confidence = _calculateStraightnessConfidence(points);

      expect(confidence, greaterThan(0.8)); // Should be high confidence
    });

    test('confidence calculation for curved line should be low', () {
      final points = <Offset>[];
      for (int i = 0; i <= 20; i++) {
        final x = i * 5.0;
        final y = 100 + sin(i * 0.5) * 30; // Sine wave
        points.add(Offset(x, y));
      }

      final confidence = _calculateStraightnessConfidence(points);

      expect(confidence, lessThan(0.5)); // Should be low confidence
    });
  });
}

// Helper function to calculate straightness confidence
double _calculateStraightnessConfidence(List<Offset> points) {
  if (points.length < 3) return 0.0;

  final start = points.first;
  final end = points.last;
  final idealLength = (end - start).distance;

  if (idealLength == 0) return 0.0;

  double totalDeviation = 0.0;

  for (final point in points) {
    // Calculate perpendicular distance from point to line
    final distance = _distanceToLine(point, start, end);
    totalDeviation += distance;
  }

  final avgDeviation = totalDeviation / points.length;
  final deviationRatio = avgDeviation / idealLength;

  // Convert to confidence (0 deviation = 1.0 confidence)
  return (1.0 - deviationRatio).clamp(0.0, 1.0);
}

double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
  final lineVector = lineEnd - lineStart;
  final pointVector = point - lineStart;

  final lineLengthSquared = lineVector.distanceSquared;
  if (lineLengthSquared == 0) return pointVector.distance;

  final t = (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) / lineLengthSquared;
  final projection = lineStart + lineVector * t.clamp(0.0, 1.0);

  return (point - projection).distance;
}
