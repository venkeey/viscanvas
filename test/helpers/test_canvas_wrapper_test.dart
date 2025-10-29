import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';
import 'test_canvas_wrapper.dart';

void main() {
  group('TestCanvasWrapper', () {
    testWidgets('should create canvas wrapper with default size', (tester) async {
      await tester.pumpWidget(TestCanvasWrapper(child: Container()));

      expect(find.byType(TestCanvasWrapper), findsOneWidget);
    });

    testWidgets('should create canvas wrapper with custom size', (tester) async {
      const customSize = Size(1200, 800);
      await tester.pumpWidget(TestCanvasWrapper(
        child: Container(),
        canvasSize: customSize,
      ));

      expect(find.byType(TestCanvasWrapper), findsOneWidget);
    });
  });

  group('CanvasTestHelper', () {
    test('should create test rectangle', () {
      final rect = CanvasTestDataFactory.createTestRectangle();

      expect(rect.type, 'rectangle');
      expect(rect.bounds.width, 120.0);
      expect(rect.bounds.height, 80.0);
    });

    test('should create test circle', () {
      final circle = CanvasTestDataFactory.createTestCircle();

      expect(circle.type, 'circle');
      expect(circle.radius, 60.0);
    });

    test('should create test triangle', () {
      final triangle = CanvasTestDataFactory.createTestTriangle();

      expect(triangle.type, 'triangle');
      expect(triangle.size, 60.0);
    });

    test('should create canvas state with shapes', () {
      final shapes = [
        CanvasTestDataFactory.createTestRectangle(),
        CanvasTestDataFactory.createTestCircle(),
      ];

      final canvasState = CanvasTestHelper.createCanvasWithShapes(shapes: shapes);

      expect(canvasState.nodes.length, 2);
      expect(canvasState.nodes[0].shape.type, 'rectangle');
      expect(canvasState.nodes[1].shape.type, 'circle');
    });
  });
}