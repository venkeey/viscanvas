import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/main.dart' as app;
import 'package:viscanvas/pages/drawingCanvas.dart';

/// DETAILED DIAGNOSTIC: Why connectors don't work
void main() {
  testWidgets('DETAILED: Why can\'t we connect shapes?', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    print('\n═══════════════════════════════════════════════════════');
    print('🔍 DIAGNOSTIC: Connector Functionality');
    print('═══════════════════════════════════════════════════════\n');

    // 1. Check if CanvasService exists
    final canvasScreen = find.byType(CanvasScreen);
    expect(canvasScreen, findsOneWidget);
    print('✅ 1. CanvasScreen widget exists');

    // 2. Check what tools are available
    final allButtons = find.byType(IconButton);
    print('📊 2. Found ${allButtons.evaluate().length} IconButtons in UI');

    if (allButtons.evaluate().isEmpty) {
      print('❌    NO TOOL BUTTONS FOUND! This is the problem!');
    } else {
      print('   Tool buttons:');
      for (int i = 0; i < allButtons.evaluate().length && i < 10; i++) {
        try {
          final button = tester.widget<IconButton>(allButtons.at(i));
          final icon = button.icon;
          print('   - Button $i: ${icon.runtimeType}');
        } catch (e) {
          print('   - Button $i: Could not inspect');
        }
      }
    }

    // 3. Look for specific tool icons
    print('\n🔍 3. Checking for expected tool icons:');
    final toolChecks = {
      'Select (near_me)': Icons.near_me,
      'Rectangle': Icons.rectangle_outlined,
      'Circle': Icons.circle_outlined,
      'Connector (timeline)': Icons.timeline,
      'Pan (pan_tool)': Icons.pan_tool,
    };

    for (final entry in toolChecks.entries) {
      final found = find.byIcon(entry.value);
      if (found.evaluate().isNotEmpty) {
        print('   ✅ ${entry.key} - FOUND');
      } else {
        print('   ❌ ${entry.key} - MISSING');
      }
    }

    // 4. Check sidebar
    final sidebar = find.byType(CustomScrollView);
    print('\n📊 4. Sidebar check:');
    if (sidebar.evaluate().isEmpty) {
      print('   ❌ No CustomScrollView found (sidebar might be missing)');
    } else {
      print('   ✅ CustomScrollView exists');
    }

    // 5. Try to create shapes
    print('\n🎨 5. Creating test shapes...');
    await tester.drag(find.byType(CanvasScreen), const Offset(100, 80));
    await tester.pumpAndSettle();
    print('   ✅ Drag gesture completed (shape may or may not be created)');

    // 6. Try to find any created objects
    final customPaints = find.byType(CustomPaint);
    print('\n📊 6. Found ${customPaints.evaluate().length} CustomPaint widgets');
    print('   (Shapes should render via CustomPaint)');

    // 7. Check for any error text
    final errorTexts = find.textContaining('Error', findRichText: true);
    if (errorTexts.evaluate().isNotEmpty) {
      print('\n❌ 7. Found error messages in UI!');
      for (final error in errorTexts.evaluate()) {
        try {
          final text = error.widget as Text;
          print('   Error: ${text.data}');
        } catch (e) {
          print('   Error: Could not read error text');
        }
      }
    } else {
      print('\n✅ 7. No error messages visible');
    }

    // 8. Summary
    print('\n═══════════════════════════════════════════════════════');
    print('📋 DIAGNOSIS SUMMARY:');
    print('═══════════════════════════════════════════════════════');

    final hasButtons = allButtons.evaluate().isNotEmpty;
    final hasConnectorIcon = find.byIcon(Icons.timeline).evaluate().isNotEmpty;

    if (!hasButtons) {
      print('🚨 CRITICAL: No tool buttons found in UI!');
      print('   Root cause: Sidebar or tool palette not rendering');
      print('   Fix: Check MiroSidebar or toolbar widget initialization');
    } else if (!hasConnectorIcon) {
      print('🚨 PROBLEM: Connector tool button missing!');
      print('   Root cause: Connector icon not added to toolbar');
      print('   Fix: Add Icons.timeline button to MiroSidebar');
    } else {
      print('✅ UI elements present - issue may be in event handling');
      print('   Next: Test actual connector tool activation');
    }

    print('\n═══════════════════════════════════════════════════════\n');
  });

  testWidgets('DETAILED: Can we activate connector tool if it exists?', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    print('\n🔧 Attempting to activate connector tool...\n');

    // Try to find and tap connector button
    final connectorButton = find.byIcon(Icons.timeline);

    if (connectorButton.evaluate().isEmpty) {
      print('❌ CONFIRMED: Connector button does not exist in UI');
      print('   This is why you cannot connect shapes!');
      return;
    }

    print('✅ Connector button found! Tapping...');
    await tester.tap(connectorButton);
    await tester.pumpAndSettle();

    print('✅ Connector tool activation attempted');

    // Now try to draw a connection
    print('\n🔗 Attempting to draw connection...');
    await tester.dragFrom(const Offset(200, 200), const Offset(400, 200));
    await tester.pumpAndSettle();

    print('✅ Connection drag gesture completed');
    print('   (Check visually if connector line appeared)');
  });

  testWidgets('DETAILED: What happens when we create shapes?', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    print('\n🎨 Testing shape creation workflow...\n');

    final canvas = find.byType(CanvasScreen);

    // Count CustomPaint widgets before
    final paintsBefore = find.byType(CustomPaint).evaluate().length;
    print('📊 CustomPaint widgets before: $paintsBefore');

    // Try to create a shape
    print('🖱️  Drawing shape...');
    await tester.dragFrom(const Offset(300, 300), const Offset(100, 80));
    await tester.pumpAndSettle();

    // Count CustomPaint widgets after
    final paintsAfter = find.byType(CustomPaint).evaluate().length;
    print('📊 CustomPaint widgets after: $paintsAfter');

    if (paintsAfter > paintsBefore) {
      print('✅ New CustomPaint created! Shape likely rendered.');
    } else {
      print('❌ No new CustomPaint! Shape not created or not rendered.');
      print('   Issue: Shape creation logic not working');
    }

    // Try to interact with the shape
    print('\n🖱️  Attempting to tap on shape location...');
    await tester.tapAt(const Offset(350, 340));
    await tester.pumpAndSettle();
    print('✅ Tap completed');

    // Try to drag the shape
    print('\n🖱️  Attempting to drag shape...');
    await tester.drag(canvas, const Offset(50, 50));
    await tester.pumpAndSettle();
    print('✅ Drag completed');
    print('   (Check visually if shape moved)');
  });
}
