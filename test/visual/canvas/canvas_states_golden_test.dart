import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/canvas_test_harness.dart';
import '../../helpers/golden_utils.dart';

void main() {
  group('Canvas visual states (Windows goldens, scaffold)', () {
    testWidgets('baseline empty', (tester) async {
      await pumpCanvasHarness(tester, const ColoredBox(color: Colors.white));
      await expectGoldenWithinThreshold(
        tester,
        goldenName: 'goldens/windows/canvas/empty.png',
      );
    }, skip: true);

    testWidgets('selection overlays', (tester) async {
      await pumpCanvasHarness(tester, const ColoredBox(color: Colors.white));
      await expectGoldenWithinThreshold(
        tester,
        goldenName: 'goldens/windows/canvas/selection_overlay.png',
      );
    }, skip: true);
  });
}










