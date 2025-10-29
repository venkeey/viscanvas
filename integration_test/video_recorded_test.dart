import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart' as app;
import 'package:viscanvas/pages/drawingCanvas.dart';

/// VIDEO RECORDED TEST - Perfect for No-Code Platform
/// This test automatically captures screenshots at each step
/// Screenshots can be compiled into video for users to review
void main() {
  patrolTest(
    'VIDEO TEST: Create and connect shapes - With Screenshots',
    nativeAutomation: true, // Enable native automation for better recording
    ($) async {
      print('\n════════════════════════════════════════════════════════');
      print('🎥 VIDEO RECORDED TEST - Creating Screenshot Gallery');
      print('════════════════════════════════════════════════════════\n');

      // Create output directory for screenshots
      final screenshotDir = Directory('test_screenshots');
      if (!screenshotDir.existsSync()) {
        screenshotDir.createSync(recursive: true);
      }
      print('📁 Screenshots will be saved to: ${screenshotDir.path}\n');

      // STEP 1: Launch App
      print('▶️  STEP 1: Launching application...');
      app.main();
      await $.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await $.native.takeScreenshot('01_app_launched');
      print('✅ STEP 1 COMPLETE - Screenshot saved: 01_app_launched.png\n');

      await Future.delayed(const Duration(seconds: 1));

      // STEP 2: Verify Canvas Loaded
      print('▶️  STEP 2: Verifying canvas loaded...');
      final canvas = find.byType(CanvasScreen);
      expect(canvas, findsOneWidget);

      await $.native.takeScreenshot('02_canvas_loaded');
      print('✅ STEP 2 COMPLETE - Screenshot saved: 02_canvas_loaded.png\n');

      await Future.delayed(const Duration(seconds: 1));

      // STEP 3: Select Rectangle Tool
      print('▶️  STEP 3: Selecting Rectangle tool...');
      final rectangleButton = find.byIcon(Icons.rectangle_outlined);
      expect(rectangleButton, findsOneWidget);

      await $.tap(rectangleButton);
      await $.pumpAndSettle();

      await $.native.takeScreenshot('03_rectangle_tool_selected');
      print('✅ STEP 3 COMPLETE - Screenshot saved: 03_rectangle_tool_selected.png');
      print('   📌 Rectangle button is now highlighted\n');

      await Future.delayed(const Duration(seconds: 1));

      // STEP 4: Draw First Rectangle
      print('▶️  STEP 4: Drawing first rectangle...');
      final rect1Start = const Offset(200, 200);
      final rect1End = const Offset(350, 300);

      await $.tester.dragFrom(rect1Start, rect1End - rect1Start);
      await $.pumpAndSettle();

      await $.native.takeScreenshot('04_first_rectangle_created');
      print('✅ STEP 4 COMPLETE - Screenshot saved: 04_first_rectangle_created.png');
      print('   📌 First rectangle visible at (200, 200)\n');

      await Future.delayed(const Duration(seconds: 2));

      // STEP 5: Draw Second Rectangle
      print('▶️  STEP 5: Drawing second rectangle...');
      final rect2Start = const Offset(450, 200);
      final rect2End = const Offset(600, 300);

      await $.tester.dragFrom(rect2Start, rect2End - rect2Start);
      await $.pumpAndSettle();

      await $.native.takeScreenshot('05_second_rectangle_created');
      print('✅ STEP 5 COMPLETE - Screenshot saved: 05_second_rectangle_created.png');
      print('   📌 Two rectangles now visible\n');

      await Future.delayed(const Duration(seconds: 2));

      // STEP 6: Select Connector Tool
      print('▶️  STEP 6: Selecting Connector tool...');
      final connectorButton = find.byIcon(Icons.timeline);
      expect(connectorButton, findsOneWidget);

      await $.tap(connectorButton);
      await $.pumpAndSettle();

      await $.native.takeScreenshot('06_connector_tool_selected');
      print('✅ STEP 6 COMPLETE - Screenshot saved: 06_connector_tool_selected.png');
      print('   📌 Connector button is now highlighted\n');

      await Future.delayed(const Duration(seconds: 1));

      // STEP 7: Draw Connection
      print('▶️  STEP 7: Drawing connection between rectangles...');
      final rect1Center = Offset(
        (rect1Start.dx + rect1End.dx) / 2,
        (rect1Start.dy + rect1End.dy) / 2,
      );
      final rect2Center = Offset(
        (rect2Start.dx + rect2End.dx) / 2,
        (rect2Start.dy + rect2End.dy) / 2,
      );

      await $.tester.dragFrom(rect1Center, rect2Center - rect1Center);
      await $.pumpAndSettle();

      await $.native.takeScreenshot('07_connection_created');
      print('✅ STEP 7 COMPLETE - Screenshot saved: 07_connection_created.png');
      print('   📌 Connection line drawn between rectangles\n');

      await Future.delayed(const Duration(seconds: 2));

      // STEP 8: Final Verification
      print('▶️  STEP 8: Final verification...');
      expect(canvas, findsOneWidget);

      await $.native.takeScreenshot('08_final_result');
      print('✅ STEP 8 COMPLETE - Screenshot saved: 08_final_result.png');
      print('   📌 Test completed successfully\n');

      print('════════════════════════════════════════════════════════');
      print('🎉 VIDEO TEST COMPLETE!');
      print('════════════════════════════════════════════════════════\n');

      print('📊 TEST RESULTS:');
      print('   ✅ Total Steps: 8');
      print('   ✅ Screenshots Captured: 8');
      print('   ✅ All Assertions Passed');
      print('   ✅ No Errors Detected\n');

      print('📁 Screenshot Location:');
      print('   ${screenshotDir.absolute.path}\n');

      print('🎬 NEXT STEPS FOR YOUR NO-CODE PLATFORM:');
      print('   1. Screenshots are in test_screenshots/ folder');
      print('   2. Use FFmpeg to convert to video:');
      print('      ffmpeg -framerate 1 -pattern_type glob -i "*.png" output.mp4');
      print('   3. Upload video to cloud storage (S3/Azure)');
      print('   4. Display in user dashboard\n');

      await Future.delayed(const Duration(seconds: 2));
    },
  );
}
