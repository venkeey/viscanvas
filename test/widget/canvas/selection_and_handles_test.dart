import 'package:flutter_test/flutter_test.dart';

import '../../helpers/canvas_test_harness.dart';

void main() {
  group('Selection and handles (scaffold)', () {
    testWidgets('selects object and shows handles (placeholder)', (tester) async {
      await pumpCanvasHarness(tester, const SizedBox());
      expect(true, isTrue);
    });
  });
}











