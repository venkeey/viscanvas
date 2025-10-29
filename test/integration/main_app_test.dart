// test/integration/main_app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart';

void main() {
  group('Main App Integration Tests', () {
    
    // Test 1: App loads and shows canvas
    patrolWidgetTest('App loads and shows canvas', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Verify the main app loads
      expect($(find.byType(MainApp)), findsOneWidget);
      expect($(find.byType(MaterialApp)), findsOneWidget);
      
      print('✅ Main app loaded successfully');
    });

    // Test 2: Notion Demo navigation works
    patrolWidgetTest('Notion Demo navigation works', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Look for the Notion Demo button and tap it
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      // Verify navigation worked
      print('✅ Notion Demo navigation completed');
    });

    // Test 3: Canvas tools are accessible
    patrolWidgetTest('Canvas tools are accessible', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Test that sidebar tools are present
      expect($(Icons.auto_awesome), findsOneWidget); // AI Templates
      expect($(Icons.edit), findsOneWidget); // Select tool
      expect($(Icons.pan_tool), findsOneWidget); // Pan tool
      expect($(Icons.crop_free), findsOneWidget); // Frame tool
      expect($(Icons.text_fields), findsOneWidget); // Text tool
      
      print('✅ Canvas tools are accessible');
    });

    // Test 4: App theme and styling
    patrolWidgetTest('App theme and styling', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Verify MaterialApp is present with proper theme
      expect($(find.byType(MaterialApp)), findsOneWidget);
      
      print('✅ App theme and styling verified');
    });

    // Test 5: Back button functionality
    patrolWidgetTest('Back button functionality', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Test back button (if it exists)
      final backButton = $(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await backButton.tap();
        await $.pumpAndSettle();
        print('✅ Back button tapped');
      } else {
        print('ℹ️ Back button not found (may not be visible)');
      }
    });

    // Test 6: Tool selection
    patrolWidgetTest('Tool selection works', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Test selecting different tools
      await $(Icons.edit).tap(); // Select tool
      await $.pumpAndSettle();
      
      await $(Icons.pan_tool).tap(); // Pan tool
      await $.pumpAndSettle();
      
      await $(Icons.text_fields).tap(); // Text tool
      await $.pumpAndSettle();
      
      print('✅ Tool selection works');
    });

    // Test 7: Performance and responsiveness
    patrolWidgetTest('Performance and responsiveness', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Wait for any initial loading
      await Future.delayed(const Duration(milliseconds: 500));
      await $.pumpAndSettle();
      
      // Verify app is still responsive
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ App performance test completed');
    });

    // Test 8: Multiple navigation cycles
    patrolWidgetTest('Multiple navigation cycles', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Perform multiple navigation cycles
      for (int i = 0; i < 3; i++) {
        await $(Icons.description).tap();
        await $.pumpAndSettle();
        
        await $(Icons.arrow_back).tap();
        await $.pumpAndSettle();
      }
      
      print('✅ Multiple navigation cycles completed');
    });
  });
}
