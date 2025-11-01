import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Canvas frame timing (Windows) - scaffold', () {
    testWidgets('average raster < 16.6ms during scripted pan/zoom (placeholder)', (tester) async {
      final List<FrameTiming> timings = <FrameTiming>[];
      final TimingsCallback cb = (List<FrameTiming> list) => timings.addAll(list);
      addTearDown(() => SchedulerBinding.instance.removeTimingsCallback(cb));
      SchedulerBinding.instance.addTimingsCallback(cb);

      // TODO: trigger scripted interaction once canvas is wired up.
      await tester.pump(const Duration(milliseconds: 500));

      if (timings.isEmpty) return; // scaffold
      final double avgRasterMs = timings
              .map((t) => t.rasterDuration.inMicroseconds / 1000.0)
              .fold<double>(0.0, (a, b) => a + b) /
          math.max(1, timings.length);
      expect(avgRasterMs, lessThan(16.6), reason: 'avg raster = $avgRasterMs ms');
    }, skip: true);
  });
}











