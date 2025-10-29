import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

void main() {
  group('Sidebar Visual Tests', () {
    testGoldens('App bar with add shape menu', (tester) async {
      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider(
          create: (context) => CanvasState(),
          child: const MyApp(),
        ),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'app_bar_default');
    });

    testGoldens('App bar with popup menu open', (tester) async {
      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider(
          create: (context) => CanvasState(),
          child: const MyApp(),
        ),
        surfaceSize: const Size(800, 600),
      );

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'app_bar_popup_menu_open');
    });

    testGoldens('Connection confirmation dialog component', (tester) async {
      await tester.pumpWidgetBuilder(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConnectionConfirmationDialog(
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
        surfaceSize: const Size(400, 200),
      );

      await screenMatchesGolden(tester, 'connection_confirmation_dialog');
    });

    testGoldens('Delete button component', (tester) async {
      await tester.pumpWidgetBuilder(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Colors.red,
                child: const Icon(Icons.delete),
              ),
            ),
          ),
        ),
        surfaceSize: const Size(200, 200),
      );

      await screenMatchesGolden(tester, 'delete_button_component');
    });

    testGoldens('Shape node widget', (tester) async {
      final canvasState = CanvasState();
      final node = canvasState.nodes.firstWhere((node) => node.shape.type == 'rectangle');

      await tester.pumpWidgetBuilder(
        ChangeNotifierProvider.value(
          value: canvasState,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ShapeAwareNodeWidget(node: node),
              ),
            ),
          ),
        ),
        surfaceSize: const Size(200, 200),
      );

      await screenMatchesGolden(tester, 'shape_node_widget');
    });
  });
}