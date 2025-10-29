import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/models/canvas_objects/canvas_circle.dart';
import 'package:viscanvas/models/canvas_objects/canvas_rectangle.dart';
import 'package:viscanvas/models/canvas_objects/connector.dart';

void main() {
  group('Connector Handles', () {
    late CanvasRectangle sourceRect;
    late CanvasCircle targetCircle;
    late Connector connector;

    setUp(() {
      sourceRect = CanvasRectangle(
        id: 'rect1',
        worldPosition: const Offset(100, 100),
        size: const Size(100, 100),
        strokeColor: Colors.black,
      );
      targetCircle = CanvasCircle(
        id: 'circle1',
        worldPosition: const Offset(300, 100),
        radius: 50,
        strokeColor: Colors.black,
      );
      connector = Connector(
        id: 'conn1',
        sourceObject: sourceRect,
        targetObject: targetCircle,
        sourcePoint: sourceRect.getBoundingRect().center,
        targetPoint: targetCircle.getBoundingRect().center,
        strokeColor: Colors.black,
        strokeWidth: 2.0,
      );
    });

    test('should provide handle positions', () {
      expect(connector.startHandle, equals(connector.sourcePoint));
      expect(connector.endHandle, equals(connector.targetPoint));
      
      // Quarter handles should be calculated at 25% and 75% of the path
      final firstQuarterHandle = connector.firstQuarterHandle;
      final thirdQuarterHandle = connector.thirdQuarterHandle;
      
      expect(firstQuarterHandle, isNotNull);
      expect(thirdQuarterHandle, isNotNull);
      
      // For the simple fallback, handles should be positioned between source and target
      expect(firstQuarterHandle.dx, greaterThanOrEqualTo(connector.sourcePoint.dx));
      expect(firstQuarterHandle.dx, lessThanOrEqualTo(connector.targetPoint.dx));
      expect(thirdQuarterHandle.dx, greaterThanOrEqualTo(connector.sourcePoint.dx));
      expect(thirdQuarterHandle.dx, lessThanOrEqualTo(connector.targetPoint.dx));
    });

    test('should update curvature scale', () {
      final originalScale = connector.curvatureScale;
      connector.curvatureScale = 2.0;
      expect(connector.curvatureScale, equals(2.0));
      connector.invalidatePathCache(); // Ensure path is recomputed
    });
  });
}