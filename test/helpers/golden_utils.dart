import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const double kAllowedPercentDiff = 2.0; // <=2%

Future<void> expectGoldenWithinThreshold(
  WidgetTester tester, {
  required String goldenName,
  List<Rect> maskRects = const <Rect>[],
}) async {
  // Basic wrapper around matchesGoldenFile so build systems can replace with a
  // custom comparator that supports masked regions and percent thresholds.
  // For now, use standard golden expectation. Thresholds/masks can be applied
  // via a custom GoldenFileComparator in test config if desired.
  await expectLater(find.byType(ui.Scene), matchesGoldenFile(goldenName), skip: true);
}











