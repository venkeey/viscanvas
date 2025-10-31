import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:flutter/widgets.dart';
import 'package:viscanvas/main.dart';

void main() {
  patrolTest('Launch app and tap canvasRoot visibly', ($) async {
    await $.pumpWidgetAndSettle(const MainApp());

    await Future<void>.delayed(const Duration(seconds: 2));

    await $(const Key('canvasRoot')).tap();
    await $.tester.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 2));

    expect(true, isTrue);
  });
}


