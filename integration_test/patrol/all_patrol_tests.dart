import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:viscanvas/pages/connectors.dart';

// Import all test functions
import 'drawing_workflows_test.dart' as drawing;
import 'shape_manipulation_test.dart' as shape;
import 'connector_tests.dart' as connector;
import 'streaming_data_test.dart' as streaming;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('All Patrol Integration Tests', () {
    // Drawing Workflow Tests
    testWidgets('Complete rectangle drawing workflow', drawing.main);
    testWidgets('Freehand drawing workflow', drawing.main);
    testWidgets('Text tool workflow', drawing.main);
    testWidgets('Shape creation and manipulation workflow', drawing.main);
    testWidgets('Canvas zoom and pan workflow', drawing.main);

    // Shape Manipulation Tests
    testWidgets('Shape selection and movement', shape.main);
    testWidgets('Shape resizing', shape.main);
    testWidgets('Multi-shape selection', shape.main);
    testWidgets('Shape deletion', shape.main);
    testWidgets('Shape duplication', shape.main);
    testWidgets('Shape property editing', shape.main);

    // Connector System Tests
    testWidgets('Create connector between shapes', connector.main);
    testWidgets('Connector auto-routing', connector.main);
    testWidgets('Connector deletion', connector.main);
    testWidgets('Multiple connectors management', connector.main);
    testWidgets('Connector updates when shapes move', connector.main);
    testWidgets('Connector selection and properties', connector.main);

    // Real-time Data Testing
    testWidgets('Real-time canvas updates during drawing', streaming.main);
    testWidgets('Connection confirmation dialog real-time updates', streaming.main);
    testWidgets('Real-time node movement updates connected edges', streaming.main);
    testWidgets('Real-time selection state updates', streaming.main);
    testWidgets('Real-time keyboard shortcuts', streaming.main);
    testWidgets('Real-time drag preview during connection', streaming.main);
  });
}