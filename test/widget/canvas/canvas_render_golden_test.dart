import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/canvas_test_harness.dart';
import '../../helpers/golden_utils.dart';

void main() {
  group('Canvas render goldens (scaffold)', () {
    testWidgets('empty canvas baseline (placeholder)', (tester) async {
      final Widget canvasStub = Container(color: Colors.white);
      await pumpCanvasHarness(tester, canvasStub);
      await expectGoldenWithinThreshold(tester, goldenName: 'goldens/windows/canvas/empty.png');
    }, skip: true);

    testWidgets('grid on, shapes added (placeholder)', (tester) async {
      final Widget canvasStub = Container(color: Colors.white);
      await pumpCanvasHarness(tester, canvasStub);
      await expectGoldenWithinThreshold(tester, goldenName: 'goldens/windows/canvas/grid_shapes.png');
    }, skip: true);
  });
}











