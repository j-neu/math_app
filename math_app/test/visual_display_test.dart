import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/screens/diagnostic_screen.dart';

/// Smoke tests for the visual-item renderer (tasks.md R5.2).
///
/// `buildVisualDisplay` is the public switch behind
/// `DiagnosticScreen._buildVisualDisplay`; pumping every item ID proves each
/// arrangement builds without throwing.
void main() {
  const visualItemIds = [
    'A2.2-01',
    'A2.2-02',
    'A2.3-01',
    'B1.2-01',
    'B1.2-02',
    'B1.3-01',
    'B2.1-01',
    'B2.1-02',
    'B2.2-01',
    'DDA-04',
    'DDA-05',
    'DDA-06',
    'DDB-01',
    'DDB-02',
    'DDB-04',
    'DDB-05',
    'V3Z-01',
    'V3Z-02',
    'V3D-01',
    'V3D-02',
    'V3D-03',
    'V3D-04',
    'V3D-05',
    'V3D-06',
    'V3D-07',
    'V3D-08',
    'V3D-09',
    'V3D-10',
    'V3D-11',
    'V3D-12',
    'V3D-13',
    'V3S-01',
    'V3S-02',
    'V3S-03',
    'V3S-04',
    'V3S-05',
    'V3S-06',
    'V3S-07',
    'V3S-08',
    'V3G-01',
    'V3K-01',
    'V3K-02',
    'V3M-01',
    'V3M-02',
    'V3M-03',
    'V3Z-03',
    'V3Z-04',
  ];

  DiagnosticQuestion questionFor(String id) => DiagnosticQuestion(
        listNumber: 1,
        sourceType: QuestionType.image,
        questionText: id,
        answerFormat: AnswerFormat.single,
        correctAnswer: '1',
        german: 'Test',
        english: 'Test',
        ifWrongPracticeSkills: const [],
      );

  for (final id in visualItemIds) {
    testWidgets('visual display for $id builds without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // The real DiagnosticScreen wraps visual items in a
            // SingleChildScrollView (some, like the legend+puzzle pairs,
            // are taller than a typical viewport) -- match that here so
            // this smoke test doesn't flag a real screen's tall content as
            // a RenderFlex overflow.
            body: SingleChildScrollView(
              child: Center(child: buildVisualDisplay(questionFor(id))),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('A2.1-01 flash requires Bereit and completes without throwing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: buildVisualDisplay(questionFor('A2.1-01'))),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Bereit'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('DDB-05 tap places the marker and writes the snapped value',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: buildVisualDisplay(questionFor('DDB-05'), controller: controller),
          ),
        ),
      ),
    );
    await tester.pump();

    // The number line spans the screen width; tapping at 75% places 75.
    final line = tester.getTopLeft(find.byType(GestureDetector).first);
    final width = tester.getSize(find.byType(GestureDetector).first).width;
    await tester.tapAt(Offset(line.dx + width * 0.75, line.dy + 30));
    await tester.pump();

    expect(controller.text, '75');
    expect(tester.takeException(), isNull);
  });
}
