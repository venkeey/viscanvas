import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:viscanvas/ui/canvas_screen.dart';

void main() {
  group('CanvasScreen Basic Tests', () {
    testWidgets('should render CanvasScreen without errors', (tester) async {
      // Set up a larger test window to accommodate the sidebar
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: CanvasScreen(),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify basic components are present
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('should handle basic keyboard shortcuts', (tester) async {
      // Set up a larger test window
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: CanvasScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Test escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      // Test select tool shortcut (V key)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.pump();

      // Verify the screen still renders after keyboard events
      expect(find.byType(CanvasScreen), findsOneWidget);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('should handle basic canvas interactions', (tester) async {
      // Set up a larger test window
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: CanvasScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the main canvas area (CustomPaint)
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify the screen works
      expect(find.byType(CanvasScreen), findsOneWidget);

      // Reset window size
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}