import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/manipulatives/fingerbild.dart';
import 'package:math_app/widgets/manipulatives/rekenrek.dart';
import 'package:math_app/widgets/manipulatives/staebchen.dart';
import 'package:math_app/widgets/manipulatives/stellenwerttafel.dart';
import 'package:math_app/widgets/manipulatives/zahlenstrahl.dart';
import 'package:math_app/widgets/manipulatives/zehnerfeld.dart';

Future<void> pumpWidget(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
  await tester.pump();
}

void main() {
  testWidgets('ZehnerfeldWidget renders 0-filled frame without throwing',
      (tester) async {
    await pumpWidget(tester, const ZehnerfeldWidget(filled: {}));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ZehnerfeldWidget renders full frame without throwing',
      (tester) async {
    await pumpWidget(
      tester,
      const ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('VergleichZehnerfelderWidget renders without throwing',
      (tester) async {
    await pumpWidget(tester, const VergleichZehnerfelderWidget());
    expect(tester.takeException(), isNull);
  });

  testWidgets('RekenrekWidget renders full 10x2 frame without throwing',
      (tester) async {
    await pumpWidget(tester, const RekenrekWidget(topLeft: 10, bottomLeft: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('RekenrekFlashWidget flashes for 800 ms then fades out',
      (tester) async {
    await pumpWidget(
      tester,
      const RekenrekFlashWidget(topLeft: 4, bottomLeft: 0),
    );
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
    // Flush the 800 ms timer plus the 200 ms fade.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('VergleichRekenrekWidget renders without throwing', (tester) async {
    await pumpWidget(tester, const VergleichRekenrekWidget());
    expect(tester.takeException(), isNull);
  });

  testWidgets('FingerBildWidget renders without throwing', (tester) async {
    await pumpWidget(
      tester,
      const FingerBildWidget(leftCount: 0, rightCount: 0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaebchenBundelWidget renders without throwing', (tester) async {
    await pumpWidget(tester, const StaebchenBundelWidget());
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaebchenEinzelWidget renders without throwing', (tester) async {
    await pumpWidget(tester, const StaebchenEinzelWidget());
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaebchenWidget renders empty and mixed groups without throwing',
      (tester) async {
    await pumpWidget(tester, const StaebchenWidget(bundles: 0, singles: 0));
    expect(tester.takeException(), isNull);
    await pumpWidget(tester, const StaebchenWidget(bundles: 5, singles: 6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaebchenOeffnenWidget opens the bundle on tap', (tester) async {
    await pumpWidget(tester, const StaebchenOeffnenWidget());
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(find.text('13 einzelne Stäbchen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StellenwerttafelWidget renders 99 without throwing',
      (tester) async {
    await pumpWidget(
      tester,
      const StellenwerttafelWidget(tensValue: 9, onesValue: 9),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('StellenwerttafelWidget renders numberAbove without throwing',
      (tester) async {
    await pumpWidget(tester, const StellenwerttafelWidget(numberAbove: '47'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ZahlenstrahlPainter paints arrow and mark at both ends',
      (tester) async {
    for (final value in [0.0, 100.0, 50.0]) {
      await pumpWidget(
        tester,
        CustomPaint(
          size: const Size(340, 110),
          painter: ZahlenstrahlPainter(
            arrowAt: value,
            majorTicks: const {0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100},
            minorTicks: const {},
            labels: const {0: '0', 50: '50', 100: '100'},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('ZahlenstrahlArrowWidget renders arrow at both ends without throwing',
      (tester) async {
    await pumpWidget(tester, const ZahlenstrahlArrowWidget(value: 0));
    expect(tester.takeException(), isNull);
    await pumpWidget(tester, const ZahlenstrahlArrowWidget(value: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ZahlenstrahlMarkWidget renders static initialMark without throwing',
      (tester) async {
    await pumpWidget(tester, const ZahlenstrahlMarkWidget(initialMark: 75));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ZahlenstrahlMarkWidget taps and writes the snapped value',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpWidget(tester, ZahlenstrahlMarkWidget(controller: controller));

    final line = tester.getTopLeft(find.byType(GestureDetector));
    final width = tester.getSize(find.byType(GestureDetector)).width;
    await tester.tapAt(Offset(line.dx + width * 0.75, line.dy + 30));
    await tester.pump();

    expect(controller.text, '75');
    expect(tester.takeException(), isNull);
  });
}
