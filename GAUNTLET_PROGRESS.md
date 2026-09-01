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

## Open items / decisions
- [ ] 59-vs-60 core item count (Jakob's R2.9 sign-off determines final state).
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
