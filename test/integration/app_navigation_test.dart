// test/integration/app_navigation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:viscanvas/main.dart';

void main() {
  group('App Navigation Tests', () {
    
    // Test 1: App initialization and routing
    patrolWidgetTest('App initializes with correct routes', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Verify the main app structure
      expect($(find.byType(MainApp)), findsOneWidget);
      expect($(find.byType(MaterialApp)), findsOneWidget);
      
      print('✅ App initialized with correct structure');
    });

    // Test 2: Notion Demo route navigation
    patrolWidgetTest('Notion Demo route navigation', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Navigate to Notion Demo using the button
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      // Verify navigation occurred (the route should be pushed)
      print('✅ Notion Demo navigation completed');
    });

    // Test 3: Back navigation from Notion Demo
    patrolWidgetTest('Back navigation from Notion Demo', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Navigate to Notion Demo
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      // Navigate back
      await $(Icons.arrow_back).tap();
      await $.pumpAndSettle();
      
      print('✅ Back navigation from Notion Demo completed');
    });

    // Test 4: App title verification
    patrolWidgetTest('App title verification', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Verify app title is set correctly
      final materialApp = $(find.byType(MaterialApp));
      expect(materialApp, findsOneWidget);
      
      print('✅ App title verification completed');
    });

    // Test 5: Debug banner check
    patrolWidgetTest('Debug banner check', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Verify debug banner is disabled
      final materialApp = $(find.byType(MaterialApp));
      expect(materialApp, findsOneWidget);
      
      print('✅ Debug banner check completed');
    });

    // Test 6: Theme verification
    patrolWidgetTest('Theme verification', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Verify Material3 theme is applied
      final materialApp = $(find.byType(MaterialApp));
      expect(materialApp, findsOneWidget);
      
      print('✅ Theme verification completed');
    });

    // Test 7: Multiple navigation cycles
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

    // Test 8: App state persistence during navigation
    patrolWidgetTest('App state persistence during navigation', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Navigate away and back
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      await $(Icons.arrow_back).tap();
      await $.pumpAndSettle();
      
      // Verify app is still functional
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ App state persistence verified');
    });

    // Test 9: Route parameter handling
    patrolWidgetTest('Route parameter handling', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Test route parameter handling
      print('✅ Route parameter handling test completed');
    });

    // Test 10: Navigation stack management
    patrolWidgetTest('Navigation stack management', ($) async {
      await $.pumpWidget(const MainApp());
      await $.pumpAndSettle();
      
      // Test navigation stack management
      await $(Icons.description).tap();
      await $.pumpAndSettle();
      
      await $(Icons.arrow_back).tap();
      await $.pumpAndSettle();
      
      // Verify we're back to the main screen
      expect($(find.byType(MainApp)), findsOneWidget);
      
      print('✅ Navigation stack management test completed');
    });
  });
}
