import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CanvasTestHarness extends StatelessWidget {
  final Widget child;
  final Size fixedSize;
  final ThemeMode themeMode;

  const CanvasTestHarness({
    super.key,
    required this.child,
    this.fixedSize = const Size(1280, 800),
    this.themeMode = ThemeMode.light,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData light = ThemeData.light(useMaterial3: true);
    final ThemeData dark = ThemeData.dark(useMaterial3: true);
    return MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.0),
      child: Localizations(
        delegates: const <LocalizationsDelegate<dynamic>>[],
        locale: const Locale('en'),
        child: MaterialApp(
          theme: light,
          darkTheme: dark,
          themeMode: themeMode,
          home: SizedBox(
            width: fixedSize.width,
            height: fixedSize.height,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

Future<void> pumpCanvasHarness(WidgetTester tester, Widget child,
    {Size size = const Size(1280, 800), ThemeMode mode = ThemeMode.light}) async {
  tester.view.physicalSize = Size(size.width, size.height);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(CanvasTestHarness(child: child, fixedSize: size, themeMode: mode));
  await tester.pumpAndSettle();
}

Offset rotatePoint(Offset p, Offset center, double radians) {
  final double s = math.sin(radians);
  final double c = math.cos(radians);
  final double dx = p.dx - center.dx;
  final double dy = p.dy - center.dy;
  return Offset(center.dx + dx * c - dy * s, center.dy + dx * s + dy * c);
}










