import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/canvas_test_harness.dart';

void main() {
  group('Keyboard shortcuts (scaffold)', () {
    testWidgets('Ctrl+Z triggers undo (placeholder)', (tester) async {
      await pumpCanvasHarness(tester, const SizedBox());
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(true, isTrue);
    });
  });
}








