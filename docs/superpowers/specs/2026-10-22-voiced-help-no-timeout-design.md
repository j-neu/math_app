# Voiced diagnostic with staged help, no child-facing timeout

**Date:** 2026-10-22
**Status:** Design approved by Jakob, 2026-10-22. Next step: implementation plan.
**Trigger:** First diagnostic runs with real children. The 30 s timeout and the
"Noch mehr Zeit?" dialog annoyed them. The children also aren't very confident with
digital devices: they need help they can ask for in steps, and they need every question
and every hint read aloud.

## Decisions (Jakob, 2026-10-22)

| Question | Decision |
|---|---|
| Child-facing timeout | Removed completely: no timer, no dialog, no skip-on-timeout. |
| Response time | Still recorded per item, as a stopwatch that starts when the question audio has finished playing. |
| Slow answers | **No auto-fail.** Correct is correct. Time is shown to the teacher. The existing class-level `slow_response_flag` in the Förderplan stays. Per-item time rules come later, from pilot data. |
| Help | Three stages per question, each unlocked by tapping "Hilfe" again. |
| Hint scoring | Highest hint level used is stored per item and shown to the teacher. **Correct after hint 3 counts as not mastered** (`was_correct = false`). Hints 1–2 do not change correctness. |
| Audio autoplay | The question is read aloud automatically when it appears. A big 🔊 button replays it. |
| Hint texts | Claude drafts all texts and generates audio directly. Jakob reviews by listening in the app. |
| Intro video | MP4 file shown to the class on a projector. |

## 1. Timeout removal (child app)

`math_app/lib/screens/diagnostic_screen.dart`:

- Delete `_timeoutSecondsFor`, `_handleTimeout`, `_grantMoreTime`, `_skipCurrentQuestion`
  and the `PausableTimeout` budget. Replace them with a plain stopwatch.
- The stopwatch starts when the question audio completes (or immediately if playback
  fails), and stops on submit.
- `wasCorrect = textCorrect && helpLevel < 3`. The `tookTooLong` branch is removed.
- The `'timeout'` status is no longer produced by the client. It stays valid in the DB
  check constraint so old rows remain readable.

## 2. Three-stage help

### Content: new columns in `math_app/Research/diagnostic_v4_master.csv`

| Column | Purpose | Example (skip-5 item) |
|---|---|---|
| `Sprechtext` | What the voice says for the question. Numbers and blanks become speakable ("…siebzig, und dann?"). Picture items start with "Schau dir das Bild an." | "Zähle in Fünferschritten weiter. Sechzig, fünfundsechzig, siebzig. Welche vier Zahlen kommen dann?" |
| `Hilfe1` | The same question, said differently. | "Die Zahlen werden immer um fünf größer. Wie geht es weiter?" |
| `Hilfe2` | The question broken down a bit. | "Nach siebzig kommt die nächste Zahl. Zähle dafür fünf weiter. Dann machst du das noch dreimal." |
| `Hilfe3` | A direct instruction: what exactly to do. | "Rechne zu jeder Zahl plus fünf. So bekommst du die nächste Zahl." |

Rules for the hint texts:
- German, short sentences, words a 6–8-year-old knows.
- Hint 3 says *what to do*, but it never gives the answer itself.
- The `Hilfetext` column and its single-dialog UI are retired.

### UI

- Big 🔊 button next to the question: replays the question audio.
- Big "Hilfe" button. Each tap reveals the next hint as a card under the question and
  plays its audio. Each card has its own 🔊 replay button. After hint 3 the Hilfe
  button disappears.
- Only one audio plays at a time: starting a new clip stops the current one.

## 3. Recording hint use (backend + dashboard)

- New migration: `diagnostic_results.help_level smallint not null default 0`, with a
  check that the value is between 0 and 3.
- `diagnostic-results` edge function accepts `help_level`. `diagnostic-sessions`
  returns it, so a resumed session knows which hints were already used.
- Dashboard Förderplan Detail-Tabelle: the status cell shows the hint level, e.g.
  "richtig · Hilfe 2" or "falsch · nach Hilfe 3".
- `foerderplan-generate` stays unchanged. The hint-3 rule is already in `was_correct`.
- The migration and edge-function deploys touch production, so they get Jakob's
  explicit go before running.

## 4. Audio generation

- Voice: Jakob's Qwen3-TTS zero-shot clone, German reference (`reference_de.wav`), in
  `C:\Users\jakob\Documents\Cursor projects\Voice`.
- Texts are deduplicated: identical text means one file. Each file is named
  `<sha1(text)[:12]>.mp3`, so editing a text regenerates only that clip.
- Output goes to `math_app/assets/audio/diagnostic/`, registered as a Flutter asset
  directory, about 430 clips and about 15–20 MB. Clips are fetched on demand per question.
- A script at `scripts/generate_diagnostic_audio.py` collects the texts and generates
  only the missing clips. It submits them as **one** batch job through the Voice tool's
  own `build_job` / engine runner, using the same engine and reference as `voice speak`.
  This avoids reloading the 1.7B model about 430 times.
- Post-processing: the same denoise/loudnorm ffmpeg chain used for
  `zahlen_diktat_17_47_70_72_84.mp3`.
- Quality check: transcribe a sample of clips with Whisper and compare them to the
  source text. Regenerate garbled ones.
- The existing Zahlendiktat item (Q55) keeps its dedicated listening audio. Its
  `Sprechtext` audio is the instruction only.

## 5. Intro video (MP4)

**Audience:** first and second graders who aren't confident with computers, shown on a
projector before their first diagnostic. Tone: "explain it like I'm 5". Slow, one idea
at a time, every action shown with an animated finger or cursor *and* said aloud, short
pauses after each step.

**Example question:** counting in steps of five with numbers that are **not** in the item
bank, e.g. "Zähle in Fünferschritten weiter: 5, 10, 15, __, __". It has two answer boxes,
so moving between boxes can be shown. The real skip-5 items (Q24/Q25) use other numbers.

**Content, in order:**
1. "Gleich siehst du Aufgaben. Ich lese sie dir vor." The question appears and is read.
2. **Hear it again:** the finger taps 🔊 and the question plays again. "Wenn du die
   Aufgabe nochmal hören willst, drück auf den Lautsprecher."
3. **Help, three times:** the finger taps Hilfe, the hint 1 card appears and is read.
   Tap again for hint 2, then hint 3. "Wenn du nicht weiterweißt, drück auf Hilfe. Du
   kannst bis zu dreimal drücken."
4. **Typing numbers:** the keyboard is shown with the number row *and* the Zahlenblock
   (number pad on the right) highlighted. "Die Zahlen findest du hier oben oder hier
   rechts." The first box is already blinking: "Hier blinkt es. Hier kommt deine Zahl
   rein." Type the 2 on the number row and the 0 on the Zahlenblock: "Beides geht."
5. **Enter moves to the next box:** the Enter key is highlighted and pressed, and the
   cursor jumps to box 2. "Mit der Enter-Taste kommst du zum nächsten Kästchen." Type 25.
6. **Fixing a mistake with backspace:** a wrong digit is typed. **First** the finger
   taps into the box ("Zuerst tippst du in das Kästchen, das du ändern willst"),
   **then** the backspace key is highlighted and pressed and the digit disappears.
   "Mit dieser Taste mit dem Pfeil löschst du die Zahl." The correct digit is typed.
7. **Done:** Enter on the last box, or the Weiter button, goes to the next question.
   "Wenn du fertig bist, drück Enter oder Weiter."
8. Closing: "Du schaffst das! Es ist nicht schlimm, wenn du etwas nicht weißt."

**Build:** an animated HTML mock of the real question screen (same colors and layout as
the app). Playwright records it frame by frame, and ffmpeg muxes the frames with the
narration. The narration is a UTF-8 script rendered with
`uv run --no-sync voice speak script.txt --lang de --engine qwen3 -o out\video.mp3` from
the Voice project folder. The animation timing is derived from that audio's segment
lengths. The hint audio inside the video reuses the generated clips. Output:
`out/intro_video.mp4` in the Math_App folder, about 90–120 s.

**Teacher note (not in the video):** the Zahlenblock only types digits when Num Lock is on.
Check this on each device before the session.

## Build order

1. Timeout removal plus the stopwatch. This can ship on its own.
2. CSV texts plus audio generation.
3. Help UI, plus `help_level` in the migration, the edge functions and the dashboard.
4. Intro video.

## Verification

- `flutter test`, `flutter analyze`. Dashboard `npx tsc --noEmit`. Backend `deno check`.
- A content check: every CSV row has `Sprechtext`, `Hilfe1`–`Hilfe3`, and every text
  resolves to an existing audio file.
- Manual run in the browser: autoplay, replay, all three hints, Enter and backspace flow,
  no dialog after a long wait, and `help_level` visible in the dashboard.
