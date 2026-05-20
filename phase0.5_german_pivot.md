# Phase 0.5: Full German Language Pivot

**Status:** ~99% complete. Last updated: 2026-05-16 (session 3).
**Created:** 2026-05-16
**Owner:** Jakob (solo)
**Horizon:** 1–2 focused days. Mechanical work, no architecture changes.

---

## Progress tracker

### Done ✅
- Locale infra (`main.dart` — `initializeDateFormatting`, `MaterialApp` locale + delegates)
- `main.dart` HomeScreen strings (greeting, buttons, messages)
- `user_selection_screen.dart` (all strings, create-user dialog, pluralization)
- `settings_screen.dart` (all strings + deleted language picker)
- `rewards_settings_screen.dart` (full rewrite to German)
- `exercise_screen.dart` (AppBar, error fallbacks, BottomNavBar labels)
- `learning_path_screen.dart` (AppBar, status labels, progress strings, reward modals)
- `lib/widgets/common/level_selection_drawer.dart`
- `lib/widgets/common/numeric_input_widget.dart`
- `lib/widgets/common/number_grid_widget.dart`
- `lib/widgets/common/scrolling_number_band.dart`
- `lib/widgets/common/minimalist_exercise_scaffold.dart`
- ~90 widget files under `lib/widgets/` (4 parallel Haiku agents)
- `countforward_level2/3_widget.dart` — feedback strings fixed manually (agent had missed them)
- `countforward100_level2/3_widget.dart` — feedback strings fixed manually
- `lib/exercises/count_steps_100field_exercise.dart` (title, LevelConfigs, instructions, dialogs)
- `lib/exercises/count_steps_backwards_100field_exercise.dart` (title, LevelConfigs, instructions, dialogs)
- Platform names: `AndroidManifest.xml`, `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, `macos/Runner/Configs/AppInfo.xcconfig`, `web/manifest.json`, `web/index.html`, `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `linux/runner/my_application.cc`
- `lib/exercises/count_100field_exercise.dart` — LevelConfig titles/descriptions, `_getInstructions()` texts, completion dialog
- `lib/exercises/count_dots_exercise_v2.dart` — title, hints, unlock messages, lock messages, level titles, instructions
- `lib/exercises/count_forward_exercise.dart` — title, hints, unlock snackbar, lock messages, instructions, finale snackbar
- `lib/exercises/count_forward_50_exercise.dart` — title, hints, instructions, finale snackbar
- `lib/exercises/count_forward_100_exercise.dart` — title, hints, unlock snackbar, lock messages, instructions, finale snackbar
- `lib/exercises/count_objects_exercise.dart` — title, hints, unlock messages, lock messages, level titles, instructions
- `lib/exercises/finger_blitz_exercise.dart` — `_LevelConfig` titles + descriptions (4 entries)
- `lib/models/exercise_config.dart` — default `successMessages` + `guidanceMessages` + factory `decompose10` feedback strings
- `lib/models/reward_config.dart` — fallback string
- `lib/services/reward_service.dart` — fallback string `"Great job!"` → `"Toll gemacht!"`
- `lib/exercises/decompose_10_exercise.dart` — completion dialog + fallback text
- `lib/exercises/tens_calculation_exercise.dart` — retry message, lock message, fallback
- `lib/exercises/doubling_fingers_exercise.dart` — fallback text
- `lib/exercises/doubling_fingers_20_exercise.dart` — fallback text
- `lib/exercises/doubling_mirror_exercise.dart` — fallback text
- `lib/exercises/doubling_tens_exercise.dart` — fallback text
- `lib/exercises/find_neighbors_exercise.dart` — fallback text
- `lib/widgets/findneighbors_level{1-4}_widget.dart` — `'Excellent!'` → `'Super!'`
- Grep sweep complete — no user-facing English strings remain in `lib/`
- `flutter analyze` clean (0 errors; pre-existing warnings/infos only)

### Still to do ❌
- Visual regression: click through every reachable screen to confirm no English survives (manual)

---

## Context

The diagnostic-flow and Förderplan screens are already German (shipped in `phase0_tasks.md`). Everything else — the **start screen, home screen, settings, rewards settings, exercise chrome, exercise feedback, tooltips, error messages, app title, and date formats** — is still English. Memory says "all user-facing text must be in German; no English strings anywhere in the UI."

This is impossible to ignore once a pilot teacher opens the app. A German Grundschule cannot use a tool that greets kids in English. The fix is mechanical — find every English string, replace with German — but the *volume* is significant: ~150–180 strings across ~40–50 files.

**Goal:** A user who installs and uses the app from cold launch never sees English. Includes app title, system dialogs, date formatting, and edge-case screens (empty states, error screens, locked-level toasts, exercise-completion modals).

**Decision (locked, consistent with `phase1_school_platform.md`):** Hard-code German strings inline. **No `intl`/ARB localization infrastructure**, even though `flutter_localizations` is in pubspec. The single exception is `intl`'s `DateFormat` with German locale data, which we need anyway for German date strings.

This matches the existing pattern in `diagnostic_screen.dart` and `diagnostic_report_screen.dart` — all strings are inline German, no `AppLocalizations.of(context)` indirection.

---

## Strategic decisions (locked)

| Decision | Choice | Reasoning |
|---|---|---|
| Translation approach | Hard-code German inline | Matches existing pattern, zero infra cost, fast. ARB-based l10n explicitly out of scope per phase1 plan. |
| Language picker | **Remove entirely** | Phase 0.5 commits to German-only. A picker with one option is clutter; a picker promising future English ("demnächst") creates a years-away commitment. |
| Date formatting | `DateFormat('d. MMMM yyyy', 'de_DE')` | Replace `DateFormat('MMM d, yyyy')` everywhere. Initialize German locale data once at app start. |
| App display name | `Numeris – Mathe-Diagnose` | Replace `Numeris Math App` in `main.dart:19` and platform-level config (`AndroidManifest.xml`, `Info.plist`, `web/manifest.json`). |
| Tone — kid-facing | Informal "du", warm, short | Matches existing diagnostic-screen tone (`'Deine Antwort'`, `'Weiter'`). |
| Tone — settings/rewards | Neutral imperative or second-person formal | Industry standard for German EdTech parent/teacher screens. Avoid "du" in settings; avoid heavy "Sie + Konjunktiv" formality. |
| Math vocabulary | Standard Grundschul-Deutsch | `Aufgabe`, `Diagnose`, `Förderplan`, `Übung`, `Stufe`/`Level`. "Level" is borrowed and standard in DE EdTech (Anton, Bettermarks both use it). |
| Emojis | Keep as-is | Translation work doesn't touch emoji placement in achievement strings. |
| `assets/zahlen_diktat.mp3` etc. | Out of scope | Audio is already German. |

---

## Scope by file

Drafted translations below. Treat as proposed copy; Jakob reviews. Format: `English original` → `Proposed German`.

### `lib/main.dart`

| Line | Context | English | German |
|---|---|---|---|
| 19 | `MaterialApp(title: …)` | `Numeris Math App` | `Numeris – Mathe-Diagnose` |
| 105 | Button — diagnostic in progress | `Continue Diagnostic Test` | `Diagnose fortsetzen` |
| 107 | Message | `You're X questions into the diagnostic test!` | `Du hast schon X Fragen geschafft!` |
| 110 | Button — completed | `View Learning Path` | `Zum Lernpfad` |
| 112-113 | Message — bypassed | `Ready to start practicing? X skills available!` | `Bereit zum Üben? Es warten X Bereiche auf dich!` |
| 114 | Message — returning | `Ready for your next challenge?` | `Bereit für die nächste Aufgabe?` |
| 117 | Button — resume | `Resume Diagnostic Test` | `Diagnose fortsetzen` |
| 119 | Message — resume | `Let's continue where you left off!` | `Lass uns da weitermachen, wo du aufgehört hast!` |
| 122 | Button — new user | `Start Diagnostic Test` | `Diagnose starten` |
| 124 | Message — new user | `Let's find out what you already know!` | `Lass uns herausfinden, was du schon kannst!` |
| 129 | AppBar | `Welcome, ${name}!` | `Hallo, ${name}!` |

### `lib/screens/user_selection_screen.dart`

| Line | Context | English | German |
|---|---|---|---|
| ~135 | AppBar | (verify — likely `Numeris` or app name) | `Numeris` (keep brand) |
| 151 | Main title | `Who is learning today?` | `Wer lernt heute?` |
| 173 | Empty state | `No users yet` | `Noch keine Profile` |
| 180 | Empty state hint | `Create your first user to get started!` | `Lege ein erstes Profil an, um loszulegen.` |
| 217 | Subtitle dynamic | `Diagnostic in progress (Question X)` | `Diagnose läuft (Frage X)` |
| 219 | Subtitle | `New user - Start diagnostic test` | `Neues Profil — Diagnose starten` |
| 220 | Subtitle dynamic | `X skills to practice` | `X Bereiche zum Üben` |
| 236 | Button | `Add New User` | `Neues Profil anlegen` |
| 254 | Button | `Start Without Diagnostic (Not Recommended)` | `Ohne Diagnose starten (nicht empfohlen)` |
| 51 | Dialog field | `labelText: 'Name'` | `Name` (same) |
| 52 | Dialog field | `hintText: 'Enter child\'s name'` | `Name des Kindes` |
| 61 | Dialog field | `labelText: 'Age'` | `Alter` |
| 62 | Dialog field | `hintText: 'Enter age'` | `Alter eingeben` |
| 72 | Dialog button | `Cancel` | `Abbrechen` |
| 81 | SnackBar | `Please enter a name` | `Bitte einen Namen eingeben` |
| 91 | Dialog button | `Create` | `Anlegen` |
| 283 | Skip dialog title | `Skip Diagnostic Test` | `Diagnose überspringen` |

### `lib/screens/settings_screen.dart`

**Major change:** delete `_showLanguageDialog` (lines 335–379) and the entire `Language & Display` section header + `Language` `ListTile` (lines 154–174). After deletion, the next section header becomes the top of the list.

| Line | Context | English | German |
|---|---|---|---|
| 147 | AppBar | `Settings` | `Einstellungen` |
| 180 | Section header | `Learning & Progress` | `Lernen & Fortschritt` |
| 189 | ListTile title | `Retake Diagnostic Test` | `Diagnose wiederholen` |
| 190 | ListTile subtitle | `This will reset your learning path.` | `Setzt den Lernpfad zurück.` |
| 197 | ListTile title | `Retake Incorrect Questions` | `Falsche Antworten wiederholen` |
| 198 | ListTile subtitle | `Practice only what you missed.` | `Nur die verpassten Fragen üben.` |
| 206 | Switch title | `Diagnostic Test Mode` | `Diagnose-Modus` |
| 209 | Switch subtitle | `Shortened Test (skips harder questions when easier ones fail)` | `Verkürzte Diagnose (schwere Fragen werden übersprungen, wenn leichtere nicht gelöst wurden)` |
| 210 | Switch subtitle | `Complete Test (all questions shown, no skips)` | `Vollständige Diagnose (alle Fragen, keine Auslassungen)` |
| 217 | Switch title | `Lock Exercises in Order` | `Übungen der Reihe nach freischalten` |
| 220 | Switch subtitle | `Exercises must be completed sequentially` | `Übungen werden nacheinander freigeschaltet` |
| 221 | Switch subtitle | `Child can freely choose which exercise to practice` | `Kind kann frei wählen, welche Übung es macht` |
| 228 | ListTile title | `Reward Settings` | `Belohnungen` |
| 229 | ListTile subtitle | `Configure rewards for practice milestones` | `Belohnungen für Übungs-Meilensteine festlegen` |
| 248 | Section header | `Reports` | `Berichte` |
| 257 | ListTile title | `View Evaluation Report` | `Förderplan ansehen` |
| 259 | Subtitle (empty) | `No diagnostic reports available` | `Noch keine Diagnose abgeschlossen` |
| 260 | Subtitle dynamic | `Latest: <date>` | `Zuletzt: <date>` — switch `DateFormat` to `'d. MMMM yyyy'` `de_DE` |
| 286 | Section header | `Data Management` | `Daten` |
| 299 | ListTile title | `Delete User Profile` | `Profil löschen` |
| 302 | ListTile subtitle | `Permanently delete this user and all data` | `Profil und alle Daten dauerhaft löschen` |
| 313 | Section header | `About` | `Über die App` |
| 322 | ListTile title | `App Version` | `App-Version` |
| 323 | ListTile subtitle | `1.0.0 (Development)` | `1.0.0 (Entwicklung)` |
| 327 | ListTile title | `Pedagogical Framework` | `Pädagogisches Konzept` |
| 328 | ListTile subtitle | `Based on iMINT & PIKAS research` | `Basiert auf iMINT- und PIKAS-Forschung` |
| 391 | SnackBar | `Great job! You answered all questions correctly in the last test.` | `Klasse! Du hast in der letzten Diagnose alle Fragen richtig beantwortet.` |
| 400 | Dialog title | `Retake Incorrect Questions?` | `Falsche Antworten wiederholen?` |
| 402-404 | Dialog body | `You will retake the X questions you missed in the last diagnostic test. This will create a new updated learning path based on your new answers. Are you sure you want to continue?` | `Du wiederholst die X Fragen, die du in der letzten Diagnose nicht richtig hattest. Daraus entsteht ein aktualisierter Lernpfad. Möchtest du fortfahren?` |
| 409 | Dialog button | `Cancel` | `Abbrechen` |
| 501 | Delete confirmation dialog | `Delete User Profile?` | `Profil löschen?` |

### `lib/screens/rewards_settings_screen.dart`

| Line | Context | English | German |
|---|---|---|---|
| 125 | AppBar | `Reward Settings` | `Belohnungen` |
| 150 | Section title | `Daily Exercise Reward` | `Belohnung für tägliches Üben` |
| 151 | Section subtitle | (verify in file) | `Belohnung, wenn dein Kind heute eine Übung abschließt` |
| 162 | Section title | `Completed Exercise Reward` | `Belohnung für abgeschlossene Übungen` |
| 163 | Section subtitle | (verify) | `Belohnung, wenn dein Kind eine Übung vollständig meistert` |
| 174 | Section title | `Milestone Reward` | `Meilenstein-Belohnung` |
| 200 | Tooltip | `Info` | `Info` (same) |
| 206 | Instructions | `Add rewards that motivate your child:` | `Belohnungen hinzufügen, die dein Kind motivieren:` |
| 221 | Field | `labelText: 'Add a reward...'` | `Belohnung hinzufügen…` |
| 222 | Field | `hintText: 'e.g., "20 minutes of screen time"'` | `z. B. „20 Minuten Bildschirmzeit"` |
| 240 | Button | `Add` | `Hinzufügen` |
| 259 | Empty state | `No rewards added yet` | `Noch keine Belohnungen` |
| 267 | Empty state hint | `Add rewards to motivate your child!` | `Füge Belohnungen hinzu, um dein Kind zu motivieren.` |
| 372 | Info dialog title | `About Rewards` | `Über Belohnungen` |

### `lib/screens/exercise_screen.dart` and `lib/screens/learning_path_screen.dart`

| Context | English | German |
|---|---|---|
| AppBar (exercise) | `Learning Path` | `Lernpfad` |
| Error state | `No Action Content` / `No Image Content` / `No Symbol Content` | `Inhalt fehlt` (single string; these are broken-content fallbacks) |
| Error state | `Unknown View` | `Unbekannte Ansicht` |
| Error state | `Level not implemented` | `Level noch nicht verfügbar` |
| Toast | `Showing all exercises` | `Alle Übungen werden angezeigt` |
| Toast | `Showing matched exercises only` | `Nur passende Übungen werden angezeigt` |

### Exercise widgets (~40 files, mostly under `lib/widgets/` and `lib/exercises/`)

These share a common set of button labels, dialog titles, hints, and feedback strings. The pattern is repeated; translate once per pattern.

| English | German |
|---|---|
| `Stop` | `Stopp` |
| `Next Level` | `Nächstes Level` |
| `Check` | `Prüfen` |
| `Cancel` | `Abbrechen` |
| `Stop for Today` | `Für heute beenden` |
| `Continue` | `Weiter` |
| `Level $n Complete! 🎉` | `Level $n geschafft! 🎉` |
| `Game Over!` | `Versuch zu Ende` |
| `Error` | `Fehler` |
| `Enter number...` | `Zahl eingeben…` |
| `Track with eyes...` | `Mit den Augen verfolgen…` |
| `Count in your head...` | `Im Kopf zählen…` |
| `Your answer...` | `Deine Antwort…` |
| `From memory...` | `Aus dem Gedächtnis…` |
| `Level locked! Complete previous levels first.` | `Level gesperrt. Schließe zuerst die vorherigen Level ab.` |
| `Complete Level ${n} first!` | `Schließe zuerst Level ${n} ab.` |
| `Complete previous levels first!` | `Schließe zuerst die vorherigen Level ab.` |
| `First, tap a number on the line!` | `Tippe zuerst eine Zahl auf dem Zahlenstrahl an.` |
| `Choose Level` / `Select Level` | `Level wählen` |
| `Instructions` | `Anleitung` |
| `Check Answers` | `Antworten prüfen` |
| `Peek` | `Kurz zeigen` |
| `Hint` / `Get a hint` | `Tipp` |
| `Hide number line` | `Zahlenstrahl ausblenden` |

### Feedback messages (achievement / failure)

| English | German |
|---|---|
| `🎉 Skill Completed! Great job!` | `🎉 Geschafft! Tolle Arbeit!` |
| `🎉 Level 2 Unlocked! Now practice with support!` | `🎉 Level 2 freigeschaltet! Jetzt mit Hilfe üben!` |
| `🎉 Level 3 Unlocked! Test your memory!` | `🎉 Level 3 freigeschaltet! Jetzt aus dem Gedächtnis!` |
| `🎉 Level 4 Unlocked! Extended sequence challenge!` | `🎉 Level 4 freigeschaltet! Längere Aufgaben warten!` |
| `🎉 Finale Unlocked! Easier review to complete!` | `🎉 Finale freigeschaltet! Eine letzte einfache Runde.` |
| `Great job! Ready for the next challenge?` | `Toll gemacht! Bereit für die nächste Aufgabe?` |
| `Not quite! Try doubling again.` | `Fast! Versuche das Verdoppeln nochmal.` |
| `Not equal! Someone has more.` | `Nicht gleich. Einer hat mehr.` |
| `Try again to get at least $n correct!` | `Versuche es nochmal — du brauchst mindestens $n richtige.` |

### Platform-level app name (outside `lib/`)

These appear in OS launchers and PWA manifests. Verify exact paths during execution:
- `android/app/src/main/AndroidManifest.xml` — `<application android:label="...">` → `Numeris`
- `ios/Runner/Info.plist` — `CFBundleDisplayName` → `Numeris`
- `macos/Runner/Info.plist` — same
- `web/manifest.json` — `name`, `short_name`, `description` → `Numeris – Mathe-Diagnose` / `Numeris` / `Diagnose und Förderplan für Grundschul-Mathematik`
- `web/index.html` — `<title>` and meta `description`
- `windows/runner/main.cpp` and `linux/runner/...` — window title strings if any

---

## Date / locale infrastructure (one small addition)

The only non-trivial change: German `DateFormat` needs the locale data initialized once at startup.

**Add to `lib/main.dart`:**

```dart
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  runApp(const MyApp());
}
```

**Add to `MaterialApp` in `main.dart:18`:**

```dart
MaterialApp(
  title: 'Numeris – Mathe-Diagnose',
  locale: const Locale('de', 'DE'),
  supportedLocales: const [Locale('de', 'DE')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  // …
)
```

This gives us German for system widgets (date pickers, "OK"/"Abbrechen" defaults on standard dialogs, accessibility strings) without going to ARB.

**Find all `DateFormat(...)` calls** and standardize:
- `DateFormat('MMM d, yyyy')` → `DateFormat('d. MMMM yyyy', 'de_DE')` (e.g. "15. Mai 2026")
- Short form: `DateFormat('dd.MM.yyyy', 'de_DE')` (e.g. "15.05.2026") for table cells
- Confirm `diagnostic_report_screen.dart` already uses German format — verify line 106 area.

---

## Execution order

Do the work in this order to keep the codebase compilable at every step:

1. **Locale infra** in `main.dart` (one commit). App still mostly-English, but date format and system dialogs are German.
2. **Delete language picker** in `settings_screen.dart` — remove dialog + ListTile + section header. One commit.
3. **`main.dart` HomeScreen strings** — translate the home greeting + buttons. One commit. Visible win.
4. **`user_selection_screen.dart`** — start screen. The first thing a teacher sees. One commit.
5. **`settings_screen.dart` content** — all the section headers, ListTiles, dialogs. One commit.
6. **`rewards_settings_screen.dart`** — one commit.
7. **`exercise_screen.dart` / `learning_path_screen.dart`** — one commit.
8. **Exercise widgets** — likely 2–4 commits split by skill set (counting widgets, decompose widgets, strategy widgets) to keep diff sizes manageable.
9. **Platform-level app names** (`AndroidManifest.xml`, `Info.plist`, `web/manifest.json`, `web/index.html`) — one commit.
10. **Final sweep:** `grep -rE "Text\('([A-Za-z]+ )+'\)"` and similar — catch what was missed.

Each step compiles and runs. At any rollback point, the app is still functional, just with mixed-language UI temporarily.

---

## Critical files (read/modify)

| File | Action |
|---|---|
| `math_app/lib/main.dart` | Modify — locale setup + HomeScreen + MaterialApp title |
| `math_app/lib/screens/user_selection_screen.dart` | Modify — start screen + create-user dialog + skip-diagnostic dialog |
| `math_app/lib/screens/settings_screen.dart` | Modify — translate all + **delete** `_showLanguageDialog` and language ListTile |
| `math_app/lib/screens/rewards_settings_screen.dart` | Modify — all strings |
| `math_app/lib/screens/exercise_screen.dart` | Modify — AppBar + error states |
| `math_app/lib/screens/learning_path_screen.dart` | Modify — AppBar + toasts |
| `math_app/lib/widgets/answer_widgets.dart` | Verify — already partly German |
| `math_app/lib/widgets/**/*.dart` | Modify — exercise chrome strings |
| `math_app/lib/exercises/**/*.dart` | Modify — exercise chrome strings |
| `math_app/android/app/src/main/AndroidManifest.xml` | Modify — app label |
| `math_app/ios/Runner/Info.plist` | Modify — `CFBundleDisplayName` |
| `math_app/macos/Runner/Info.plist` | Modify — `CFBundleDisplayName` |
| `math_app/web/manifest.json` | Modify — name/short_name/description |
| `math_app/web/index.html` | Modify — `<title>` and meta tags |
| `math_app/pubspec.yaml` | No change needed — `flutter_localizations` and `intl` already present |

---

## Verification

1. **Cold launch:** `flutter run -d windows` (or chrome). First screen is `UserSelectionScreen`. Title reads `Wer lernt heute?`, button reads `Neues Profil anlegen`. No English anywhere on screen.
2. **Create profile:** Dialog labels `Name`, `Alter`, hints in German, buttons `Abbrechen` / `Anlegen`.
3. **Empty-state SnackBar:** Submit without name → SnackBar says `Bitte einen Namen eingeben`.
4. **HomeScreen:** New user reads `Lass uns herausfinden, was du schon kannst!` with button `Diagnose starten`. AppBar: `Hallo, [Name]!`.
5. **Settings:** Open from HomeScreen — AppBar `Einstellungen`. No `Language & Display` section. First section is `Lernen & Fortschritt`. Every ListTile in German. Dialogs (`Diagnose wiederholen?`, `Falsche Antworten wiederholen?`, `Profil löschen?`) all German.
6. **Rewards:** Navigate Settings → `Belohnungen`. All sections German. Field hint `z. B. „20 Minuten Bildschirmzeit"`.
7. **Date display:** Settings → `Förderplan ansehen` row should show `Zuletzt: 15. Mai 2026` format (assuming at least one diagnostic completed).
8. **Exercise chrome:** Open any exercise. Buttons `Stopp`, `Prüfen`, `Weiter`, tooltips `Anleitung`, `Tipp`. Completion modal `Level 1 geschafft! 🎉`.
9. **System dialogs:** Trigger any platform date picker or `showDatePicker` if present — verify weekday names are German ("Montag", "Dienstag").
10. **App switcher / launcher:** Switch apps on Windows/Android — Numeris appears as `Numeris` (not `math_app` or `Numeris Math App`).
11. **Web build (smoke):** `flutter build web && python -m http.server -d build/web 8080` — open in browser, browser tab title is `Numeris – Mathe-Diagnose`.
12. **Grep sweep:**
    - `grep -rE "Text\(['\"][A-Z][a-z]+ [A-Za-z]+" math_app/lib/` — looks for English-looking `Text("Word Word")` patterns.
    - `grep -rE "(hintText|labelText|tooltip): ['\"][A-Za-z ]+['\"]" math_app/lib/` — input decorations.
    - Manually review hits. Acceptable hits: math vocabulary that's the same in English/German (`Level`, `Info`), proper nouns (`iMINT`, `PIKAS`, `Numeris`). Anything else is a miss.
13. **`flutter analyze`** clean.
14. **Visual regression:** Click through every reachable screen with a fresh profile + with a profile mid-diagnostic + with a profile post-diagnostic. No English string survives.

---

## Risks

- **(High confidence) Volume → missed strings.** 150+ strings across 40+ files mean some will slip through. The grep sweep in step 12 is mandatory, not optional. A single English word on a real classroom screen will be the thing a pilot teacher screenshots and emails.
- **(Moderate confidence) Hidden English in dynamic strings.** String concatenation, `'foo $bar baz'` interpolation, and switch-case-built sentences are easier to miss. Pay extra attention to `lib/main.dart:99–125` (`message` and `buttonText` ladders) and similar conditional UI text.
- **(Moderate confidence) German pluralization gotchas.** `"$n Bereiche"` works for n>1 but is wrong for n=1. Sentences like `'X skills to practice'` → `'X Bereiche zum Üben'` is fine for plural, awkward for n=1. Where it matters, use Dart conditional: `n == 1 ? '1 Bereich' : '$n Bereiche'`. Don't introduce ICU plural rules — overkill.
- **(Low confidence, high cost) Platform-level app-name change can break things.** `AndroidManifest.xml` label changes are safe; `Info.plist` `CFBundleDisplayName` change requires a clean Xcode build. Test on each platform you actually deploy to.
- **(Moderate confidence) Some `Text(...)` instances are inside third-party widget builders** (e.g., `pdf` package rendering). Out of scope here — the PDF service should already be German per `phase0_tasks.md`.

---

## Out of scope

- ARB / `.arb` file infrastructure. No `AppLocalizations`. Phase 1 explicitly defers this.
- English-language re-introduction. (Future, if at all, only when serving non-DE markets — speculative.)
- Renaming the Dart package `math_app` → `numeris_app`. Out of scope; affects imports everywhere.
- Math content translation. CSV diagnostic prompts and `skills_taxonomy.csv` are already German.
- Audio file re-recording. Existing audio is German.
- Translating `print()` / `debugPrint()` log lines. Dev-facing only.

---

## Dependencies on current work

This plan **assumes complete**:
- `phase0_tasks.md` — diagnostic + Förderplan screens are German. (Done.)

This plan **must complete before**:
- Any `phase1_school_platform.md` work, since the Flutter Web build of the student client is the same code; English strings would leak directly to a pilot teacher's QR-code session.
- Any pilot exposure, period.
