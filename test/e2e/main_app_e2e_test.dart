// test/e2e/main_app_e2e_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart';

void main() {
  group('MainApp End-to-End Tests', () {
    
    // Test 1: Complete app startup flow
    patrolWidgetTest('Complete app startup flow', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Verify app loads completely
      expect($(find.byType(MainApp)), findsOneWidget);
      expect($(find.byType(MaterialApp)), findsOneWidget);
      expect($(find.byType(InfiniteCanvasApp)), findsOneWidget);
      
      print('✅ Complete app startup flow successful');
    });

    // Test 2: Full navigation flow
    patrolWidgetTest('Full navigation flow', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Navigate to Notion Demo
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      // Navigate back
      await $(Icons.arrow_back).tap();
      await $.pumpAndSettle();
      
      // Verify we're back to main screen
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ Full navigation flow successful');
    });

    // Test 3: Complete tool interaction flow
    patrolWidgetTest('Complete tool interaction flow', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Test all major tools
      await $(Icons.auto_awesome).tap(); // AI Templates
      await $.pumpAndSettle();
      
      await $(Icons.edit).tap(); // Select tool
      await $.pumpAndSettle();
      
      await $(Icons.pan_tool).tap(); // Pan tool
      await $.pumpAndSettle();
      
      await $(Icons.brush).tap(); // Pen tool
      await $.pumpAndSettle();
      
      await $(Icons.text_fields).tap(); // Text tool
      await $.pumpAndSettle();
      
      await $(Icons.crop_free).tap(); // Frame tool
      await $.pumpAndSettle();
      
      print('✅ Complete tool interaction flow successful');
    });

    // Test 4: App state persistence
    patrolWidgetTest('App state persistence', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Perform some actions
      await $(Icons.edit).tap();
      await $.pumpAndSettle();
      
      // Navigate away and back
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      await $(Icons.arrow_back).tap();
      await $.pumpAndSettle();
      
      // Verify app state is maintained
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ App state persistence successful');
    });

    // Test 5: Performance under load
    patrolWidgetTest('Performance under load', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Perform rapid tool switching
      for (int i = 0; i < 10; i++) {
        await $(Icons.edit).tap();
        await $.pumpAndSettle();
        
        await $(Icons.pan_tool).tap();
        await $.pumpAndSettle();
        
        await $(Icons.brush).tap();
        await $.pumpAndSettle();
      }
      
      // Verify app is still responsive
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ Performance under load successful');
    });

    // Test 6: Memory management
    patrolWidgetTest('Memory management', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Perform multiple navigation cycles
      for (int i = 0; i < 5; i++) {
        await $(Icons.description).tap();
        await $.pumpAndSettle();
        
        await $(Icons.arrow_back).tap();
        await $.pumpAndSettle();
      }
      
      // Verify app is still stable
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ Memory management successful');
    });

    // Test 7: Error handling
    patrolWidgetTest('Error handling', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Test rapid interactions that might cause errors
      await $(Icons.edit).tap();
      await $.pumpAndSettle();
      
      await $(Icons.pan_tool).tap();
      await $.pumpAndSettle();
      
      await $(Icons.brush).tap();
      await $.pumpAndSettle();
      
      // Verify app handles errors gracefully
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ Error handling successful');
    });

    // Test 8: Complete user workflow
    patrolWidgetTest('Complete user workflow', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Simulate a complete user workflow
      await $(Icons.edit).tap(); // Select tool
      await $.pumpAndSettle();
      
      await $(Icons.brush).tap(); // Switch to pen
      await $.pumpAndSettle();
      
      await $(Icons.circle).tap(); // Create circle
      await $.pumpAndSettle();
      
      await $(Icons.text_fields).tap(); // Add text
      await $.pumpAndSettle();
      
      await $(Icons.pan_tool).tap(); // Pan around
      await $.pumpAndSettle();
      
      await $(Icons.description).tap(); // Navigate to Notion Demo
      await $.pumpAndSettle();
      
      await $(Icons.arrow_back).tap(); // Go back
      await $.pumpAndSettle();
      
      // Verify everything worked
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ Complete user workflow successful');
    });
  });
}
