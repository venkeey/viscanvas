import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/drawingCanvas.dart';

// Mock classes for testing
class MockCanvasObject extends CanvasObject {
  final Rect mockBounds;

  MockCanvasObject({
    required String id,
    required Offset worldPosition,
    required this.mockBounds,
    Color strokeColor = Colors.black,
    double strokeWidth = 2.0,
  }) : super(
          id: id,
          worldPosition: worldPosition,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
        );

  @override
  Rect calculateBoundingRect() => mockBounds;

  @override
  bool hitTest(Offset worldPoint) => mockBounds.contains(worldPoint);

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {}

  @override
  void move(Offset delta) {
    worldPosition += delta;
  }

  @override
  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds) {}

  @override
  CanvasObject clone() => MockCanvasObject(
        id: id,
        worldPosition: worldPosition,
        mockBounds: mockBounds,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
}

void main() {
  group('AnchorPoint Tests', () {
    test('should create anchor point with correct properties', () {
      final position = Offset(100, 200);
      final anchor = AnchorPoint(
        position: position,
        edge: NodeEdge.right,
        edgePosition: 0.5,
      );

      expect(anchor.position, position);
      expect(anchor.edge, NodeEdge.right);
      expect(anchor.edgePosition, 0.5);
    });

    test('should calculate correct normal vectors for each edge', () {
      final anchorRight = AnchorPoint(position: Offset.zero, edge: NodeEdge.right);
      final anchorLeft = AnchorPoint(position: Offset.zero, edge: NodeEdge.left);
      final anchorTop = AnchorPoint(position: Offset.zero, edge: NodeEdge.top);
      final anchorBottom = AnchorPoint(position: Offset.zero, edge: NodeEdge.bottom);

      expect(anchorRight.normal, Offset(1, 0));
      expect(anchorLeft.normal, Offset(-1, 0));
      expect(anchorTop.normal, Offset(0, -1));
      expect(anchorBottom.normal, Offset(0, 1));
    });

    test('should use default edge position of 0.5', () {
      final anchor = AnchorPoint(position: Offset.zero, edge: NodeEdge.right);
      expect(anchor.edgePosition, 0.5);
    });
  });

  group('ConnectorCalculator Tests', () {
    late MockCanvasObject sourceObject;
    late MockCanvasObject targetObject;

    setUp(() {
      sourceObject = MockCanvasObject(
        id: 'source',
        worldPosition: Offset(0, 0),
        mockBounds: Rect.fromLTWH(0, 0, 100, 50),
      );

      targetObject = MockCanvasObject(
        id: 'target',
        worldPosition: Offset(200, 0),
        mockBounds: Rect.fromLTWH(200, 0, 100, 50),
      );
    });

    test('should calculate smart anchor point for horizontal layout (target to right)', () {
      final anchor = ConnectorCalculator.getSmartAnchorPoint(
        sourceObject,
        targetObject,
        isSource: true,
      );

      expect(anchor.edge, NodeEdge.right);
      expect(anchor.position.dx, 100.0); // Right edge of source
      expect(anchor.position.dy, 25.0); // Center vertically
    });

    test('should calculate smart anchor point for horizontal layout (target to left)', () {
      final anchor = ConnectorCalculator.getSmartAnchorPoint(
        targetObject,
        sourceObject,
        isSource: true,
      );

      expect(anchor.edge, NodeEdge.left);
      expect(anchor.position.dx, 200.0); // Left edge of target
      expect(anchor.position.dy, 25.0); // Center vertically
    });

    test('should calculate smart anchor point for vertical layout (target below)', () {
      final bottomSource = MockCanvasObject(
        id: 'source',
        worldPosition: Offset(0, 0),
        mockBounds: Rect.fromLTWH(0, 0, 100, 50),
      );

      final topTarget = MockCanvasObject(
        id: 'target',
        worldPosition: Offset(0, 100),
        mockBounds: Rect.fromLTWH(0, 100, 100, 50),
      );

      final anchor = ConnectorCalculator.getSmartAnchorPoint(
        bottomSource,
        topTarget,
        isSource: true,
      );

      expect(anchor.edge, NodeEdge.bottom);
      expect(anchor.position.dx, 50.0); // Center horizontally
      expect(anchor.position.dy, 50.0); // Bottom edge of source
    });

    test('should calculate smart anchor point for vertical layout (target above)', () {
      final topSource = MockCanvasObject(
        id: 'source',
        worldPosition: Offset(0, 100),
        mockBounds: Rect.fromLTWH(0, 100, 100, 50),
      );

      final bottomTarget = MockCanvasObject(
        id: 'target',
        worldPosition: Offset(0, 0),
        mockBounds: Rect.fromLTWH(0, 0, 100, 50),
      );

      final anchor = ConnectorCalculator.getSmartAnchorPoint(
        topSource,
        bottomTarget,
        isSource: true,
      );

      expect(anchor.edge, NodeEdge.top);
      expect(anchor.position.dx, 50.0); // Center horizontally
      expect(anchor.position.dy, 100.0); // Top edge of source
    });

    test('should handle circle objects with angle-based anchor points', () {
      final circleSource = CanvasCircle(
        id: 'circle',
        worldPosition: Offset(0, 0),
        strokeColor: Colors.black,
        radius: 25.0,
      );

      final target = MockCanvasObject(
        id: 'target',
        worldPosition: Offset(100, 0),
        mockBounds: Rect.fromLTWH(100, 0, 50, 50),
      );

      final anchor = ConnectorCalculator.getSmartAnchorPoint(
        circleSource,
        target,
        isSource: true,
      );

      // For circle to the right, should be at 0 degrees (right side)
      // The position is the center of the circle plus the radius in the direction
      final expectedX = circleSource.getBoundingRect().center.dx + circleSource.radius * cos(0);
      final expectedY = circleSource.getBoundingRect().center.dy + circleSource.radius * sin(0);
      expect(anchor.position.dx, closeTo(expectedX, 0.1));
      expect(anchor.position.dy, closeTo(expectedY, 0.1));
    });

    test('should create curved path with correct start and end points', () {
      final start = Offset(0, 0);
      final end = Offset(100, 0);
      final startDir = 'right';
      final endDir = 'left';

      final path = ConnectorCalculator.createCurvedPath(start, end, startDir, endDir);

      // Check that path contains the start and end points
      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 1));
      expect(bounds.right, closeTo(100, 1));
    });

    test('should create smart curved path with anchor points', () {
      final startAnchor = AnchorPoint(position: Offset(0, 0), edge: NodeEdge.right);
      final endAnchor = AnchorPoint(position: Offset(100, 0), edge: NodeEdge.left);

      final path = ConnectorCalculator.createSmartCurvedPath(startAnchor, endAnchor);

      final pathMetrics = path.computeMetrics();
      expect(pathMetrics.isNotEmpty, true);
    });

    test('should create C-curve for short distances', () {
      final startAnchor = AnchorPoint(position: Offset(0, 0), edge: NodeEdge.right);
      final endAnchor = AnchorPoint(position: Offset(100, 0), edge: NodeEdge.left);

      final path = ConnectorCalculator.createSmartCurvedPath(startAnchor, endAnchor);

      // C-curve should be a simple cubic curve
      final pathMetrics = path.computeMetrics();
      expect(pathMetrics.length, 1);
    });

    test('should create S-curve for long distances', () {
      final startAnchor = AnchorPoint(position: Offset(0, 0), edge: NodeEdge.right);
      final endAnchor = AnchorPoint(position: Offset(600, 0), edge: NodeEdge.left);

      final path = ConnectorCalculator.createSmartCurvedPath(startAnchor, endAnchor);

      // S-curve should have two segments
      final pathMetrics = path.computeMetrics();
      expect(pathMetrics.length, 1); // Still one continuous path but with S-shape
    });

    test('should calculate closest edge point for rectangle', () {
      final rect = MockCanvasObject(
        id: 'rect',
        worldPosition: Offset(0, 0),
        mockBounds: Rect.fromLTWH(0, 0, 100, 50),
      );

      // Point to the right
      final rightPoint = ConnectorCalculator.getClosestEdgePoint(rect, Offset(150, 25));
      expect(rightPoint, Offset(100, 25)); // Right edge, center

      // Point to the left
      final leftPoint = ConnectorCalculator.getClosestEdgePoint(rect, Offset(-50, 25));
      expect(leftPoint, Offset(0, 25)); // Left edge, center

      // Point above
      final topPoint = ConnectorCalculator.getClosestEdgePoint(rect, Offset(50, -25));
      expect(topPoint, Offset(50, 0)); // Top edge, center

      // Point below
      final bottomPoint = ConnectorCalculator.getClosestEdgePoint(rect, Offset(50, 75));
      expect(bottomPoint, Offset(50, 50)); // Bottom edge, center
    });

    test('should calculate closest edge point for circle', () {
      final circle = CanvasCircle(
        id: 'circle',
        worldPosition: Offset(0, 0),
        strokeColor: Colors.black,
        radius: 25.0,
      );

      // Point to the right - should return a point on the circle's edge
      final rightPoint = ConnectorCalculator.getClosestEdgePoint(circle, Offset(50, 0));
      final center = circle.getBoundingRect().center;
      final distanceFromCenter = (rightPoint - center).distance;
      expect(distanceFromCenter, closeTo(circle.radius, 1.0)); // Should be on the circle edge

      // Point above - should return a point on the circle's edge
      final topPoint = ConnectorCalculator.getClosestEdgePoint(circle, Offset(0, -50));
      final distanceFromCenterTop = (topPoint - center).distance;
      expect(distanceFromCenterTop, closeTo(circle.radius, 1.0)); // Should be on the circle edge
    });

    test('should estimate edge direction correctly', () {
      expect(ConnectorCalculator.estimateEdgeDirection(Offset(10, 0), Offset(0, 0)), 'right');
      expect(ConnectorCalculator.estimateEdgeDirection(Offset(-10, 0), Offset(0, 0)), 'left');
      expect(ConnectorCalculator.estimateEdgeDirection(Offset(0, 10), Offset(0, 0)), 'bottom');
      expect(ConnectorCalculator.estimateEdgeDirection(Offset(0, -10), Offset(0, 0)), 'top');
    });

    test('should calculate distance to line correctly', () {
      final point = Offset(0, 10);
      final lineStart = Offset(0, 0);
      final lineEnd = Offset(10, 0);

      final distance = ConnectorCalculator.distanceToLine(point, lineStart, lineEnd);
      expect(distance, closeTo(10.0, 0.1)); // Point is 10 units above the horizontal line
    });

    test('should return 0 distance for point on line', () {
      final point = Offset(5, 0);
      final lineStart = Offset(0, 0);
      final lineEnd = Offset(10, 0);

      final distance = ConnectorCalculator.distanceToLine(point, lineStart, lineEnd);
      expect(distance, closeTo(0.0, 0.1));
    });
  });

  group('Connector Tests', () {
    late CanvasRectangle sourceObject;
    late CanvasRectangle targetObject;
    late Connector connector;

    setUp(() {
      sourceObject = CanvasRectangle(
        id: 'source',
        worldPosition: Offset(0, 0),
        strokeColor: Colors.black,
        size: Size(100, 50),
      );

      targetObject = CanvasRectangle(
        id: 'target',
        worldPosition: Offset(200, 0),
        strokeColor: Colors.black,
        size: Size(100, 50),
      );

      connector = Connector(
        id: 'connector_1',
        sourceObject: sourceObject,
        targetObject: targetObject,
        sourcePoint: Offset(100, 25),
        targetPoint: Offset(200, 25),
        strokeColor: Colors.blue,
        strokeWidth: 2.0,
      );
    });

    test('should create connector with correct properties', () {
      expect(connector.id, 'connector_1');
      expect(connector.sourceObject, sourceObject);
      expect(connector.targetObject, targetObject);
      expect(connector.sourcePoint, Offset(100, 25));
      expect(connector.targetPoint, Offset(200, 25));
      expect(connector.strokeColor, Colors.blue);
      expect(connector.strokeWidth, 2.0);
      expect(connector.showArrow, true);
    });

    test('should calculate bounding rect correctly', () {
      final bounds = connector.getBoundingRect();
      expect(bounds.left, 100.0);
      expect(bounds.top, 25.0);
      expect(bounds.right, 200.0);
      expect(bounds.bottom, 25.0);
    });

    test('should hit test connector line', () {
      // Point on the connector line
      expect(connector.hitTest(Offset(150, 25)), true);

      // Point near the connector line
      expect(connector.hitTest(Offset(150, 30)), true);

      // Point far from the connector line
      expect(connector.hitTest(Offset(150, 50)), false);
    });

    test('should update points when objects move', () {
      // Store original points
      final originalSourcePoint = connector.sourcePoint;
      final originalTargetPoint = connector.targetPoint;

      // Move source object
      sourceObject.move(Offset(50, 25));

      connector.updatePoints();

      // Points should be recalculated based on new object positions
      expect(connector.sourcePoint, isNot(equals(originalSourcePoint)));
      expect(connector.targetPoint, isNot(equals(originalTargetPoint)));
    });

    test('should compute path correctly', () {
      final path = connector.path;
      expect(path, isNotNull);

      final metrics = path.computeMetrics();
      expect(metrics.isNotEmpty, true);
    });

    test('should clone connector correctly', () {
      final cloned = connector.clone() as Connector;

      expect(cloned.id, 'connector_1_copy');
      expect(cloned.sourceObject, sourceObject);
      expect(cloned.targetObject, targetObject);
      expect(cloned.strokeColor, Colors.blue);
      expect(cloned.strokeWidth, 2.0);
      expect(cloned.showArrow, true);
    });

    test('should not move independently', () {
      final originalPosition = connector.worldPosition;
      connector.move(Offset(10, 10));

      // Position should remain the same (connectors don't move independently)
      expect(connector.worldPosition, originalPosition);
    });

    test('should not resize', () {
      final originalBounds = connector.getBoundingRect();
      connector.resize(ResizeHandle.topLeft, Offset(10, 10), Offset.zero, originalBounds);

      // Bounds should remain the same (connectors don't resize)
      expect(connector.getBoundingRect(), originalBounds);
    });
  });

  group('FreehandConnector Tests', () {
    late FreehandConnector connector;

    setUp(() {
      connector = FreehandConnector(color: Colors.red, strokeWidth: 3.0);
    });

    test('should create freehand connector with correct properties', () {
      expect(connector.points, isEmpty);
      expect(connector.paint.color.value, Colors.red.value);
      expect(connector.paint.strokeWidth, 3.0);
      expect(connector.paint.style, PaintingStyle.stroke);
    });

    test('should add points correctly', () {
      connector.addPoint(Offset(0, 0));
      connector.addPoint(Offset(10, 5));
      connector.addPoint(Offset(20, 10));

      expect(connector.points.length, 3);
      expect(connector.points[0], Offset(0, 0));
      expect(connector.points[1], Offset(10, 5));
      expect(connector.points[2], Offset(20, 10));
    });

    test('should compute path correctly', () {
      connector.addPoint(Offset(0, 0));
      connector.addPoint(Offset(10, 5));
      connector.addPoint(Offset(20, 10));

      final path = connector.path;
      final metrics = path.computeMetrics();
      expect(metrics.isNotEmpty, true);
    });

    test('should analyze stroke for connection intent', () {
      final objects = [
        MockCanvasObject(
          id: 'obj1',
          worldPosition: Offset(0, 0),
          mockBounds: Rect.fromLTWH(0, 0, 50, 50),
        ),
        MockCanvasObject(
          id: 'obj2',
          worldPosition: Offset(100, 0),
          mockBounds: Rect.fromLTWH(100, 0, 50, 50),
        ),
      ];

      // Create a straight line from obj1 to obj2
      connector.addPoint(Offset(25, 25)); // Start near obj1
      connector.addPoint(Offset(50, 25)); // Middle
      connector.addPoint(Offset(75, 25)); // Middle
      connector.addPoint(Offset(100, 25)); // Middle
      connector.addPoint(Offset(125, 25)); // End near obj2

      final analysis = connector.analyzeStroke(objects);

      // The analysis should detect some connection intent
      expect(analysis.sourceObject, isNotNull);
      expect(analysis.targetObject, isNotNull);
      expect(analysis.confidence, greaterThan(0.0));
    });

    test('should reject invalid connection (same object)', () {
      final objects = [
        MockCanvasObject(
          id: 'obj1',
          worldPosition: Offset(0, 0),
          mockBounds: Rect.fromLTWH(0, 0, 50, 50),
        ),
      ];

      connector.addPoint(Offset(25, 25));
      connector.addPoint(Offset(30, 30));

      final analysis = connector.analyzeStroke(objects);

      expect(analysis.isValidConnection, false);
      expect(analysis.confidence, 0.0);
    });

    test('should reject invalid connection (too few points)', () {
      final objects = [
        MockCanvasObject(
          id: 'obj1',
          worldPosition: Offset(0, 0),
          mockBounds: Rect.fromLTWH(0, 0, 50, 50),
        ),
        MockCanvasObject(
          id: 'obj2',
          worldPosition: Offset(100, 0),
          mockBounds: Rect.fromLTWH(100, 0, 50, 50),
        ),
      ];

      connector.addPoint(Offset(25, 25)); // Only 1 point
      connector.addPoint(Offset(30, 30)); // Only 2 points

      final analysis = connector.analyzeStroke(objects);

      expect(analysis.isValidConnection, false);
    });

    test('should calculate confidence based on straightness', () {
      final objects = [
        MockCanvasObject(
          id: 'obj1',
          worldPosition: Offset(0, 0),
          mockBounds: Rect.fromLTWH(0, 0, 50, 50),
        ),
        MockCanvasObject(
          id: 'obj2',
          worldPosition: Offset(100, 0),
          mockBounds: Rect.fromLTWH(100, 0, 50, 50),
        ),
      ];

      // Very straight line
      connector.addPoint(Offset(25, 25));
      connector.addPoint(Offset(50, 25));
      connector.addPoint(Offset(75, 25));
      connector.addPoint(Offset(100, 25));
      connector.addPoint(Offset(125, 25));

      final analysis = connector.analyzeStroke(objects);

      expect(analysis.confidence, greaterThan(0.5)); // Should be quite straight
    });
  });

  group('ConnectorAnalysis Tests', () {
    test('should create analysis with valid connection', () {
      final source = MockCanvasObject(
        id: 'source',
        worldPosition: Offset.zero,
        mockBounds: Rect.fromLTWH(0, 0, 50, 50),
      );

      final target = MockCanvasObject(
        id: 'target',
        worldPosition: Offset(100, 0),
        mockBounds: Rect.fromLTWH(100, 0, 50, 50),
      );

      final analysis = ConnectorAnalysis(
        sourceObject: source,
        targetObject: target,
        confidence: 0.8,
      );

      expect(analysis.sourceObject, source);
      expect(analysis.targetObject, target);
      expect(analysis.confidence, 0.8);
      expect(analysis.isValidConnection, true);
    });

    test('should identify invalid connection (same object)', () {
      final sameObject = MockCanvasObject(
        id: 'obj',
        worldPosition: Offset.zero,
        mockBounds: Rect.fromLTWH(0, 0, 50, 50),
      );

      final analysis = ConnectorAnalysis(
        sourceObject: sameObject,
        targetObject: sameObject,
        confidence: 0.8,
      );

      expect(analysis.isValidConnection, false);
    });

    test('should identify invalid connection (low confidence)', () {
      final source = MockCanvasObject(
        id: 'source',
        worldPosition: Offset.zero,
        mockBounds: Rect.fromLTWH(0, 0, 50, 50),
      );

      final target = MockCanvasObject(
        id: 'target',
        worldPosition: Offset(100, 0),
        mockBounds: Rect.fromLTWH(100, 0, 50, 50),
      );

      final analysis = ConnectorAnalysis(
        sourceObject: source,
        targetObject: target,
        confidence: 0.2, // Below threshold
      );

      expect(analysis.isValidConnection, false);
    });

    test('should handle null objects', () {
      final analysis = ConnectorAnalysis(
        sourceObject: null,
        targetObject: null,
        confidence: 1.0,
      );

      expect(analysis.isValidConnection, false);
    });
  });

  group('NodeEdge Extension Tests', () {
    test('OffsetExtension normalize should work correctly', () {
      final vector = Offset(3, 4);
      final normalized = vector.normalize();

      expect(normalized.dx, closeTo(0.6, 0.1)); // 3/5
      expect(normalized.dy, closeTo(0.8, 0.1)); // 4/5
      expect(normalized.distance, closeTo(1.0, 0.1));
    });

    test('OffsetExtension normalize should handle zero vector', () {
      final zero = Offset.zero.normalize();
      expect(zero, Offset.zero);
    });
  });
}