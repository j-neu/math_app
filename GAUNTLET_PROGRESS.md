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

### 2026-08-31 — Live data snapshot (pilot)
`schools` → Pilotschule (`pilotschule`). `classes` → 2b (`22WW`, repaired), 3a (`4A35`), Klasse 2a (`3CD7`). `students` → SCH01 (2b), S01 (Klasse 2a). `diagnostics` → cleanroom-v1 (60), imint-grundschule-zr20 (92).

---

## Open items / decisions
- [ ] 59-vs-60 core item count (Jakob's R2.9 sign-off determines final state).
- [ ] P2/P3/P4 acceptance criteria from independent critics.
- [ ] Live deployment of any new edge functions / dashboard changes after this build.
