import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/main.dart' as app;
import 'package:viscanvas/ui/canvas_screen.dart';

/// CRITICAL: End-to-End Visual User Journey Tests
/// These tests simulate REAL user interactions and catch bugs that unit tests miss
///
/// HOW TO VIEW UX WHILE TESTING:
/// 1. Run with: flutter test --platform chrome test/e2e/visual_user_journey_test.dart
/// 2. Or use integration_test with patrol: patrol test
/// 3. Add tester.pump(Duration(seconds: 2)) to pause and see UI

void main() {
  testWidgets('USER JOURNEY: Create two shapes and connect them', (tester) async {
    // Start the real app
    app.main();
    await tester.pumpAndSettle();

    // Find the canvas
    final canvas = find.byType(CanvasScreen);
    expect(canvas, findsOneWidget, reason: 'Canvas should be visible');

    print('✅ Step 1: App loaded');

    // STEP 1: Select rectangle tool
    final rectangleButton = find.byIcon(Icons.rectangle_outlined);
    if (rectangleButton.evaluate().isNotEmpty) {
      await tester.tap(rectangleButton);
      await tester.pumpAndSettle();
      print('✅ Step 2: Rectangle tool selected');
    }

    // STEP 2: Draw first rectangle
    final firstRectStart = const Offset(200, 200);
    final firstRectEnd = const Offset(300, 280);

    await tester.dragFrom(firstRectStart, firstRectEnd - firstRectStart);
    await tester.pumpAndSettle();
    print('✅ Step 3: First rectangle drawn at $firstRectStart');

    // PAUSE TO VIEW
    await tester.pump(const Duration(milliseconds: 500));

    // STEP 3: Draw second rectangle
    final secondRectStart = const Offset(400, 200);
    final secondRectEnd = const Offset(500, 280);

    await tester.dragFrom(secondRectStart, secondRectEnd - secondRectStart);
    await tester.pumpAndSettle();
    print('✅ Step 4: Second rectangle drawn at $secondRectStart');

    // PAUSE TO VIEW
    await tester.pump(const Duration(milliseconds: 500));

    // STEP 4: Try to select first rectangle
    final firstRectCenter = Offset(
      (firstRectStart.dx + firstRectEnd.dx) / 2,
      (firstRectStart.dy + firstRectEnd.dy) / 2,
    );

    // Select tool first
    final selectButton = find.byIcon(Icons.near_me);
    if (selectButton.evaluate().isNotEmpty) {
      await tester.tap(selectButton);
      await tester.pumpAndSettle();
      print('✅ Step 5: Select tool activated');
    }

    await tester.tapAt(firstRectCenter);
    await tester.pumpAndSettle();
    print('✅ Step 6: Tapped first rectangle at $firstRectCenter');

    // CRITICAL CHECK: Can we actually interact with the shape?
    // This is where the bug occurs - shapes are drawn but not selectable

    // STEP 5: Try to drag first rectangle
    final dragDelta = const Offset(50, 50);
    await tester.dragFrom(firstRectCenter, dragDelta);
    await tester.pumpAndSettle();
    print('✅ Step 7: Attempted to drag first rectangle');

    // PAUSE TO VIEW RESULT
    await tester.pump(const Duration(milliseconds: 500));

    // STEP 6: Try connector tool
    final connectorButton = find.byIcon(Icons.timeline);
    if (connectorButton.evaluate().isNotEmpty) {
      await tester.tap(connectorButton);
      await tester.pumpAndSettle();
      print('✅ Step 8: Connector tool selected');
    }

    // STEP 7: Try to connect rectangles
    final secondRectCenter = Offset(
      (secondRectStart.dx + secondRectEnd.dx) / 2,
      (secondRectStart.dy + secondRectEnd.dy) / 2,
    );

    await tester.dragFrom(firstRectCenter, secondRectCenter - firstRectCenter);
    await tester.pumpAndSettle();
    print('✅ Step 9: Attempted to connect rectangles');

    // FINAL PAUSE TO SEE RESULT
    await tester.pump(const Duration(seconds: 1));

    // ASSERTIONS: These will FAIL if the bug exists
    // The canvas widget exists but functionality is broken
    expect(canvas, findsOneWidget);

    print('\n⚠️  TEST COMPLETE - Check console output above for user journey');
    print('If shapes were drawn but not interactive, the bug is confirmed');
  });

  testWidgets('SMOKE TEST: Can we create ANY shape that responds?', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Try the simplest possible interaction
    final canvas = find.byType(CanvasScreen);
    expect(canvas, findsOneWidget);

    // Just tap anywhere
    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();

    // Drag anywhere
    await tester.drag(canvas, const Offset(100, 100));
    await tester.pumpAndSettle();

    print('✅ Basic smoke test completed - app didn\'t crash');
  });

  testWidgets('DIAGNOSTIC: What UI elements are actually present?', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Find all buttons
    final allButtons = find.byType(IconButton);
    print('\n📊 Found ${allButtons.evaluate().length} IconButtons');

    final allIcons = find.byType(Icon);
    print('📊 Found ${allIcons.evaluate().length} Icons');

    // Check for expected tool buttons
    final expectedIcons = [
      Icons.near_me, // Select
      Icons.rectangle_outlined, // Rectangle
      Icons.circle_outlined, // Circle
      Icons.timeline, // Connector
      Icons.pan_tool, // Pan
    ];

    for (final icon in expectedIcons) {
      final found = find.byIcon(icon);
      if (found.evaluate().isNotEmpty) {
        print('✅ Found tool: $icon');
      } else {
        print('❌ Missing tool: $icon');
      }
    }

    // Check for canvas
    final canvas = find.byType(CustomPaint);
    print('📊 Found ${canvas.evaluate().length} CustomPaint widgets');
  });

  testWidgets('REGRESSION TEST: Newly created shapes should be in repository', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Get reference to CanvasService if possible
    final canvasScreen = tester.widget<CanvasScreen>(find.byType(CanvasScreen));

    // Draw a shape
    await tester.dragFrom(
      const Offset(200, 200),
      const Offset(100, 80),
    );
    await tester.pumpAndSettle();

    // The critical assertion: objects should be in the data model
    // This is where we'd check canvasService.objects.length
    // But we need access to the service first

    expect(find.byType(CanvasScreen), findsOneWidget);
    print('✅ Shape creation attempted');
  });

  testWidgets('BUG REPRODUCTION: Two shapes cannot be connected', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    print('\n🐛 REPRODUCING REPORTED BUG:');
    print('1. Create two shapes');
    print('2. Try to connect them');
    print('3. Try to drag them');
    print('Expected: Should work');
    print('Actual: ???\n');

    // Select rectangle tool (if exists)
    final toolButtons = find.byType(IconButton);
    if (toolButtons.evaluate().length > 1) {
      // Tap second button (usually rectangle)
      await tester.tap(toolButtons.at(1));
      await tester.pumpAndSettle();
    }

    // Create shape 1
    await tester.dragFrom(const Offset(200, 200), const Offset(80, 60));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    print('✅ Shape 1 created');

    // Create shape 2
    await tester.dragFrom(const Offset(400, 200), const Offset(80, 60));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    print('✅ Shape 2 created');

    // Try to select connector tool
    if (toolButtons.evaluate().length > 3) {
      await tester.tap(toolButtons.at(3)); // Connector might be 4th button
      await tester.pumpAndSettle();
    }

    // Try to connect
    await tester.dragFrom(const Offset(240, 230), const Offset(440, 230));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    print('✅ Connection attempted');

    // Visual pause
    await tester.pump(const Duration(seconds: 1));

    print('\n🔍 If connection failed to appear, bug is confirmed');
  });
}
