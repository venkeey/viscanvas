// test/unit/main_app_unit_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/main.dart';

void main() {
  group('MainApp Unit Tests', () {
    
    // Test 1: MainApp widget creation
    testWidgets('MainApp widget creates successfully', (WidgetTester tester) async {
      const mainApp = MainApp();
      
      expect(mainApp, isA<MainApp>());
      expect(mainApp.key, isNull);
    });

    // Test 2: MainApp widget with key
    testWidgets('MainApp widget with key creates successfully', (WidgetTester tester) async {
      const key = Key('test_main_app');
      const mainApp = MainApp(key: key);
      
      expect(mainApp, isA<MainApp>());
      expect(mainApp.key, equals(key));
    });

    // Test 3: MainApp build method returns InfiniteCanvasApp
    testWidgets('MainApp build method returns InfiniteCanvasApp', (WidgetTester tester) async {
      const mainApp = MainApp();
      
      await tester.pumpWidget(const MaterialApp(home: mainApp));
      
      expect(find.byType(InfiniteCanvasApp), findsOneWidget);
    });

    // Test 4: MainApp is StatelessWidget
    test('MainApp is StatelessWidget', () {
      const mainApp = MainApp();
      
      expect(mainApp, isA<StatelessWidget>());
    });

    // Test 5: MainApp build method is const
    testWidgets('MainApp build method is const', (WidgetTester tester) async {
      const mainApp = MainApp();
      
      await tester.pumpWidget(const MaterialApp(home: mainApp));
      
      // Verify that the widget can be rebuilt without issues
      await tester.pump();
      await tester.pump();
      
      expect(find.byType(InfiniteCanvasApp), findsOneWidget);
    });

    // Test 6: MainApp widget tree structure
    testWidgets('MainApp widget tree structure', (WidgetTester tester) async {
      const mainApp = MainApp();
      
      await tester.pumpWidget(const MaterialApp(home: mainApp));
      
      // Verify the widget tree structure
      expect(find.byType(MainApp), findsOneWidget);
      expect(find.byType(InfiniteCanvasApp), findsOneWidget);
    });

    // Test 7: MainApp widget properties
    test('MainApp widget properties', () {
      const mainApp = MainApp();
      
      expect(mainApp.runtimeType, equals(MainApp));
      expect(mainApp.key, isNull);
    });

    // Test 8: MainApp widget equality
    test('MainApp widget equality', () {
      const mainApp1 = MainApp();
      const mainApp2 = MainApp();
      
      expect(mainApp1, equals(mainApp2));
    });

    // Test 9: MainApp widget with different keys
    test('MainApp widget with different keys', () {
      const mainApp1 = MainApp(key: Key('app1'));
      const mainApp2 = MainApp(key: Key('app2'));
      
      expect(mainApp1, isNot(equals(mainApp2)));
    });

    // Test 10: MainApp widget hash code
    test('MainApp widget hash code', () {
      const mainApp1 = MainApp();
      const mainApp2 = MainApp();
      
      expect(mainApp1.hashCode, equals(mainApp2.hashCode));
    });
  });
}
