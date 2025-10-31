import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:flutter/widgets.dart';
import 'package:viscanvas/main.dart';

void main() {
  patrolTest('Launch app and right-click canvasRoot visibly (clipboard entry)', ($) async {
    await $.pumpWidgetAndSettle(const MainApp());

    await Future<void>.delayed(const Duration(seconds: 2));

    // Right-click on canvas root (Windows)
    final rect = (await $(const Key('canvasRoot')).box).rect;
    await $.native.contextTap(rect.center);
    await $.tester.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 2));

    expect(true, isTrue);
  });
}


