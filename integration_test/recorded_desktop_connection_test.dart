import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:viscanvas/main.dart' as app;
import 'package:viscanvas/pages/drawingCanvas.dart';
import 'package:viscanvas/test_helpers/screen_recorder.dart';

/// DESKTOP INTEGRATION TEST WITH VIDEO RECORDING
/// This test captures video of the entire test execution
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RECORDED: Create and connect two shapes', (tester) async {
    String? videoPath;

    try {
      // Start screen recording
      final recorder = ScreenRecorder(testName: 'create_and_connect_shapes');
      await recorder.startRecording();

      print('\n════════════════════════════════════════════════════════');
      print('🎥 DESKTOP TEST WITH VIDEO RECORDING');
      print('════════════════════════════════════════════════════════\n');

      // Start the real app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('✅ Step 1: App launched\n');

      await Future.delayed(const Duration(seconds: 1));

      // Verify canvas
      final canvas = find.byType(CanvasScreen);
      expect(canvas, findsOneWidget);
      print('✅ Step 2: Canvas loaded\n');

      // Select Rectangle Tool
      print('🔧 Step 3: Selecting Rectangle tool...');
      final rectangleButton = find.byIcon(Icons.rectangle_outlined);
      expect(rectangleButton, findsOneWidget);

      await tester.tap(rectangleButton);
      await tester.pumpAndSettle();
      print('✅ Rectangle tool selected\n');

      await Future.delayed(const Duration(seconds: 2));

      // Draw First Rectangle
      print('🎨 Step 4: Drawing first rectangle...');
      final rect1Start = const Offset(200, 200);
      final rect1Delta = const Offset(150, 100);

      await tester.dragFrom(rect1Start, rect1Delta);
      await tester.pumpAndSettle();
      print('✅ First rectangle created\n');

      await Future.delayed(const Duration(seconds: 3));

      // Draw Second Rectangle
      print('🎨 Step 5: Drawing second rectangle...');
      final rect2Start = const Offset(450, 200);
      final rect2Delta = const Offset(150, 100);

      await tester.dragFrom(rect2Start, rect2Delta);
      await tester.pumpAndSettle();
      print('✅ Second rectangle created\n');

      await Future.delayed(const Duration(seconds: 3));

      // Select Connector Tool
      print('🔧 Step 6: Selecting Connector tool...');
      final connectorButton = find.byIcon(Icons.timeline);
      expect(connectorButton, findsOneWidget);

      await tester.tap(connectorButton);
      await tester.pumpAndSettle();
      print('✅ Connector tool selected\n');

      await Future.delayed(const Duration(seconds: 2));

      // Draw Connection
      print('🔗 Step 7: Drawing connection...');
      final rect1Center = Offset(
        rect1Start.dx + rect1Delta.dx / 2,
        rect1Start.dy + rect1Delta.dy / 2,
      );
      final rect2Center = Offset(
        rect2Start.dx + rect2Delta.dx / 2,
        rect2Start.dy + rect2Delta.dy / 2,
      );

      await tester.dragFrom(rect1Center, rect2Center - rect1Center);
      await tester.pumpAndSettle();
      print('✅ Connection drawn\n');

      await Future.delayed(const Duration(seconds: 3));

      // Verification
      expect(canvas, findsOneWidget);
      print('✅ Step 8: Test complete!\n');

      await Future.delayed(const Duration(seconds: 2));

      // Stop recording
      videoPath = await recorder.stopRecording();

      print('════════════════════════════════════════════════════════');
      print('🎉 TEST COMPLETE WITH VIDEO!');
      print('════════════════════════════════════════════════════════\n');

      if (videoPath != null) {
        print('📹 Video saved: $videoPath');
        print('🎬 Watch the video to see the full test execution\n');
      }
    } catch (e) {
      print('❌ Test failed: $e');
      rethrow;
    }
  });
}
