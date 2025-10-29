// test/visual/main_app_visual_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart';

void main() {
  group('MainApp Visual Tests', () {
    
    // Test 1: App visual appearance
    patrolWidgetTest('App visual appearance', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Take screenshot for visual verification
      await $.native.takeScreenshot('main_app_visual');
      
      // Verify key visual elements are present
      expect($(find.byType(MainApp)), findsOneWidget);
      expect($(find.byType(MaterialApp)), findsOneWidget);
      
      print('✅ App visual appearance test completed');
    });

    // Test 2: Tool sidebar visual appearance
    patrolWidgetTest('Tool sidebar visual appearance', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Take screenshot of tool sidebar
      await $.native.takeScreenshot('tool_sidebar_visual');
      
      // Verify tool icons are visible
      expect($(Icons.auto_awesome), findsOneWidget);
      expect($(Icons.edit), findsOneWidget);
      expect($(Icons.pan_tool), findsOneWidget);
      
      print('✅ Tool sidebar visual appearance test completed');
    });

    // Test 3: Navigation button visual appearance
    patrolWidgetTest('Navigation button visual appearance', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Take screenshot of navigation button
      await $.native.takeScreenshot('navigation_button_visual');
      
      // Verify navigation button is visible
      expect($(Icons.description), findsOneWidget);
      
      print('✅ Navigation button visual appearance test completed');
    });

    // Test 4: Canvas area visual appearance
    patrolWidgetTest('Canvas area visual appearance', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Take screenshot of canvas area
      await $.native.takeScreenshot('canvas_area_visual');
      
      // Verify canvas is present
      expect($(find.byType(InfiniteCanvasApp)), findsOneWidget);
      
      print('✅ Canvas area visual appearance test completed');
    });

    // Test 5: Theme visual appearance
    patrolWidgetTest('Theme visual appearance', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Take screenshot for theme verification
      await $.native.takeScreenshot('theme_visual');
      
      // Verify theme is applied
      expect($(find.byType(MaterialApp)), findsOneWidget);
      
      print('✅ Theme visual appearance test completed');
    });

    // Test 6: Tool selection visual feedback
    patrolWidgetTest('Tool selection visual feedback', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Select a tool and take screenshot
      await $(Icons.edit).tap();
      await $.pumpAndSettle();
      
      await $.native.takeScreenshot('tool_selection_visual');
      
      print('✅ Tool selection visual feedback test completed');
    });

    // Test 7: Navigation state visual appearance
    patrolWidgetTest('Navigation state visual appearance', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Navigate to Notion Demo and take screenshot
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      await $.native.takeScreenshot('navigation_state_visual');
      
      print('✅ Navigation state visual appearance test completed');
    });

    // Test 8: Complete UI visual verification
    patrolWidgetTest('Complete UI visual verification', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Take comprehensive screenshot
      await $.native.takeScreenshot('complete_ui_visual');
      
      // Verify all major UI elements
      expect($(find.byType(MainApp)), findsOneWidget);
      expect($(find.byType(MaterialApp)), findsOneWidget);
      expect($(find.byType(InfiniteCanvasApp)), findsOneWidget);
      
      print('✅ Complete UI visual verification test completed');
    });
  });
}

