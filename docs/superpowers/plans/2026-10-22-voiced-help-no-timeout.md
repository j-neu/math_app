# Voiced Diagnostic, Staged Help, No Timeout: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the child-facing timeout, give every diagnostic question three voiced help stages, read every question aloud in Jakob's voice clone, record hint use for the teacher, and produce an intro MP4 for the class.

**Architecture:** Texts live in four new CSV columns. A Python script turns them into MP3 assets with the local Qwen3 voice clone, as one batch job. The Flutter diagnostic screen swaps the `PausableTimeout` for a small `AnswerClock`, and swaps the single Hilfe dialog for a `HelpPanel` widget. `help_level` travels with each result through the edge functions into a new DB column and the dashboard. The video is an HTML animation recorded frame by frame by Playwright and muxed by ffmpeg.

**Tech Stack:** Flutter 3 / Dart (`audioplayers` ^6), Supabase Postgres + Deno edge functions, Next.js 14 dashboard, Python 3.12 (Voice project env, `uv`), Node 24 + Playwright, ffmpeg.

**Spec:** `docs/superpowers/specs/2026-10-22-voiced-help-no-timeout-design.md`

## Global Constraints

- All child- and teacher-facing text is German. No English strings in the UI.
- Voice commands run from `C:\Users\jakob\Documents\Cursor projects\Voice`, always with `uv run --no-sync`. Engine `qwen3`, `--lang de`, zero-shot clone (no `--checkpoint`).
- `was_correct = textCorrect && helpLevel < 3`. Response time never makes an answer wrong.
- Hint 3 must never contain the correct answer.
- No production change (Supabase migration, edge-function deploy, git push) without Jakob's explicit go in this session.
- Audio files are bundled Flutter assets under `math_app/assets/audio/diagnostic/`, named `q<ListNumber>_<slot>.mp3`, where slot is one of `frage`, `hilfe1`, `hilfe2`, `hilfe3`.
  - Deviation from the spec's hash naming: Dart has no `crypto` dependency, and per-item names need no lookup manifest on the client.
  - The generator keeps a `manifest.json` of file → spoken text, so only changed texts are regenerated.

---

## File Structure

| File | Responsibility |
|---|---|
| `math_app/lib/services/answer_clock.dart` (new) | Response-time stopwatch: starts on the first of question-audio-end or first input. |
| `math_app/lib/services/help_grading.dart` (new) | `gradeWithHelp()` and the `kMaxHelpLevel` constant. |
| `math_app/lib/services/diagnostic_audio.dart` (new) | Asset paths for an item's question and hint clips. |
| `math_app/lib/widgets/diagnostic/help_panel.dart` (new) | 🔊 replay button, Hilfe button, revealed hint cards. |
| `math_app/lib/screens/diagnostic_screen.dart` | Wire the clock, help panel, autoplay. Delete the timeout code. |
| `math_app/lib/models/diagnostic_question.dart`, `lib/services/diagnostic_service.dart` | Parse `Sprechtext`, `Hilfe1`–`Hilfe3`. |
| `math_app/lib/models/diagnostic_result.dart`, `lib/services/api_service.dart` | Carry `helpLevel`. |
| `math_app/Research/diagnostic_v4_master.csv` | Replace the `Hilfetext` column with `Sprechtext,Hilfe1,Hilfe2,Hilfe3`. |
| `scripts/check_diagnostic_voice_texts.py` (new) | Content gate for the four text columns. |
| `scripts/german_numbers.py` (new) | Digits to German words, for TTS input. |
| `scripts/generate_diagnostic_audio.py` (new) | Batch TTS plus loudnorm, incremental via the manifest. |
| `backend/supabase/migrations/20261022000000_help_level.sql` (new) | `help_level` column. |
| `backend/supabase/functions/diagnostic-results/index.ts`, `diagnostic-sessions/index.ts` | Accept and return `help_level`. |
| `dashboard/app/dashboard/foerderplan/[sessionId]/page.tsx` | Show the hint level in the status cell. |
| `tools/intro_video/` (new) | Narration script, HTML animation, recorder, build script. |

---

### Task 1: Remove the timeout and add AnswerClock

**Files:**
- Create: `math_app/lib/services/answer_clock.dart`, `math_app/lib/services/help_grading.dart`
- Create: `math_app/test/answer_clock_test.dart`, `math_app/test/help_grading_test.dart`
- Modify: `math_app/lib/screens/diagnostic_screen.dart` (fields ~102-106; `dispose` ~211; `_timeoutSecondsFor` / `_startQuestionTimer` / `_grantMoreTime` / `_handleTimeout` / `_skipCurrentQuestion` ~216-322; `_nextQuestionInner` ~429-470; build ~941-945; `_showHilfe` ~1084-1107)
- Delete: `math_app/lib/services/pausable_timeout.dart`, `math_app/test/pausable_timeout_test.dart` (no other users; check with `grep -rn PausableTimeout math_app/lib math_app/test`)

**Interfaces:**
- Produces:
  - `class AnswerClock { AnswerClock({DateTime Function()? now}); void startIfIdle(); void stop(); bool get started; Duration get elapsed; }`
  - `const int kMaxHelpLevel = 3; bool gradeWithHelp({required bool textCorrect, required int helpLevel})`

- [ ] **Step 1: Write the failing tests**

`math_app/test/answer_clock_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/answer_clock.dart';

void main() {
  test('elapsed is zero before start', () {
    final clock = AnswerClock(now: () => DateTime(2026, 1, 1, 10));
    expect(clock.started, isFalse);
    expect(clock.elapsed, Duration.zero);
  });

  test('startIfIdle only starts once; elapsed counts from first start', () {
    var t = DateTime(2026, 1, 1, 10, 0, 0);
    final clock = AnswerClock(now: () => t);
    clock.startIfIdle();
    t = t.add(const Duration(seconds: 5));
    clock.startIfIdle(); // second trigger (e.g. audio end after typing) is ignored
    t = t.add(const Duration(seconds: 7));
    expect(clock.elapsed, const Duration(seconds: 12));
  });

  test('stop freezes elapsed', () {
    var t = DateTime(2026, 1, 1, 10);
    final clock = AnswerClock(now: () => t);
    clock.startIfIdle();
    t = t.add(const Duration(seconds: 3));
    clock.stop();
    t = t.add(const Duration(seconds: 100));
    expect(clock.elapsed, const Duration(seconds: 3));
  });
}
```

`math_app/test/help_grading_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/help_grading.dart';

void main() {
  test('correct with up to two hints stays correct', () {
    for (final h in [0, 1, 2]) {
      expect(gradeWithHelp(textCorrect: true, helpLevel: h), isTrue);
    }
  });
  test('correct after hint 3 counts as not mastered', () {
    expect(gradeWithHelp(textCorrect: true, helpLevel: kMaxHelpLevel), isFalse);
  });
  test('wrong stays wrong', () {
    expect(gradeWithHelp(textCorrect: false, helpLevel: 0), isFalse);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `cd math_app && flutter test test/answer_clock_test.dart test/help_grading_test.dart`
Expected: FAIL, the URIs don't exist.

- [ ] **Step 3: Implement**

`math_app/lib/services/answer_clock.dart`:
```dart
/// Measures how long a child takes to answer one diagnostic question.
/// Starts on whichever happens first: the question audio finishing, or the
/// child starting to type. There is no budget and nothing fires: the time
/// is recorded for the teacher only (spec 2026-10-22 §1).
class AnswerClock {
  final DateTime Function() _now;
  DateTime? _startedAt;
  DateTime? _stoppedAt;

  AnswerClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  bool get started => _startedAt != null;

  void startIfIdle() {
    _startedAt ??= _now();
  }

  void stop() {
    if (_startedAt != null) _stoppedAt ??= _now();
  }

  Duration get elapsed {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    return (_stoppedAt ?? _now()).difference(start);
  }
}
```

`math_app/lib/services/help_grading.dart`:
```dart
/// Number of help stages per diagnostic question.
const int kMaxHelpLevel = 3;

/// An answer only counts as mastered if the child got it right without the
/// last, direct-instruction hint (spec 2026-10-22, Jakob's decision).
bool gradeWithHelp({required bool textCorrect, required int helpLevel}) =>
    textCorrect && helpLevel < kMaxHelpLevel;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd math_app && flutter test test/answer_clock_test.dart test/help_grading_test.dart`
Expected: PASS.

- [ ] **Step 5: Rewire `diagnostic_screen.dart`**

1. Replace the import `'../services/pausable_timeout.dart'` with `'../services/answer_clock.dart'` and `'../services/help_grading.dart'`.
2. Replace the field `PausableTimeout? _responseTimer;` (and its comment) with:
   ```dart
   // Response time for the current question. No budget, no dialog: the
   // child-facing timeout was removed after the first real-kid runs
   // (spec 2026-10-22). Recorded for the teacher only.
   AnswerClock? _answerClock;
   int _helpLevel = 0;
   ```
3. Delete `_timeoutSecondsFor`, `_grantMoreTime`, `_handleTimeout` and `_skipCurrentQuestion` entirely.
4. Replace `_startQuestionTimer` with:
   ```dart
   void _startQuestion(List<DiagnosticQuestion> questions) {
     if (_currentQuestionIndex >= questions.length) return;
     final question = questions[_currentQuestionIndex];
     _answerClock = AnswerClock();
     _helpLevel = 0;
     if (question.audioAsset != null) {
       _playAudio(question.audioAsset!);
     }
     // Task 5 starts the clock on question-audio completion. Until then,
     // start immediately so time is always recorded.
     _answerClock!.startIfIdle();
   }
   ```
   Rename every call site of `_startQuestionTimer` to `_startQuestion` (lines ~530, ~567, ~943). In the build method, change `if (_responseTimer == null)` to `if (_answerClock == null)`.
5. In `dispose`, delete `_responseTimer?.cancel();`.
6. In `_nextQuestionInner`, replace the block from `// Stop the timer` through the `tookTooLong` / `wasCorrect` lines with:
   ```dart
   _answerClock?.stop();
   final responseTime =
       (_answerClock?.elapsed.inMilliseconds ?? 0) / 1000.0;
   final userAnswer = _textController.text.trim();
   _answers[_currentQuestionIndex] = userAnswer;
   final currentQuestion = questions[_currentQuestionIndex];
   final textCorrect = _checkAnswer(currentQuestion, userAnswer);
   final wasCorrect =
       gradeWithHelp(textCorrect: textCorrect, helpLevel: _helpLevel);
   ```
   Replace the two debug `print` blocks that reference `timeThreshold` / `tookTooLong` with a single `debugPrint('Q${currentQuestion.listNumber}: correct=$wasCorrect help=$_helpLevel t=${responseTime}s');`.
7. Wherever the screen nulls the clock between questions (the code that previously reassigned `_responseTimer` when advancing), set `_answerClock = null;` so the build method's post-frame callback starts the next question.
8. In `_showHilfe`, delete the `_responseTimer?.pause()` and `resume()` lines. Task 5 deletes `_showHilfe` itself.

- [ ] **Step 6: Verify**

Run: `cd math_app && grep -n "_responseTimer\|PausableTimeout\|Noch mehr Zeit\|Weiter versuchen\|tookTooLong" -r lib test`
Expected: no output.

Run: `cd math_app && flutter analyze && flutter test`
Expected: analyze clean, all tests pass.

- [ ] **Step 7: Commit**

```bash
git add -A math_app/lib math_app/test
git commit -m "feat(diagnostic): remove child-facing timeout, record response time only"
```

---

### Task 2: Text columns in the CSV and the parser

**Files:**
- Modify: `math_app/Research/diagnostic_v4_master.csv` (header plus every row)
- Modify: `math_app/lib/models/diagnostic_question.dart`, `math_app/lib/services/diagnostic_service.dart:28-29,63-84`
- Create: `math_app/lib/services/diagnostic_audio.dart`
- Test: `math_app/test/diagnostic_service_test.dart` (add a group), `math_app/test/diagnostic_audio_test.dart` (new)

**Interfaces:**
- Produces:
  - `DiagnosticQuestion.sprechtext` (`String?`) and `DiagnosticQuestion.hilfen` (`List<String>`, 0–3 entries in stage order). The `hilfetext` field is removed.
  - `class DiagnosticAudio { static String questionAsset(int listNumber); static String hintAsset(int listNumber, int stage); }`, where stage is 1..3. Returns e.g. `assets/audio/diagnostic/q24_frage.mp3` and `assets/audio/diagnostic/q24_hilfe2.mp3`.

- [ ] **Step 1: Restructure the CSV header**

Run this one-off with `uv run --no-project python` from the repo root:
```python
import csv
p = 'math_app/Research/diagnostic_v4_master.csv'
rows = list(csv.reader(open(p, encoding='utf-8', newline='')))
hdr = rows[0]
assert hdr[13] == 'Hilfetext' and len(hdr) == 14, hdr
assert all((r[13] if len(r) > 13 else '').strip() == '' for r in rows[1:]), 'Hilfetext not empty'
rows[0] = hdr[:13] + ['Sprechtext', 'Hilfe1', 'Hilfe2', 'Hilfe3']
for r in rows[1:]:
    r[:] = (r + [''] * 17)[:13] + ['', '', '', '']
csv.writer(open(p, 'w', encoding='utf-8', newline=''), lineterminator='\n').writerows(rows)
```
Expected: no assertion error. `git diff --stat` shows only this file.

- [ ] **Step 2: Write the failing tests**

Append to `math_app/test/diagnostic_service_test.dart`, inside `main()`:
```dart
  group('voice text columns', () {
    const header =
        'ListNumber,SourceType,QuestionText,AnswerFormat,CorrectAnswer,German,English,IfWrong_practice_skills,Ifwrong_skip,Notes,SkipGroup,Zahlenraum,AudioAsset,Sprechtext,Hilfe1,Hilfe2,Hilfe3\n';
    test('parses Sprechtext and three hints in order', () {
      final qs = DiagnosticService.loadQuestionsFromCsv(header +
          '24,Text,"Zähle: 5, 10, __",Single,15,"Zähle: 5, 10, __",x,skip5_forward_zr100,,,,ZR100,,Sprich das,H eins,H zwei,H drei\n');
      expect(qs.single.sprechtext, 'Sprich das');
      expect(qs.single.hilfen, ['H eins', 'H zwei', 'H drei']);
    });
    test('missing hint columns give an empty list', () {
      final qs = DiagnosticService.loadQuestionsFromCsv(header +
          '1,Text,Q,Single,1,Q,x,quantify_count_zr10,,,,ZR10,\n');
      expect(qs.single.sprechtext, isNull);
      expect(qs.single.hilfen, isEmpty);
    });
  });
```

`math_app/test/diagnostic_audio_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/diagnostic_audio.dart';

void main() {
  test('asset paths', () {
    expect(DiagnosticAudio.questionAsset(24), 'assets/audio/diagnostic/q24_frage.mp3');
    expect(DiagnosticAudio.hintAsset(24, 2), 'assets/audio/diagnostic/q24_hilfe2.mp3');
  });
  test('hint stage out of range throws', () {
    expect(() => DiagnosticAudio.hintAsset(24, 0), throwsRangeError);
    expect(() => DiagnosticAudio.hintAsset(24, 4), throwsRangeError);
  });
}
```

- [ ] **Step 3: Run them to verify they fail**

Run: `cd math_app && flutter test test/diagnostic_service_test.dart test/diagnostic_audio_test.dart`
Expected: FAIL (`sprechtext` and `hilfen` undefined, `diagnostic_audio.dart` missing).

- [ ] **Step 4: Implement**

In `diagnostic_question.dart`:
- Replace `final String? hilfetext; // On-demand help text...` with:
  ```dart
  final String? sprechtext; // What the voice says for the question (TTS source)
  final List<String> hilfen; // Help stages 1..3: rephrase, breakdown, direct instruction
  ```
- In the constructor, replace `this.hilfetext,` with `this.sprechtext, this.hilfen = const [],`.

In `diagnostic_service.dart`:
- Update the doc comment's schema line to `...,AudioAsset,Sprechtext,Hilfe1,Hilfe2,Hilfe3`.
- Replace the `hilfetextRaw` line with:
  ```dart
  String col(int i) => row.length > i ? row[i].toString().trim() : '';
  final sprechtextRaw = col(13);
  final hilfen = [col(14), col(15), col(16)].where((h) => h.isNotEmpty).toList();
  ```
- Replace `hilfetext: hilfetextRaw.isEmpty ? null : hilfetextRaw,` with `sprechtext: sprechtextRaw.isEmpty ? null : sprechtextRaw, hilfen: hilfen,`.

`math_app/lib/services/diagnostic_audio.dart`:
```dart
/// Bundled voice clips for diagnostic items, generated by
/// scripts/generate_diagnostic_audio.py from the CSV's Sprechtext/Hilfe1-3.
class DiagnosticAudio {
  static const _dir = 'assets/audio/diagnostic';

  static String questionAsset(int listNumber) => '$_dir/q${listNumber}_frage.mp3';

  static String hintAsset(int listNumber, int stage) {
    RangeError.checkValueInInterval(stage, 1, 3, 'stage');
    return '$_dir/q${listNumber}_hilfe$stage.mp3';
  }
}
```

- [ ] **Step 5: Fix the remaining `hilfetext` references**

Run: `cd math_app && grep -rn "hilfetext" lib test`. In `diagnostic_screen.dart`, temporarily remove the `if (question.hilfetext != null ...)` block that renders the Hilfe button, and the `_showHilfe` method. Task 5 replaces both. Fix any test fixtures that construct `hilfetext:`.

- [ ] **Step 6: Verify**

Run: `cd math_app && flutter analyze && flutter test`
Expected: clean, all pass.

- [ ] **Step 7: Commit**

```bash
git add math_app
git commit -m "feat(diagnostic): Sprechtext + three Hilfe columns replace Hilfetext"
```

---

### Task 3: Author the texts and the content gate

**Files:**
- Create: `scripts/check_diagnostic_voice_texts.py`, `scripts/tests/test_check_diagnostic_voice_texts.py`
- Modify: `math_app/Research/diagnostic_v4_master.csv` (fill columns 13–16 for every row)

**Interfaces:**
- Produces: `check(rows: list[dict]) -> list[str]`, which returns error strings, empty when clean. The CLI exits 1 on errors.

- [ ] **Step 1: Write the failing test**

`scripts/tests/test_check_diagnostic_voice_texts.py`:
```python
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from check_diagnostic_voice_texts import check

def row(**kw):
    base = dict(ListNumber='24', CorrectAnswer='75, 80, 85, 90', Sprechtext='Zähle weiter.',
                Hilfe1='Die Zahlen werden immer um 5 größer.',
                Hilfe2='Was kommt nach 70, wenn du 5 weiterzählst?',
                Hilfe3='Rechne zu jeder Zahl plus 5.')
    base.update(kw)
    return base

def test_clean_row_passes():
    assert check([row()]) == []

def test_missing_text_fails():
    assert any('Hilfe2' in e for e in check([row(Hilfe2='')]))

def test_hint3_must_not_contain_answer():
    assert any('verrät' in e for e in check([row(Hilfe3='Schreib 75, 80, 85, 90.')]))

def test_single_answer_leak_is_whole_word_only():
    # answer 9 must not match inside 90 or 19
    assert check([row(CorrectAnswer='9', Hilfe3='Zähle 19 und 90 nicht mit.')]) == []
    assert any('verrät' in e for e in check([row(CorrectAnswer='9', Hilfe3='Es sind 9.')]))

def test_overlong_hint_fails():
    assert any('zu lang' in e for e in check([row(Hilfe1='wort ' * 31)]))
```

- [ ] **Step 2: Run it to verify it fails**

Run: `uv run --no-project --with pytest pytest scripts/tests/test_check_diagnostic_voice_texts.py -q`
Expected: FAIL, the module is missing.

- [ ] **Step 3: Implement the checker**

`scripts/check_diagnostic_voice_texts.py`:
```python
"""Gate for the diagnostic voice texts (spec 2026-10-22 §2).

Every row needs Sprechtext + Hilfe1..3, each hint at most 30 words, and
Hilfe3 (the direct instruction) must not give away the answer.
Usage: python scripts/check_diagnostic_voice_texts.py
"""
import csv, re, sys, pathlib

CSV = pathlib.Path(__file__).resolve().parents[1] / 'math_app/Research/diagnostic_v4_master.csv'
FIELDS = ['Sprechtext', 'Hilfe1', 'Hilfe2', 'Hilfe3']
MAX_WORDS = 30

def _answer_tokens(answer: str) -> list[str]:
    return [t for t in re.split(r'[,;/\s]+', answer.strip()) if t]

def check(rows):
    errors = []
    for r in rows:
        n = r['ListNumber']
        for f in FIELDS:
            text = (r.get(f) or '').strip()
            if not text:
                errors.append(f'Q{n}: {f} fehlt')
            elif f != 'Sprechtext' and len(text.split()) > MAX_WORDS:
                errors.append(f'Q{n}: {f} zu lang ({len(text.split())} Wörter)')
        h3 = r.get('Hilfe3') or ''
        tokens = _answer_tokens(r.get('CorrectAnswer') or '')
        if tokens and all(re.search(rf'(?<![\d]){re.escape(t)}(?![\d])', h3) for t in tokens):
            errors.append(f'Q{n}: Hilfe3 verrät die Antwort')
    return errors

def main():
    rows = list(csv.DictReader(open(CSV, encoding='utf-8')))
    errors = check(rows)
    for e in errors:
        print(e)
    print(f'{len(rows)} Zeilen, {len(errors)} Fehler')
    sys.exit(1 if errors else 0)

if __name__ == '__main__':
    main()
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `uv run --no-project --with pytest pytest scripts/tests/test_check_diagnostic_voice_texts.py -q`
Expected: 5 passed.

- [ ] **Step 5: Author the texts for all rows**

Work through the CSV in order, family by family (the rows are grouped). For each row, read `German`, `CorrectAnswer`, `AnswerFormat` and, for image rows, the visual item spec (`buildVisualDisplay` in `diagnostic_screen.dart`, keyed by `QuestionText`), then write:

- **Sprechtext:** what the child hears. One or two short sentences. Image rows start with "Schau dir das Bild an." Blanks are never read as symbols: "60, 65, 70, __" becomes "60, 65, 70. Welche Zahlen kommen dann?". Digits are fine here, because the generator converts them to words. Q55 (Zahlendiktat): the instruction only. Its dictation audio plays after it.
- **Hilfe1:** the same question, asked a different way. Not easier, just different words.
- **Hilfe2:** broken down: the first step, or what to look at first.
- **Hilfe3:** a direct instruction of what to do, e.g. "Rechne zu jeder Zahl plus 5. So bekommst du die nächste Zahl." Never the answer.
- All hints: words a 6–8-year-old knows, short sentences, at most 30 words, digits as digits (they are displayed).

Reference row (Q24, `skip5_forward_zr100`):

| Column | Text |
|---|---|
| Sprechtext | Zähle in Fünferschritten weiter. 60, 65, 70. Welche vier Zahlen kommen dann? |
| Hilfe1 | Die Zahlen werden immer um 5 größer. Wie geht es nach 70 weiter? |
| Hilfe2 | Schau auf die 70. Zähle 5 weiter. Das ist die erste Zahl. Dann machst du das noch dreimal. |
| Hilfe3 | Rechne zu jeder Zahl plus 5. So bekommst du die nächste Zahl. |

Write the texts with a Python helper that loads the CSV with `csv.DictReader`, sets the four fields from a dict keyed by `ListNumber`, and writes it back with `lineterminator='\n'` and the same header order. Do it one family per helper run, so diffs stay reviewable.

- [ ] **Step 6: Gate**

Run: `uv run --no-project python scripts/check_diagnostic_voice_texts.py`
Expected: `111 Zeilen, 0 Fehler` (the row count may differ; it is `wc -l` minus 1).

Run: `cd math_app && flutter test test/diagnostic_service_test.dart test/diagnostic_answerability_test.dart`
Expected: PASS (the CSV still parses).

- [ ] **Step 7: Commit**

```bash
git add scripts/check_diagnostic_voice_texts.py scripts/tests/test_check_diagnostic_voice_texts.py math_app/Research/diagnostic_v4_master.csv
git commit -m "content(diagnostic): Sprechtext and three help stages for every item"
```

---

### Task 4: Generate the audio with the voice clone

**Files:**
- Create: `scripts/german_numbers.py`, `scripts/tests/test_german_numbers.py`
- Create: `scripts/generate_diagnostic_audio.py`
- Create: `math_app/assets/audio/diagnostic/*.mp3`, `math_app/assets/audio/diagnostic/manifest.json`
- Modify: `math_app/pubspec.yaml` (assets list)

**Interfaces:**
- Consumes: the CSV columns from Task 3. `voice.jobs.Item`, `voice.jobs.build_job(engine=, items=, dataset_dir=, checkpoint=, out_dir=)` and `voice.jobs.run_in_engine_env(engine, job)` from the Voice project (`src/voice/jobs.py`).
- Produces: `spoken(text: str) -> str` (digits to German words), and the MP3 files at the paths `DiagnosticAudio` returns.

- [ ] **Step 1: Write the failing number test**

`scripts/tests/test_german_numbers.py`:
```python
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from german_numbers import number_to_words, spoken

def test_numbers():
    cases = {0: 'null', 1: 'eins', 7: 'sieben', 11: 'elf', 16: 'sechzehn', 17: 'siebzehn',
             20: 'zwanzig', 21: 'einundzwanzig', 30: 'dreißig', 65: 'fünfundsechzig',
             70: 'siebzig', 99: 'neunundneunzig', 100: 'hundert', 101: 'hunderteins',
             345: 'dreihundertfünfundvierzig', 1000: 'tausend'}
    for n, w in cases.items():
        assert number_to_words(n) == w, n

def test_spoken_replaces_digits_and_blanks():
    assert spoken('60, 65, 70, __') == 'sechzig, fünfundsechzig, siebzig, …'
    assert spoken('Rechne plus 5.') == 'Rechne plus fünf.'
    assert spoken('1 Punkt') == 'ein Punkt'
```

- [ ] **Step 2: Run it to verify it fails**

Run: `uv run --no-project --with pytest pytest scripts/tests/test_german_numbers.py -q`
Expected: FAIL, the module is missing.

- [ ] **Step 3: Implement `scripts/german_numbers.py`**

```python
"""German number words for TTS input (0..1000). Displayed texts keep digits;
only the string sent to the voice engine is converted."""
import re

_ONES = ['null', 'eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht', 'neun',
         'zehn', 'elf', 'zwölf', 'dreizehn', 'vierzehn', 'fünfzehn', 'sechzehn', 'siebzehn',
         'achtzehn', 'neunzehn']
_TENS = {2: 'zwanzig', 3: 'dreißig', 4: 'vierzig', 5: 'fünfzig', 6: 'sechzig', 7: 'siebzig',
         8: 'achtzig', 9: 'neunzig'}

def _below_100(n: int) -> str:
    if n < 20:
        return _ONES[n]
    t, o = divmod(n, 10)
    if o == 0:
        return _TENS[t]
    unit = 'ein' if o == 1 else _ONES[o]
    return f'{unit}und{_TENS[t]}'

def number_to_words(n: int) -> str:
    if n == 1000:
        return 'tausend'
    if not 0 <= n < 1000:
        return str(n)
    h, rest = divmod(n, 100)
    if h == 0:
        return _below_100(rest)
    head = 'hundert' if h == 1 else _ONES[h] + 'hundert'
    return head if rest == 0 else head + _below_100(rest)

def spoken(text: str) -> str:
    text = re.sub(r'_{2,}', '…', text)
    # "1 Punkt" -> "ein Punkt"; a standalone 1 elsewhere stays "eins"
    text = re.sub(r'(?<![\d])1(?= [A-ZÄÖÜ][a-zäöüß])', 'ein', text)
    return re.sub(r'\d+', lambda m: number_to_words(int(m.group())), text)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `uv run --no-project --with pytest pytest scripts/tests/test_german_numbers.py -q`
Expected: 2 passed.

- [ ] **Step 5: Write `scripts/generate_diagnostic_audio.py`**

```python
"""Generate the diagnostic voice clips with Jakob's Qwen3 voice clone.

Run from the Voice project so its environment and `voice` package are used:
  cd "C:/Users/jakob/Documents/Cursor projects/Voice"
  uv run --no-sync python "C:/Users/jakob/StudioProjects/Math_App/scripts/generate_diagnostic_audio.py"

One batch job, so the 1.7B model loads once (the same engine and German
reference `voice speak --lang de --engine qwen3` uses). Incremental:
manifest.json maps file -> spoken text; unchanged texts are skipped.
"""
import csv, json, pathlib, subprocess, sys, tempfile

MATH_APP = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MATH_APP / 'scripts'))
from german_numbers import spoken  # noqa: E402

from voice.jobs import Item, build_job, run_in_engine_env  # noqa: E402

VOICE_ROOT = pathlib.Path.cwd()
CSV = MATH_APP / 'math_app/Research/diagnostic_v4_master.csv'
OUT = MATH_APP / 'math_app/assets/audio/diagnostic'
SLOTS = [('Sprechtext', 'frage'), ('Hilfe1', 'hilfe1'), ('Hilfe2', 'hilfe2'), ('Hilfe3', 'hilfe3')]

def wanted() -> dict[str, str]:
    files = {}
    for r in csv.DictReader(open(CSV, encoding='utf-8')):
        for col, slot in SLOTS:
            text = (r.get(col) or '').strip()
            if text:
                files[f"q{r['ListNumber']}_{slot}.mp3"] = spoken(text)
    return files

def main():
    if not (VOICE_ROOT / 'src/voice').exists():
        sys.exit('run this from the Voice project folder')
    OUT.mkdir(parents=True, exist_ok=True)
    manifest_path = OUT / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {}
    want = wanted()
    todo = {f: t for f, t in want.items() if manifest.get(f) != t or not (OUT / f).exists()}
    print(f'{len(want)} clips, {len(todo)} to generate')
    if todo:
        with tempfile.TemporaryDirectory() as tmp:
            items = [Item(id=f.removesuffix('.mp3'), text=t, lang='de') for f, t in todo.items()]
            job = build_job(engine='qwen3', items=items, dataset_dir=VOICE_ROOT / 'data/dataset',
                            checkpoint=None, out_dir=tmp)
            run_in_engine_env('qwen3', job)
            for f, t in todo.items():
                wav = pathlib.Path(tmp) / f.replace('.mp3', '.wav')
                if not wav.exists():
                    print(f'FEHLT: {f}')
                    continue
                subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(wav),
                                '-af', 'silenceremove=start_periods=1:start_threshold=-50dB,'
                                       'areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
                                       'loudnorm=I=-16:TP=-1.5:LRA=11',
                                '-ar', '44100', '-ac', '1', '-b:a', '64k', str(OUT / f)], check=True)
                manifest[f] = t
    for stale in set(manifest) - set(want):
        (OUT / stale).unlink(missing_ok=True)
        manifest.pop(stale)
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
    print('fertig')

if __name__ == '__main__':
    main()
```

- [ ] **Step 6: Smoke-run on three rows first**

Temporarily limit `wanted()` to `ListNumber in {'1', '24', '55'}` with an env-var guard: `if os.environ.get('ONLY') and r['ListNumber'] not in os.environ['ONLY'].split(','): continue` (add `import os`; keep the guard).

Run (PowerShell):
```powershell
cd "C:\Users\jakob\Documents\Cursor projects\Voice"; $env:ONLY="1,24,55"; uv run --no-sync python "C:\Users\jakob\StudioProjects\Math_App\scripts\generate_diagnostic_audio.py"; Remove-Item Env:ONLY
```
Expected: `12 clips, 12 to generate`, then `fertig`. Play `q24_hilfe3.mp3` and confirm it says "Rechne zu jeder Zahl plus fünf…" in Jakob's voice, with no whine.

- [ ] **Step 7: Full run**

Run the same command without `ONLY`. Expected: all clips generated, and a second run prints `… 0 to generate`. Wall time on the RTX 3060 is roughly 20–40 min, so run it in the background.

- [ ] **Step 8: Whisper spot-check**

Transcribe 20 random clips with the Voice project's faster-whisper (`large-v3`, `language='de'`) and compare each transcript to its manifest text. Regenerate any clip whose words differ beyond punctuation: delete the file and rerun Step 7. Run from the Voice folder:
```python
import json, random, pathlib
from faster_whisper import WhisperModel
d = pathlib.Path(r'C:\Users\jakob\StudioProjects\Math_App\math_app\assets\audio\diagnostic')
m = json.loads((d / 'manifest.json').read_text(encoding='utf-8'))
model = WhisperModel('large-v3', device='cpu', compute_type='int8')
for f in random.sample(sorted(m), 20):
    segs, _ = model.transcribe(str(d / f), language='de')
    print(f, '|', m[f], '|', ' '.join(s.text.strip() for s in segs))
```

- [ ] **Step 9: Register the assets and commit**

In `math_app/pubspec.yaml`, under `assets:` after `- assets/skill_specs/`, add `- assets/audio/diagnostic/`.

Run: `cd math_app && flutter test` (expected: PASS).

```bash
git add scripts/german_numbers.py scripts/tests/test_german_numbers.py scripts/generate_diagnostic_audio.py math_app/assets/audio/diagnostic math_app/pubspec.yaml
git commit -m "feat(diagnostic): voice clips for every question and hint (Qwen3 clone)"
```

---

### Task 5: Help panel, autoplay and replay in the child screen

**Files:**
- Create: `math_app/lib/widgets/diagnostic/help_panel.dart`, `math_app/test/help_panel_test.dart`
- Modify: `math_app/lib/screens/diagnostic_screen.dart` (`_startQuestion`, build Column ~970-1005, `_buildAudioReplayButton`, `_playAudio`)

**Interfaces:**
- Consumes: `DiagnosticQuestion.hilfen`, `DiagnosticAudio.questionAsset/hintAsset`, `AnswerClock.startIfIdle`, `_helpLevel` (Task 1).
- Produces: `class HelpPanel extends StatelessWidget { const HelpPanel({required List<String> hints, required int revealed, required VoidCallback onReplayQuestion, required VoidCallback onRequestHelp, required ValueChanged<int> onReplayHint}); }`. `revealed` is 0..3. `onReplayHint` receives the stage (1..3).

- [ ] **Step 1: Write the failing widget test**

`math_app/test/help_panel_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/diagnostic/help_panel.dart';

Widget host(int revealed, {VoidCallback? onHelp, ValueChanged<int>? onHint, VoidCallback? onReplay}) =>
    MaterialApp(home: Scaffold(body: HelpPanel(
      hints: const ['Eins', 'Zwei', 'Drei'],
      revealed: revealed,
      onReplayQuestion: onReplay ?? () {},
      onRequestHelp: onHelp ?? () {},
      onReplayHint: onHint ?? (_) {},
    )));

void main() {
  testWidgets('shows only revealed hints', (t) async {
    await t.pumpWidget(host(2));
    expect(find.text('Eins'), findsOneWidget);
    expect(find.text('Zwei'), findsOneWidget);
    expect(find.text('Drei'), findsNothing);
  });

  testWidgets('Hilfe button calls onRequestHelp and disappears after stage 3', (t) async {
    var asked = 0;
    await t.pumpWidget(host(0, onHelp: () => asked++));
    await t.tap(find.text('Hilfe'));
    expect(asked, 1);
    await t.pumpWidget(host(3));
    expect(find.text('Hilfe'), findsNothing);
  });

  testWidgets('replay buttons report question and hint stage', (t) async {
    var replays = 0; int? hint;
    await t.pumpWidget(host(2, onReplay: () => replays++, onHint: (s) => hint = s));
    await t.tap(find.byKey(const ValueKey('replay_question')));
    await t.tap(find.byKey(const ValueKey('replay_hint_2')));
    expect(replays, 1);
    expect(hint, 2);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd math_app && flutter test test/help_panel_test.dart`
Expected: FAIL, the import is missing.

- [ ] **Step 3: Implement `help_panel.dart`**

```dart
import 'package:flutter/material.dart';

/// Child-facing controls under a diagnostic question: replay the question,
/// ask for help (up to three stages), and replay any revealed hint.
/// Big targets: these children are not confident with devices.
class HelpPanel extends StatelessWidget {
  final List<String> hints;
  final int revealed;
  final VoidCallback onReplayQuestion;
  final VoidCallback onRequestHelp;
  final ValueChanged<int> onReplayHint;

  const HelpPanel({
    super.key,
    required this.hints,
    required this.revealed,
    required this.onReplayQuestion,
    required this.onRequestHelp,
    required this.onReplayHint,
  });

  @override
  Widget build(BuildContext context) {
    final shown = hints.take(revealed).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('replay_question'),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 64)),
              icon: const Icon(Icons.volume_up, size: 32),
              label: const Text('Nochmal hören', style: TextStyle(fontSize: 20)),
              onPressed: onReplayQuestion,
            ),
            if (revealed < hints.length)
              FilledButton.icon(
                key: const ValueKey('request_help'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 64),
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.lightbulb, size: 32),
                label: const Text('Hilfe', style: TextStyle(fontSize: 20)),
                onPressed: onRequestHelp,
              ),
          ],
        ),
        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              color: const Color(0xFFFFF8E1),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                  child: Text('${i + 1}'),
                ),
                title: Text(shown[i], style: const TextStyle(fontSize: 20)),
                trailing: IconButton(
                  key: ValueKey('replay_hint_${i + 1}'),
                  iconSize: 32,
                  tooltip: 'Hilfe nochmal hören',
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => onReplayHint(i + 1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd math_app && flutter test test/help_panel_test.dart`
Expected: 3 passed.

- [ ] **Step 5: Wire it into the screen**

In `diagnostic_screen.dart`:

1. Add an audio-completion listener in `initState`:
   ```dart
   _audioCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
     final next = _queuedAudio;
     _queuedAudio = null;
     if (next != null) {
       _playAudio(next);
     } else {
       _answerClock?.startIfIdle();
     }
   });
   ```
   Add the fields `StreamSubscription<void>? _audioCompleteSub; String? _queuedAudio;`, call `_audioCompleteSub?.cancel();` in `dispose`, and add `import 'dart:async';` if it is missing.
2. Replace `_startQuestion` (from Task 1) with:
   ```dart
   void _startQuestion(List<DiagnosticQuestion> questions) {
     if (_currentQuestionIndex >= questions.length) return;
     final question = questions[_currentQuestionIndex];
     _answerClock = AnswerClock();
     setState(() => _helpLevel = 0);
     _playQuestionAudio(question);
   }

   /// The voiced prompt, then (Q55 only) the dictation clip queued behind it.
   void _playQuestionAudio(DiagnosticQuestion question) {
     _queuedAudio = question.audioAsset;
     if (question.sprechtext != null) {
       _playAudio(DiagnosticAudio.questionAsset(question.listNumber));
     } else if (_queuedAudio != null) {
       final a = _queuedAudio!;
       _queuedAudio = null;
       _playAudio(a);
     } else {
       _answerClock?.startIfIdle();
     }
   }
   ```
3. In `_playAudio`, wrap the body in `try { … } catch (e) { debugPrint('audio failed: $e'); _queuedAudio = null; _answerClock?.startIfIdle(); }`, so a missing clip or blocked autoplay never leaves the clock unstarted.
4. Start the clock on the first input. In `initState`, add `_textController.addListener(() { if (_textController.text.isNotEmpty) _answerClock?.startIfIdle(); });`.
5. In the build Column, replace the old `if (question.audioAsset != null) ...[ _buildAudioReplayButton(...) ]` block with:
   ```dart
   const SizedBox(height: 16),
   HelpPanel(
     key: ValueKey('help_${question.listNumber}'),
     hints: question.hilfen,
     revealed: _helpLevel,
     onReplayQuestion: () => _playQuestionAudio(question),
     onRequestHelp: () {
       if (_helpLevel >= question.hilfen.length) return;
       setState(() => _helpLevel++);
       _queuedAudio = null;
       _playAudio(DiagnosticAudio.hintAsset(question.listNumber, _helpLevel));
     },
     onReplayHint: (stage) {
       _queuedAudio = null;
       _playAudio(DiagnosticAudio.hintAsset(question.listNumber, stage));
     },
   ),
   ```
   Delete `_buildAudioReplayButton`. Add the imports for `help_panel.dart` and `diagnostic_audio.dart`.
6. Autoplay on the web needs a prior user gesture. The child taps "Start" (or enters a code) before question 1, so this is satisfied. If `play` throws, step 3 still starts the clock and the 🔊 button works.

- [ ] **Step 6: Verify**

Run: `cd math_app && flutter analyze && flutter test`
Expected: clean, all pass.

Manual check: run `cd math_app && flutter run -d chrome`, open the diagnostic, and confirm:
- the question is read on arrival;
- 🔊 replays it;
- Hilfe reveals and reads stages 1→2→3, then the button disappears;
- each hint card's 🔊 replays that hint;
- Q55 plays the instruction, then the dictation;
- waiting 60 s shows no dialog.

- [ ] **Step 7: Commit**

```bash
git add math_app
git commit -m "feat(diagnostic): voiced question autoplay and three-stage help panel"
```

---

### Task 6: Record `help_level` end to end

**Files:**
- Create: `backend/supabase/migrations/20261022000000_help_level.sql`
- Modify: `backend/supabase/functions/diagnostic-results/index.ts`, `backend/supabase/functions/diagnostic-sessions/index.ts:118-131`
- Modify: `math_app/lib/models/diagnostic_result.dart`, `math_app/lib/services/api_service.dart` (`ServerResult`, `postResult`), `math_app/lib/screens/diagnostic_screen.dart` (`_AnswerRow`, `_persistRowWithRetry`, `_nextQuestionInner`, `_hydrateFromServer`)
- Modify: `dashboard/app/dashboard/foerderplan/[sessionId]/page.tsx:135-160,335-350`
- Test: `math_app/test/diagnostic_result_help_level_test.dart` (new)

**Interfaces:**
- Consumes: `_helpLevel` (Task 1/5).
- Produces: DB column `diagnostic_results.help_level smallint not null default 0`, request field `help_level`, response field `help_level`, and `DiagnosticResult.helpLevel` / `ServerResult.helpLevel` (`int`, default 0).

- [ ] **Step 1: Write the failing Dart test**

`math_app/test/diagnostic_result_help_level_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_result.dart';
import 'package:math_app/services/api_service.dart';

void main() {
  test('DiagnosticResult round-trips helpLevel, defaulting to 0', () {
    final r = DiagnosticResult(questionId: '1', wasCorrect: true, responseTimeSeconds: 2, helpLevel: 2);
    expect(DiagnosticResult.fromJson(r.toJson()).helpLevel, 2);
    expect(DiagnosticResult.fromJson({'questionId': '1', 'wasCorrect': true, 'responseTimeSeconds': 1}).helpLevel, 0);
  });
  test('ServerResult parses help_level, defaulting to 0', () {
    expect(ServerResult.fromJson({'question_number': 3, 'help_level': 3}).helpLevel, 3);
    expect(ServerResult.fromJson({'question_number': 3}).helpLevel, 0);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd math_app && flutter test test/diagnostic_result_help_level_test.dart`
Expected: FAIL, no `helpLevel` named parameter.

- [ ] **Step 3: Implement the client side**

- `DiagnosticResult`: add `final int helpLevel;` (doc: `/// Highest help stage the child opened (0-3)`), the constructor param `this.helpLevel = 0`, `'helpLevel': helpLevel` in `toJson`, `helpLevel: json['helpLevel'] as int? ?? 0` in `fromJson`, and `int? helpLevel` in `copyWith`.
- `ServerResult`: add `final int helpLevel;` (constructor `this.helpLevel = 0`), and `helpLevel: j['help_level'] as int? ?? 0` in `fromJson`.
- `ApiService.postResult`: add the param `int helpLevel = 0` and the body field `'help_level': helpLevel,`.
- `diagnostic_screen.dart`:
  - add `int helpLevel` to the `_AnswerRow` record type and pass `helpLevel: _helpLevel` where `currentRow` is built in `_nextQuestionInner`;
  - for gate-skipped rows built in the skip walk, pass `helpLevel: 0`;
  - pass `helpLevel: row.helpLevel` in `_persistRowWithRetry`;
  - add `helpLevel: _helpLevel` to the `DiagnosticResult` in `_nextQuestionInner`;
  - add `helpLevel: r.helpLevel` in `_hydrateFromServer`.

Run: `cd math_app && flutter analyze && flutter test`
Expected: clean, all pass.

- [ ] **Step 4: Migration**

`backend/supabase/migrations/20261022000000_help_level.sql`:
```sql
-- Highest help stage (0-3) the child opened for this item (spec 2026-10-22).
-- Correct-after-stage-3 is already folded into was_correct by the client;
-- this column is for the teacher's Detail-Tabelle.
alter table public.diagnostic_results
  add column help_level smallint not null default 0
  check (help_level between 0 and 3);
```

- [ ] **Step 5: Edge functions**

In `diagnostic-results/index.ts`:
- add `help_level?: number;` to `ResultPayload`;
- add `help_level` to the destructure;
- add `help_level: Number.isInteger(help_level) && help_level! >= 0 && help_level! <= 3 ? help_level : 0,` to the upsert object;
- update the header comment's body list.

In `diagnostic-sessions/index.ts`, add `help_level` to the select string (`"question_id, was_correct, response_time_seconds, status, user_answer, help_level, "`) and `help_level: (r.help_level as number | null) ?? 0,` to the mapped object.

Run: `cd backend/supabase/functions && deno check diagnostic-results/index.ts diagnostic-sessions/index.ts`
Expected: no errors.

- [ ] **Step 6: Dashboard**

In `page.tsx`:
- add `help_level` to the `.select(...)` string and `help_level: number;` to the row type;
- after the `statusLabel` if/else chain, add:
  ```tsx
  if (row.help_level > 0 && row.status !== "skipped") {
    statusLabel += row.help_level === 3 && !row.was_correct
      ? " · nach Hilfe 3"
      : ` · Hilfe ${row.help_level}`;
  }
  ```

Run: `cd dashboard && npx tsc --noEmit`
Expected: no errors.

- [ ] **Step 7: Commit (no deploy)**

```bash
git add backend dashboard math_app
git commit -m "feat(diagnostic): record help_level per answer and show it to teachers"
```

- [ ] **Step 8: Deploy, only after Jakob's explicit go**

Order matters, because the function writes the new column:
1. `cd backend && supabase db push`
2. `supabase functions deploy diagnostic-results` and `supabase functions deploy diagnostic-sessions`
3. `git push origin main` (this auto-deploys the dashboard and the child app on Vercel).

Verify: answer one question with hint 2 on the production child app, then confirm the dashboard row shows "Richtig · Hilfe 2".

---

### Task 7: Intro video

**Files:**
- Create: `tools/intro_video/narration.txt`, `tools/intro_video/scene.html`, `tools/intro_video/record.mjs`, `tools/intro_video/package.json`, `tools/intro_video/build.ps1`
- Output: `out/intro_video.mp4` (git-ignored; add `out/` to `.gitignore` if it isn't covered)

**Interfaces:**
- Consumes: Jakob's voice via `voice speak`. Same palette and button labels as `HelpPanel` ("Nochmal hören", "Hilfe", "Weiter").
- Produces: one MP4, 1920×1080, 30 fps, about 90–120 s.

- [ ] **Step 1: Narration, one paragraph per scene**

`tools/intro_video/narration.txt` (UTF-8; a blank line between scenes makes `voice speak` insert a longer pause):
```text
Hallo! Gleich bekommst du ein paar Rechenaufgaben. Ich lese dir jede Aufgabe vor.

Hier ist eine Aufgabe zum Üben. Zähle in Fünferschritten weiter: fünf, zehn, fünfzehn. Welche zwei Zahlen kommen dann?

Du willst die Aufgabe nochmal hören? Kein Problem. Drück auf den Knopf mit dem Lautsprecher. Dann lese ich sie dir nochmal vor.

Du weißt nicht weiter? Dann drück auf den gelben Knopf. Da steht Hilfe.

Jetzt sage ich dir die Aufgabe mit anderen Worten. Die Zahlen werden immer um fünf größer.

Du kannst nochmal auf Hilfe drücken. Dann erkläre ich es dir genauer. Schau auf die fünfzehn. Zähle fünf weiter.

Und wenn du nochmal drückst, sage ich dir genau, was du machen sollst. Rechne zu jeder Zahl plus fünf. Dreimal kannst du Hilfe drücken. Mehr nicht.

Jetzt schreibst du deine Antwort. Siehst du das Kästchen? Da blinkt ein kleiner Strich. Dort kommt deine Zahl hin.

Die Zahlen findest du auf der Tastatur. Entweder hier oben in der Reihe. Oder hier rechts, auf dem Zahlenblock.

Wir schreiben die zwanzig. Erst die Zwei. Dann die Null.

Es gibt noch ein zweites Kästchen. Um dorthin zu kommen, drückst du die Enter-Taste. Das ist die große Taste mit dem Pfeil, der um die Ecke geht. Schau, jetzt blinkt es im zweiten Kästchen.

Oh! Hier ist eine falsche Zahl. Das ist nicht schlimm. Wir machen sie weg.

Zuerst tippst du in das Kästchen mit der falschen Zahl. Ganz wichtig: zuerst ins Kästchen tippen!

Dann drückst du diese Taste. Sie hat einen Pfeil nach links. Damit löschst du die Zahl. Weg ist sie!

Jetzt schreiben wir die richtige Zahl: fünfundzwanzig.

Fertig! Wenn du alles aufgeschrieben hast, drückst du Enter oder den grünen Knopf Weiter. Dann kommt die nächste Aufgabe.

Das war's schon. Du schaffst das! Und wenn du etwas nicht weißt, ist das gar nicht schlimm.
```

- [ ] **Step 2: Generate the voiceover, one clip per scene**

Animation timing comes from each scene's audio length. So also render each paragraph separately: write `scene_NN.txt` per paragraph, then run `voice speak` per file. Add this to `build.ps1`:
```powershell
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$voice = 'C:\Users\jakob\Documents\Cursor projects\Voice'
$work = Join-Path $here 'work'; New-Item -ItemType Directory -Force $work | Out-Null
$paras = (Get-Content (Join-Path $here 'narration.txt') -Raw -Encoding utf8) -split "(\r?\n){2,}" | Where-Object { $_.Trim() }
Push-Location $voice
try {
  for ($i = 0; $i -lt $paras.Count; $i++) {
    $txt = Join-Path $work ('scene_{0:d2}.txt' -f $i)
    $mp3 = Join-Path $work ('scene_{0:d2}.mp3' -f $i)
    if (-not (Test-Path $mp3)) {
      [IO.File]::WriteAllText($txt, $paras[$i].Trim(), [Text.UTF8Encoding]::new($false))
      uv run --no-sync voice speak $txt --lang de --engine qwen3 -o $mp3
    }
  }
} finally { Pop-Location }
# Durations -> timeline.json for the animation
$durs = Get-ChildItem $work -Filter 'scene_*.mp3' | Sort-Object Name | ForEach-Object {
  [double](ffprobe -v error -show_entries format=duration -of csv=p=0 $_.FullName)
}
($durs | ConvertTo-Json) | Set-Content (Join-Path $work 'timeline.json') -Encoding utf8
```
Expected: 17 MP3s in `tools/intro_video/work/` and a `timeline.json` with 17 numbers.

- [ ] **Step 3: Animated scene**

Create `tools/intro_video/scene.html`, a single self-contained page at 1920×1080. It exposes `window.renderAt(tSeconds)`, which draws the frame for a given time, deterministically (no CSS transitions, no timers). Elements:

- The question screen mock: progress bar, prompt "Zähle in Fünferschritten weiter: 5, 10, 15, [ ] , [ ]" with two inline boxes, "Nochmal hören" (🔊) and a yellow "Hilfe" button, hint cards with a number badge, and a green "Weiter" button.
- A big animated pointing hand (SVG) that glides to targets with ease-in-out and "presses" them (scale 0.9 for 150 ms, plus a ripple ring).
- A keyboard drawing (shown from scene 8 on): the number row, a separate Zahlenblock on the right, Enter (an L-shaped key with a ↵ arrow) and Backspace (⟵). Each key highlights yellow and pulses when the narration names it.
- The box caret: a blinking 4 px bar inside the focused box (blink derived from `t`, 1 Hz).
- Text appears in the boxes keystroke by keystroke, synced to the key presses.

The scene table (index = paragraph from Step 1). Each scene's start time is the running sum of `timeline.json`, plus 0.6 s padding after each:

| # | On screen |
|---|---|
| 0 | Question screen fades in. |
| 1 | The prompt is highlighted word by word. |
| 2 | Hand → 🔊, press; the speaker icon emits sound waves. |
| 3 | Hand → Hilfe, hover pulse. |
| 4 | Press Hilfe; hint card 1 slides in. |
| 5 | Press Hilfe; hint card 2. |
| 6 | Press Hilfe; hint card 3; the Hilfe button fades out. |
| 7 | Box 1 enlarges with a glow; the caret blinks. |
| 8 | The keyboard slides up; the number row glows, then the Zahlenblock glows. |
| 9 | Key "2" pressed, "2" in box 1; key "0" pressed, "20". |
| 10 | Enter key glows and is pressed; the caret jumps to box 2 with an arrow trail. |
| 11 | "26" appears in box 2 with a red wobble. |
| 12 | Hand → taps box 2; the box glows; a big "1." badge. |
| 13 | The Backspace key glows, "2." badge, pressed twice; the digits vanish one at a time. |
| 14 | "25" typed on the Zahlenblock. |
| 15 | Enter pressed (and the Weiter button pulses); a ✓ and a confetti burst. |
| 16 | "Du schaffst das!" with a star; fade out. |

The page fetches `work/timeline.json` and, for scenes 4–6, plays nothing itself (audio is muxed later). Load fonts locally or use the system font (`Segoe UI, sans-serif`). No network.

- [ ] **Step 4: Recorder**

`tools/intro_video/package.json`:
```json
{ "private": true, "type": "module", "dependencies": { "playwright": "1.47.2" } }
```

`tools/intro_video/record.mjs`:
```js
import { chromium } from 'playwright';
import { mkdirSync, readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname).replace(/^\/(\w:)/, '$1');
const durs = JSON.parse(readFileSync(path.join(here, 'work/timeline.json'), 'utf8'));
const total = durs.reduce((a, d) => a + d + 0.6, 0) + 1;
const fps = 30;
const frames = path.join(here, 'work/frames');
mkdirSync(frames, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
await page.goto(pathToFileURL(path.join(here, 'scene.html')).href);
await page.waitForFunction(() => window.ready === true);
for (let f = 0; f < Math.ceil(total * fps); f++) {
  await page.evaluate((t) => window.renderAt(t), f / fps);
  await page.screenshot({ path: path.join(frames, `f${String(f).padStart(5, '0')}.png`) });
}
await browser.close();
console.log('frames done', total.toFixed(1), 's');
```
The page must load `work/timeline.json` with `fetch` and set `window.ready = true`. Chromium blocks `fetch` on `file://`. So launch with `chromium.launch({ args: ['--allow-file-access-from-files'] })`, or inline the timeline by having `build.ps1` write `work/timeline.js` (`window.TIMELINE = [...]`) and loading it with a `<script>` tag. Use the inline `timeline.js` approach.

- [ ] **Step 5: Assemble in `build.ps1`**

Append:
```powershell
# timeline.js for the page
"window.TIMELINE = $((Get-Content (Join-Path $work 'timeline.json') -Raw));" | Set-Content (Join-Path $work 'timeline.js') -Encoding utf8
Push-Location $here; try { npm install --silent; node record.mjs } finally { Pop-Location }
# Audio track: each scene clip followed by 0.6 s silence, plus 1 s tail
$list = Join-Path $work 'concat.txt'
$sil = Join-Path $work 'sil.mp3'
ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=24000:cl=mono -t 0.6 -q:a 9 $sil
(Get-ChildItem $work -Filter 'scene_*.mp3' | Sort-Object Name | ForEach-Object { "file '$($_.FullName)'"; "file '$sil'" }) | Set-Content $list -Encoding ascii
$audio = Join-Path $work 'narration_full.mp3'
ffmpeg -y -loglevel error -f concat -safe 0 -i $list -ar 44100 -ac 1 $audio
$outDir = Join-Path (Resolve-Path "$here\..\..") 'out'; New-Item -ItemType Directory -Force $outDir | Out-Null
ffmpeg -y -loglevel error -framerate 30 -i (Join-Path $work 'frames\f%05d.png') -i $audio `
  -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -b:a 128k -shortest (Join-Path $outDir 'intro_video.mp4')
Write-Host "wrote $outDir\intro_video.mp4"
```
Also add `tools/intro_video/work/` and `tools/intro_video/node_modules/` to `.gitignore`.

- [ ] **Step 6: Build and review**

Run: `powershell -File tools/intro_video/build.ps1`
Expected: `wrote …\out\intro_video.mp4`.

Check: `ffprobe -v error -show_entries format=duration -of csv=p=0 out/intro_video.mp4` gives 90–150 s.

Extract stills at each scene's midpoint (`ffmpeg -ss <t> -i out/intro_video.mp4 -frames:v 1 work/check_NN.png`) and look at them:
- the hand is on the right target;
- the keys named in the narration are the ones highlighted;
- box 2 is visibly tapped *before* backspace is pressed.

Then watch the whole video once and confirm the audio-to-animation sync is within about 0.3 s.

- [ ] **Step 7: Commit**

```bash
git add tools/intro_video .gitignore
git commit -m "feat(video): voiced intro video for the diagnostic (help, Enter, backspace)"
```

---

## Self-review notes

- Spec §1 → Task 1. §2 content → Tasks 2 and 3. §2 UI → Task 5. §3 → Task 6. §4 → Task 4. §5 → Task 7. Build order is kept: Task 1 is shippable alone.
- Deviation, recorded in Global Constraints: per-item audio names plus a manifest instead of hash names.
- `_helpLevel` is defined in Task 1 and used in Tasks 5 and 6. `hilfen` / `sprechtext` are defined in Task 2 and used in Tasks 3, 4 and 5. `DiagnosticAudio` is defined in Task 2 and used in Task 5.
