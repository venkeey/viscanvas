import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart';
import 'package:viscanvas/services/canvas/canvas_service.dart';
import 'package:viscanvas/models/canvas_objects/canvas_object.dart';
import 'package:viscanvas/models/canvas_objects/connector.dart';
import 'package:viscanvas/ui/canvas_screen.dart';
import 'package:viscanvas/domain/canvas_domain.dart';

/// Canvas End-to-End Test with Enhanced Drag Support
///
/// This test validates canvas functionality including:
/// - Creating shapes (Rectangle, Circle) via drag operations
/// - Creating connectors between shapes via drag operations
/// - Verifying objects appear in the objects panel
/// - Testing undo/redo functionality
///
/// DRAG OPERATION IMPROVEMENTS:
/// - Uses performMouseDrag() with proper mouse event simulation
/// - Includes hover events before drag to set cursor state
/// - Moves in incremental steps with pump() calls between
/// - Adds delays and verification after each shape creation
/// - Provides detailed logging for debugging
///
/// TROUBLESHOOTING:
/// - If shapes aren't created: Check coordinates are within canvas bounds
/// - If connector fails: Ensure start/end points are on/near shapes
/// - If drag doesn't work: Try performMouseDragAlternative() which uses moveBy
/// - Check console output for detailed position and object count logs

/// Helper function to get the CanvasService from the widget tree
CanvasService? getCanvasService(dynamic $) {
  try {
    final canvasScreenElement = $.tester.element(find.byType(CanvasScreen));
    final canvasScreenState = canvasScreenElement as StatefulElement;
    final state = canvasScreenState.state;
    // Use the public getter instead of accessing private field
    return (state as dynamic).service as CanvasService?;
  } catch (e) {
    print('⚠️ Could not get CanvasService: $e');
    return null;
  }
}

/// Helper function to perform a reliable mouse drag operation
Future<void> performMouseDrag(
  dynamic $,
  Offset start,
  Offset end, {
  int steps = 10,
  Duration stepDuration = const Duration(milliseconds: 50),
  bool withHover = false,  // Disabled by default to avoid pointer tracking issues
}) async {
  print('🖱️ Starting drag from $start to $end');
  print('   Distance: ${(end - start).distance.toStringAsFixed(1)} pixels');

  // Optional: Simple hover implementation (disabled by default)
  // Note: Can cause pointer tracking issues in some test scenarios
  if (withHover) {
    print('  ⚠️ Hover is experimental and may cause issues');
    final hoverGesture = await $.tester.createGesture(kind: PointerDeviceKind.mouse);
    await hoverGesture.moveTo(start);
    await $.tester.pump(const Duration(milliseconds: 50));
    await hoverGesture.removePointer();
    await $.tester.pump(const Duration(milliseconds: 50));
  }

  // Start the gesture with mouse and primary button
  final gesture = await $.tester.startGesture(
    start,
    kind: PointerDeviceKind.mouse,
    buttons: kPrimaryMouseButton,
  );

  // Wait to ensure the down event is processed
  await $.tester.pump(const Duration(milliseconds: 150));

  // Calculate step size
  final dx = (end.dx - start.dx) / steps;
  final dy = (end.dy - start.dy) / steps;

  // Move in increments with logging
  for (int i = 1; i <= steps; i++) {
    final intermediate = Offset(
      start.dx + (dx * i),
      start.dy + (dy * i),
    );
    await gesture.moveTo(intermediate);
    await $.tester.pump(stepDuration);

    // Log progress at key points
    if (i == 1 || i == steps ~/ 2 || i == steps) {
      print('  📍 Step $i/$steps: $intermediate');
    }
  }

  // Extra pump to ensure final position is registered
  await $.tester.pump(const Duration(milliseconds: 150));

  // Release the mouse button
  await gesture.up();
  await $.pumpAndSettle();

  print('✅ Drag completed to $end');
}

/// Alternative drag method using moveBy instead of moveTo
Future<void> performMouseDragAlternative(
  dynamic $,
  Offset start,
  Offset end, {
  int steps = 10,
  Duration stepDuration = const Duration(milliseconds: 50),
}) async {
  print('🖱️ Alternative drag from $start to $end');

  final gesture = await $.tester.startGesture(
    start,
    kind: PointerDeviceKind.mouse,
    buttons: kPrimaryMouseButton,
  );

  await $.tester.pump(const Duration(milliseconds: 150));

  final delta = end - start;
  final stepOffset = Offset(delta.dx / steps, delta.dy / steps);

  for (int i = 0; i < steps; i++) {
    await gesture.moveBy(stepOffset);
    await $.tester.pump(stepDuration);
  }

  await $.tester.pump(const Duration(milliseconds: 150));
  await gesture.up();
  await $.pumpAndSettle();

  print('✅ Alternative drag completed');
}

void main() {
  patrolWidgetTest('Canvas end-to-end: create shapes, connect, verify objects panel', ($) async {
    // Disable autosave and autosave loading for a clean test environment
    CanvasService.globalAutoSaveEnabled = false;

    // Launch app
    await $.pumpWidget(const MainApp());
    await $.pumpAndSettle();

    // Use the full native window; no test overrides for size/DPI

    // Give time to visually confirm launch
    await Future<void>.delayed(const Duration(seconds: 3));

    // Tap canvas root to focus
    final canvasFinder = $(const Key('canvasRoot'));
    await canvasFinder.tap();
    await $.pumpAndSettle();

    // Visual pause
    await Future<void>.delayed(const Duration(seconds: 1));

    // Ensure clean slate: Ctrl+Shift+Delete to clear canvas (test-only shortcut)
    await $.tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await $.tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await $.tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await $.tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await $.tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await $.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Set zoom to 50% via test-only shortcut: Ctrl+Shift+5
    await $.tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await $.tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await $.tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await $.tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await $.tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await $.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Select tool via keyboard (V)
    await $.tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await $.pumpAndSettle();

    // Pan: drag across the canvas
    final Rect canvasRect = $.tester.getRect(find.byKey(const Key('canvasRoot')));
    await performMouseDrag($, canvasRect.center, canvasRect.center + const Offset(200, 120));
    await $.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 1));

    // "Zoom-ish": simulate a short two-pointer scale gesture (approximation)
    // Note: full pinch simulation on desktop is limited; this provides visual movement
    final center = canvasRect.center;
    final gesture1 = await $.tester.startGesture(center + const Offset(-20, 0));
    final gesture2 = await $.tester.startGesture(center + const Offset(20, 0));
    await $.tester.pump(const Duration(milliseconds: 16));
    await gesture1.moveBy(const Offset(-20, 0));
    await gesture2.moveBy(const Offset(20, 0));
    await $.tester.pump(const Duration(milliseconds: 16));
    await gesture1.up();
    await gesture2.up();
    await $.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 1));

    // Get service to verify tool selection
    final service = getCanvasService($);
    expect(service, isNotNull, reason: 'CanvasService should be available');

    // Create two shapes: rectangle then circle at different positions
    // Select Rectangle via toolbar button (more reliable than keyboard in tests)
    await $(const Key('tool_rectangle')).tap();
    await $.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Verify rectangle tool is selected
    expect(service!.currentTool, equals(ToolType.rectangle),
           reason: 'Rectangle tool should be active');

    // Rectangle is created by drag (start->end) rather than tap
    final Offset rectStart = center + const Offset(-260, -140);
    final Offset rectEnd = center + const Offset(-140, -60);
    print('🔷 Creating rectangle from $rectStart to $rectEnd');

    final objectsBeforeRect = service.objects.length;
    await performMouseDrag($, rectStart, rectEnd, steps: 15);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Verify rectangle was created
    print('📊 Objects before rectangle: $objectsBeforeRect, after: ${service.objects.length}');
    expect(service.objects.length, equals(objectsBeforeRect + 1),
           reason: 'Rectangle should have been created');

    // Select Circle via toolbar button
    await $(const Key('tool_circle')).tap();
    await $.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Verify circle tool is selected
    expect(service.currentTool, equals(ToolType.circle),
           reason: 'Circle tool should be active');

    final Offset circleStart = center + const Offset(180, 80);
    final Offset circleEnd = center + const Offset(260, 160);
    print('⭕ Creating circle from $circleStart to $circleEnd');

    final objectsBeforeCircle = service.objects.length;
    await performMouseDrag($, circleStart, circleEnd, steps: 15);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Verify circle was created
    print('📊 Objects before circle: $objectsBeforeCircle, after: ${service.objects.length}');
    expect(service.objects.length, equals(objectsBeforeCircle + 1),
           reason: 'Circle should have been created');

    await Future<void>.delayed(const Duration(seconds: 1));

    // Verify two shapes were created (Rectangle and Circle)
    print('📊 Objects after creating shapes: ${service.objects.length}');
    expect(service.objects.length, equals(2), reason: 'Should have 2 objects (Rectangle and Circle)');

    // Verify we have one Rectangle and one Circle
    final rectangles = service.objects.where((obj) => obj.getDisplayTypeName() == 'Rectangle').toList();
    final circles = service.objects.where((obj) => obj.getDisplayTypeName() == 'Circle').toList();
    expect(rectangles.length, equals(1), reason: 'Should have 1 Rectangle');
    expect(circles.length, equals(1), reason: 'Should have 1 Circle');

    // Connect the two shapes via connector tool: drag line from first to second
    // Select Connector via toolbar button
    await $(const Key('tool_connector')).tap();
    await $.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Verify connector tool is selected
    expect(service.currentTool, equals(ToolType.connector),
           reason: 'Connector tool should be active');

    // Drag from rectangle's right edge to circle center to connect them
    final Offset rectCenter = Offset(
      (rectStart.dx + rectEnd.dx) / 2,
      (rectStart.dy + rectEnd.dy) / 2,
    );
    final double rectWidth = (rectEnd.dx - rectStart.dx).abs();
    final Offset connectorStart = Offset(rectCenter.dx + rectWidth / 2 - 2, rectCenter.dy);

    final Offset circleCenter = Offset(
      (circleStart.dx + circleEnd.dx) / 2,
      (circleStart.dy + circleEnd.dy) / 2,
    );
    final Offset connectorEnd = circleCenter;

    print('🔗 Creating connector from $connectorStart to $connectorEnd');
    print('   Rectangle center: $rectCenter, Circle center: $circleCenter');

    final objectsBeforeConnector = service.objects.length;
    await performMouseDrag($, connectorStart, connectorEnd, steps: 30, stepDuration: const Duration(milliseconds: 40));

    // Small wait-and-check loop to allow connector creation to complete
    {
      final start = DateTime.now();
      final expectedCount = objectsBeforeConnector + 1;
      while (service.objects.length < expectedCount && DateTime.now().difference(start).inMilliseconds < 1500) {
        await $.tester.pump(const Duration(milliseconds: 60));
        print('  ⏳ Waiting for connector... (${service.objects.length}/$expectedCount objects)');
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Verify connector was created
    print('📊 Objects before connector: $objectsBeforeConnector, after: ${service.objects.length}');
    if (service.objects.length > objectsBeforeConnector) {
      final lastObj = service.objects.last;
      print('   Last created object: ${lastObj.getDisplayTypeName()}');
    }

    // Verify connector was created
    int objectsAfterConnector = service.objects.length;
    print('📊 Objects after creating connector: $objectsAfterConnector');
    expect(objectsAfterConnector, equals(3), reason: 'Should have 3 objects (Rectangle, Circle, and Connector)');

    // Verify we have a connector
    final connectors = service.objects.where((obj) => obj is Connector).toList();
    expect(connectors.length, equals(1), reason: 'Should have 1 Connector');

    // Assert: Objects panel shows newly created Rectangle, Circle, and Connector groups via keys
    expect(find.byKey(const Key('objectsGroup_Rectangle')), findsOneWidget,
           reason: 'Rectangle group should be visible in objects panel');
    expect(find.byKey(const Key('objectsGroup_Circle')), findsOneWidget,
           reason: 'Circle group should be visible in objects panel');
    expect(find.byKey(const Key('objectsGroup_Connector')), findsOneWidget,
           reason: 'Connector group should be visible in objects panel');

    // Undo/Redo via Ctrl+Z / Ctrl+Y
    await $.tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await $.tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await $.tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await $.tester.pumpAndSettle();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    await $.tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await $.tester.sendKeyEvent(LogicalKeyboardKey.keyY);
    await $.tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await $.tester.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 1));

    // Context menu step skipped for Patrol 3.0 on Windows desktop
    await Future<void>.delayed(const Duration(seconds: 1));

    // Final verification: All objects are still present after undo/redo
    final finalObjects = service.objects;
    print('📊 Final object count: ${finalObjects.length}');
    expect(finalObjects.length, equals(3), reason: 'Should still have 3 objects after undo/redo');

    // Verify all object types are correct
    final finalRectangles = finalObjects.where((obj) => obj.getDisplayTypeName() == 'Rectangle').toList();
    final finalCircles = finalObjects.where((obj) => obj.getDisplayTypeName() == 'Circle').toList();
    final finalConnectors = finalObjects.where((obj) => obj is Connector).toList();

    expect(finalRectangles.length, equals(1), reason: 'Should have 1 Rectangle at end');
    expect(finalCircles.length, equals(1), reason: 'Should have 1 Circle at end');
    expect(finalConnectors.length, equals(1), reason: 'Should have 1 Connector at end');

    // Verify objects panel still shows all groups after undo/redo
    expect(find.byKey(const Key('objectsGroup_Rectangle')), findsOneWidget,
           reason: 'Rectangle group should be visible in panel after undo/redo');
    expect(find.byKey(const Key('objectsGroup_Circle')), findsOneWidget,
           reason: 'Circle group should be visible in panel after undo/redo');
    expect(find.byKey(const Key('objectsGroup_Connector')), findsOneWidget,
           reason: 'Connector group should be visible in panel after undo/redo');

    print('✅ All canvas features tested successfully!');
    print('✅ Created 2 different shapes (Rectangle and Circle)');
    print('✅ Connected them using the connector tool');
    print('✅ Verified all objects appear in the objects panel');

    // Final small pause for visual confirmation
    await Future<void>.delayed(const Duration(seconds: 2));
  });
}


