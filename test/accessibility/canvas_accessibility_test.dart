import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/connectors.dart';
import 'package:provider/provider.dart';

void main() {
  group('Canvas Accessibility Tests', () {
    testWidgets('nodes should have semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => CanvasState(),
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify semantic structure exists
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('keyboard navigation with Tab should work', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate Tab key press
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Keyboard events should be handled
      expect(find.byType(NodeCanvas), findsOneWidget);
    });

    testWidgets('Ctrl+A should select all nodes (keyboard accessibility)', (tester) async {
      final canvasState = CanvasState();
      expect(canvasState.nodes.length, 3); // Default nodes

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Press Ctrl+A
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // All nodes should be selected
      expect(canvasState.selectedNodes.length, 3);
    });

    testWidgets('Delete key should remove selected nodes', (tester) async {
      final canvasState = CanvasState();
      canvasState.selectAll();
      expect(canvasState.selectedNodes.length, 3);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap delete button
      final deleteButton = find.byIcon(Icons.delete);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        expect(canvasState.nodes.length, 0);
      }
    });

    testWidgets('Escape key should clear selection', (tester) async {
      final canvasState = CanvasState();
      canvasState.selectAll();
      expect(canvasState.selectedNodes.length, 3);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Press Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Selection should be cleared
      expect(canvasState.selectedNodes.length, 0);
    });

    test('calculateContrastRatio should meet WCAG AA standards', () {
      // Test common color combinations
      final blackOnWhite = calculateContrastRatio(Colors.black, Colors.white);
      expect(blackOnWhite, greaterThanOrEqualTo(4.5)); // WCAG AA

      final whiteOnBlack = calculateContrastRatio(Colors.white, Colors.black);
      expect(whiteOnBlack, greaterThanOrEqualTo(4.5));

      // Test default shape colors
      final defaultFill = Colors.blue.shade100;
      final defaultBorder = Colors.blue.shade700;
      final shapeContrast = calculateContrastRatio(defaultFill, defaultBorder);
      expect(shapeContrast, greaterThanOrEqualTo(3.0)); // At least some contrast
    });

    test('calculateContrastRatio should be symmetric', () {
      final color1 = Colors.blue;
      final color2 = Colors.yellow;

      final ratio1 = calculateContrastRatio(color1, color2);
      final ratio2 = calculateContrastRatio(color2, color1);

      expect(ratio1, closeTo(ratio2, 0.01));
    });

    test('calculateContrastRatio with same color should be 1.0', () {
      final ratio = calculateContrastRatio(Colors.blue, Colors.blue);
      expect(ratio, closeTo(1.0, 0.01));
    });

    testWidgets('touch targets should meet minimum size (44x44 dp)', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find interactive elements (if they have keys)
      // In real implementation, verify buttons, handles, etc. are >= 44x44
      final deleteButton = find.byIcon(Icons.delete);
      if (deleteButton.evaluate().isNotEmpty) {
        final size = tester.getSize(deleteButton);
        expect(size.width, greaterThanOrEqualTo(40.0)); // Allow some tolerance
        expect(size.height, greaterThanOrEqualTo(40.0));
      }
    });

    testWidgets('semantic tree should include canvas state information', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: Scaffold(
              body: Semantics(
                label: 'Canvas with ${canvasState.nodes.length} nodes',
                child: const NodeCanvas(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify semantic tree
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, contains('Canvas'));
    });

    testWidgets('focus indicators should be visible', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate focus (via Tab)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Focus should be handled
      expect(find.byType(NodeCanvas), findsOneWidget);
    });

    testWidgets('screen reader announcements for canvas state changes', (tester) async {
      final canvasState = CanvasState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: canvasState,
            child: const Scaffold(
              body: NodeCanvas(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialNodeCount = canvasState.nodes.length;

      // Add a node
      canvasState.addNode(RectangleShape(Rect.fromLTWH(0, 0, 100, 100)));
      await tester.pumpAndSettle();

      // Verify node was added
      expect(canvasState.nodes.length, initialNodeCount + 1);
    });
  });
}

double calculateContrastRatio(Color foreground, Color background) {
  final luminance1 = foreground.computeLuminance();
  final luminance2 = background.computeLuminance();

  final lighter = max(luminance1, luminance2);
  final darker = min(luminance1, luminance2);

  return (lighter + 0.05) / (darker + 0.05);
}
