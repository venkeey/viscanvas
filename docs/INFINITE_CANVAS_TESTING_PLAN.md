# Comprehensive UX Testing Implementation Plan
## Flutter Infinite Canvas App Testing Framework - Advanced Edition

### Executive Summary
This implementation plan outlines a systematic approach to building a comprehensive automated testing framework for a Flutter infinite canvas application. The plan covers unit, widget, integration, and UX testing across desktop, mobile, and web platforms, with special focus on complex canvas interactions like drawing tools, shape manipulation, connectors, freehand drawing, real-time collaboration, and infinite canvas navigation.

**Key Enhancements from Trading App Testing Learnings:**
- Property-based testing for canvas operations
- AI-powered test generation for interaction scenarios
- Advanced visual regression with ML capabilities
- Security testing for collaborative features
- Mutation testing for critical canvas logic
- Enhanced accessibility testing for shape manipulation

---

## Phase 0: Framework Selection Strategy (Pre-Implementation)

### 0.1 Core Testing Stack (Non-Conflicting)
```yaml
# Recommended framework combination - tested for compatibility
core_stack:
  unit_widget: "flutter_test"        # Built-in, always use
  integration: "patrol"              # Advanced integration with native APIs
  visual: "flutter_golden_toolkit"   # Primary visual testing
  mocking: "mocktail"                # Null-safe mocking
  
specialized_tools:
  contract_testing: "pact"           # If backend integration exists
  performance: "custom_benchmarks"   # Canvas-specific metrics
  accessibility: "flutter_test"      # Built-in semantic testing
  
infrastructure:
  ci_cd: "github_actions"
  parallel_execution: "flank"        # When test suite grows
  analytics: "custom_prometheus"     # Test metrics tracking
```

### 0.2 Framework Compatibility Matrix
| Framework | Works With | Conflicts With | Use Case |
|-----------|-----------|----------------|----------|
| Patrol | flutter_test, mocktail | integration_test (partial) | Advanced integration |
| Golden Toolkit | All frameworks | None (complementary) | Visual regression |
| Mocktail | All frameworks | mockito (choose one) | Enhanced mocking |
| Pact | Any framework | None | Contract testing |

**Decision Rule:** One framework per testing layer. No duplicate functionality unless in migration period or regulatory requirements.

---

## Phase 1: Foundation Setup (Weeks 1-2)

### 1.1 Environment Setup
```yaml
# pubspec.yaml dependencies
dev_dependencies:
  flutter_test: ^1.0.0
  integration_test: ^1.0.0
  patrol: ^3.0.0                     # Advanced integration testing
  mocktail: ^1.0.0                   # Null-safe mocking
  flutter_golden_toolkit: ^0.15.0    # Visual regression
  test_coverage: ^0.2.0
  fake_async: ^1.3.0                 # Time-based testing
  dart_check: ^0.5.0                 # Property-based testing (NEW)
  flutter_test_accessibility: ^1.0.0 # Accessibility testing (NEW)
```

### 1.2 Directory Structure
```
test/
├── unit/
│   ├── domain/
│   │   ├── canvas_objects/
│   │   ├── tools/
│   │   ├── transforms/
│   │   └── events/
│   ├── services/
│   │   ├── persistence/
│   │   ├── rendering/
│   │   └── collaboration/
│   └── utils/
├── widget/
│   ├── canvas/
│   ├── tools/
│   ├── sidebar/
│   ├── shapes/
│   └── connectors/
├── integration/
│   ├── patrol/
│   ├── drawing_workflows/
│   ├── shape_manipulation/
│   └── collaboration/
├── visual/
│   ├── golden/
│   └── screenshots/
├── performance/
│   ├── rendering/
│   ├── memory/
│   └── gestures/
└── helpers/
    ├── test_data/
    ├── mocks/
    └── utilities/
```

### 1.3 Test Infrastructure Setup
- [ ] Create `TestCanvasWrapper` for consistent test environment
- [ ] Set up mock services for canvas persistence
- [ ] Configure test data factories for canvas objects
- [ ] Implement canvas test utilities and helpers

---

## Phase 2: Core Testing Implementation (Weeks 3-4)

### 2.1 Unit Testing - Domain Layer
**Priority: High | Effort: Medium**

#### 2.1.1 Canvas Object Tests
```dart
// test/unit/domain/canvas_objects/rectangle_shape_test.dart
void main() {
  group('RectangleShape Tests', () {
    test('should calculate correct connection points', () {
      final rect = RectangleShape(Rect.fromLTWH(0, 0, 100, 50));
      final points = rect.suggestedConnectionPoints;
      
      expect(points.length, 4);
      expect(points[0], Offset(50, 0));   // Top
      expect(points[1], Offset(100, 25)); // Right
      expect(points[2], Offset(50, 50));  // Bottom
      expect(points[3], Offset(0, 25));   // Left
    });
    
    test('should find closest edge point correctly', () {
      final rect = RectangleShape(Rect.fromLTWH(0, 0, 100, 50));
      
      // Test from top-left
      final closest = rect.getClosestEdgePoint(Offset(-10, -10));
      expect(closest, Offset(0, 25)); // Left edge
      
      // Test from bottom-right
      final closest2 = rect.getClosestEdgePoint(Offset(110, 60));
      expect(closest2, Offset(100, 25)); // Right edge
    });
    
    test('should detect point containment', () {
      final rect = RectangleShape(Rect.fromLTWH(10, 10, 100, 50));
      
      expect(rect.containsPoint(Offset(50, 30)), true);  // Inside
      expect(rect.containsPoint(Offset(5, 30)), false);  // Outside left
      expect(rect.containsPoint(Offset(50, 5)), false);  // Outside top
    });
  });
}
```

#### 2.1.2 Transform2D Tests
```dart
// test/unit/domain/transforms/transform2d_test.dart
void main() {
  group('Transform2D Tests', () {
    test('should convert world to screen coordinates', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );
      
      final worldPoint = Offset(10, 20);
      final screenPoint = transform.worldToScreen(worldPoint);
      
      expect(screenPoint, Offset(120, 90)); // (10*2 + 100, 20*2 + 50)
    });
    
    test('should convert screen to world coordinates', () {
      final transform = Transform2D(
        translation: Offset(100, 50),
        scale: 2.0,
      );
      
      final screenPoint = Offset(120, 90);
      final worldPoint = transform.screenToWorld(screenPoint);
      
      expect(worldPoint, Offset(10, 20)); // (120-100)/2, (90-50)/2
    });
    
    test('should handle scale transformations', () {
      final transform = Transform2D(
        translation: Offset.zero,
        scale: 0.5,
      );
      
      final worldPoint = Offset(100, 200);
      final screenPoint = transform.worldToScreen(worldPoint);
      
      expect(screenPoint, Offset(50, 100));
    });
  });
}
```

#### 2.1.3 Tool Logic Tests
```dart
// test/unit/domain/tools/drawing_tool_test.dart
void main() {
  group('Drawing Tool Tests', () {
    test('should create rectangle with correct bounds', () {
      final tool = RectangleTool();
      final startPoint = Offset(10, 10);
      final endPoint = Offset(50, 30);
      
      final rectangle = tool.createShape(startPoint, endPoint);
      
      expect(rectangle.bounds, Rect.fromLTRB(10, 10, 50, 30));
      expect(rectangle.type, 'rectangle');
    });
    
    test('should create circle with correct center and radius', () {
      final tool = CircleTool();
      final center = Offset(30, 30);
      final radius = 20.0;
      
      final circle = tool.createShape(center, center + Offset(radius, 0));
      
      expect(circle.center, center);
      expect(circle.radius, closeTo(20.0, 0.1));
    });
    
    test('should handle freehand drawing points', () {
      final tool = FreehandTool();
      final points = [
        Offset(0, 0),
        Offset(10, 5),
        Offset(20, 10),
        Offset(30, 15),
      ];
      
      final path = tool.createPath(points);
      
      expect(path.getBounds(), isA<Rect>());
      expect(path.getBounds().width, greaterThan(0));
      expect(path.getBounds().height, greaterThan(0));
    });
  });
}
```

#### 2.1.4 Property-Based Testing (NEW)
**Priority: High | Effort: Medium**

Property-based testing automatically generates hundreds of test cases to discover edge cases.

```dart
// test/unit/domain/property_based/shape_properties_test.dart
import 'package:dart_check/dart_check.dart';

void main() {
  group('Shape Property-Based Tests', () {
    propertyTest('any point inside rectangle bounds should be detected',
      forAll(
        rectangleGen,
        pointInsideRectGen,
        (rectangle, point) {
          // Property: containsPoint should return true for any point inside bounds
          expect(rectangle.containsPoint(point), isTrue);
        },
      ),
    );
    
    propertyTest('closest edge point should always be on the edge',
      forAll(
        rectangleGen,
        arbitraryPointGen,
        (rectangle, point) {
          final edgePoint = rectangle.getClosestEdgePoint(point);
          
          // Property: edge point must be on the rectangle perimeter
          final isOnEdge =
            edgePoint.dx == rectangle.bounds.left ||
            edgePoint.dx == rectangle.bounds.right ||
            edgePoint.dy == rectangle.bounds.top ||
            edgePoint.dy == rectangle.bounds.bottom;
          
          expect(isOnEdge, isTrue);
        },
      ),
    );
    
    propertyTest('freehand stroke analysis should handle any valid point sequence',
      forAll(
        validPointSequenceGen,
        (points) {
          final stroke = FreehandStroke();
          points.forEach((p) => stroke.addPoint(p));
          
          // Property: analysis should never throw
          expect(() => stroke.analyzeStroke([]), returnsNormally);
          
          // Property: confidence should be between 0 and 1
          final analysis = stroke.analyzeStroke([]);
          expect(analysis.confidence, inInclusiveRange(0.0, 1.0));
        },
      ),
    );
    
    propertyTest('connection point calculation should be commutative',
      forAll(
        generate((random) => Offset(
          random.nextDouble() * 1000,
          random.nextDouble() * 1000,
        )),
        (point) {
          final rect = RectangleShape(Rect.fromLTWH(100, 100, 200, 150));
          
          final connectionPoint1 = rect.getClosestEdgePoint(point);
          final connectionPoint2 = rect.getClosestEdgePoint(point);
          
          // Property: same input should always give same output
          expect(connectionPoint1, equals(connectionPoint2));
        },
      ),
    );
  });
}

// Property-based test generators
final rectangleGen = generate((random) {
  final left = random.nextDouble() * 500;
  final top = random.nextDouble() * 500;
  final width = random.nextDouble() * 200 + 50;
  final height = random.nextDouble() * 200 + 50;
  
  return RectangleShape(Rect.fromLTWH(left, top, width, height));
});

final pointInsideRectGen = generate((random) {
  // Generate point that's guaranteed to be inside a rectangle
  return Offset(
    random.nextDouble() * 200 + 50,
    random.nextDouble() * 200 + 50,
  );
});

final arbitraryPointGen = generate((random) {
  return Offset(
    random.nextDouble() * 1000 - 500,
    random.nextDouble() * 1000 - 500,
  );
});

final validPointSequenceGen = generate((random) {
  final length = random.nextInt(50) + 5;
  return List.generate(length, (i) => Offset(
    random.nextDouble() * 500,
    random.nextDouble() * 500,
  ));
});
```

**Benefits:**
- Discovers edge cases human testers miss
- Tests invariants (properties that should always be true)
- Automatically shrinks failing cases to minimal examples
- Validates mathematical correctness of shape calculations

### 2.2 Widget Testing - UI Components
**Priority: High | Effort: Medium**

#### 2.2.1 Canvas Widget Tests
```dart
// test/widget/canvas/infinite_canvas_test.dart
void main() {
  group('Infinite Canvas Widget Tests', () {
    testWidgets('should render canvas with initial state', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(),
        ),
      );
      
      expect(find.byType(InfiniteCanvas), findsOneWidget);
      expect(find.byKey(ValueKey('canvas_area')), findsOneWidget);
    });
    
    testWidgets('should handle pan gestures', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(),
        ),
      );
      
      final canvas = find.byKey(ValueKey('canvas_area'));
      final initialCenter = tester.getCenter(canvas);
      
      // Simulate pan gesture
      await tester.drag(canvas, Offset(100, 50));
      await tester.pumpAndSettle();
      
      // Verify canvas moved (this would need to be implemented in the widget)
      expect(find.byKey(ValueKey('canvas_area')), findsOneWidget);
    });
    
    testWidgets('should handle zoom gestures', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(),
        ),
      );
      
      final canvas = find.byKey(ValueKey('canvas_area'));
      final center = tester.getCenter(canvas);
      
      // Simulate pinch-to-zoom
      final gesture1 = await tester.startGesture(center - Offset(20, 0));
      final gesture2 = await tester.startGesture(center + Offset(20, 0));
      
      await gesture1.moveTo(center - Offset(50, 0));
      await gesture2.moveTo(center + Offset(50, 0));
      
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      
      // Verify zoom occurred
      expect(find.byKey(ValueKey('canvas_area')), findsOneWidget);
    });
  });
}
```

#### 2.2.2 Miro Sidebar Tests
```dart
// test/widget/sidebar/miro_sidebar_test.dart
void main() {
  group('Miro Sidebar Tests', () {
    testWidgets('should render all tool buttons', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: MiroSidebar(
            onToolSelected: (tool) {},
            selectedTool: null,
          ),
        ),
      );
      
      // Check for key tools
      expect(find.byKey(ValueKey('tool_select')), findsOneWidget);
      expect(find.byKey(ValueKey('tool_rectangle')), findsOneWidget);
      expect(find.byKey(ValueKey('tool_circle')), findsOneWidget);
      expect(find.byKey(ValueKey('tool_freehand')), findsOneWidget);
      expect(find.byKey(ValueKey('tool_text')), findsOneWidget);
      expect(find.byKey(ValueKey('tool_connector')), findsOneWidget);
    });
    
    testWidgets('should highlight selected tool', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: MiroSidebar(
            onToolSelected: (tool) {},
            selectedTool: 'rectangle',
          ),
        ),
      );
      
      final rectangleButton = find.byKey(ValueKey('tool_rectangle'));
      final button = tester.widget<Container>(rectangleButton);
      
      // Verify selected state styling
      expect(button.decoration, isA<BoxDecoration>());
    });
    
    testWidgets('should call onToolSelected when tool is tapped', (tester) async {
      String? selectedTool;
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: MiroSidebar(
            onToolSelected: (tool) => selectedTool = tool,
            selectedTool: null,
          ),
        ),
      );
      
      await tester.tap(find.byKey(ValueKey('tool_rectangle')));
      await tester.pumpAndSettle();
      
      expect(selectedTool, 'rectangle');
    });
    
    testWidgets('should handle undo/redo buttons', (tester) async {
      bool undoCalled = false;
      bool redoCalled = false;
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: MiroSidebar(
            onToolSelected: (tool) {},
            selectedTool: null,
            onUndo: () => undoCalled = true,
            onRedo: () => redoCalled = true,
            canUndo: true,
            canRedo: true,
          ),
        ),
      );
      
      await tester.tap(find.byKey(ValueKey('undo_button')));
      await tester.pumpAndSettle();
      expect(undoCalled, true);
      
      await tester.tap(find.byKey(ValueKey('redo_button')));
      await tester.pumpAndSettle();
      expect(redoCalled, true);
    });
  });
}
```

#### 2.2.3 Shape Widget Tests
```dart
// test/widget/shapes/rectangle_widget_test.dart
void main() {
  group('Rectangle Widget Tests', () {
    testWidgets('should render rectangle with correct dimensions', (tester) async {
      final rectangle = RectangleShape(Rect.fromLTWH(10, 10, 100, 50));
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: RectangleWidget(shape: rectangle),
        ),
      );
      
      expect(find.byType(RectangleWidget), findsOneWidget);
      
      // Verify positioning
      final widget = tester.widget<Positioned>(find.byType(Positioned));
      expect(widget.left, 10.0);
      expect(widget.top, 10.0);
    });
    
    testWidgets('should show resize handles when selected', (tester) async {
      final rectangle = RectangleShape(Rect.fromLTWH(10, 10, 100, 50));
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: RectangleWidget(
            shape: rectangle,
            isSelected: true,
          ),
        ),
      );
      
      // Check for resize handles
      expect(find.byKey(ValueKey('resize_handle_topLeft')), findsOneWidget);
      expect(find.byKey(ValueKey('resize_handle_topRight')), findsOneWidget);
      expect(find.byKey(ValueKey('resize_handle_bottomLeft')), findsOneWidget);
      expect(find.byKey(ValueKey('resize_handle_bottomRight')), findsOneWidget);
    });
    
    testWidgets('should handle drag gestures', (tester) async {
      final rectangle = RectangleShape(Rect.fromLTWH(10, 10, 100, 50));
      Offset? newPosition;
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: RectangleWidget(
            shape: rectangle,
            onPositionChanged: (pos) => newPosition = pos,
          ),
        ),
      );
      
      final rectangleWidget = find.byType(RectangleWidget);
      await tester.drag(rectangleWidget, Offset(50, 30));
      await tester.pumpAndSettle();
      
      expect(newPosition, isNotNull);
      expect(newPosition!.dx, 60.0); // 10 + 50
      expect(newPosition!.dy, 40.0); // 10 + 30
    });
  });
}
```

---

## Phase 3: Integration Testing (Weeks 5-6)

### 3.1 Patrol Integration Tests
**Priority: High | Effort: High**

#### 3.1.1 Drawing Workflow Tests
```dart
// test/integration/patrol/drawing_workflows_test.dart
void main() {
  patrolTest('Complete rectangle drawing workflow', ($) async {
    // Launch app
    await $.pumpWidgetAndSettle(MyApp());
    
    // Select rectangle tool
    await $.tap('tool_rectangle');
    await $.pumpAndSettle();
    
    // Draw rectangle on canvas
    final canvas = $('canvas_area');
    await $.drag(canvas, Offset(100, 100), Offset(200, 150));
    await $.pumpAndSettle();
    
    // Verify rectangle was created
    await $.waitUntilExists($('rectangle_0'));
    expect($('rectangle_0'), isVisible);
    
    // Verify rectangle has correct dimensions
    final rectangle = $.getWidget<RectangleWidget>($('rectangle_0'));
    expect(rectangle.shape.bounds.width, 100.0);
    expect(rectangle.shape.bounds.height, 50.0);
  });
  
  patrolTest('Freehand drawing workflow', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Select freehand tool
    await $.tap('tool_freehand');
    await $.pumpAndSettle();
    
    // Draw freehand path
    final canvas = $('canvas_area');
    final startPoint = $.getCenter(canvas);
    
    // Simulate drawing a curved path
    await $.native.startGesture(startPoint);
    await $.native.moveTo(startPoint + Offset(20, 10));
    await $.native.moveTo(startPoint + Offset(40, -5));
    await $.native.moveTo(startPoint + Offset(60, 15));
    await $.native.endGesture();
    await $.pumpAndSettle();
    
    // Verify freehand path was created
    await $.waitUntilExists($('freehand_path_0'));
    expect($('freehand_path_0'), isVisible);
  });
  
  patrolTest('Text tool workflow', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Select text tool
    await $.tap('tool_text');
    await $.pumpAndSettle();
    
    // Click on canvas to create text
    final canvas = $('canvas_area');
    await $.tap(canvas);
    await $.pumpAndSettle();
    
    // Type text
    await $.enterText('Hello Canvas!', into: 'text_input');
    await $.tap('confirm_text');
    await $.pumpAndSettle();
    
    // Verify text was created
    await $.waitUntilExists($('text_0'));
    expect($('text_0'), isVisible);
    expect($('Hello Canvas!'), isVisible);
  });
}
```

#### 3.1.2 Shape Manipulation Tests
```dart
// test/integration/patrol/shape_manipulation_test.dart
void main() {
  patrolTest('Shape selection and movement', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Create a rectangle first
    await $.tap('tool_rectangle');
    final canvas = $('canvas_area');
    await $.drag(canvas, Offset(100, 100), Offset(200, 150));
    await $.pumpAndSettle();
    
    // Select the rectangle
    await $.tap('rectangle_0');
    await $.pumpAndSettle();
    
    // Verify selection handles appear
    expect($('resize_handle_topLeft'), isVisible);
    expect($('resize_handle_bottomRight'), isVisible);
    
    // Move the rectangle
    await $.drag('rectangle_0', Offset(50, 30));
    await $.pumpAndSettle();
    
    // Verify new position
    final rectangle = $.getWidget<RectangleWidget>($('rectangle_0'));
    expect(rectangle.shape.bounds.left, 150.0); // 100 + 50
    expect(rectangle.shape.bounds.top, 130.0);  // 100 + 30
  });
  
  patrolTest('Shape resizing', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Create and select rectangle
    await $.tap('tool_rectangle');
    final canvas = $('canvas_area');
    await $.drag(canvas, Offset(100, 100), Offset(200, 150));
    await $.tap('rectangle_0');
    await $.pumpAndSettle();
    
    // Resize using bottom-right handle
    await $.drag('resize_handle_bottomRight', Offset(50, 25));
    await $.pumpAndSettle();
    
    // Verify new dimensions
    final rectangle = $.getWidget<RectangleWidget>($('rectangle_0'));
    expect(rectangle.shape.bounds.width, 150.0);  // 100 + 50
    expect(rectangle.shape.bounds.height, 75.0);  // 50 + 25
  });
  
  patrolTest('Multi-shape selection', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Create multiple shapes
    await $.tap('tool_rectangle');
    final canvas = $('canvas_area');
    await $.drag(canvas, Offset(100, 100), Offset(200, 150));
    
    await $.tap('tool_circle');
    await $.drag(canvas, Offset(250, 100), Offset(300, 150));
    await $.pumpAndSettle();
    
    // Select multiple shapes (Ctrl+click or drag selection)
    await $.native.pressKey(LogicalKeyboardKey.controlLeft);
    await $.tap('rectangle_0');
    await $.tap('circle_0');
    await $.native.releaseKey(LogicalKeyboardKey.controlLeft);
    await $.pumpAndSettle();
    
    // Verify both shapes are selected
    expect($('rectangle_0').isSelected, true);
    expect($('circle_0').isSelected, true);
  });
}
```

#### 3.1.3 Connector System Tests
```dart
// test/integration/patrol/connector_tests.dart
void main() {
  patrolTest('Create connector between shapes', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Create two shapes
    await $.tap('tool_rectangle');
    final canvas = $('canvas_area');
    await $.drag(canvas, Offset(100, 100), Offset(200, 150));
    
    await $.tap('tool_circle');
    await $.drag(canvas, Offset(300, 100), Offset(350, 150));
    await $.pumpAndSettle();
    
    // Select connector tool
    await $.tap('tool_connector');
    await $.pumpAndSettle();
    
    // Draw connector from rectangle to circle
    await $.drag('rectangle_0', $.getCenter($('circle_0')));
    await $.pumpAndSettle();
    
    // Verify connector was created
    await $.waitUntilExists($('connector_0'));
    expect($('connector_0'), isVisible);
    
    // Verify connector endpoints
    final connector = $.getWidget<ConnectorWidget>($('connector_0'));
    expect(connector.startShape, 'rectangle_0');
    expect(connector.endShape, 'circle_0');
  });
  
  patrolTest('Connector auto-routing', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Create shapes with obstacle
    await $.tap('tool_rectangle');
    final canvas = $('canvas_area');
    await $.drag(canvas, Offset(100, 100), Offset(200, 150)); // Start shape
    
    await $.tap('tool_rectangle');
    await $.drag(canvas, Offset(100, 200), Offset(200, 250)); // Obstacle
    
    await $.tap('tool_circle');
    await $.drag(canvas, Offset(300, 100), Offset(350, 150)); // End shape
    await $.pumpAndSettle();
    
    // Create connector
    await $.tap('tool_connector');
    await $.drag('rectangle_0', $.getCenter($('circle_0')));
    await $.pumpAndSettle();
    
    // Verify connector routes around obstacle
    final connector = $.getWidget<ConnectorWidget>($('connector_0'));
    final path = connector.path;
    
    // Check that path doesn't intersect with obstacle
    expect(path.getBounds().intersect(Rect.fromLTWH(100, 200, 100, 50)).isEmpty, true);
  });
}
```

---

## Phase 4: Visual Testing (Weeks 7-8)

### 4.1 Golden Testing for Canvas Components
**Priority: Medium | Effort: Low**

```dart
// test/visual/golden/canvas_golden_test.dart
void main() {
  group('Canvas Golden Tests', () {
    testWidgets('Empty canvas state', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(InfiniteCanvas),
        matchesGoldenFile('goldens/empty_canvas.png'),
      );
    });
    
    testWidgets('Canvas with multiple shapes', (tester) async {
      final shapes = [
        RectangleShape(Rect.fromLTWH(50, 50, 100, 80)),
        CircleShape(center: Offset(200, 100), radius: 40),
        TextShape(text: 'Hello World', position: Offset(100, 200)),
      ];
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(initialShapes: shapes),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(InfiniteCanvas),
        matchesGoldenFile('goldens/canvas_with_shapes.png'),
      );
    });
    
    testWidgets('Canvas with connectors', (tester) async {
      final shapes = [
        RectangleShape(Rect.fromLTWH(50, 50, 100, 80)),
        CircleShape(center: Offset(250, 100), radius: 40),
      ];
      
      final connectors = [
        Connector(
          id: 'connector_0',
          startShape: 'rectangle_0',
          endShape: 'circle_0',
          path: Path()..moveTo(150, 90)..lineTo(210, 100),
        ),
      ];
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(
            initialShapes: shapes,
            initialConnectors: connectors,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(InfiniteCanvas),
        matchesGoldenFile('goldens/canvas_with_connectors.png'),
      );
    });
  });
}
```

### 4.2 Sidebar Visual Tests
```dart
// test/visual/golden/sidebar_golden_test.dart
void main() {
  group('Sidebar Golden Tests', () {
    testWidgets('Default sidebar state', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: MiroSidebar(
            onToolSelected: (tool) {},
            selectedTool: null,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(MiroSidebar),
        matchesGoldenFile('goldens/sidebar_default.png'),
      );
    });
    
    testWidgets('Sidebar with selected tool', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: MiroSidebar(
            onToolSelected: (tool) {},
            selectedTool: 'rectangle',
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      await expectLater(
        find.byType(MiroSidebar),
        matchesGoldenFile('goldens/sidebar_rectangle_selected.png'),
      );
    });
  });
}
```

---

## Phase 5: Performance Testing (Weeks 9-10)

### 5.1 Canvas Rendering Performance
**Priority: Medium | Effort: Medium**

```dart
// test/performance/canvas_rendering_test.dart
void main() {
  group('Canvas Rendering Performance Tests', () {
    testWidgets('Render 1000 shapes performance', (tester) async {
      final stopwatch = Stopwatch()..start();
      
      // Create 1000 random shapes
      final shapes = List.generate(1000, (i) => 
        RectangleShape(Rect.fromLTWH(
          i % 20 * 50.0,
          (i ~/ 20) * 50.0,
          40.0,
          40.0,
        ))
      );
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(initialShapes: shapes),
        ),
      );
      
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      // Performance assertion - should render in under 200ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
    
    testWidgets('Pan performance with many shapes', (tester) async {
      // Create canvas with many shapes
      final shapes = List.generate(500, (i) => 
        RectangleShape(Rect.fromLTWH(i * 2.0, i * 2.0, 20.0, 20.0))
      );
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(initialShapes: shapes),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final canvas = find.byKey(ValueKey('canvas_area'));
      final initialFrameTime = tester.binding.framePolicy;
      
      // Perform rapid panning
      for (int i = 0; i < 10; i++) {
        await tester.drag(canvas, Offset(50, 0));
        await tester.pump();
      }
      
      // Ensure we maintain 60 FPS during panning
      final frameTimes = tester.binding.getFrameTimes();
      final averageFrameTime = frameTimes.average();
      expect(averageFrameTime.inMilliseconds, lessThan(16)); // 60 FPS
    });
    
    testWidgets('Zoom performance', (tester) async {
      final shapes = List.generate(200, (i) => 
        CircleShape(center: Offset(i * 5.0, i * 5.0), radius: 10.0)
      );
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(initialShapes: shapes),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final canvas = find.byKey(ValueKey('canvas_area'));
      final center = tester.getCenter(canvas);
      
      // Simulate zoom in
      final gesture1 = await tester.startGesture(center - Offset(20, 0));
      final gesture2 = await tester.startGesture(center + Offset(20, 0));
      
      await gesture1.moveTo(center - Offset(50, 0));
      await gesture2.moveTo(center + Offset(50, 0));
      
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();
      
      // Verify zoom completed without performance issues
      expect(find.byType(InfiniteCanvas), findsOneWidget);
    });
  });
}
```

### 5.2 Memory Usage Tests
```dart
// test/performance/memory_usage_test.dart
void main() {
  group('Memory Usage Tests', () {
    testWidgets('Memory usage with large canvas', (tester) async {
      final initialMemory = _getMemoryUsage();
      
      // Create canvas with many objects
      final shapes = List.generate(1000, (i) => 
        RectangleShape(Rect.fromLTWH(i * 1.0, i * 1.0, 10.0, 10.0))
      );
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(initialShapes: shapes),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final finalMemory = _getMemoryUsage();
      final memoryIncrease = finalMemory - initialMemory;
      
      // Memory should not increase excessively
      expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // 50MB limit
    });
    
    testWidgets('Memory cleanup after object deletion', (tester) async {
      final shapes = List.generate(100, (i) => 
        RectangleShape(Rect.fromLTWH(i * 10.0, i * 10.0, 50.0, 50.0))
      );
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(initialShapes: shapes),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final memoryWithShapes = _getMemoryUsage();
      
      // Delete all shapes
      for (int i = 0; i < 100; i++) {
        await tester.tap(find.byKey(ValueKey('rectangle_$i')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('delete_button')));
        await tester.pumpAndSettle();
      }
      
      final memoryAfterDeletion = _getMemoryUsage();
      final memoryFreed = memoryWithShapes - memoryAfterDeletion;
      
      // Should free significant memory
      expect(memoryFreed, greaterThan(1024 * 1024)); // At least 1MB freed
    });
  });
}

int _getMemoryUsage() {
  // Implementation would depend on platform
  // This is a placeholder
  return 0;
}
```

---

## Phase 6: Advanced Testing Features (Weeks 11-12)

### 6.1 Cross-Platform Testing
**Priority: High | Effort: High**

#### 6.1.1 Platform-Specific Gesture Tests
```dart
// test/platform_specific/desktop_tests.dart
class DesktopTestSuite {
  static void run() {
    group('Desktop-Specific Tests', () {
      testWidgets('Keyboard shortcuts', (tester) async {
        await tester.pumpWidget(TestCanvasWrapper(child: MyApp()));
        
        // Test Ctrl+Z for undo
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/keyevent',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('keydown', {
              'keymap': 'linux',
              'type': 'keydown',
              'key': 'ControlLeft',
            }),
          ),
          (data) {},
        );
        
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/keyevent',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('keydown', {
              'keymap': 'linux',
              'type': 'keydown',
              'key': 'KeyZ',
            }),
          ),
          (data) {},
        );
        
        // Verify undo was triggered
        expect(find.byKey(ValueKey('undo_button')), findsOneWidget);
      });
      
      testWidgets('Right-click context menu', (tester) async {
        await tester.pumpWidget(TestCanvasWrapper(child: MyApp()));
        
        // Create a shape
        await tester.tap(find.byKey(ValueKey('tool_rectangle')));
        final canvas = find.byKey(ValueKey('canvas_area'));
        await tester.drag(canvas, Offset(100, 100), Offset(200, 150));
        await tester.pumpAndSettle();
        
        // Right-click on shape
        await tester.tap(find.byKey(ValueKey('rectangle_0')), 
                        buttons: kSecondaryButton);
        await tester.pumpAndSettle();
        
        // Verify context menu appears
        expect(find.byType(ContextMenu), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Duplicate'), findsOneWidget);
      });
    });
  }
}
```

#### 6.1.2 Mobile Touch Tests
```dart
// test/platform_specific/mobile_tests.dart
class MobileTestSuite {
  static void run() {
    group('Mobile-Specific Tests', () {
      testWidgets('Touch gesture handling', (tester) async {
        await tester.pumpWidget(TestCanvasWrapper(child: MyApp()));
        
        final canvas = find.byKey(ValueKey('canvas_area'));
        final center = tester.getCenter(canvas);
        
        // Test long press
        await tester.longPress(canvas);
        await tester.pumpAndSettle();
        
        // Verify long press menu appears
        expect(find.byType(LongPressMenu), findsOneWidget);
      });
      
      testWidgets('Pinch-to-zoom on mobile', (tester) async {
        await tester.pumpWidget(TestCanvasWrapper(child: MyApp()));
        
        final canvas = find.byKey(ValueKey('canvas_area'));
        final center = tester.getCenter(canvas);
        
        // Simulate pinch gesture
        final gesture1 = await tester.startGesture(center - Offset(20, 0));
        final gesture2 = await tester.startGesture(center + Offset(20, 0));
        
        await gesture1.moveTo(center - Offset(50, 0));
        await gesture2.moveTo(center + Offset(50, 0));
        
        await gesture1.up();
        await gesture2.up();
        await tester.pumpAndSettle();
        
        // Verify zoom occurred
        expect(find.byKey(ValueKey('zoomed_canvas')), findsOneWidget);
      });
    });
  }
}
```

### 6.2 Collaboration Testing
```dart
// test/integration/patrol/collaboration_test.dart
void main() {
  patrolTest('Real-time collaboration', ($) async {
    // This would require multiple app instances or mock collaboration
    final mockCollaborationService = MockCollaborationService();
    
    await $.pumpWidgetAndSettle(
      TestCanvasWrapper(
        overrides: [
          collaborationService.overrideWithValue(mockCollaborationService),
        ],
        child: MyApp(),
      ),
    );
    
    // Create shape in first instance
    await $.tap('tool_rectangle');
    final canvas = $('canvas_area');
    await $.drag(canvas, Offset(100, 100), Offset(200, 150));
    await $.pumpAndSettle();
    
    // Simulate remote user creating shape
    mockCollaborationService.simulateRemoteAction(
      CanvasEvent.shapeCreated(
        id: 'remote_rectangle_0',
        shape: RectangleShape(Rect.fromLTWH(300, 100, 100, 50)),
      ),
    );
    
    await $.pumpAndSettle();
    
    // Verify remote shape appears
    await $.waitUntilExists($('remote_rectangle_0'));
    expect($('remote_rectangle_0'), isVisible);
  });
}
```

---

## Phase 7: CI/CD Integration (Weeks 13-14)

### 7.1 GitHub Actions Workflow
```yaml
# .github/workflows/canvas_test.yml
name: Infinite Canvas App Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    strategy:
      matrix:
        platform: [android, ios, web, windows, macos, linux]
    
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.0'
          
      - name: Run unit and widget tests
        run: flutter test --coverage
        
      - name: Run integration tests
        run: flutter test integration_test/
        
      - name: Run Patrol tests
        run: patrol test
        
      - name: Run golden tests
        run: flutter test test/visual/
        
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
          
      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.platform }}
          path: test_results/
          
      - name: Upload golden files
        uses: actions/upload-artifact@v3
        if: github.event_name == 'pull_request'
        with:
          name: golden-files
          path: test/goldens/
```

### 7.2 Test Reporting
```dart
// test/helpers/canvas_test_reporter.dart
class CanvasTestReporter {
  static void generateReport(WidgetTester tester) {
    final performanceData = _collectCanvasPerformanceMetrics(tester);
    final coverageData = _collectCoverageData();
    final visualRegressionData = _compareGoldenFiles();
    
    _generateHTMLReport(performanceData, coverageData, visualRegressionData);
  }
  
  static Map<String, dynamic> _collectCanvasPerformanceMetrics(WidgetTester tester) {
    return {
      'canvas_render_time': _getCanvasRenderTime(),
      'shape_creation_time': _getShapeCreationTime(),
      'pan_performance': _getPanPerformance(),
      'zoom_performance': _getZoomPerformance(),
      'memory_usage': _getMemoryUsage(),
      'frame_times': tester.binding.getFrameTimes(),
    };
  }
}
```

---

## Phase 8: Test Data Management (Weeks 15-16)

### 8.1 Canvas Test Data Factory
```dart
// test/helpers/test_data/canvas_test_data_factory.dart
class CanvasTestDataFactory {
  static RectangleShape createRectangle({
    double x = 0.0,
    double y = 0.0,
    double width = 100.0,
    double height = 50.0,
  }) {
    return RectangleShape(Rect.fromLTWH(x, y, width, height));
  }
  
  static CircleShape createCircle({
    double centerX = 0.0,
    double centerY = 0.0,
    double radius = 25.0,
  }) {
    return CircleShape(center: Offset(centerX, centerY), radius: radius);
  }
  
  static TextShape createText({
    String text = 'Test Text',
    double x = 0.0,
    double y = 0.0,
    double fontSize = 16.0,
  }) {
    return TextShape(
      text: text,
      position: Offset(x, y),
      fontSize: fontSize,
    );
  }
  
  static Connector createConnector({
    required String startShapeId,
    required String endShapeId,
    Path? customPath,
  }) {
    return Connector(
      id: 'connector_${Uuid().v4()}',
      startShape: startShapeId,
      endShape: endShapeId,
      path: customPath ?? Path()..moveTo(0, 0)..lineTo(100, 100),
    );
  }
  
  static List<CanvasObject> createComplexCanvas() {
    return [
      createRectangle(x: 50, y: 50, width: 100, height: 80),
      createCircle(centerX: 200, centerY: 100, radius: 40),
      createText(text: 'Hello Canvas', x: 100, y: 200),
      createRectangle(x: 300, y: 150, width: 80, height: 60),
    ];
  }
  
  static List<Connector> createConnectorNetwork() {
    return [
      createConnector(startShapeId: 'shape_0', endShapeId: 'shape_1'),
      createConnector(startShapeId: 'shape_1', endShapeId: 'shape_2'),
      createConnector(startShapeId: 'shape_2', endShapeId: 'shape_3'),
    ];
  }
}
```

### 8.2 Mock Services
```dart
// test/helpers/mocks/mock_canvas_services.dart
class MockCanvasPersistenceService extends Mock implements CanvasPersistenceService {
  final Map<String, CanvasData> _savedCanvases = {};
  
  @override
  Future<void> saveCanvas(String canvasId, CanvasData data) async {
    _savedCanvases[canvasId] = data;
  }
  
  @override
  Future<CanvasData?> loadCanvas(String canvasId) async {
    return _savedCanvases[canvasId];
  }
  
  @override
  Future<List<String>> listCanvases() async {
    return _savedCanvases.keys.toList();
  }
  
  void clearSavedCanvases() {
    _savedCanvases.clear();
  }
}

class MockCollaborationService extends Mock implements CollaborationService {
  final StreamController<CanvasEvent> _eventController = StreamController.broadcast();
  
  @override
  Stream<CanvasEvent> get eventStream => _eventController.stream;
  
  @override
  Future<void> sendEvent(CanvasEvent event) async {
    _eventController.add(event);
  }
  
  void simulateRemoteAction(CanvasEvent event) {
    _eventController.add(event);
  }
  
  void dispose() {
    _eventController.close();
  }
}
```

---

## Implementation Timeline

### Week 1-2: Foundation
- [ ] Set up test environment and dependencies
- [ ] Create directory structure
- [ ] Implement TestCanvasWrapper and mock services
- [ ] Set up basic CI pipeline

### Week 3-4: Core Testing
- [ ] Implement unit tests for domain objects
- [ ] Create widget tests for canvas components
- [ ] Set up test data factories
- [ ] Implement basic integration tests

### Week 5-6: Integration Testing
- [ ] Implement Patrol integration tests
- [ ] Create drawing workflow tests
- [ ] Add shape manipulation tests
- [ ] Implement connector system tests

### Week 7-8: Visual Testing
- [ ] Set up golden testing
- [ ] Implement visual regression tests
- [ ] Create screenshot testing
- [ ] Add responsive design tests

### Week 9-10: Performance Testing
- [ ] Implement canvas rendering benchmarks
- [ ] Create memory usage tests
- [ ] Add gesture performance tests
- [ ] Set up performance monitoring

### Week 11-12: Advanced Features
- [ ] Implement cross-platform tests
- [ ] Add collaboration testing
- [ ] Create accessibility tests
- [ ] Implement advanced gesture tests

### Week 13-14: CI/CD Integration
- [ ] Set up GitHub Actions workflow
- [ ] Implement test reporting
- [ ] Add coverage reporting
- [ ] Set up artifact storage

### Week 15-16: Test Data Management
- [ ] Implement comprehensive test data factory
- [ ] Create mock services
- [ ] Set up test data cleanup
- [ ] Implement test isolation

---

## Success Metrics

### Coverage Targets
- **Unit Tests**: 90%+ code coverage for domain layer
- **Widget Tests**: 85%+ component coverage
- **Integration Tests**: 100% critical user workflows
- **Visual Tests**: 100% UI components

### Performance Targets
- **Canvas Rendering**: <200ms for 1000 shapes
- **Shape Creation**: <50ms per shape
- **Pan Performance**: 60 FPS during panning
- **Memory Usage**: <50MB for normal operations

### Quality Targets
- **Test Stability**: <3% flaky test rate
- **Test Execution**: <45 minutes for full suite
- **Bug Detection**: 95% of bugs caught before production
- **Regression Prevention**: 100% of critical regressions prevented

---

## Risk Mitigation

### Technical Risks
1. **Canvas Performance**: Complex rendering with many objects
2. **Gesture Conflicts**: Multiple simultaneous gestures
3. **Memory Leaks**: Long-running canvas sessions
4. **Cross-Platform Differences**: Platform-specific behaviors

### Mitigation Strategies
1. **Performance Monitoring**: Continuous performance testing
2. **Gesture Testing**: Comprehensive gesture conflict testing
3. **Memory Testing**: Regular memory leak detection
4. **Platform Testing**: Extensive cross-platform validation

---

## Conclusion

This implementation plan provides a comprehensive roadmap for building a robust testing framework specifically for the Flutter infinite canvas application. The plan addresses the unique challenges of canvas-based applications including complex gestures, shape manipulation, real-time rendering, and cross-platform compatibility.

The key to success is starting with the foundation (Phase 1-2), building core testing capabilities (Phase 3-4), and then expanding to advanced features (Phase 5-8). Regular monitoring of success metrics and risk mitigation will ensure the testing framework remains effective and maintainable for the infinite canvas application.


## Phase 2.5: Advanced Testing Features (NEW)

### 2.5.1 Accessibility Testing
**Priority: High | Effort: Medium**

Canvas-based UIs present unique accessibility challenges. This section ensures the infinite canvas is usable with assistive technologies.

```dart
// test/accessibility/canvas_accessibility_test.dart
void main() {
  group('Canvas Accessibility Tests', () {
    testWidgets('shapes should have semantic labels', (tester) async {
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(
            nodes: [
              Node('rect_1', Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 120, 120))),
              Node('circle_1', Offset(300, 100), CircleShape(Offset(60, 60), 60)),
            ],
          ),
        ),
      );
      
      // Verify semantic labels exist
      expect(
        find.bySemanticsLabel('Rectangle node rect_1'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Circle node circle_1'),
        findsOneWidget,
      );
    });
    
    testWidgets('connectors should announce connection relationships', (tester) async {
      final node1 = Node('source', Offset(100, 100), RectangleShape(Rect.fromLTWH(0, 0, 100, 100)));
      final node2 = Node('target', Offset(300, 100), CircleShape(Offset(50, 50), 50));
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          child: InfiniteCanvas(
            nodes: [node1, node2],
            edges: [
              Edge(sourceNode: node1, targetNode: node2, sourcePoint: Offset.zero, targetPoint: Offset.zero),
            ],
          ),
        ),
      );
      
      // Verify connector semantics
      final semantics = tester.getSemantics(find.byType(Edge).first);
      expect(
        semantics.label,
        contains('Connected from source to target'),
      );
    });
    
    testWidgets('keyboard navigation should work for all canvas operations', (tester) async {
      await tester.pumpWidget(TestCanvasWrapper(child: InfiniteCanvas()));
      
      // Focus canvas
      await tester.tap(find.byType(InfiniteCanvas));
      await tester.pumpAndSettle();
      
      // Arrow keys should move focus between nodes
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      
      // Verify first node is focused
      expect(
        find.descendant(
          of: find.byType(Node),
          matching: find.byKey(ValueKey('focused_node')),
        ),
        findsOneWidget,
      );
      
      // Space/Enter should select node
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      
      expect(find.byKey(ValueKey('selected_node')), findsOneWidget);
    });
    
    testWidgets('screen reader should announce canvas state changes', (tester) async {
      final canvasState = CanvasState();
      
      await tester.pumpWidget(
        TestCanvasWrapper(
          overrides: [canvasStateProvider.overrideWithValue(canvasState)],
          child: InfiniteCanvas(),
        ),
      );
      
      // Add node
      canvasState.addNode(RectangleShape(Rect.fromLTWH(0, 0, 100, 100)));
      await tester.pumpAndSettle();
      
      // Verify announcement
      final announcement = tester.getSemantics(find.byType(Announcement).first);
      expect(announcement.label, 'Rectangle node added to canvas');
      
      // Delete node
      canvasState.deleteSelected();
      await tester.pumpAndSettle();
      
      expect(announcement.label, 'Selected nodes deleted');
    });
    
    testWidgets('contrast ratios should meet WCAG AA standards', (tester) async {
      await tester.pumpWidget(TestCanvasWrapper(child: InfiniteCanvas()));
      
      // Verify shape colors
      final shapePaint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
      final painter = shapePaint.painter as NodeShapePainter;
      
      // Check contrast ratio between shape fill and border
      final contrastRatio = calculateContrastRatio(
        painter.fillColor,
        painter.borderColor,
      );
      
      expect(contrastRatio, greaterThanOrEqualTo(4.5)); // WCAG AA standard
    });
    
    testWidgets('touch targets should meet minimum size requirements', (tester) async {
      await tester.pumpWidget(TestCanvasWrapper(child: InfiniteCanvas()));
      
      // Verify connection points are at least 44x44 dp (accessibility guideline)
      final connectionPoint = find.byKey(ValueKey('connection_point_0'));
      final size = tester.getSize(connectionPoint);
      
      expect(size.width, greaterThanOrEqualTo(44.0));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });
  });
}

double calculateContrastRatio(Color foreground, Color background) {
  final luminance1 = foreground.computeLuminance();
  final luminance2 = background.computeLuminance();
  
  final lighter = max(luminance1, luminance2);
  final darker = min(luminance1, luminance2);
  
  return (lighter + 0.05) / (darker + 0.05);
}
```

### 2.5.2 Security Testing for Collaborative Canvas
**Priority: Medium | Effort: Medium**

For real-time collaborative features, security testing is critical.

```dart
// test/security/canvas_security_test.dart
void main() {
  group('Canvas Security Tests', () {
    test('should sanitize user input in text shapes', () {
      final textShape = TextShape(
        text: '<script>alert("XSS")</script>',
        position: Offset(100, 100),
      );
      
      // Verify XSS prevention
      expect(textShape.sanitizedText, isNot(contains('<script>')));
      expect(textShape.sanitizedText, contains('&lt;script&gt;'));
    });
    
    test('should validate canvas data before deserialization', () {
      final maliciousJson = '''
      {
        "nodes": [{
          "__proto__": {"isAdmin": true},
          "id": "node_1",
          "position": {"x": 100, "y": 100}
        }]
      }
      ''';
      
      expect(
        () => CanvasSerializer.fromJson(maliciousJson),
        throwsA(isA<SecurityException>()),
      );
    });
    
    test('should enforce size limits on canvas operations', () {
      final canvasState = CanvasState();
      
      // Attempt to create extremely large shape (DoS attack)
      expect(
        () => canvasState.addNode(
          RectangleShape(Rect.fromLTWH(0, 0, 1000000, 1000000)),
        ),
        throwsA(isA<SizeLimitException>()),
      );
    });
    
    test('should rate-limit real-time collaboration events', () async {
      final collaborationService = MockCollaborationService();
      
      // Simulate flood of events
      final events = List.generate(
        1000,
        (i) => CanvasEvent.nodeAdded(id: 'node_$i'),
      );
      
      for (final event in events) {
        await collaborationService.sendEvent(event);
      }
      
      // Verify rate limiting kicked in
      expect(collaborationService.rejectedEvents, greaterThan(900));
    });
    
    test('should validate WebSocket messages', () async {
      final mockWebSocket = MockWebSocketChannel();
      
      // Send malformed message
      mockWebSocket.sink.add('{"invalid": true}');
      
      // Verify rejection
      expect(
        mockWebSocket.stream,
        emitsError(isA<ValidationException>()),
      );
    });
  });
  
  group('OWASP Top 10 Canvas-Specific Tests', () {
    test('A1: Injection - SQL injection in canvas queries', () {
      final query = CanvasQueryBuilder()
        .whereNodeId("node_1' OR '1'='1")
        .build();
      
      // Verify parameterized queries are used
      expect(query.parameters, isNotEmpty);
      expect(query.sql, isNot(contains("OR '1'='1")));
    });
    
    test('A3: Sensitive Data Exposure - canvas data encryption', () {
      final canvas = CanvasData(nodes: [testNode], edges: [testEdge]);
      final encrypted = CanvasEncryption.encrypt(canvas);
      
      // Verify encryption
      expect(encrypted.ciphertext, isNot(contains('node_')));
      expect(encrypted.algorithm, equals('AES-256-GCM'));
    });
    
    test('A5: Broken Access Control - user permissions', () {
      final canvasState = CanvasState();
      final user = User(id: 'user_1', role: 'viewer');
      
      // Viewers should not be able to delete nodes
      expect(
        () => canvasState.deleteNode('node_1', user: user),
        throwsA(isA<PermissionException>()),
      );
    });
  });
}
```

### 2.5.3 AI-Powered Test Generation (NEW)
**Priority: Low | Effort: High**

Use AI to automatically generate test scenarios from user interactions and code patterns.

```dart
// test/ai_powered/ai_test_generator.dart
class AITestGenerator {
  final OpenAIClient openai;
  
  AITestGenerator(this.openai);
  
  /// Generate test cases from user story descriptions
  Future<List<TestCase>> generateFromUserStories(List<String> stories) async {
    final prompt = '''
    Generate comprehensive Flutter integration tests for an infinite canvas app.
    
    User Stories:
    ${stories.map((s) => '- $s').join('\n')}
    
    For each story, generate:
    1. Test name
    2. Setup steps
    3. Action steps (drag, tap, freehand draw, etc.)
    4. Assertion steps
    5. Edge cases to cover
    
    Focus on:
    - Shape manipulation (rectangles, circles, triangles)
    - Freehand drawing with connection detection
    - Connector routing and optimization
    - Multi-shape selection
    - Keyboard shortcuts (Ctrl+A, Delete, etc.)
    
    Return as JSON array of test cases.
    ''';
    
    final response = await openai.complete(prompt);
    return TestCase.fromJsonArray(response.choices[0].text);
  }
  
  /// Analyze actual user sessions to generate realistic test scenarios
  Future<List<TestScenario>> generateFromUserSessions(
    List<UserSession> sessions,
  ) async {
    // Analyze patterns in user behavior
    final commonPatterns = _analyzeSessionPatterns(sessions);
    
    final prompt = '''
    Based on these actual user interaction patterns in our infinite canvas app:
    
    ${commonPatterns.map((p) => '- ${p.description}: ${p.frequency}%').join('\n')}
    
    Generate edge case tests that users might trigger but we haven't tested.
    Consider:
    - Rapid action sequences
    - Unusual gesture combinations
    - Boundary conditions
    - Error recovery scenarios
    ''';
    
    final response = await openai.complete(prompt);
    return TestScenario.fromJsonArray(response.choices[0].text);
  }
  
  /// Self-healing tests: AI adapts selectors when UI changes
  Future<String> healBrokenTest(
    TestCase brokenTest,
    String errorMessage,
  ) async {
    final prompt = '''
    This Flutter test is failing:
    
    Test Code:
    ```dart
    ${brokenTest.code}
    ```
    
    Error:
    ${errorMessage}
    
    Suggest a fix that:
    1. Maintains test intent
    2. Uses more robust selectors (semantic labels over keys)
    3. Adds appropriate waits for animations
    4. Handles potential timing issues
    
    Return the fixed test code.
    ''';
    
    final response = await openai.complete(prompt);
    return response.choices[0].text;
  }
  
  List<InteractionPattern> _analyzeSessionPatterns(List<UserSession> sessions) {
    // Implement pattern analysis
    // Returns common interaction sequences
    return [];
  }
}

// Example usage in CI/CD
class AITestGenerationPipeline {
  Future<void> runAITestGeneration() async {
    final generator = AITestGenerator(OpenAIClient(apiKey: env['OPENAI_KEY']));
    
    // 1. Generate tests from backlog user stories
    final stories = await fetchUserStoriesFromJira();
    final generatedTests = await generator.generateFromUserStories(stories);
    
    // 2. Save generated tests for review
    for (final test in generatedTests) {
      await File('test/ai_generated/${test.name}_test.dart')
        .writeAsString(test.dartCode);
    }
    
    // 3. Run generated tests
    final results = await runFlutterTests('test/ai_generated/');
    
    // 4. If tests fail, attempt self-healing
    for (final failure in results.failures) {
      final healedCode = await generator.healBrokenTest(
        failure.testCase,
        failure.error,
      );
      
      // Save healed version for human review
      await File('test/ai_generated/${failure.testCase.name}_healed.dart')
        .writeAsString(healedCode);
    }
  }
}
```

**AI Testing Tools Recommendation:**
- **Testim.io**: Self-healing tests with AI-powered locators
- **Applitools**: AI visual testing for canvas rendering
- **Mabl**: AI test generation from user sessions
- **Custom GPT-4**: Generate test scenarios from requirements


## Phase 3.5: Real-World Infinite Canvas Test Scenarios (NEW)

### 3.5.1 Freehand Drawing with Connection Detection
Based on the actual [`connectors.dart`](lib/pages/connectors.dart:229) implementation, test the intelligent connection detection.

```dart
// test/integration/patrol/freehand_connection_test.dart
void main() {
  patrolTest('Freehand drawing should detect connection intent', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Setup: Create two nodes
    final node1Center = Offset(150, 200);
    final node2Center = Offset(400, 200);
    
    // Draw freehand stroke from node1 to node2
    await $.native.startGesture(node1Center);
    
    // Simulate user drawing a relatively straight line
    for (int i = 0; i <= 10; i++) {
      final progress = i / 10.0;
      final point = Offset.lerp(node1Center, node2Center, progress)!;
      await $.native.moveTo(point);
      await $.pump(Duration(milliseconds: 10));
    }
    
    await $.native.endGesture();
    await $.pumpAndSettle();
    
    // Verify connection confirmation dialog appears
    expect($('Create Connection?'), isVisible);
    expect($('Convert freehand line to connection'), isVisible);
    
    // Confirm connection
    await $.tap('Yes');
    await $.pumpAndSettle();
    
    // Verify edge was created (not freehand stroke)
    final canvasState = $.tester.widget<ChangeNotifierProvider>(
      find.byType(ChangeNotifierProvider),
    ).create(null) as CanvasState;
    
    expect(canvasState.edges.length, 1);
    expect(canvasState.freehandStrokes.length, 0);
  });
  
  patrolTest('Squiggly freehand should stay as drawing', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Draw a very squiggly line (low confidence)
    final startPoint = Offset(100, 100);
    await $.native.startGesture(startPoint);
    
    // Create squiggly pattern
    for (int i = 0; i < 20; i++) {
      final x = 100 + i * 5.0;
      final y = 100 + sin(i * 0.5) * 20; // Sine wave
      await $.native.moveTo(Offset(x, y));
      await $.pump(Duration(milliseconds: 10));
    }
    
    await $.native.endGesture();
    await $.pumpAndSettle();
    
    // Verify NO connection dialog (confidence too low)
    expect($('Create Connection?'), findsNothing);
    
    // Verify kept as freehand stroke
    final canvasState = getCanvasState($);
    expect(canvasState.freehandStrokes.length, 1);
    expect(canvasState.edges.length, 0);
  });
}
```

### 3.5.2 Shape-Aware Connection Points
Test the [`NodeShape`](lib/pages/connectors.dart:7) abstraction with different shapes.

```dart
// test/integration/shape_connection_points_test.dart
void main() {
  group('Shape-Aware Connection Point Tests', () {
    testWidgets('Rectangle should connect at cardinal points', (tester) async {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 200, 150));
      
      // Test top connection
      final topPoint = rect.getClosestEdgePoint(Offset(200, 50));
      expect(topPoint.dy, equals(100.0)); // Top edge
      expect(topPoint.dx, closeTo(200.0, 1.0)); // Center X
      
      // Test right connection
      final rightPoint = rect.getClosestEdgePoint(Offset(350, 175));
      expect(rightPoint.dx, equals(300.0)); // Right edge
      expect(rightPoint.dy, closeTo(175.0, 1.0)); // Center Y
    });
    
    testWidgets('Circle should connect at any angle', (tester) async {
      final circle = CircleShape(Offset(200, 200), 50);
      
      // Test 45-degree angle connection
      final angle45Point = circle.getClosestEdgePoint(Offset(250, 150));
      final expectedAngle = atan2(150 - 200, 250 - 200);
      
      expect(
        angle45Point,
        offsetCloseTo(
          Offset(
            200 + 50 * cos(expectedAngle),
            200 + 50 * sin(expectedAngle),
          ),
          1.0,
        ),
      );
    });
    
    testWidgets('Triangle should connect at vertices and edges', (tester) async {
      final triangle = TriangleShape(Offset(200, 200), 50);
      
      // Test connection from above (should hit top vertex)
      final topConnection = triangle.getClosestEdgePoint(Offset(200, 100));
      expect(topConnection, offsetCloseTo(Offset(200, 150), 1.0));
      
      // Test connection from side (should hit edge, not vertex)
      final sideConnection = triangle.getClosestEdgePoint(Offset(100, 220));
      expect(sideConnection.dx, lessThan(200)); // On left edge
    });
  });
}

// Custom matcher for Offset comparison with tolerance
Matcher offsetCloseTo(Offset expected, double tolerance) {
  return predicate<Offset>(
    (actual) =>
        (actual.dx - expected.dx).abs() < tolerance &&
        (actual.dy - expected.dy).abs() < tolerance,
    'offset close to $expected within $tolerance',
  );
}
```

### 3.5.3 Multi-Shape Selection with Keyboard Shortcuts
Test the [`_NodeCanvasState`](lib/pages/connectors.dart:840) keyboard handling.

```dart
// test/integration/patrol/keyboard_shortcuts_test.dart
void main() {
  patrolTest('Ctrl+A should select all nodes', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Verify initial state (3 nodes by default)
    expect($('rectangle 1'), isVisible);
    expect($('circle 2'), isVisible);
    expect($('triangle 3'), isVisible);
    
    // Focus canvas
    await $.tap($('canvas_area'));
    await $.pumpAndSettle();
    
    // Press Ctrl+A
    await $.native.pressKey(LogicalKeyboardKey.controlLeft);
    await $.native.pressKey(LogicalKeyboardKey.keyA);
    await $.native.releaseKey(LogicalKeyboardKey.keyA);
    await $.native.releaseKey(LogicalKeyboardKey.controlLeft);
    await $.pumpAndSettle();
    
    // Verify all nodes are selected
    final canvasState = getCanvasState($);
    expect(canvasState.selectedNodes.length, 3);
    
    // Delete button should appear
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });
  
  patrolTest('Delete key should remove selected nodes', ($) async {
    await $.pumpWidgetAndSettle(MyApp());
    
    // Select all nodes
    await $.tap($('canvas_area'));
    await $.native.pressKey(LogicalKeyboardKey.controlLeft);
    await $.native.pressKey(LogicalKeyboardKey.keyA);
    await $.native.releaseKey(LogicalKeyboardKey.keyA);
    await $.native.releaseKey(LogicalKeyboardKey.controlLeft);
    await $.pumpAndSettle();
    
    // Tap delete button
    await $.tap(find.byIcon(Icons.delete));
    await $.pumpAndSettle();
    
    // Verify all nodes deleted
    final canvasState = getCanvasState($);
    expect(canvasState.nodes.length, 0);
    expect(canvasState.edges.length, 0);
  });
}
```

### 3.5.4 Stress Test: Rapid Freehand Drawing
Test the [`FreehandStroke`](lib/pages/connectors.dart:230) under heavy load.

```dart
// test/performance/freehand_stress_test.dart
void main() {
  testWidgets('Should handle 1000 rapid freehand strokes', (tester) async {
    final canvasState = CanvasState();
    
    await tester.pumpWidget(
      TestCanvasWrapper(
        overrides: [canvasStateProvider.overrideWithValue(canvasState)],
        child: InfiniteCanvas(),
      ),
    );
    
    final stopwatch = Stopwatch()..start();
    
    // Create 1000 freehand strokes rapidly
    for (int i = 0; i < 1000; i++) {
      canvasState.startFreehandStroke(Offset(i * 1.0, 100));
      
      // Add 10 points per stroke
      for (int j = 0; j < 10; j++) {
        canvasState.updateFreehandStroke(Offset(i * 1.0 + j, 100 + j));
      }
      
      canvasState.endFreehandStroke(Offset(i * 1.0 + 10, 110));
      
      if (i % 100 == 0) {
        await tester.pump();
      }
    }
    
    await tester.pumpAndSettle();
    stopwatch.stop();
    
    // Performance assertions
    expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
    expect(canvasState.freehandStrokes.length, lessThanOrEqualTo(1000));
    
    // Memory check
    final memoryUsage = _getMemoryUsage();
    expect(memoryUsage, lessThan(100 * 1024 * 1024)); // 100MB limit
  });
}
```

### 3.5.5 Edge Cases: Degenerate Shapes
Test boundary conditions in shape calculations.

```dart
// test/unit/edge_cases/degenerate_shapes_test.dart
void main() {
  group('Degenerate Shape Edge Cases', () {
    test('Zero-size rectangle should handle gracefully', () {
      final rect = RectangleShape(Rect.fromLTWH(100, 100, 0, 0));
      
      expect(() => rect.suggestedConnectionPoints, returnsNormally);
      expect(() => rect.containsPoint(Offset(100, 100)), returnsNormally);
    });
    
    test('Zero-radius circle should not crash', () {
      final circle = CircleShape(Offset(100, 100), 0);
      
      expect(() => circle.getClosestEdgePoint(Offset(150, 150)), returnsNormally);
      expect(circle.suggestedConnectionPoints.length, greaterThan(0));
    });
    
    test('Negative rectangle dimensions should be normalized', () {
      // User might drag from bottom-right to top-left
      final rect = RectangleShape(Rect.fromPoints(
        Offset(200, 200),
        Offset(100, 100),
      ));
      
      expect(rect.bounds.width, greaterThanOrEqualTo(0));
      expect(rect.bounds.height, greaterThanOrEqualTo(0));
    });
    
    test('Extremely large shapes should not cause overflow', () {
      final rect = RectangleShape(Rect.fromLTWH(0, 0, 1e10, 1e10));
      
      expect(() => rect.getClosestEdgePoint(Offset(1e9, 1e9)), returnsNormally);
    });
  });
}
```


## Phase 9: Framework Selection & Best Practices (NEW)

### 9.1 Definitive Framework Selection Guide

**Based on Trading App Testing Learnings:**

#### ✅ RECOMMENDED: Single Framework Per Layer

```yaml
# Optimal testing stack for Infinite Canvas App
primary_stack:
  unit_tests:
    framework: "flutter_test"
    mocking: "mocktail"
    property_testing: "dart_check"
    
  widget_tests:
    framework: "flutter_test"
    visual_regression: "flutter_golden_toolkit"
    accessibility: "flutter_test (semantics)"
    
  integration_tests:
    framework: "patrol"  # Advanced over integration_test
    reason: "Native device APIs, better gesture support"
    
specialized_tools:
  performance:
    framework: "custom_benchmarks"
    metrics: ["frame_times", "memory", "gesture_latency"]
    
  security:
    framework: "custom_security_tests"
    tools: ["OWASP ZAP (CI/CD only)"]
    
  visual_ai:
    framework: "applitools (optional)"
    use_when: "Pixel-perfect canvas rendering critical"
```

#### ❌ AVOID: Redundant Frameworks

```yaml
# DON'T use these together (conflicting functionality)
conflicts:
  integration:
    avoid_together: ["patrol", "integration_test", "flutter_driver"]
    choose: "patrol"
    
  mocking:
    avoid_together: ["mocktail", "mockito"]
    choose: "mocktail"
    
  visual:
    avoid_together: ["golden_toolkit", "applitools", "percy"]
    choose: "golden_toolkit (primary), applitools (optional enterprise)"
```

### 9.2 When to Use Multiple Frameworks

**Only use redundant frameworks in these scenarios:**

```dart
// ✅ ACCEPTABLE: Different testing dimensions
class MultiFrameworkStrategy {
  // Scenario 1: Temporary migration (2-4 weeks max)
  void migrationPeriod() {
    runLegacyTests(integration_test);  // Existing tests
    runNewTests(patrol);               // Migrating to this
    // Delete integration_test after migration
  }
  
  // Scenario 2: Mission-critical canvas operations
  void criticalFinancialFlows() {
    // If canvas is used for financial visualization
    runFunctionalTests(patrol);         // Business logic
    runVisualTests(applitools);         // Pixel-perfect accuracy
    runPerformanceTests(custom);        // Response time
  }
  
  // Scenario 3: Regulatory requirements
  void regulatoryCompliance() {
    runInternalTests(patrol);           // Internal QA
    runExternalAuditTests(selenium);    // Independent verification
  }
}

// ❌ UNACCEPTABLE: Duplicate coverage
class BadMultiFrameworkStrategy {
  void duplicateIntegrationTests() {
    // DON'T write same test in two frameworks
    runWithPatrol(orderFlowTest);       // ❌
    runWithIntegrationTest(orderFlowTest); // ❌ Duplicate effort
  }
}
```

### 9.3 Framework Compatibility Matrix - Infinite Canvas Specific

| Framework | Compatible With | Incompatible With | Canvas-Specific Benefit |
|-----------|----------------|-------------------|------------------------|
| **Patrol** | flutter_test, mocktail, golden_toolkit | integration_test (partial) | Advanced gesture handling for freehand drawing |
| **dart_check** | All frameworks | None | Property-based testing for shape calculations |
| **Golden Toolkit** | All frameworks | percy, applitools (choose one) | Fast visual regression for shape rendering |
| **Mocktail** | All frameworks | mockito (choose one) | Null-safe mocking for canvas state |
| **Custom Benchmarks** | All frameworks | None | Canvas-specific performance metrics |

### 9.4 Progressive Framework Adoption Timeline

```yaml
# Recommended adoption order for infinite canvas app

month_1_foundation:
  add:
    - flutter_test (unit/widget)
    - mocktail (mocking)
    - golden_toolkit (basic visual)
  effort: "Low"
  impact: "High"
  
month_2_integration:
  add:
    - patrol (replace integration_test if present)
    - dart_check (property-based testing)
  effort: "Medium"
  impact: "High"
  
month_3_advanced:
  add:
    - custom_performance_benchmarks
    - accessibility_testing_suite
  effort: "Medium"
  impact: "Medium"
  
month_6_enterprise:
  consider:
    - applitools (if visual quality critical)
    - ai_test_generation (if team large)
    - mutation_testing (if codebase mature)
  effort: "High"
  impact: "Low-Medium"
```

### 9.5 Decision Framework Flowchart

```
START: Need to add testing?
│
├─ Testing single function/class? 
│  └─ YES → flutter_test + mocktail
│
├─ Testing widget rendering?
│  └─ YES → flutter_test + golden_toolkit
│
├─ Testing user journey with gestures?
│  └─ YES → patrol
│
├─ Need native device features (GPS, camera)?
│  └─ YES → patrol (not integration_test)
│
├─ Need pixel-perfect visual validation?
│  ├─ Budget < $1000/month? → golden_toolkit
│  └─ Budget > $1000/month? → applitools
│
├─ Testing performance/memory?
│  └─ YES → custom benchmarks (canvas-specific)
│
├─ Testing accessibility?
│  └─ YES → flutter_test semantics (built-in)
│
└─ Testing security?
   └─ YES → custom security tests + OWASP ZAP
```

### 9.6 Cost-Benefit Analysis

**Framework Investment vs. Return:**

| Framework | Setup Cost | Maintenance Cost | ROI | When to Use |
|-----------|-----------|------------------|-----|-------------|
| flutter_test | $0 | Low | ∞ | Always (built-in) |
| mocktail | $0 | Low | High | Always (null-safe mocking) |
| patrol | $0 | Medium | High | Integration tests with gestures |
| dart_check | $0 | Medium | High | Complex math/shape logic |
| golden_toolkit | $0 | Low | High | Visual regression |
| applitools | $99-999/mo | Low | Medium | Enterprise visual QA |
| BrowserStack | $29-299/mo | Low | Medium | Real device testing |
| AI test gen | $20-200/mo | High | Low-Medium | Large teams, mature codebase |

### 9.7 Common Anti-Patterns to Avoid

```dart
// ❌ ANTI-PATTERN 1: Framework duplication
class BadTestStrategy {
  void duplicateTests() {
    // Writing same test in multiple frameworks
    test_with_patrol('draw rectangle');
    test_with_integration_test('draw rectangle'); // ❌ Waste
  }
}

// ✅ CORRECT: Single framework, comprehensive test
class GoodTestStrategy {
  void comprehensiveTest() {
    patrol_test('complete rectangle workflow', () {
      // One test covers: creation, movement, resizing, deletion
      createRectangle();
      moveRectangle();
      resizeRectangle();
      deleteRectangle();
    });
  }
}

// ❌ ANTI-PATTERN 2: Framework overkill
class OverkillStrategy {
  void unnecessaryFrameworks() {
    // Using enterprise tools for simple app
    runWithApplitools(); // ❌ Overkill for MVP
    runWithBrowserStack(); // ❌ Not needed yet
    runWithAIGeneration(); // ❌ Premature optimization
  }
}

// ✅ CORRECT: Start simple, scale as needed
class IncrementalStrategy {
  void startSimple() {
    // MVP: Basic testing
    runFlutterTest();
    runPatrolTests();
    
    // Later: Add visual testing if needed
    if (visualRegressionsBecomeIssue) {
      addGoldenTests();
    }
  }
}
```

### 9.8 Final Recommendation for Infinite Canvas App

**Tier 1 (Essential - Implement Now):**
```yaml
must_have:
  - flutter_test (unit/widget)
  - mocktail (mocking)
  - patrol (integration)
  - golden_toolkit (visual)
  - dart_check (property-based for shapes)
```

**Tier 2 (Important - Add in 1-3 months):**
```yaml
should_have:
  - custom_performance_benchmarks
  - accessibility_testing
  - security_test_suite
```

**Tier 3 (Nice to Have - Evaluate after 6 months):**
```yaml
optional:
  - applitools (if pixel-perfect critical)
  - ai_test_generation (if team > 5 engineers)
  - mutation_testing (if codebase mature)
  - browserstack (if cross-device issues arise)
```

**Decision Rule:**
> "Use ONE framework per testing layer. Only add more if they serve genuinely different purposes (functional vs. visual vs. performance). Time saved from not maintaining duplicate tests is better spent writing better tests in a single framework."

---

## Conclusion & Implementation Checklist

### Updated Success Metrics

**Coverage Targets:**
- **Unit Tests**: 90%+ code coverage for domain layer (shapes, transforms, connectors)
- **Widget Tests**: 85%+ component coverage (canvas, shapes, UI controls)
- **Integration Tests**: 100% critical user workflows (drawing, connecting, manipulating)
- **Visual Tests**: 100% UI components with baseline images
- **Property-Based Tests**: 20+ property tests for shape calculations
- **Accessibility Tests**: 100% WCAG AA compliance
- **Security Tests**: All OWASP Top 10 covered

**Performance Targets:**
- **Canvas Rendering**: <200ms for 1000 shapes
- **Shape Creation**: <50ms per shape
- **Freehand Drawing**: 60 FPS during stroke capture
- **Connection Detection**: <100ms for stroke analysis
- **Memory Usage**: <50MB for normal operations
- **Mutation Score**: >80% (mutations killed by tests)

**Quality Targets:**
- **Test Stability**: <3% flaky test rate
- **Test Execution**: <45 minutes for full suite
- **Bug Detection**: 95% of bugs caught before production
- **Regression Prevention**: 100% of critical regressions prevented

### Key Takeaways from Trading App Testing

1. **Don't duplicate frameworks** - costs more, helps less
2. **Property-based testing** catches edge cases humans miss
3. **Mutation testing** validates your tests are effective
4. **Accessibility** is non-negotiable for canvas UIs
5. **Security testing** critical for collaborative features
6. **AI test generation** is useful but not essential
7. **Start simple**, scale complexity as needed
8. **Framework conflicts** cause more problems than they solve
9. **Comprehensive tests** in one framework > partial tests in two
10. **Real-world scenarios** based on actual implementation > theoretical tests

### Implementation Priority Order

**Week 1-2:** Foundation
- ✅ Set up flutter_test + mocktail
- ✅ Create 20+ unit tests for shape logic
- ✅ Add property-based tests for calculations

**Week 3-4:** Integration
- ✅ Install patrol
- ✅ Create 10+ integration tests for user workflows
- ✅ Test freehand drawing + connection detection

**Week 5-6:** Visual & Accessibility
- ✅ Set up golden_toolkit
- ✅ Create baseline images for all shapes
- ✅ Add accessibility tests (semantic labels, keyboard nav)

**Week 7-8:** Advanced Features
- ✅ Add mutation testing for critical logic
- ✅ Implement security tests for collaboration
- ✅ Set up CI/CD pipeline

**Month 3+:** Optimization
- ✅ Add performance benchmarks
- ✅ Consider AI test generation (optional)
- ✅ Evaluate applitools for visual testing (optional)

This plan now incorporates all learnings from the trading app testing framework while being specifically tailored to the infinite canvas implementation. The focus is on practical, maintainable, and effective testing without framework bloat.
