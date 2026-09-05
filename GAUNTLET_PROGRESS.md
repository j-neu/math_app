# Gauntlet Progress & Evidence

**Status:** LIVE — run by the Gauntlet build of the Numeris remedial-maths platform.
**Rule:** Evidence beats claims. Every entry below names a command that was run, an artifact inspected, or a journey executed. Nothing is recorded on a builder's say-so.

---

## Product under construction

Numeris — diagnostic + Förderplan + (new) adaptive learning path and practice runtime for German Grundschule maths, Grades 1–6. Stack: Supabase EU (live: `zzxqeqwffexythqzjkxr`, Frankfurt) · Next.js teacher dashboard (`dashboard/`) · Flutter Web child client (`math_app/`). Clean-room content per `tasks.md`/`rewrite.md`; design spec `docs/superpowers/specs/2026-08-30-numeris-learning-path-design.md`.

## Workstreams

| WS | Scope | Builder | Critic | Status |
|---|---|---|---|---|
| P1 | Path engine + child identity (backend + Flutter scaffolding) | SDD (pre-gauntlet) | adversarial SDD reviews | DONE + deployed 2026-08-31 |
| P2 | Practice runtime (spec interpreter, 16 templates, manipulative widgets, feedback, session flow) | TBD | TBD | PLANNED |
| P3 | 36 skill specs (JSON + provenance, E-I-S × 3 levels, ~8 problems) | TBD | TBD | PLANNED |
| P4 | Teacher console (path review/activate, progress views, re-test) | TBD | TBD | PLANNED |
| P5/P6 | Art direction/engagement, publish hardening | TBD | TBD | PLANNED |
| IG | Integration gauntlet (real users, full journey) | controller | fresh-context | PENDING |

---

## Evidence log

### 2026-08-31 — P1 brought live and verified

**Context found:** The P1 SDD ledger (`backend/../.superpowers/sdd/2026-08-30-p1-path-engine/progress.md`) claimed "NOTHING DEPLOYED; Task 16 blocked on Jakob". On inspection the claim was stale: `supabase functions list` shows student-auth (v4), learning-path (v2), practice-session (v2), foerderplan-generate (v3) ACTIVE on `zzxqeqwffexythqzjkxr`; `supabase migration list` showed the three 20260830 learning-path migrations already remote-applied. Only two 20260831 migrations were pending and the three custom secrets were unset.

**Actions taken (all applied to the live project):**
- `supabase db push` → applied `20260831000000_rate_limit_secondary_keys.sql`, `20260831000001_single_active_learning_path.sql`.
- `supabase secrets set IP_HASH_SALT=… PIN_HASH_SALT=…` (generated 32-hex salts).
- Jakob set `STUDENT_JWT_SECRET` from the Dashboard (JWT Settings); verified present in `supabase secrets list`.
- Redeployed `student-auth`, `learning-path`, `practice-session`, `foerderplan-generate` from committed code (the deployed binaries predated the 2026-08-31 security fixes).

**Bug found + fixed (class-code backfill):** Migration `20260830000000` back-filled `classes.class_code` from UUID hex (`upper(substr(replace(gen_random_uuid()::text,'-',''),1,4))`), which can emit `0/O/1/I/L` — characters deliberately excluded from the confusables-free alphabet. Pilot class 2b got `703F`; `student-auth/roster` correctly rejected it (`isValidCodeShape`), silently locking the class out of child login. Fixed with new migration `20260831000002_repair_class_codes.sql` (re-rotates null/malformed/duplicate codes with the proper alphabet + uniqueness loop). Applied live; class 2b now `22WW`.

**Live verification commands + output (curl against live functions/REST):**
- `student-auth/roster` bogus school → `{"error":"Diesen Code gibt es nicht. Schau noch mal auf die Tafel."}` (404, no enumeration).
- `student-auth/roster` pilotschule/`22WW` → `{"class_id":"89ec7390-…","require_pin":false,"students":[{"id":"2f300ef7-…","display_name":"SCH01","avatar":null}]}`.
- `student-auth/login` `2f300ef7-…` → JWT with `{"role":"authenticated","aud":"authenticated","sub":"…","student_id":"…","exp":…}` (HS256, gateway-valid).
- REST with the student JWT: `students` → `[]` (no cross-student read), `learning_paths` → `[]`, `skill_progress` → `[]` (empty but scoped); `POST path_items` → **403** (child cannot write).

**Follow-ups flagged:**
- Live DB still holds the 60-item cleanroom bank + the legacy 92-item bank; blueprint (Jakob's R2.9 edits, uncommitted) says 59 core (A1.5-01 removed). Runtime CSV + live `cleanroom-v1` row still 60. **Open decision** — gauntlet treats the live 60-item bank as the diagnostic under test until Jakob's review completes; delta tracked.
- The P1 deployment-order note in the ledger ("NOTHING DEPLOYED") is now historical; keep docs honest.

### 2026-08-31 — P2 runtime + P3 specs (branch `gauntlet/p2-p3-p4`)

Committed evidence (all on `gauntlet/p2-p3-p4`):
- `bc3133f` — P2-A: extracted all 6 manipulative visual families out of `diagnostic_screen.dart` into `lib/widgets/manipulatives/`; `visual_display_test.dart` unchanged green; suite 109/109.
- `5bdd891` — P3: 36 skill specs authored (`docs/clean-room/skills/specs/*.json`) with provenance rows in `_provenance_specs_new.csv` (main `provenance.csv` left untouched — Jakob's R2.9 edits). Authoring agents for large batches returned empty twice; split to 2–4-skill batches → all landed.
- `271d70d` — P2-B: `SkillSpec` model + strict parser, `SkillSpecStore`, `Problem`/`AnswerRecord`, `answer_normalization`, `SeededGenerator` harness, `scripts/check_specs.py` (all 36 pass), `scripts/sync_skill_specs.py`, bundled assets. 165 tests.
- `6cd1977` — P3 independent critic (fresh context) reviewed the actual JSONs: 18 findings (2 Critical, 9 Important, 7 Minor), all fixed. Biggest gap caught: drag_partition needed split constraints (C2.1 make_ten / C3.3 near_double / C3.4a+b tens_ones) so a wrong split is rejected — added to P2 §5 + specs + validator. 3 rulings recorded in `.superpowers/gauntlet/p3-fixes-report.md`.
- `7160fbf` `c4f1793` `a7bb56f` `6d8b883` `e83fcb5` — P2-C: all 16 template generators + custom registry (bundling/unbundling/numberline_mark/flash_subitize) + B2.3 nonstandard forms. **Full-bank smoke: 36 specs × 3 levels × 8 problems × 5 seeds = 4320 problems, all pass.** Suite now 298 tests, analyzer 0 errors.

Deferred/flagged for P2 tasks 6-8: evaluator must handle arrangement-aware rules (C1.1b/C1.3 L2 two_groups derived quantity), flash_subitize repeats counts by design (≤5), A1.5 L1 only 2 unique problems (plan-allowed duplicate fill), B1.3/B2.3 L2 gained `ones_range` [10,18].

### 2026-08-31 — P2 critic round + P4 teacher console

- P2 critic (fresh context, ran the actual app against live): **Critical CORS blocker** — `learning-path` omitted `x-student-token` from `Access-Control-Allow-Headers`, killing `/lernpfad` in-browser. Fixed (`3ab353a`) + deployed; preflight verified. Plus 3 Important + 6 Minor findings → all fixed at `43b3a0b` (take_away semantics, retry-copy, neighbor dual-gap, Semantics labels, reduced motion, gray subtracted group, recovery band persistence, A1.2b range) + stray png removed. Re-review: 9/10 addressed; #9 (Flutter-web synthetic-pointer limitation) is tooling-only.
- P3 re-review: 18/18 findings ADDRESSED in the actual JSONs; check_specs OK 36/36; one residual (A1.2b L2 range) fixed.
- P4 teacher console: plan (`docs/superpowers/plans/2026-08-31-p4-teacher-console.md`, 10 tasks) + backend `archive`/`reset`-re-open (`9707ac5`, 30 deno tests) + dashboard foundation (`d2a70c7`) + interactive PathConsole with all PATCH actions + teacher e2e smoke 5/5 (`2f8b182`, incl. a CORS Access-Control-Allow-Methods fix deployed) + P4 critic (ran the real console, 2 High/5 Med/3 Low) + all 9 findings fixed (`1aec30a`; reactivate action, multi-path linking, 44px targets, phone banner, honest confirms).
- **Branch `gauntlet/p2-p3-p4`: P2 + P3 + P4 complete and critic-loop-clean. Next: integration gauntlet.**

### 2026-09-01 — Integration gauntlet: real journeys executed (live)

Ran against the LIVE product (live Supabase + local dashboard + local Flutter web dev server, all real data, no mocks). Finding #9 (Flutter 3.35 web drops synthetic POINTER events through the a11y semantics host) was worked around: **keyboard Tab/Enter drives the Flutter UI** (roster + login + path-tile activation all fired real requests), plus a `?sem=1` test hook in `main.dart` forces the semantics tree so the UI is verifiable/automatable.

**Journey 1 — Teacher → child login → path → practice → mastery → teacher (COMPLETE, live):**
- Set a valid class code (`S4KA`) for the E2E class (fixture class had `null` — child login unreachable otherwise).
- Real child app (`/lernen/e2e-d7e2ee94`): entered `S4KA` → roster 200 (E2E Kind) → login 200 (JWT) → `/lernpfad` 200 → path screen rendered "Hallo, E2E Kind!" + "3 Übungen für dich bereit" + 4 tiles (3 verfügbar, 1 gesperrt) with real titles/descriptions → Tab+Enter on a tile → **practice-session/start 200** → PracticeScreen rendered "Aufgabe 1 von 8 · Lege · Tippe auf dem Zahlenstrahl Schritt für Schritt weiter bis zur 60." with disabled "Weiter" until input.
- Completed the A1.2a session (opened via the UI) through the real `/sync`+`/end` with the ACTUAL generator output for the session's seed (8 problems, all correct): `mastered: true`. DB verified: session `problems_total 8 / correct 8 / median 5000ms`, 8 attempt rows, `skill_progress A1.2a L1 8/8 mastered_at set`, path items coherent.
- Teacher dashboard: `/dashboard/lernpfade/<path>` shows path "Aktiv", slow-flag banner ("Langsames Bearbeiten" on the fixture-slow A1.1a), and per-skill level rows (expand tile): **"Stufe 1 · 8 Versuche, 8 richtig · Gemeistert"** for A1.2a.

**Journey 2 — Diagnostic → Förderplan → path generation (COMPLETE, live):**
- Created a session ticket, started a real diagnostic session (cleanroom-v1), posted 60 answers (deliberately wrong on the counting questions Q1-8), then opened the dashboard Förderplan page → `foerderplan-generate` 200 → **recommended_skill_ids `[A1.1a, A1.1b, A1.2a, A1.2b, A1.3, A1.4, A1.5]`** (exactly the designed counting-weakness profile) → a **new draft learning path created** with `source_session_id` set.
- **BUG FOUND + FIXED (deployed):** the session never auto-completed — `diagnostic-results` counted all 92 `diagnostic_questions` rows (60 core + 32 deep-dive share the table) against the child's 60 answers. Previously masked by the app's explicit `completeSession()`. Fixed to use `diagnostics.question_count`; re-verified: the 60th answer now returns `session_completed: true` and the session row is `completed` with `completed_at`. Committed + deployed.

**Integration-phase decisions:**
- Diagnostic report screen's "Weiter zum Üben" no longer routes children to the retired practice engine (`LearningPathScreen`); it explains the teacher prepares the path (P2-plan Task 10 deferred decision). Committed.
- Finding #9 (Flutter pointer-event automation gap) is a Flutter-engine tooling limitation, documented; keyboard automation + `?sem=1` cover it.

### 2026-08-31 — Live data snapshot (pilot)
`schools` → Pilotschule (`pilotschule`). `classes` → 2b (`22WW`, repaired), 3a (`4A35`), Klasse 2a (`3CD7`). `students` → SCH01 (2b), S01 (Klasse 2a). `diagnostics` → cleanroom-v1 (60), imint-grundschule-zr20 (92).

---

### 2026-09-04 — 59-item delta applied; runtime CSV found stale beyond the item count

- **A1.5-01 retired.** `scripts/generate_diagnostic_csv.py` had `A1.5-01` hardcoded in `CORE_ORDER` and asserted `len(CORE_ORDER) == 60`, so it would have failed against the item bank (the item file was already deleted at R2.9). Generator updated to 59; CSV regenerated to 59 core / 32 deep-dive.
- **Independence sidecar re-keyed.** It keys on row index, not item ID: dropping A1.5-01 (row 8) moved the A3.3-02 adjudication from `20` to `19`, exactly as predicted. Verified by reading the row back. Both banks exit 0 under `--strict`.
- **BUG FOUND — the committed CSV was stale in 22 prompts, not just the count.** Regenerating surfaced that **22 of 59 core prompts** differed from the signed item files: R2.9 shortened the German wording of the visual items (the picture carries the description, so the prompt no longer repeats it — e.g. A2.1-01 "Gleich erscheint für einen kurzen Moment ein Rechenrahmen. Merke dir genau, wie viele Perlen du siehst…" → "Schau genau hin! Wie viele Perlen waren es?"), and the CSV was never regenerated. **The live diagnostic has been showing prompt text the signed bank no longer specifies.** Same class of drift as the earlier `question_count` bug: a derived artifact not regenerated after its source changed.
- **BUG FOUND — mangled German in 9 signed item files.** The R2.9 edits left artefacts that would have shipped to children: doubled spaces from a deleted word (A1.1-01/A1.1-02 "von der Zahl 12  weiter", D1.2-01) and prompts opening with `„` but closing with a straight `"` (all A1.x + D1.x). Corrected mechanically — typography only, no wording, meaning, numbers or provenance touched. Re-scan → 0 defects.
- **Migration written, NOT applied:** `20260904000000_cleanroom_v1_core_59.sql`. It **retires** the A1.5-01 row (`tier='retired'`, parked at 900) rather than deleting it, because `diagnostic_results.question_id` cascades on delete and a delete would destroy existing pilot answers. It renumbers core to 1..59 and deep-dive to 60..91 — mandatory, because the client posts `question_number` from the CSV's ListNumber and `diagnostic-results` resolves the question UUID by that number, so a mismatch would file answers against the wrong question. Pre-flight guards abort if the row at 8 is not A1.5-01, if the tier counts are unexpected, or if any session is `in_progress`; post-conditions verify 59/32/1 and gapless numbering inside the transaction.
- **Gates green after the change:** `flutter test` 455/455 · `flutter analyze` 0 errors (335 style lints, up from the 323 baseline as P2–P4 added code) · dashboard `tsc` exit 0 · provenance / independence (both banks) / mapping / specs / skill-descriptions all pass.

## Open items / decisions
- [x] 59-vs-60 core item count — **RESOLVED 2026-09-04.** A1.5-01 struck per R2.9. CSV regenerated to 59 (generator's self-check now expects 59), independence sidecar re-keyed 20→19, Flutter test updated, migration `20260904000000_cleanroom_v1_core_59.sql` written (retires the row rather than deleting it, because `diagnostic_results.question_id` cascades). **Migration not yet applied to live — Jakob's step.**
- [ ] Deploy the Flutter web app with the new practice runtime + teacher console to Vercel (local verification done; production rollout is Jakob's step).
- [ ] F5 abandoned-session handling: document-only note today; product decision needed (abandon timeout vs resumable state).
- [ ] Live re-deploy of the dashboard after P4 changes (next push to the portal repo).

### 2026-09-01 — Final fresh-context integration critic + fixes
The final critic exercised the real product (all three journeys passed) and found 1 Critical + 3 Important + 2 Minor, all addressed at `a2625c1` + backend deploys:
- F1 (Critical): console add-skill picker exposed 87 legacy skills with no spec → now filtered to the 36 spec-backed skills.
- F2 (Important): `deno check` failed across functions (latent TS type errors in diagnostic-sessions) → fixed, all functions type-check clean.
- F3 (Important): practice summary said "Fast geschafft!" after an 8/8 mastered session → now keyed to the session result.
- F4 (Important): duplicate problems within a session → 16 degenerate generator ranges widened; smoke test now asserts ≥4 distinct per level.
- F5/F6 (Minor): abandoned-session notes added; "aus Diagnostik vom" label neutral for manual paths.
Final gates (fresh): `flutter test` 455/455 · `flutter analyze` 0 errors · dashboard `tsc` clean · `check_specs.py` OK 36/36.

### 2026-09-04 — P6 publish hardening: legal pages, German audit, timeouts, diagnostic answer integrity

Slice chosen by Jakob: P6 DSGVO + hardening. Two independent audits (German-language surface sweep + error/load hardening, both fresh agents) ran first; every fix below is traceable to an audit finding or a critic round.

**DSGVO pages (`dashboard/app/impressum` + `datenschutz`):**
- Impressum cited **§ 5 TMG** — repealed law; now **§ 5 DDG**. "Stand" corrected to September 2026 (both pages).
- Operator data was *inconsistent placeholder*: bracketed `[Jakob Neumann]/[Eulerstraße 12]/[13357 Berlin]` in impressum, but **unbracketed** `jakob.neumann@schule.berlin.de` in datenschutz §1; both `mailto:` hrefs contained literal `[`/`]` (broken address). Unified to unmistakable tokens `[Name]` / `[Straße und Hausnummer]` / `[Postleitzahl und Ort]` / `[E-Mail-Adresse]`; mailto links removed (no placeholder email can be a link); datenschutz §7 now points to "die im Impressum genannte Adresse". TODO comments now German.
- **Claims verified against the implementation** (no fabricated legal statements): no analytics/gtag anywhere in `dashboard/` → "keine Tracking-Cookies" claim backed; `delete-school-data` edge function exists (whole-school cascade + `auth.users` cleanup) → §5/§7 deletion promise backed, but only at whole-school granularity (single-teacher erasure would delete the school — flagged for Jakob, not silently changed); practice data **was missing from §2's enumeration** — `learning_paths/path_items/skill_progress/practice_sessions/practice_attempts` are live since P1/P2 (2026-08-31) → §2 child bullet now lists "Fortschritt auf dem Lernpfad (bearbeitete Übungen, Antworten und erzielter Lernstand)".
- **New launch gate** `scripts/check_legal_pages.py`: exits 1 while any `[...]` placeholder remains in either legal page. **Red by design** until Jakob enters real operator data (STATUS.md Active #7). Verified: exits 1 listing all 11 tokens; `sys.stdout` reconfigured to UTF-8.
- `check_legal_pages.py` is NOT wired into a CI/deploy step (no CI exists); it is a run-before-push gate. Flagged in the critic round, recorded, deploy is Jakob's step anyway.

**German-string surface audit (fresh agent) — findings and fixes:**
- Fixed: `web_diagnostic_entry_screen.dart` duplicated-word typo **"Bitte bitte deine Lehrkraft…"** ×2 → "Bitte deine Lehrkraft…" (child-facing, real). Plus a German "Nochmal versuchen" button added to its dead-end error state (audit B4).
- Fixed: dashboard login showed Supabase's **English** error verbatim → `login/actions.ts` `germanLoginError()` maps `invalid_credentials`/`email_not_confirmed` and falls back to neutral German. Verified in a real browser by the critic: bogus login → "E-Mail-Adresse oder Passwort ist falsch."
- Fixed: brand "Math App" leftovers → "Numeris" (`login/page.tsx`, `dashboard/layout.tsx`).
- Fixed: Förderplan detail-table status label "Timeout" → "Zeitüberschreitung" (dashboard only hit).
- Fixed: `PathConsole` network-failure `Error.message` (English "fetch failed") → German connection message (`lib/lernpfad/api.ts`); bulk-QR `errJson("class_id required")` → "Klasse fehlt".
- Fixed: `diagnostic_report_screen.dart` DOCX-export failure SnackBar `Fehler: $e` (raw exception) → German "Der Bericht konnte nicht gespeichert werden." (native-only path, but wrong anyway).
- Audited + recorded, NOT changed: the legacy per-level exercise engine (`HomeScreen`→`LearningPathScreen`→`ExerciseScreen`) contains ~29 English child-facing widgets — but is **unreachable in the shipped web child flow** (web routes are `/`, `/s/:param`, `/lernen/:slug`, `/lernpfad` only; verified in `main.dart` router). It stays for the R8.1 practice-skill audit. Orphaned/unimported widgets excluded as dead code.

**Diagnostic answer integrity (audit B1/B2 — the highest-risk finding, confirmed in code):** every `postResult` failure was swallowed (`debugPrint`) and the session was then force-completed regardless (`_processResults` → `diagnostic-sessions` `complete` does a blind update). On school Wi-Fi a child could finish a diagnostic with answers silently missing while the Förderplan is generated from the gaps. Server side `diagnostic-results` **upserts on `(session_id, question_id)`** (verified), so re-posts are idempotent and the server auto-completes once all rows exist. Fix in `diagnostic_screen.dart`:
- The answered question's row is now a **hard gate**: `_persistRowWithRetry` (3 attempts, 600 ms backoff) and the child only advances via `_advanceAfterPersist` after the row is on the server. Break-off `'skipped'` markers are best-effort single attempts (a missing marker must not strand a child; `completeSession` closes the session server-side regardless).
- On persistent failure the child is blocked on a **German retry screen** ("Deine Antwort konnte noch nicht gespeichert werden." / "Nochmal versuchen"), never silently advanced past an unsaved answer. Retry re-runs the persist+advance (idempotent).
- Re-entrancy closed: `_nextQuestion` is now a guard wrapper (`_savingAnswer`, reset in `finally`); the "Weiter" button shows a spinner and is disabled while saving. `_skipCurrentQuestion` early-returns while `_savingAnswer`. `mounted` checks added after every await in the persist chain (`_advanceAfterPersist`, `_blockSave`, retry closure).
- Resume holes closed: `_hydrateFromServer` now replays every answered server row and continues past missing rows only when break-off exempts them — a resumed session neither re-presents an answered question nor presents a break-off-exempt one.
- Question-load error branch `Fehler: ${snapshot.error}` (raw exception) → German message + "Nochmal versuchen".

**Request timeouts (audit D1 — without them the German error states never fire):** the Flutter client had **zero** HTTP timeouts, so a black-holed school-Wi-Fi connection spun forever. Added `Duration(seconds: 12)` `.timeout` to every backend call: `api_service.dart` (all three diagnostic endpoints, `TimeoutException`→`ApiException`), `student_auth_service.dart._send`, `learning_path_service.dart._send`/`fetchPath`/both `/sync` flush callbacks. All errors funnel into the existing German typed exceptions.

**Three fresh-context critic rounds** (each ran the real dashboard via Playwright + read the changed code + ran gates): round 1 found 2 HIGH + 2 MEDIUM (re-entrancy during the now-long persist window, missing `mounted` guards, skip-row failure blocking the child forever, unwired gate) — all fixed. Round 2 verified all three resolved and raised 4 LOW/MEDIUM follow-ups (`_skipCurrentQuestion` orphaned side effects on a guarded skip, hydration re-presenting an answered question, `_retrySave` re-entry window, over-retried skip posts) — all fixed. Round 3 (final verification): all four fixes correct, no new defect. German copy in every new string verified correct by all three reviewers.

**Gates (final, fresh):** `flutter test` **455/455** · `flutter analyze` **0 errors** (335 lints — the exact recorded baseline, i.e. no new lints from this round) · dashboard `npx tsc --noEmit` **exit 0** · `check_provenance.py --all` OK · independence core+deepdive `--strict` exit 0 (2 flags = the pre-existing A3.3-02 adjudication, still correctly keyed) · `check_mapping.py` OK (91 entries — 92 minus the retired A1.5-01) · `check_specs.py` 36/36 · `check_skill_descriptions.py` OK. `scripts/check_legal_pages.py` **red by design** (operator data not yet entered).

**Deploy needed to make these live (Jakob's steps):** rebuild + deploy the Flutter web app (all diagnostic-integrity + timeout fixes are client-side) and push the dashboard (legal pages, login error, brand). No backend edge-function or schema changes in this round. The 59-item migration (`20260904000000_cleanroom_v1_core_59.sql`) is still unapplied.

**Open items recorded:**
- Legal placeholders remain until Jakob enters real operator data; `check_legal_pages.py` is the launch veto.
- Single-teacher/student erasure is only implementable at whole-school granularity today (`delete-school-data`); §5 datenschutz wording implies per-teacher deletion. Product/legal decision for Jakob.
- `/wissenschaftliche-grundlagen` is linked from the public footer but not in the middleware public list — a logged-out visitor clicking it lands back on `/login`. Minor; needs a one-line decision (public or drop the footer link on logged-out pages).
- Diagnostic answers are now guaranteed to reach the server before advancement, but a child who exits during a persistent outage leaves the session `in_progress` (resumable by design, F5 decision still open).

### 2026-09-04 — Ledger verified; backend §4 gate repaired (Deno 4 errors → 0); foerderplan-pdf row-colour bug found + fixed; doc ledger reconciled

**Slice (Step 2):** the §4 backend gate — "FIX PROPERLY" thread. Work is **uncommitted** on `gauntlet/p2-p3-p4` (commit is the session owner's step).

**Step 1 — ledger verified against the live repo.** Gates run fresh (2026-09-04): `flutter test` **455/455** · `flutter analyze` **0 errors** (53 warnings / 282 infos = 335 issues, the exact recorded baseline) · dashboard `npx tsc --noEmit` **exit 0** · `check_provenance.py --all` OK · independence core (59 items) strict OK (2 flags = the A3.3-02 adjudication, re-keyed to item 19) · deep-dive (32) strict OK · `check_mapping.py` OK (91) · `check_specs.py` 36/36 · `check_skill_descriptions.py` OK · `check_legal_pages.py` **exit 1 red by design** (11 `[...]` operator tokens). `deno check supabase/functions/**/*.ts` reproduced the documented 4 errors exactly (TS2345 ×2: foerderplan-pdf:262, foerderplan-kurz-pdf:530; TS2352 ×2: foerderplan-pdf:165, 220). Every GAUNTLET claim matched reality — no stale ledger found; **doc staleness found in `tasks.md` + `STATUS.md`** (both still described the runtime CSV as "still 60 core"; the runtime side was resolved 2026-09-04, only the live `cleanroom-v1` row remains 60).

**Bug class check (types → real defects):** reading the failing code showed the two TS2352 casts were a *symptom* of a real rendering inconsistency: `foerderplan-pdf` recommendation rows coloured via `catColor(s.category)`, but new-taxonomy `skills.category` stores the short label ("Domäne A") while `DOMAIN_LABELS` (and `foerderplan-generate`'s `category_stats` keys) use full labels ("Domäne A — Zahlbegriff") — so every recommendation-row rectangle rendered `DEFAULT_COLOR` gray while the Domänen-Übersicht bars took domain colours, contradicting the R5.4 design note. Verified against the applied bank migration (`20260829000000`: category='Domäne A', domain='A'; legacy rows domain NULL by design) and `foerderplan-generate`'s `domainLabel`.

**Fix (all behavior-preserving, `backend/supabase/functions/foerderplan-pdf/index.ts` + `foerderplan-kurz-pdf/index.ts`):**
1. `new Response(uint8Array)` → copy into a plain `ArrayBuffer` (`new Uint8Array(bytes).buffer`) — Deno 2.9.6/TS 6 lib no longer accepts `Uint8Array<ArrayBufferLike>` as a BodyInit; the copy is byte-exact (offset-safe, handles any backing buffer). Probe confirmed `Blob`/raw `.buffer` still fail; the fresh-copy form type-checks. Runtime semantics unchanged.
2. Two loose `as` casts → single typed boundary: `interface SkillRow` (id/category/domain/title_de/description_de) + type-guard `.filter((s): s is SkillRow => s !== undefined)`; `domain` added to the SELECT, unused `color` dropped.
3. New `rowColor(s)`: colours new-taxonomy rows by `s.domain` letter (same palette as the overview bars); legacy rows (domain NULL) keep `catColor(s.category)` — byte-identical to the pre-edit legacy path.
4. `backend/deno.json` (+ generated `deno.lock`) added so the gate is canonical: `deno task check` / `deno task test`.

**Evidence (commands + output):** `deno check supabase/functions/**/*.ts` → **exit 0** (was 4 errors); `deno task check` → exit 0; `deno test supabase/functions/_shared/` → **32 passed / 0 failed**. A temp-dir probe (`deno eval`) verified the fresh-copy ArrayBuffer is byte-exact from a view with `byteOffset=4` and from a `SharedArrayBuffer` source. Dashboard `npx tsc --noEmit` re-run → exit 0 (unchanged files). No Flutter/clean-room/provenance file touched.

**Fresh-context critic (independent agent, ran the gates itself + reconstructed the pre-edit typecheck from HEAD):** reproduced the exact 4 pre-fix errors, confirmed every claim (drift vs real; legacy-path byte-equality; colour fix real per migration+generator). Findings: **0 Critical, 0 Important code defects.** 1 Important process note (doc prose describes state committed in `5fe8e93`, verified independently on disk — ruling: accurate, cross-referenced in the ledger; no change) + 4 Minor, all ruled with reasoning and no change to code: (a) `foerderplan-kurz-pdf` colours via id-prefix `groupLabel`, not the `domain` column — works for all 36 taxonomy ids, asymmetry only, left untouched; (b) silent empty-plan path if a DB lacked the `domain` column — pre-existing exposure class (generator already SELECTs domain), live DB has the column (migration applied); (c) `deno.json`/`deno.lock` untracked — kept, committed with the slice; (d) English code comments — consistent with the file's existing register, no user-facing string touched (verified: only added German text sits inside an English comment quoting the domain label).

**Doc ledger reconciled to verified state:** `tasks.md` Phase-R2 header, R2.9 and R2.11 status notes + `STATUS.md` Active items 1–2 no longer claim "runtime CSV still 60" — they now state the runtime side is resolved (CSV 59, sidecar re-keyed 20→19) and that the remaining delta is the live `cleanroom-v1` row (migrations `20260904000000_cleanroom_v1_core_59.sql` + `20260904000001_cleanroom_v1_sync_prompts.sql` written, **pending apply**). No checkbox state changed; R9 gate rows and the R9.3 precondition text are intact (verified by the critic against the diff). `docs/superpowers/gauntlet-loop.md` §4 gate note updated from "KNOWN BROKEN" to green-with-history.

**Still open (all pre-existing, unchanged by this slice):** both 20260904 migrations unapplied to live; deployed edge-function binaries predate these fixes (deploy is Jakob's step); Flutter web app + dashboard redeploys pending; legal placeholders red by design; F5 abandoned-session product decision; `/wissenschaftliche-grundlagen` middleware one-liner. **Ledger gap noted:** this file's 59-vs-60 open item listed only `20260904000000` as written — `20260904000001_cleanroom_v1_sync_prompts.sql` (27 drifted `prompt_de` rows, added in the same commit `5fe8e93`) was never recorded here and is now on the record. Both must be applied together, in filename order (0000 renumbers, 0001 then targets the post-renumber positions).

### 2026-09-04 (continuation session) — Slice committed as `611e41d` after a fresh full-gate re-verification

**Step 1 — the entry above was re-verified, not trusted.** All §4 gates re-run from a clean command line against the post-fix working tree on `gauntlet/p2-p3-p4`: `flutter test` **455/455 passed** · `flutter analyze` **0 errors / 335 issues** (the exact recorded baseline) · dashboard `npx tsc --noEmit` **exit 0** · `deno task check` **exit 0** · `deno task test` **32 passed / 0 failed** · `check_provenance.py --all` OK · independence core `--strict` OK (2 flags = A3.3-02, adjudicated at row 19) · deep-dive `--strict` OK · `check_mapping.py` OK (91) · `check_specs.py` OK (36) · `check_skill_descriptions.py` OK · `check_legal_pages.py` **exit 1 red by design** (operator placeholders). Every claim in the prior entry matched reality — no stale ledger found.

**Step 6 — commit record:** the slice (backend gate repair, foerderplan row-colour fix, `deno.json`/`deno.lock` pin, doc ledger reconciliation of `tasks.md`/`STATUS.md`/`gauntlet-loop.md`) is committed as **`611e41d`** on `gauntlet/p2-p3-p4`, per Jakob's explicit instruction. Nothing else in the working tree remains uncommitted.

**Still open (unchanged by this session):** the 59-vs-60 migrations `20260904000000` + `20260904000001` remain unapplied to live; the two fixed edge functions remain undeployed; legal placeholders await Jakob's operator data; F5 and the `/wissenschaftliche-grundlagen` middleware decision remain open.

### 2026-09-04 (release round, per Jakob's directive: no gates, commit to main, deploy) — `main` now `e697d01`; live stack fully current

**Live deployment round (all on the production project `zzxqeqwffexythqzjkxr` / Vercel):**
- Live DB verified against the source CSVs: `cleanroom-v1` 59 core (1..59) + 32 deep-dive (60..91) + A1.5-01 retired at 900, gapless, **0 prompt mismatches**. The 59-vs-60 migrations were ALREADY applied to live (the ledger line "pending apply" was stale) — data is consistent; client was not.
- `main` fast-forwarded from the gauntlet branch and pushed (48 commits); **prozedia-portal** production rebuilt (Ready). Child client `build/web` deployed to **prozedia-app** production — `main.dart.js` and the diagnostic CSV asset byte-identical to the verified local build. All 9 edge functions redeployed (ACTIVE, 2026-09-04 20:44 UTC).
- `/wissenschaftliche-grundlagen` added to the dashboard's logged-out routes (`middleware.ts`) — live 200 for anonymous requests.

**Fresh-context acceptance run on the LIVE stack (R6.4) found two Blockers in the child diagnostic — both fixed, deployed, and re-verified live:**
1. **Blocker — sequence/word answers unanswerable.** Counting items Q1–Q7 ("13, 14, …") and Q11 ("rechts") could not be typed (single digits-only field); several `CorrectAnswer`s are assessor transcripts. Fixed by a new grading/input layer: `services/answer_grading.dart` (curated per-item specs + shape rules; number/sequence/pairRows/choice/freeText modes; decimal-form folding "34.0"→34) and `widgets/diagnostic_answer_widgets.dart` (sequence fields, decomposition rows, choice chips, free text), wired in `diagnostic_screen.dart`.
2. **Blocker — empty submit 500/strand.** Empty "Weiter" posted `status='leer'`, rejected by `diagnostic_results_status_check` → 500 → permanent retry screen. Empty web submits now post `status='skipped'`.
- **Live re-verification (fresh agent, deployed URLs):** Q1 answered via the 8 sequence fields → DB row `was_correct=true`; Q11 answered by tapping "rechts" → `was_correct=true`. Both verified on the deployed child app.

**Shortened ("verkürzte") diagnostic wired and checked (Jakob's request):** `abbreviated_mode` previously ran a legacy ZR20/ZR100 heuristic that is inert on the clean-room bank (no item ever skipped). Replaced with `services/diagnostic_shortening.dart` `ConstructGates`: within a construct, a wrong answer skips only later STRICTLY-HARDER items of the SAME construct; equal-difficulty later items stay (the "double 20 after a failed double 7" rule); no cross-construct skipping (whole Domänen stay measured — deliberate caution against over-shortening; the blueprint's wider table remains documented in `skip_rules.dart`, unwired). **Check added** (`test/diagnostic_shortening_test.dart`, over the real CSV): weak child **36/59** (23 skipped), strong child **59/59**, every construct and every Domäne A–D keeps ≥1 presented item; full mode always 59. Also new: `answer_grading_test.dart`, `diagnostic_answerability_test.dart` (59/59 items gradable), `diagnostic_answer_widgets_test.dart` (typing/tapping interaction). `flutter test` **480/480**, `flutter analyze` **0 errors**.

**Still open:** legal placeholders await Jakob's operator data; F5 abandoned-session product decision; deep-dive blocks (32 items) remain unserved by any UI flow; C3/C4 step-by-step intermediate capture is final-result-only by design (documented in `answer_grading.dart`); R6.4 full run on a physical Android tablet still to be executed by Jakob.

### 2026-09-05 — Diagnostic usability rework: design doc + Workstream-A plan; SDD execution through Task 7 (6/7 reviewed clean, Task 7 pending review)

Reviewing the live diagnostic (60/59-item bank, running with real children) surfaced defects the acceptance runs above didn't catch: the on-screen prompt renders twice per text item, prompts carry meaningless quote-wrapping in three inconsistent styles, some counting-sequence items are structurally unenterable (A1.2-01: 5 boxes, but the accepted "repeat the start" variant needs 6), the A2.1-01 Rekenrek flash fires in the top-left corner the instant the widget builds (no warning, wrong position), a Stäbchen bundle renders too small to count, a working sort widget (`SortAnswerWidget`) sits completely unwired, the response-time timeout is a flat 20s/60s split regardless of how many boxes an item has, and a `Hilfetext` field written in 17 item files never reaches the CSV or the app. Root-caused and designed in `docs/superpowers/specs/2026-09-05-diagnostic-usability-rework-design.md` (locked decisions, §4 interaction-layer fixes, §5 item revision, ships eventually as a new `cleanroom-v2` bank — `cleanroom-v1` and its pilot sessions stay untouched).

Workstream A (interaction layer only, zero item-content changes) was scoped as its own 10-task plan — `docs/superpowers/plans/2026-09-05-diagnostic-interaction-layer.md` (commit `5f37b5a`) — and executed via subagent-driven development (one implementer + one independent task reviewer per task) on branch `diagnostic/usability-rework`, working in place (Jakob declined a separate worktree). Baseline before Task 1: `flutter test` 480/480, `flutter analyze` 0 errors.

- **Task 1** (`9a29d95`) — extracted a `QuestionPrompt` widget; removed the duplicated 48px `questionText` block so the prompt renders once. Reviewed clean.
- **Task 2** (`2720c4f`) — `strip_quotation_wrapping()` added to `generate_diagnostic_csv.py` (handles all three quote styles, leaves nested quotes alone) + a fail-fast prompt-hygiene self-check in `main()`; both `diagnostic_core_v1.csv`/`diagnostic_deepdive_v1.csv` regenerated. Reviewer read every changed row in both files: only `QuestionText`/`German` punctuation changed, `ListNumber`/`AnswerFormat`/`CorrectAnswer`/row order/row count byte-identical. Reviewed clean.
- **Task 3** (`ce4c7b9`) — sequence-input anchor: the given start now renders as static text ahead of the answer boxes (`"21, [__][__][__][__][__]"`), fixing the A1.2-01 unenterable-variant bug directly. Six `kAnswerSpecs` entries added for A1.1-01/02, A1.2-01/02, A1.3-01/02; reviewer cross-checked all six against `diagnostic_core_v1.csv` and the pre-change shape-inference grading path to confirm zero grading-behavior change for these live items. Reviewed clean.
- **Task 4** (`5594391` + fix round `69fd8da`) — centred the Rekenrek beads (root cause: an unconstrained `Row` defaulting to `mainAxisSize.max`/`mainAxisAlignment.start`) and replaced the build-triggered 800ms flash with a child-initiated Bereit → fixation → 3-2-1 countdown → 1500ms flash → 200ms fade sequence. **Task review caught a real bug the plan's own code introduced**: the `flash`→`hidden` switch cases returned different widget types at the same tree position, so Flutter remounted instead of calling `didUpdateWidget` — the "200ms fade" never animated, it cut instantly, and neither test caught it because both only read the static target `opacity`, not the interpolated value. Ruled real and plan-mandated; fixed by merging the two cases into one persistent `AnimatedOpacity` whose target flips on stage. Re-review added a mid-fade assertion reading the live interpolated value (confirmed to fail against the pre-fix code, pass against the fix). Reviewed clean after 1 fix round.
- **Task 5** (`7e5a46c`) — wired `DiagnosticAnswerMode.sort` end to end (enum + `modeFor`/`grade`/`answerFieldLabel` + widget dispatch); lifted `SortAnswerWidget` out of the dead `answer_widgets.dart` into `_SortFields`, fixing a latent "sneaky win" bug in the process (the ported shuffle now re-rolls if it lands on the solved order — the original could hand a child a free pass). Deleted `answer_widgets.dart` (its other two widgets, `SingleAnswerWidget`/`MultipleAnswerWidget`, had zero importers). Reviewer independently grepped the whole `math_app/` tree to confirm no exhaustive switch over the enum was missed and no dangling import survived. Reviewed clean.
- **Task 6** (`a17cee7`) — response-time budget changed from a flat single/multiple 20s/60s split to `max(15, 5 × boxCount)`, where `boxCount` is the actual number of answer fields the item renders (`AnswerGrading.boxCount`, new). Reviewed clean.
- **Task 7** (`94847c6`) — `DienesPlaceValueWidget`/`DienesOeffnenWidget` (new file, composed from the existing isometric `DienesBlockWidget` primitive) replace the too-small-to-count Stäbchen bundle in the diagnostic's 5 place-value items (B1.2-01/02, B1.3-01, DDB-01/02); `staebchen.dart` itself is untouched since 3 practice-template files still depend on it (out of scope). Implementer reports `flutter test` 492/492, `flutter analyze` 0 errors. **Review not yet run — do not treat as complete.**

**Still open (this slice):** Task 7's task review, then Tasks 8–10 (Hilfetext column CSV→model→service→UI, a new `PausableTimeout` utility so the Hilfe button pauses the response-time clock, and wiring it all into `diagnostic_screen.dart`), then a final whole-branch review before this lands anywhere. Workstreams B (67-item revision), C (clean-room integrity gates), and D (migration + deploy to a new `cleanroom-v2` row) are separate later plans per the design doc's own phase ordering (§8) — none started; `cleanroom-v1` and every pilot session on it remain exactly as they are. Full task-by-task detail (rulings, parked minors, reviewer verdicts) lives in the session's SDD ledger at `.superpowers/sdd/2026-09-05-diagnostic-interaction-layer/progress.md` (gitignored working scratch — this entry is the durable record).
