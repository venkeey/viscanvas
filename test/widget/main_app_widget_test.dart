// test/widget/main_app_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/main.dart';

void main() {
  group('MainApp Widget Tests', () {
    
    // Test 1: MainApp renders without crashing
    testWidgets('MainApp renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainApp()));
      
      expect(find.byType(MainApp), findsOneWidget);
      expect(find.byType(InfiniteCanvasApp), findsOneWidget);
    });

    // Test 2: MainApp renders with MaterialApp wrapper
    testWidgets('MainApp renders with MaterialApp wrapper', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainApp()));
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MainApp), findsOneWidget);
    });

    // Test 3: MainApp widget tree structure
    testWidgets('MainApp widget tree structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainApp()));
      
      // Verify the complete widget tree
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MainApp), findsOneWidget);
      expect(find.byType(InfiniteCanvasApp), findsOneWidget);
    });

    // Test 4: MainApp with different themes
    testWidgets('MainApp with different themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const MainApp(),
        ),
      );
      
      expect(find.byType(MainApp), findsOneWidget);
      
      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const MainApp(),
        ),
      );
      
      expect(find.byType(MainApp), findsOneWidget);
    });

    // Test 5: MainApp widget rebuild
    testWidgets('MainApp widget rebuild', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainApp()));
      
      expect(find.byType(MainApp), findsOneWidget);
      
      // Rebuild the widget
      await tester.pump();
      
      expect(find.byType(MainApp), findsOneWidget);
    });

    // Test 6: MainApp with key
    testWidgets('MainApp with key', (WidgetTester tester) async {
      const key = Key('test_main_app');
      await tester.pumpWidget(
        MaterialApp(home: MainApp(key: key)),
      );
      
      expect(find.byKey(key), findsOneWidget);
      expect(find.byType(MainApp), findsOneWidget);
    });

    // Test 7: MainApp widget lifecycle
    testWidgets('MainApp widget lifecycle', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainApp()));
      
      expect(find.byType(MainApp), findsOneWidget);
      
      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      
      expect(find.byType(MainApp), findsNothing);
    });

    // Test 8: MainApp widget with different MaterialApp configurations
    testWidgets('MainApp widget with different MaterialApp configurations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Test App',
          debugShowCheckedModeBanner: false,
          home: const MainApp(),
        ),
      );
      
      expect(find.byType(MainApp), findsOneWidget);
    });

    // Test 9: MainApp widget performance
    testWidgets('MainApp widget performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(const MaterialApp(home: MainApp()));
      
      stopwatch.stop();
      
      expect(find.byType(MainApp), findsOneWidget);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should render quickly
    });

    // Test 10: MainApp widget accessibility
    testWidgets('MainApp widget accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainApp()));
      
      expect(find.byType(MainApp), findsOneWidget);
      
      // Test accessibility
      final semantics = tester.getSemantics(find.byType(MainApp));
      expect(semantics, isNotNull);
    });
  });
}
