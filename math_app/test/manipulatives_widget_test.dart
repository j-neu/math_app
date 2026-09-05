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

  testWidgets(
      'RekenrekFlashWidget never flashes on build; Bereit runs fixation, '
      'countdown, a 1500 ms flash, then fades', (tester) async {
    await pumpWidget(
      tester,
      const RekenrekFlashWidget(topLeft: 4, bottomLeft: 0),
    );

    // Never on build: no beads, just the Bereit prompt.
    expect(find.byType(AnimatedOpacity), findsNothing);
    expect(find.byWidgetPredicate((w) => w is RekenrekWidget), findsNothing);
    expect(find.text('Bereit'), findsOneWidget);

    await tester.tap(find.text('Bereit'));
    await tester.pump();

    // Fixation point, then a 3-2-1 countdown.
    expect(find.text('+'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1'), findsOneWidget);

    // Flash begins only once the countdown completes.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byWidgetPredicate((w) => w is RekenrekWidget), findsOneWidget);

    // Stays visible for 1500 ms, then fades over 200 ms.
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byWidgetPredicate((w) => w is RekenrekWidget), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    // The fade must actually interpolate rather than jump straight to 0:
    // partway through the 200 ms fade the rendered opacity (the live
    // animation value inside AnimatedOpacity's FadeTransition, not the
    // target) should sit strictly between the two endpoints.
    await tester.pump(const Duration(milliseconds: 100));
    final midFade = tester
        .widget<FadeTransition>(find.byType(FadeTransition))
        .opacity
        .value;
    expect(midFade, greaterThan(0));
    expect(midFade, lessThan(1));
    await tester.pump(const Duration(milliseconds: 100));
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
