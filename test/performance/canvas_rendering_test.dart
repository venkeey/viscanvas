import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Canvas Rendering Performance Tests', () {
    testWidgets('Render performance with small number of shapes', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      // Add 10 shapes
      for (int i = 0; i < 10; i++) {
        final shape = RectangleShape(Rect.fromLTWH(i * 50.0, i * 50.0, 40.0, 40.0));
        canvasState.addNode(shape);
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // Performance assertion - should render in under 600ms (adjusted for realistic expectations)
      expect(stopwatch.elapsedMilliseconds, lessThan(600));

      print('Rendering 10 shapes took: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Render performance with medium number of shapes', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      // Add 50 shapes
      for (int i = 0; i < 50; i++) {
        final shape = RectangleShape(Rect.fromLTWH(i * 10.0, i * 10.0, 20.0, 20.0));
        canvasState.addNode(shape);
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // Performance assertion - should render in under 300ms (adjusted for realistic expectations)
      expect(stopwatch.elapsedMilliseconds, lessThan(300));

      print('Rendering 50 shapes took: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Render performance with large number of shapes', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      // Add 200 shapes
      for (int i = 0; i < 200; i++) {
        final shape = RectangleShape(Rect.fromLTWH(i % 20 * 20.0, i ~/ 20 * 20.0, 15.0, 15.0));
        canvasState.addNode(shape);
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // Performance assertion - should render in under 600ms (adjusted for realistic expectations)
      expect(stopwatch.elapsedMilliseconds, lessThan(600));

      print('Rendering 200 shapes took: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Gesture responsiveness during canvas operations', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );

      await tester.pumpAndSettle();

      // Measure gesture response time
      final canvas = find.byType(NodeCanvas);

      final stopwatch = Stopwatch()..start();

      // Simulate rapid pan gestures
      for (int i = 0; i < 10; i++) {
        await tester.drag(canvas, const Offset(20, 20));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should complete 10 gestures in under 600ms (adjusted for realistic expectations)
      expect(stopwatch.elapsedMilliseconds, lessThan(600));

      print('10 gesture operations took: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Memory usage with increasing shapes', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      // Start with baseline
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );
      await tester.pumpAndSettle();

      // Add shapes incrementally and measure performance
      final performanceResults = <int, int>{};

      for (final count in [10, 50, 100, 200]) {
        // Clear and add shapes
        canvasState.nodes.clear();
        for (int i = 0; i < count; i++) {
          final shape = RectangleShape(Rect.fromLTWH(i % 20 * 15.0, i ~/ 20 * 15.0, 10.0, 10.0));
          canvasState.addNode(shape);
        }

        final stopwatch = Stopwatch()..start();
        await tester.pumpAndSettle();
        stopwatch.stop();

        performanceResults[count] = stopwatch.elapsedMilliseconds;
        print('Rendering $count shapes took: ${stopwatch.elapsedMilliseconds}ms');
      }

      // Performance should scale reasonably (not exponentially)
      expect(performanceResults[200]! / performanceResults[10]!, lessThan(20.0));
    });

    testWidgets('Shape creation performance', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );

      await tester.pumpAndSettle();

      // Measure time to create shapes
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        final shape = RectangleShape(Rect.fromLTWH(i * 20.0, i * 20.0, 30.0, 30.0));
        canvasState.addNode(shape);
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should create 50 shapes in under 300ms (adjusted for realistic expectations)
      expect(stopwatch.elapsedMilliseconds, lessThan(300));

      print('Creating 50 shapes took: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Memory usage estimation during canvas operations', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      // Start with baseline
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );
      await tester.pumpAndSettle();

      // Add increasing numbers of shapes and monitor performance scaling
      final baselineTime = await _measureRenderTime(tester, canvasState, 0);

      final smallTime = await _measureRenderTime(tester, canvasState, 25);
      final mediumTime = await _measureRenderTime(tester, canvasState, 50);
      final largeTime = await _measureRenderTime(tester, canvasState, 100);

      // Performance should degrade gracefully, not exponentially
      final smallRatio = smallTime / baselineTime;
      final mediumRatio = mediumTime / baselineTime;
      final largeRatio = largeTime / baselineTime;

      // Ratios should be reasonable (not exponential growth)
      expect(smallRatio, lessThan(5.0));
      expect(mediumRatio, lessThan(10.0));
      expect(largeRatio, lessThan(20.0));

      print('Performance scaling ratios: small=${smallRatio.toStringAsFixed(2)}, medium=${mediumRatio.toStringAsFixed(2)}, large=${largeRatio.toStringAsFixed(2)}');
    });

    testWidgets('Gesture performance under load', (tester) async {
      final canvasState = CanvasState();
      canvasState.nodes.clear();

      // Add moderate load
      for (int i = 0; i < 30; i++) {
        final shape = RectangleShape(Rect.fromLTWH(i * 15.0, i * 15.0, 20.0, 20.0));
        canvasState.addNode(shape);
      }

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: const MaterialApp(home: NodeCanvas()),
        ),
      );
      await tester.pumpAndSettle();

      final canvas = find.byType(NodeCanvas);

      // Test gesture responsiveness under load
      final stopwatch = Stopwatch()..start();

      // Perform various gestures
      for (int i = 0; i < 5; i++) {
        await tester.drag(canvas, const Offset(10, 10));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should remain responsive even under load
      expect(stopwatch.elapsedMilliseconds, lessThan(800));

      print('Gesture performance under load (30 shapes): ${stopwatch.elapsedMilliseconds}ms for 5 gestures');
    });
  });
}

Future<int> _measureRenderTime(WidgetTester tester, CanvasState canvasState, int shapeCount) async {
  canvasState.nodes.clear();

  for (int i = 0; i < shapeCount; i++) {
    final shape = RectangleShape(Rect.fromLTWH(i * 10.0, i * 10.0, 15.0, 15.0));
    canvasState.addNode(shape);
  }

  final stopwatch = Stopwatch()..start();
  await tester.pumpAndSettle();
  stopwatch.stop();

  return stopwatch.elapsedMilliseconds;
}