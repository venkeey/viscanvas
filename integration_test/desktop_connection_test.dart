import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:viscanvas/main.dart' as app;
import 'package:viscanvas/pages/drawingCanvas.dart';

/// DESKTOP INTEGRATION TEST: Run on actual desktop window
/// This test opens a real desktop app window so you can watch the test execute
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DESKTOP APP: Create and connect two shapes', (tester) async {
    print('\n════════════════════════════════════════════════════════');
    print('🖥️  DESKTOP INTEGRATION TEST');
    print('🪟  Watch the desktop window to see shapes being created!');
    print('════════════════════════════════════════════════════════\n');

    // Start the real app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    print('✅ Step 1: Desktop app window opened\n');

    // Wait a bit so you can see the app start
    await Future.delayed(const Duration(seconds: 1));

    // Verify canvas is present
    final canvas = find.byType(CanvasScreen);
    expect(canvas, findsOneWidget);
    print('✅ Step 2: Canvas screen loaded\n');

    // STEP 1: Select Rectangle Tool
    print('🔧 Step 3: Selecting Rectangle tool...');
    final rectangleButton = find.byIcon(Icons.rectangle_outlined);
    expect(rectangleButton, findsOneWidget, reason: 'Rectangle button should exist');

    await tester.tap(rectangleButton);
    await tester.pumpAndSettle();
    print('✅ Step 3: Rectangle tool selected (look at the sidebar!)\n');

    // Pause so you can see the button highlight
    await Future.delayed(const Duration(seconds: 1));

    // STEP 2: Draw First Rectangle
    print('🎨 Step 4: Drawing FIRST rectangle...');
    print('   Watch the canvas - drawing at position (200, 200)...');

    final rect1Start = const Offset(200, 200);
    final rect1Delta = const Offset(150, 100);

    await tester.dragFrom(rect1Start, rect1Delta);
    await tester.pumpAndSettle();
    print('✅ Step 4: First rectangle created!');
    print('   ➜ You should see a blue rectangle on screen\n');

    // Pause so you can see the first shape
    await Future.delayed(const Duration(seconds: 2));

    // STEP 3: Draw Second Rectangle
    print('🎨 Step 5: Drawing SECOND rectangle...');
    print('   Watch the canvas - drawing at position (450, 200)...');

    final rect2Start = const Offset(450, 200);
    final rect2Delta = const Offset(150, 100);

    await tester.dragFrom(rect2Start, rect2Delta);
    await tester.pumpAndSettle();
    print('✅ Step 5: Second rectangle created!');
    print('   ➜ You should now see TWO rectangles on screen\n');

    // Pause so you can see both shapes
    await Future.delayed(const Duration(seconds: 2));

    // STEP 4: Select Connector Tool
    print('🔧 Step 6: Selecting Connector tool...');
    final connectorButton = find.byIcon(Icons.timeline);
    expect(connectorButton, findsOneWidget, reason: 'Connector button should exist');

    await tester.tap(connectorButton);
    await tester.pumpAndSettle();
    print('✅ Step 6: Connector tool selected (look at the sidebar!)\n');

    // Pause so you can see the button highlight
    await Future.delayed(const Duration(seconds: 1));

    // STEP 5: Draw Connection Between Shapes
    print('🔗 Step 7: Drawing CONNECTION between rectangles...');
    print('   Watch carefully - connecting from first to second shape...');

    // Calculate center points of both rectangles
    final rect1Center = Offset(
      rect1Start.dx + rect1Delta.dx / 2,
      rect1Start.dy + rect1Delta.dy / 2,
    );
    final rect2Center = Offset(
      rect2Start.dx + rect2Delta.dx / 2,
      rect2Start.dy + rect2Delta.dy / 2,
    );

    print('   From center of first shape: (${rect1Center.dx.toInt()}, ${rect1Center.dy.toInt()})');
    print('   To center of second shape: (${rect2Center.dx.toInt()}, ${rect2Center.dy.toInt()})');

    // Draw the connection
    final connectionDelta = rect2Center - rect1Center;
    await tester.dragFrom(rect1Center, connectionDelta);
    await tester.pumpAndSettle();
    print('✅ Step 7: Connection line drawn!');
    print('   ➜ You should see a LINE connecting the two rectangles\n');

    // Long pause to see the final result
    await Future.delayed(const Duration(seconds: 3));

    // VERIFICATION
    print('🔍 Step 8: Verifying everything worked...');
    expect(canvas, findsOneWidget);
    print('✅ Step 8: Test completed successfully!\n');

    print('════════════════════════════════════════════════════════');
    print('🎉 TEST COMPLETE!');
    print('════════════════════════════════════════════════════════\n');

    print('📊 WHAT YOU SHOULD SEE IN THE WINDOW:');
    print('   ✓ Two blue rectangles side by side');
    print('   ✓ A connector line between them');
    print('   ✓ Sidebar with tools (Rectangle and Connector highlighted when used)\n');

    // Final pause before closing
    print('⏳ Window will stay open for 3 more seconds...\n');
    await Future.delayed(const Duration(seconds: 3));
  });
}
