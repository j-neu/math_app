# Design — Unambiguous code lengths (Diagnose-Code vs Klassencode)

**Date:** 2026-09-02
**Owner:** Jakob
**Status:** DRAFT — awaiting review
**Supersedes:** the "4-char class code" wording of the learning-path login decision in `docs/superpowers/specs/2026-08-30-numeris-learning-path-design.md` (locked decision #3). Everything else in that spec is unaffected.

---

## 1. Context

Numeris now has several user-facing codes that a child (and a teacher) must tell apart:

| Code | Length today | Purpose | Entered at |
|---|---|---|---|
| Persönlicher Diagnose-Code (`session_tickets.short_code`) | 4 chars, letters+digits | starts/resumes/retries **one** child's diagnostic session | `/s/<schule>` |
| Klassencode (`classes.class_code`) | 4 chars, letters+digits | unlocks the class roster for the Üben/Lernpfad login | `/lernen/<schule>` |
| Bildfolge PIN (`student_pins`) | 4 picture taps | optional second factor (not text — different alphabet, not confusable) | `/lernen/<schule>` step 2 |

The two *text* codes are both 4 uppercase alphanumerics, typed into near-identical single-field screens. Nothing a child can perceive distinguishes them — the alphabets differ only by `L`, which is invisible. Kids on one screen are told "Dein Lehrer hat dir einen Code gegeben", on the other "Gib den Code von der Tafel ein". Jakob reports genuine confusion in the classroom about which code goes where.

The fix is to make the **length** a discriminator: personal diagnostic codes stay 4 (printed on a card in hand), the shared board/class code becomes 5. A 4-char code can then never be a class code.

### Constraints

- **Both flows are live.** The diagnostic flow and the learning-path login ship. The change must not break old diagnostic tickets already printed for the pilot.
- **German throughout.** Every new or changed user-facing string is German.
- **Kids do the typing.** Alphabets must stay confusable-free (`0/O/1/I`, and now also `L` on the diagnostic side).

---

## 2. Locked decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | Persönlicher Diagnose-Code stays **4 chars**; Klassencode becomes **5 chars** | Length is the only property a child reliably perceives; matches Jakob's proposal |
| 2 | Both use the **same confusable-free alphabet** `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (no `0/O/1/I/L`) | The diagnostic generator currently emits `L` despite its comment saying it does not; a 4-char code and a 5-char code from identical alphabets make length the sole discriminator |
| 3 | Existing class codes are **auto-rotated** to 5 chars by the migration | After deploy no 4-char code on a board can be a class code; teacher just refreshes the page |
| 4 | Kid entry screens show a **length label + cross-hint** when a wrong-length code is typed | Turns the failure mode from a dead "code not found" into guidance toward the correct flow |
| 5 | Existing personal diagnostic tickets keep working unchanged | They are resolved by stored value, never by length; no data change needed |

---

## 3. Target formats

| | Persönlicher Diagnose-Code | Klassencode |
|---|---|---|
| Purpose | one child's diagnostic session (incl. retry/resume) | whole-class roster for Üben/Lernpfad |
| Length | **4** | **5** |
| Alphabet | letters+digits, no `0/O/1/I/L` | same |
| Who holds it | printed on the child's card / QR sheet | shown on the board / projected |
| Entered at | `/s/<schule>` | `/lernen/<schule>` |
| Screen colour cue | blue | green |
| Kid label | "Dein persönlicher Code — 4 Zeichen" | "Klassencode von der Tafel — 5 Zeichen" |

---

## 4. Changes

### 4.1 Backend / Supabase

**`rotate_class_code`** (PL/pgSQL in `20260830000000_learning_path.sql`, written to disk by FloPy-free migrations): draw **5** characters (change the inner loop `for j in 1..4` to `1..5`).

**`_shared/codes.ts`**: `isValidCodeShape` length check 4 → 5, update the doc comment. (`CODE_ALPHABET` is already correct and shared by both code types.)

**New migration `20260902000000_class_codes_5_chars.sql`:**
1. Replaces `rotate_class_code` with the 5-char version.
2. Auto-rotates every existing class that has a `class_code` to a fresh unique 5-char code (same retry loop the function uses; classes with NULL code stay NULL — the dashboard shows "Noch kein Code" until the teacher presses "Neuer Code").
3. Adds a guard: `CHECK (class_code IS NULL OR length(class_code) = 5)` so a 4-char class code can never be written again.

Personal diagnostic tickets: **no schema change**. Old 4-char ticket codes already printed for the pilot remain valid because `diagnostic-sessions` resolves `short_code` by stored value.

### 4.2 Kid screens (Flutter, `math_app/`)

**`school_code_entry_screen.dart`** (diagnostic, expects 4):
- Replace the hard `LengthLimitingTextInputFormatter(4)` with a looser limit (~6) so a 5-char Klassencode is not silently truncated to its first 4 characters.
- Validate on submit against length 4. On length 5 show a distinct error instead of the generic length error:
  > "Das ist ein Klassencode mit 5 Zeichen — er gehört zum Üben, nicht zur Diagnose."
  Any other wrong length keeps a generic "Bitte gib genau 4 Zeichen ein."
- Add a small colour-coded caption identifying the flow ("Diagnose", blue) consistent with the dashboard panels.

**`child_login_screen.dart`** step 1 (Klassencode, expects 5):
- Field accepts up to ~7 characters; validate on submit against length 5. On length 4 show:
  > "Das ist ein persönlicher Diagnose-Code mit 4 Zeichen. Der Klassencode von der Tafel hat 5 Zeichen."
  Any other wrong length keeps a generic "Bitte gib genau 5 Zeichen ein."
- Add the matching green "Üben / Lernpfad" caption.

Widget tests: login fixtures move from 4-char to 5-char class codes; new wrong-length-hint tests for both screens assert the exact German copy.

### 4.3 Teacher dashboard (`dashboard/`)

**`StudentRow.tsx`** QR modal (personal diagnostic code):
- Label the short code as "persönlicher Diagnose-Code (4 Zeichen)".
- Fix the bug where the modal prints the literal placeholder `/s/<schulname>` — substitute the real slug as the printed bulk PDF already does.

**`bulk-qr-pdf/route.ts`**: the shared code generator drops `L` from its alphabet (it carries the same wrong "no L" comment). Newly printed codes are 4 chars from the confusable-free alphabet.

**`ClassCodePanel.tsx`** (green panel): label the displayed code as 5 characters; copy reads that kids enter the 5-stelligen Klassencode.

**Class page blue Kurzlink banner** (`dashboard/app/dashboard/klassen/[id]/page.tsx`): wording states each child's **4-stelligen persönlichen Diagnose-Code** (from their card) belongs to the diagnostic URL, while the green panel holds the **5-stelligen Klassencode** for Üben — so a teacher glancing at the page sees the two systems and their lengths side by side.

### 4.4 Code constants (optional, keep small)

If convenient, a single Dart const (`kPersonalCodeLength = 4`, `kClassCodeLength = 5`) and matching TS constants keep the two screens honest with each other. Only where it does not add indirection.

---

## 5. Rollout and verification

- Migration must run against the live project (`supabase db push`). After it runs, teachers reload the class page and the green panel shows a fresh 5-char code; the "Neuer Code" button keeps producing 5-char codes.
- Old personal diagnostic codes printed for the pilot still start a session.
- Tests:
  - `flutter test` (updated + new wrong-length-hint tests) green.
  - `flutter analyze` no new issues (baseline 323 pre-existing style lints untouched).
  - `npx tsc --noEmit` in `dashboard/` clean.
- Manual smoke: kid types a 5-char code on the diagnostic screen → sees the Üben cross-hint, not a truncation or "not found". Kid types a 4-char code on the Klassencode step → sees the diagnostic cross-hint.

## 6. Out of scope

- Bildfolge PIN (picture alphabet, no format change).
- QR/UUID tickets and the `/s/:uuid` route.
- School slug and teacher email/password login.
- Any change to the diagnostic item bank or clean-room content.

---

## 7. Reference locations (verified 2026-09-02)

- Personal diagnostic code generators: `dashboard/components/StudentRow.tsx` (`generateShortCode`, QR modal ~:266-324, literal `/s/<schulname>` at :303), `dashboard/app/api/bulk-qr-pdf/route.ts:19-31`.
- Personal code entry: `math_app/lib/screens/school_code_entry_screen.dart` (length limit :117, submit check :33-35).
- Class code generation: `backend/supabase/migrations/20260830000000_learning_path.sql:111-152` (`rotate_class_code`), backfill :158-167.
- Class code validation: `backend/supabase/functions/_shared/codes.ts` (`isValidCodeShape`, length 4 at :13).
- Class code entry: `math_app/lib/screens/child_login_screen.dart` (step 1 ~:255-297).
- Dashboard panels: `dashboard/components/ClassCodePanel.tsx`, blue banner in `dashboard/app/dashboard/klassen/[id]/page.tsx:159-176`.
- Server 404 copy for roster codes: `backend/supabase/functions/student-auth/index.ts:190-244`.
