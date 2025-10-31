import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:viscanvas/main.dart';
import 'package:viscanvas/services/canvas/canvas_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Launch app and perform visible click (Windows)', (tester) async {
    CanvasService.globalAutoSaveEnabled = false;
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 3));

    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 5));

    expect(true, isTrue);
  });
}


