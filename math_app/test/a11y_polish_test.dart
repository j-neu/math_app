import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/models/problem.dart';
import 'package:math_app/screens/child_path_screen.dart';
import 'package:math_app/services/learning_path_service.dart';
import 'package:math_app/services/skill_spec_store.dart';
import 'package:math_app/widgets/templates/flash_subitize_widget.dart';
import 'package:math_app/widgets/templates/hint_text.dart';

/// WCAG 2.x relative luminance of [c] (channels are already 0..1 doubles).
double _luminance(Color c) {
  double lin(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

Problem _flashProblem(int count, {int flashMs = 800}) => Problem(
      template: 'custom_widget',
      skillId: 'G1',
      level: 1,
      seed: 7,
      index: 0,
      promptDe: '',
      display: {
        'custom_widget': 'flash_subitize',
        'count': count,
        'flash_ms': flashMs,
        'display': 'dots',
      },
      expected: ['$count'],
    );

Future<void> _pumpFlash(WidgetTester tester,
    {required bool disableAnimations}) async {
  if (disableAnimations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: FlashSubitizeWidget(
              problem: _flashProblem(3),
              onValueChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _flashOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.byKey(const ValueKey('flash-visual')))
    .opacity;

String _pathJson() => jsonEncode({
      'path_id': 'p1',
      'unlock_width': 3,
      'items': [
        {
          'skill_id': 'A1.1a',
          'position': 1,
          'state': 'mastered',
          'title_de': 'Vorwärtszählen bis 20',
          'description_de': 'Zahlenreihe vorwärts',
          'color': 'blue',
          'progress': [
            {
              'level': 1,
              'attempts': 8,
              'correct': 8,
              'mastered_at': '2026-08-01T10:00:00Z',
            },
            {
              'level': 2,
              'attempts': 8,
              'correct': 8,
              'mastered_at': '2026-08-01T10:05:00Z',
            },
            {
              'level': 3,
              'attempts': 8,
              'correct': 8,
              'mastered_at': '2026-08-01T10:10:00Z',
            },
          ],
        },
        {
          'skill_id': 'A1.1b',
          'position': 2,
          'state': 'available',
          'title_de': 'Zählen bis 100',
          'description_de': 'Zahlenreihe bis 100',
          'color': 'green',
          'progress': [],
        },
        {
          'skill_id': 'A2.1',
          'position': 3,
          'state': 'locked',
          'title_de': 'Mengen blitzschnell erkennen',
          'description_de': 'Blitzsehen üben',
          'color': 'orange',
          'progress': [],
        },
      ],
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('WCAG contrast', () {
    test('template hint text meets 4.5:1 on the app surface', () {
      expect(
        _contrast(kHintTextColor, Colors.white),
        greaterThanOrEqualTo(4.5),
        reason: 'hint lines must stay readable (kHintTextColor vs white)',
      );
    });

    test('practice feedback hint (theme primary) meets 4.5:1 on the surface',
        () {
      // The practice screen's incorrect-answer hint uses colorScheme.primary
      // (#154761 from the app seed), and the mastered summary headline now
      // uses it too.
      const primary = Color(0xFF154761);
      expect(
        _contrast(primary, Colors.white),
        greaterThanOrEqualTo(4.5),
        reason: 'primary-coloured feedback text on the surface must pass AA',
      );
    });
  });

  group('FlashSubitizeWidget', () {
    testWidgets('"Nochmal sehen" is a >= 44x44 logical touch target',
        (tester) async {
      await _pumpFlash(tester, disableAnimations: false);

      final size =
          tester.getSize(find.byKey(const ValueKey('flash-reshow')));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets(
        'reduced motion: the flash is skipped and the dots stay visible',
        (tester) async {
      await _pumpFlash(tester, disableAnimations: true);

      expect(_flashOpacity(tester), 1, reason: 'dots visible on mount');

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 250));
      expect(_flashOpacity(tester), 1,
          reason: 'no auto-hide under reduced motion — the 800ms flash is '
              'not the only chance to see the pattern');

      await tester.tap(find.byKey(const ValueKey('flash-reshow')));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 250));
      expect(_flashOpacity(tester), 1,
          reason: 'the re-show keeps the dots visible too');
    });
  });

  group('ChildPathScreen tiles', () {
    testWidgets(
        'states carry icon + text, mastered pips show a check icon, and '
        'tiles are >= 44 px tall', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final client =
          MockClient((req) async => http.Response(_pathJson(), 200));

      await tester.pumpWidget(
        MaterialApp(
          home: ChildPathScreen(
            token: 'tok',
            displayName: 'Mia',
            service: LearningPathService(client: client),
            store: SkillSpecStore.fromJsonMap(const {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Every state is conveyed by icon + text, never colour alone.
      expect(find.text('Geschafft'), findsOneWidget);
      expect(find.text('Verfügbar'), findsOneWidget);
      expect(find.text('Noch gesperrt'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);

      // Per-level mastery is signalled by a check icon inside the pip, so
      // a green dot is never the only indicator.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pip-A1.1a-1')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
        reason: 'a mastered level pip carries a check mark',
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pip-A1.1b-1')),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
        reason: 'an unmastered pip carries no check mark',
      );

      // Tappable tiles are comfortably above the 44 px minimum.
      for (final skillId in ['A1.1a', 'A1.1b', 'A2.1']) {
        final size = tester.getSize(
          find.byKey(ValueKey('path-item-$skillId')),
        );
        expect(size.height, greaterThanOrEqualTo(44),
            reason: 'tile $skillId must be a >= 44px touch target');
      }
    });
  });
}
