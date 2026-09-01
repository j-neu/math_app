# P4 — Teacher Console for Learning Paths Implementation Plan

**Date:** 2026-08-31
**Owner:** Gauntlet controller
**Spec:** `docs/superpowers/specs/2026-08-30-numeris-learning-path-design.md` §3 (P4 row), §4.2 (RLS), §4.6 (endpoints), §6 (build protocol / DoD)
**Backend contract:** `backend/supabase/functions/learning-path/index.ts` (GET/POST/PATCH, exact shapes quoted in Tasks 1, 6, 7)
**Branch/worktree:** none yet — work happens on a branch off `main`

---

## 1. Goal

Build the teacher-facing console for the Numeris learning path inside the existing Next.js dashboard: (a) a class overview showing which students have a learning path, its status, mastered/available counts and slow-response alerts; (b) a per-student path console to view, reorder, extend, edit and activate/archive a path; (c) a per-skill progress detail (levels 1–3, attempts/correct, slow flag); (d) real empty/loading/error states on every view — no placeholder analytics, every number from the live tables; (e) the console runs on the teacher's Supabase session, all writes go through the `learning-path` PATCH edge function carrying the teacher JWT; (f) the existing dashboard flows (foerderplan page, StudentRow) keep working unchanged.

## 2. Current state (verified 2026-08-31)

- **Edge function `learning-path`** (`backend/supabase/functions/learning-path/index.ts`) ships GET / POST `/generate` / PATCH. PATCH actions: `activate`, `set_unlock_width`, `add_skill`, `remove_skill`, `set_state` (skip/lock/unlock), `reorder`, `reset_progress`. **There is NO `archive` action** — the status `archived` is in the schema check constraint but unreachable from any endpoint (spec §3 P4 requires archive). PATCH/POST authenticate via `Authorization: Bearer` (service-role key or teacher JWT → `teachers` row → `school_id`); GET authenticates only via the `x-student-token` child header.
- **`reorder_path_items(uuid, text[])`** RPC is `grant execute ... to service_role` only, and **`skill_progress` has teacher SELECT-only RLS** (no teacher DELETE) — so reorder and reset-progress *must* go through the edge function (service-role client), never direct PostgREST from the dashboard.
- **`reset_progress` leaves a dead end**: it deletes `skill_progress` for the student and sets *every* `path_items.state` to `locked`, with nothing re-opening the first `unlock_width` items. The child GET returns the path, but `practice-session/start` rejects locked items (403 "noch nicht freigeschaltet"). A teacher who resets expects "start over with the first N available again" (mirrors `/generate`: `idx < unlock_width → available`). Flagged as a backend fix in Task 1.
- **Activate enforces one active path per student** (`learning_paths_one_active_per_student`, partial unique index) and returns a specific German 409 message for a second activation.
- **`foerderplan-generate`** already creates a draft path server-to-server (service-role Bearer) — a teacher finds a waiting `draft` path after any Förderplan.
- **Dashboard** is Next.js 14 App Router: server components by default with `createClient()` from `@/lib/supabase/server` (`auth.getUser()` → `redirect("/login")`), client components (`"use client"`) for interaction with `createClient()` from `@/lib/supabase/client` + `router.refresh()`. `foerderplan/[sessionId]/page.tsx` already invokes an edge function server-side via `supabase.functions.invoke`. German UI, Tailwind. No test runner (no vitest/jest), no Playwright setup yet.
- **Backend tests that exist**: `backend/supabase/tests/schema_learning_path.sql`, `backend/supabase/tests/rls_learning_path.sql` (both transactional + rollback, run against the live project via `psql`), plus `_shared/*_test.ts` Deno suites. No edge-function contract test file yet.

## 3. Global constraints

- **Reads via PostgREST, writes via the PATCH edge function.** The console reads `learning_paths`, `path_items`, `skill_progress`, `skills` directly through the server/browser supabase client — the teacher RLS policies (`teacher_student_ids()`) scope every read to the teacher's school. All mutations (`activate`, `archive`, `set_unlock_width`, `add_skill`, `remove_skill`, `set_state`, `reorder`, `reset_progress`) go through `POST /functions/v1/learning-path` PATCH with the teacher's session JWT as Bearer. This is not an option: `reorder_path_items` and `skill_progress` DELETE are service-role-only.
- **Teacher identity (spec §4.6, user req. #5).** `supabase.functions.invoke("learning-path", { body })` from the dashboard browser client attaches the teacher's session access token as `Authorization: Bearer` automatically. Server-side invoke must first load the session (`auth.getUser()` / `auth.getSession()`) and pass `Authorization: Bearer <access_token>` explicitly. The edge function's `authenticateWriter` then resolves the user via an anon client's `auth.getUser()` and requires a `teachers` row whose `id` equals the JWT `sub`. Nuances to respect (from `index.ts`):
  - The GET handler verifies the **child** token from the `x-student-token` header only — there is **no teacher-authenticated GET**. The console never calls GET; teacher reads are PostgREST (RLS). Documented here so nobody "fixes" the console by pointing it at GET.
  - GET fails closed (500) when `STUDENT_JWT_SECRET` is unset.
  - PATCH/POST scope-check every target: the path's student's school must equal the teacher's school, else 403 `"Kein Zugriff auf diese Klasse"`.
  - PATCH/POST without a valid bearer → 401 `"Nicht angemeldet"`; cross-school → 403; second activate → 409 with the German message (must be surfaced verbatim, not remapped).
- **Spec §6 / DoD gates are acceptance criteria.** Every task's acceptance is stated against the mapping in §4 below.
- **German only.** Every string, including errors, empty states, and confirmations. No `skill_id`, `path_item`, `construct`, `Lernpfad-Eintrag` jargon in the UI — "Kompetenz", "Schritt", "Übung", "Lernpfad" are the vocabulary (rubric #1, #7).
- **Every action states its outcome before it happens; destructive ones are confirmed.** Reset and remove get an explicit German confirm dialog that says what will be lost. Rubric #3.
- **No color-only signals.** Every state is text + badge + icon; the slow flag is a labelled banner, never just a red dot. Rubric #5.
- **No placeholder analytics.** No mocked/demo numbers anywhere; every count/percentage comes from the live queries in Task 2. An empty real result renders a German empty state, never fake data.
- **Keep existing flows working.** `foerderplan/[sessionId]`, `students/[studentId]`, `klassen/[id]` and `StudentRow.tsx` are not broken by any change. The class-page task is additive only.
- **Legal gate.** New/changed files contain zero occurrences of `iMINT`, `PIKAS`, `SenBJF`, `Schulz`, `LISUM` and zero pricing strings (`kaufen`, `Preis`, `Abo`, `Lizenz kaufen`).
- Verify commands per task: `cd dashboard && npx tsc --noEmit`, `cd dashboard && npm run build`, backend `cd backend/supabase/functions && deno check <file>`, SQL `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/tests/<file>.sql`. The running local dashboard against the live Supabase project (`npm run dev`) is the test target; Playwright drives the UI.

## 4. Spec §6 acceptance criteria — how the plan makes them testable

| §6 Gate | Testable check in this plan |
|---|---|
| **Build** | `cd dashboard && npx tsc --noEmit` clean after every dashboard task; `npm run build` clean at Tasks 3, 4, 5, 7, 10; `deno check` clean on every backend change. |
| **Backend** | Migrations already applied (schema_learning_path.sql re-run → `SCHEMA OK`); `rls_learning_path.sql` re-run → `RLS OK`; Task 1 curl contract tests assert exact request/response JSON and status codes (401/403/409/400/200) for the teacher write path. |
| **Visual** | Task 9 Playwright viewport sweep at 1280×800, 1024×768 and 390×844: no overflow, no clipped German text, no sub-14px critical info, no colour-only signals (state = label + badge), tap/click targets ≥ 44 px on touch. |
| **Critic** | Task 9 runs the teacher-usability rubric (spec §6): fresh-context critic checks the real artifact; the core loop *Klasse → Lernpfad → aktivieren → Fortschritt* is completable without a manual; actions state their outcome; no dead ends. |
| **Legal** | `rg -i "imint|pikas|senbjf|schulz|lisum|kaufen|Lizenz kaufen"` over all new/changed files → zero hits. |

**User requirements → tasks:**

| Requirement | Task |
|---|---|
| 1. Class overview: who has a path, status, mastered/available counts, slow_flag alerts | 3 |
| 2. Per-student console: view/reorder/add/remove/skip/unlock_width/reset/activate/archive + draft-until-active visibility rule | 4, 5, 6, 7 (+1 backend) |
| 3. Per-skill progress detail: levels 1–3, attempts/correct, slow_flag | 5 |
| 4. Empty/loading/error states everywhere, real data only | 2, 3, 4, 5, 6, 7, 8 |
| 5. Teacher identity/RLS; PATCH carries teacher JWT; auth nuance | 1, 2, 6, 7 (nuance documented in §3) |
| 6. Existing dashboard flows keep working | 3 (additive), 10 (regression) |

## 5. Architecture / file structure

```
backend/supabase/functions/learning-path/index.ts   MODIFY: +archive action, +reset_progress re-open (Task 1)
dashboard/lib/lernpfad/types.ts                     NEW: TS types for path/items/progress/PATCH (Task 2)
dashboard/lib/lernpfad/stats.ts                     NEW: pure aggregation (counts, level shape) (Task 2)
dashboard/lib/lernpfad/stats_test.ts                NEW: Deno tests for stats.ts (Task 2)
dashboard/lib/lernpfad/queries.ts                   NEW: server-side PostgREST readers (Task 2)
dashboard/lib/lernpfad/api.ts                       NEW: client-side PATCH wrapper via functions.invoke (Task 6)
dashboard/app/dashboard/klassen/[id]/page.tsx       MODIFY: +"Lernpfade" section (Task 3)
dashboard/components/PathStatusBadge.tsx            NEW: status/progress/slow-flag badge (Task 3)
dashboard/components/PathStatusRow.tsx              NEW: per-student overview row (Task 3)
dashboard/app/dashboard/lernpfade/[pathId]/page.tsx NEW: path console server page (Task 4)
dashboard/app/dashboard/lernpfade/loading.tsx       NEW: skeleton (Task 4)
dashboard/app/dashboard/lernpfade/error.tsx         NEW: German error + retry (Task 4)
dashboard/components/PathConsole.tsx                NEW: client console (read view Task 5, writes Task 6/7)
dashboard/e2e/playwright.config.ts                  NEW: Playwright setup (Task 8)
dashboard/e2e/teacher-console.spec.ts               NEW: smoke specs (Task 8)
backend/supabase/tests/fixture_p4_console.sql       NEW: seed a draft path for a pilot student (Task 8)
backend/supabase/tests/fixture_p4_cleanup.sql       NEW: rollback/delete fixture rows (Task 8)
```

Route: `/dashboard/lernpfade/[pathId]` links from the class page rows and from `students/[studentId]` (additive link, existing pages untouched). Reads are server components; `PathConsole` is the single interactive client component.

## 6. Tasks (each: failing test → implement → green → self-review → reviewer)

### Task 1 — Backend: `archive` action + `reset_progress` re-open fix + write-path contract tests

**Why:** `archived` is unreachable today (no action), and `reset_progress` strands the child with all items locked. Both are prerequisites for console requirements #2.

**Files:**
- Modify `backend/supabase/functions/learning-path/index.ts`
- Add `backend/supabase/tests/learning_path_contract.sh` (curl contract checks; exact JSON, run against the live project)

**Step 1 — failing check.** `rg "archive" backend/supabase/functions/learning-path/index.ts` → zero hits (the gap). `git grep -n "state: \"available\"" backend/supabase/functions/learning-path/index.ts` shows only the `/generate` insert — no reset re-open.

**Step 2 — add the `archive` action.** In the PATCH switch add:
```ts
case "archive": {
  const { error } = await supabase.from("learning_paths")
    .update({ status: "archived" }).eq("id", path_id);
  if (error) {
    console.error("learning-path/archive failed:", error);
    return json({ error: "Lernpfad konnte nicht archiviert werden" }, 500);
  }
  return json({ ok: true });
}
```
Update the header comment to list `archive`. Do not touch the auth/scope block — the existing `pathStudentId`/`studentSchoolId` check already covers `archive` because it runs before the switch for every action.

**Step 3 — fix `reset_progress`.** After the existing `path_items` locked-update, re-open the first `unlock_width` by position (mirror `/generate`): load `unlock_width` from the path and `path_items(id, position)` ordered; set `state = "available"` on the first `unlock_width` rows. German error handling identical to the existing block.

**Step 4 — contract tests** `backend/supabase/tests/learning_path_contract.sh` (uses `$SUPABASE_URL`, `$SUPABASE_ANON_KEY`, and a real teacher email/password in env; asserts with `jq`):
- No token on PATCH → 401 `{"error":"Nicht angemeldet"}`.
- Teacher token of school X on a school-Y path id → 403 `{"error":"Kein Zugriff auf diese Klasse"}`.
- `activate` on a draft for a student who already has an active path → 409 with the exact German message (string equality).
- `set_unlock_width` with `0` and `11` → 400 `{"error":"unlock_width muss zwischen 1 und 10 liegen"}`.
- `reorder` with a wrong-length list → 400; full list → `{"ok":true}`.
- `reset_progress` → `{"ok":true}` **and** the first `unlock_width` items are `available`, the rest `locked` (query via PostgREST as the teacher).
- `archive` on the fixture path → `{"ok":true}`, then `status = 'archived'`.
- `reset_progress` on a student with an `active` path must not touch the other path's items.

**Acceptance:** all seven assertions green; `deno check` clean; deployed (`cd backend && supabase functions deploy learning-path`).

**Verify:** `cd backend/supabase/functions && deno check learning-path/index.ts` then `bash backend/supabase/tests/learning_path_contract.sh`.

### Task 2 — Frontend foundation: types, pure stats, server readers

**Files (NEW):** `dashboard/lib/lernpfad/types.ts`, `dashboard/lib/lernpfad/stats.ts`, `dashboard/lib/lernpfad/stats_test.ts`, `dashboard/lib/lernpfad/queries.ts`.

**Step 1 — failing Deno test for the pure logic.** `dashboard/lib/lernpfad/stats_test.ts`:
```ts
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { pathCounts, levelRowsBySkill, slowSkillIds } from "./stats.ts";
```
Cases that must fail until `stats.ts` exists: `pathCounts` over `[{state:"mastered"},{state:"available"},{state:"in_progress"},{state:"skipped"},{state:"locked"}]` → `{ mastered: 1, available: 2 }` (available counts `available` + `in_progress`; skipped/locked excluded); `levelRowsBySkill` buckets `skill_progress` rows by `skill_id` preserving `{level, attempts, correct, best_streak, slow_flag, mastered_at, last_seen_at}` in level order; `slowSkillIds` returns the distinct skill ids where any level has `slow_flag === true`.

**Step 2 — verify fail.** `cd dashboard && deno test lib/lernpfad/stats_test.ts` → fails (module not found).

**Step 3 — implement `stats.ts`** (pure, no supabase import — Deno-runnable).

**Step 4 — `types.ts`** mirrors the DB rows: `LearningPathRow {id, student_id, source_session_id, status: "draft"|"active"|"completed"|"archived", unlock_width, created_at, activated_at, completed_at}`, `PathItemRow {id, path_id, skill_id, position, origin, state, updated_at}`, `SkillProgressRow {level, attempts, correct, best_streak, slow_flag, mastered_at, last_seen_at, ...}`, and `PathPatchResult {ok: true} | {error: string}`.

**Step 5 — `queries.ts`** (server-side, exported async fns taking the server client):
- `getTeacherSchoolId(supabase)` — `teachers(school_id)` for `auth.getUser()`.
- `getClassLearningPaths(supabase, classId)` — `students(id, display_name)` for the class; `learning_paths(id, student_id, status, unlock_width, activated_at, path_items(skill_id, state))` filtered `.in("student_id", studentIds)`; `skill_progress(student_id, skill_id, slow_flag)` `.in("student_id", studentIds)`. Returned shape ready for `stats.ts` (no count logic in the page).
- `getPathDetail(supabase, pathId)` — `learning_paths` row by id, `path_items(skill_id, position, state, origin, skills!inner(id, title_de, description_de, color))` ordered by position, `skill_progress` for the path's student, full `skills` catalog (id, title_de, color) for the add-picker minus the ids already on the path.
- `getStudentOverviewLink(supabase, studentId)` — minimal, reused by the additive link on the student page.

**Acceptance:** Deno test green; `tsc --noEmit` clean; no component imports `supabase` directly for reads.

**Verify:** `cd dashboard && deno test lib/lernpfad/stats_test.ts && npx tsc --noEmit`.

### Task 3 — Class overview: Lernpfade section

**Files (MODIFY):** `dashboard/app/dashboard/klassen/[id]/page.tsx`; **(NEW):** `dashboard/components/PathStatusBadge.tsx`, `dashboard/components/PathStatusRow.tsx`.

**Step 1 — Playwright failing check.** After Task 8's harness exists, assert the class page shows a "Lernpfade" heading (see Task 8 for the spec). Before this task it fails (no section).

**Step 2 — data.** Extend the page: keep the existing student/aggregate queries untouched; add `getClassLearningPaths(supabase, params.id)` from Task 2. Build the per-student map: latest path by `activated_at`/`created_at`, `pathCounts` from its items, `slowSkillIds` from progress.

**Step 3 — UI (server component, additive section between the student list and the Klassen-Übersicht).**
- Heading "Lernpfade" with a German caption "Stand: <date>" (real, from `now()` — no fake analytics).
- One `PathStatusRow` per student (all students, even those without a path): name (link to `/dashboard/lernpfade/<pathId>` only when a path exists), status badge (Entwurf/Aktiv/Abgeschlossen/Archiviert via `PathStatusBadge` — label + colour, never colour-only), mastered/available counts as text ("3 gemeistert · 2 verfügbar"), slow-flag label "Langsames Bearbeiten" as an amber labelled chip when any flag is set.
- Empty state: no student has a path → "Noch keine Lernpfade. Nach einer abgeschlossenen Diagnostik wird automatisch ein Entwurf angelegt."
- No-path per-student row: muted "Kein Lernpfad".

**Acceptance:** every number is computed by `stats.ts` from live queries; zero hardcoded counts; tsc + build clean; no change to existing section markup or StudentRow props.

**Verify:** `cd dashboard && npx tsc --noEmit && npm run build`.

### Task 4 — Path console server page + states

**Files (NEW):** `dashboard/app/dashboard/lernpfade/[pathId]/page.tsx`, `dashboard/app/dashboard/lernpfade/loading.tsx`, `dashboard/app/dashboard/lernpfade/error.tsx`.

**Step 1 — scope guard.** Server page: `auth.getUser()` → redirect `/login`; load path via `getPathDetail`; resolve the student's `classes!inner(school_id)` and compare to `getTeacherSchoolId` — mismatch or missing path → `redirect("/dashboard")` (same pattern as `students/[studentId]`).

**Step 2 — states.**
- `loading.tsx`: skeleton cards (German `aria-label="Wird geladen"`).
- `error.tsx` (client): "Da ist etwas schiefgelaufen." + "Erneut versuchen" button (`error` + `reset`).
- Empty states in the page body: path has zero items → "Dieser Lernpfad hat noch keine Kompetenzen."; student name from the joined query.
- Draft-until-active rule visible: a banner on `draft`/`archived` paths — "Dieser Lernpfad ist für das Kind noch nicht sichtbar. Er wird erst nach dem Aktivieren angezeigt."

**Step 3 — header.** Breadcrumb (Klassen › Klasse › Name), student name, status badge, unlock width, source ("aus Diagnostik vom <datum>" from `activated_at`/`created_at`). Pass `path`, `items`, `progress`, `allSkills` into `PathConsole`.

**Acceptance:** tsc + build clean; direct hit to `/dashboard/lernpfade/<foreign-path>` redirects; draft banner present; `loading.tsx`/`error.tsx` render (Playwright asserts via route interception in Task 8).

**Verify:** `cd dashboard && npx tsc --noEmit && npm run build`.

### Task 5 — PathConsole read view + per-skill progress detail

**Files (NEW):** `dashboard/components/PathConsole.tsx` (read half, `"use client"`).

**Step 1 — Playwright failing check.** Console shows the item list with state badges and, on expanding an item, levels 1–3 with attempts/correct/mastered/slow flag. (Spec in Task 8; fails before this task.)

**Step 2 — render.** Ordered item list (server data, ordered by `position`): position number, `skills.title_de`, state badge (Gesperrt/Freigeschaltet/In Bearbeitung/Gemeistert/Übersprungen — label + colour + icon), `origin === "teacher_added"` chip "Hinzugefügt", colour dot from `skills.color`. Disabled (locked) items rendered but clearly non-interactive for the child — no implication the teacher cannot edit.

**Step 3 — per-skill disclosure.** Each item expands to the level detail from `skill_progress` via `levelRowsBySkill`: rows for levels 1–3, each with "Stufe 1/2/3", attempts/correct ("8 Versuche, 7 richtig"), mastered badge when `mastered_at` set, and a labelled amber "Langsames Bearbeiten" chip when `slow_flag`. Missing rows render "Noch nicht bearbeitet" (real absence, not zero padding).

**Acceptance:** all numbers from `skill_progress` via `stats.ts`; German only; tsc clean; no mutation calls yet.

**Verify:** `cd dashboard && npx tsc --noEmit && npm run build`.

### Task 6 — PathConsole write actions (lifecycle & state)

**Files (NEW):** `dashboard/lib/lernpfad/api.ts`; **(MODIFY):** `dashboard/components/PathConsole.tsx`.

**Step 1 — `api.ts` PATCH wrapper.** Browser client, exact shapes from `index.ts`:
```ts
export async function patchPath(supabase, body: {
  path_id: string; action: string; skill_id?: string; state?: string;
  unlock_width?: number; skill_ids?: string[];
}): Promise<{ ok: true } | { ok: false; status: number; error: string }> {
  const { data, error } = await supabase.functions.invoke("learning-path", { body });
  // data is { ok: true } or { error: string }; surface 409 activate message verbatim.
}
```
`functions.invoke` attaches the teacher's session JWT as `Authorization: Bearer` automatically; if it returns 401, force a `router.refresh()` so the session guard re-fires.

**Step 2 — actions with exact payloads** (each: pending state → call → `router.refresh()` on `ok:true` → inline German error box with the server message on failure):
- **Activate** (draft → active): `{ path_id, action: "activate" }`. On 409 show the backend's message verbatim ("Dieses Kind hat bereits einen aktiven Lernpfad…") with a hint to archive the active one first.
- **Archive**: `{ path_id, action: "archive" }`, confirm dialog: "Lernpfad archivieren? Das Kind sieht diesen Lernpfad danach nicht mehr."
- **Unlock width**: `{ path_id, action: "set_unlock_width", unlock_width }`, `<input type="number">` min 1 max 10, invalid → client-side German error before calling (backend 400 is the backstop).
- **Remove skill**: `{ path_id, action: "remove_skill", skill_id }`, confirm: "Kompetenz <titel> aus dem Lernpfad entfernen? Sie wird nicht wiederhergestellt."
- **Skip / unskip**: `{ path_id, action: "set_state", skill_id, state: "skipped" | "available" }` — skip confirms "Als übersprungen markieren?".
- **Reset progress**: `{ path_id, action: "reset_progress" }`, two-step confirm: "Fortschritt zurücksetzen? Alle Versuche und Meisterungen dieses Kindes in diesem Lernpfad werden gelöscht. Die ersten N Kompetenzen werden wieder freigeschaltet." (N = current unlock_width).

**Acceptance:** every write is via `patchPath` (no direct PostgREST writes anywhere — grep-guard `\.from\("(learning_paths|path_items|skill_progress)"\)\.(insert|update|delete)` in dashboard components → zero hits); tsc clean; all strings German; destructive actions have outcome-stating confirms.

**Verify:** `cd dashboard && npx tsc --noEmit && npm run build`; manual smoke on `npm run dev`.

### Task 7 — PathConsole structural edits: reorder + add skill

**Files (MODIFY):** `dashboard/components/PathConsole.tsx`; `dashboard/lib/lernpfad/api.ts` (already has the body shape).

**Step 1 — reorder (up/down).** Per item, "Nach oben"/"Nach unten" buttons (≥ 44 px, disabled at the ends). On click compute the full reordered `skill_ids` array and call `{ path_id, action: "reorder", skill_ids }` (the RPC requires the **complete** list and exact count — a wrong-length list is a backend 400, surfaced as the German message). After success, `router.refresh()`; the list re-renders server-ordered. No drag-and-drop dependency in this pass (keyboard/one-handed per rubric #4).

**Step 2 — add skill.** A `<select>` populated from `allSkills` minus the path's current skill ids, plus "Kompetenz hinzufügen" button → `{ path_id, action: "add_skill", skill_id }`. The added item is `locked` at the end (backend behaviour); after success the console refreshes and the new item shows; offer the teacher a one-click "Freischalten" (reuses `set_state available`) for the just-added item so a teacher-added skill is immediately usable.

**Acceptance:** reorder disabled for 0/1-item paths; add-picker excludes existing skills (prevents the 23505 duplicate → 400); German strings; tsc clean.

**Verify:** `cd dashboard && npx tsc --noEmit && npm run build`.

### Task 8 — Playwright e2e harness + smoke specs

**Files (NEW):** `dashboard/e2e/playwright.config.ts`, `dashboard/e2e/teacher-console.spec.ts`, `backend/supabase/tests/fixture_p4_console.sql`, `backend/supabase/tests/fixture_p4_cleanup.sql`.

**Step 1 — harness.** Add `@playwright/test` to `dashboard/package.json` devDependencies; `playwright.config.ts` with `baseURL: http://localhost:3000`, one project (chromium), env: `PLAYWRIGHT_TEACHER_EMAIL`, `PLAYWRIGHT_TEACHER_PASSWORD` (a real pilot teacher on the live project).

**Step 2 — fixture.** `fixture_p4_console.sql` (owner/psql, run with `psql -v student_id=<uuid>`): ensures the target student has exactly one `learning_paths` row — a `draft` path with 4 `path_items` from the live `skills` table (first 4 ids), one `skill_progress` row (level 1, attempts 8, correct 7, `slow_flag = true`) and one level-3 row with `slow_flag = false`, so both states are real data. `fixture_p4_cleanup.sql` deletes exactly those rows.

**Step 3 — specs** (all assertions on real live data, never hardcoded values):
- Overview: login → open the class page → the "Lernpfade" section lists the student with the seeded draft, badge "Entwurf", counts text, and the slow-flag chip; the German empty state shows when a student has no path.
- Console read: open `/dashboard/lernpfade/<seeded>`, assert item order, state badges, and the expanded level detail (Stufe 1: "8 Versuche, 7 richtig", slow chip; Stufe 2: "Noch nicht bearbeitet").
- Console writes: set unlock width → 2; skip an item; reorder (assert new order after refresh); activate → status badge "Aktiv"; attempt a second activate on a second draft → the exact 409 message renders; archive → "Archiviert".
- States: route interception (`page.route`) fails the path query → error.tsx renders with "Erneut versuchen"; reload after success.
- Regression: `foerderplan/[sessionId]` and the student list (StudentRow) still render after all changes.

**Acceptance:** `cd dashboard && npx playwright test` green against `npm run dev` + live project; fixture create/cleanup round-trips (cleanup leaves the DB as it was).

**Verify:** `cd dashboard && npx playwright test` (with `npm run dev` running and env set).

### Task 9 — German / legal / visual / critic gate pass

- `rg -i "imint|pikas|senbjf|schulz|lisum" dashboard/backend-changed-files` → zero hits.
- `rg -i "kaufen|Lizenz kaufen|Abo|Preis" dashboard/app dashboard/components dashboard/lib` → zero hits in new code.
- Rubric sweep at 1280×800, 1024×768, 390×844 (Playwright screenshot pass): no overflow, no clipped German text, no < 14 px critical info, no colour-only states (every state has a label), controls ≥ 44 px.
- Fresh-context critic runs the teacher-usability rubric against the running app and reports the single biggest remaining gap; fix and re-review until no findings (twice consecutively, per §6).

**Verify:** grep commands above; screenshots reviewed; critic sign-off note appended to the plan.

### Task 10 — Full gates + regression

- `cd dashboard && npx tsc --noEmit && npm run build`
- `cd backend/supabase/functions && deno test --allow-net _shared/`
- `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/tests/schema_learning_path.sql` → `SCHEMA OK`; `-f backend/supabase/tests/rls_learning_path.sql` → `RLS OK`
- `bash backend/supabase/tests/learning_path_contract.sh` → all assertions green
- `cd dashboard && npx playwright test` → all specs green (incl. foerderplan + StudentRow regression)
- Record exact outputs in the plan appendix (per P2 convention).

**Verify:** all commands above; record results.

## 7. Verification gates (per task)

- Task-level verify command listed in each task is green before moving on.
- No English UI strings in any new file; no direct PostgREST writes in dashboard components (grep-guard from Task 6).
- Backend changes keep `deno check` clean and the live project's RLS tests green.

## 8. Known gaps / deferred (explicitly out of P4 scope)

- **`completed` status is unreachable.** The schema allows it; no PATCH action sets it. The console covers draft/active/archived; auto-completion when all items are mastered is deferred to the integration phase.
- **Reset is destructive, not soft.** `reset_progress` deletes `skill_progress` rows irrevocably (rubric #3 asks destructive actions to be recoverable). Mitigated with a two-step outcome-stating confirm; a soft-delete/backup of progress is deferred.
- **Teacher-added skills start locked** and stay locked if the unlock window is full; the console's one-click "Freischalten" after add covers the common case, but window-pressure semantics are backend behaviour and unchanged.
- **Class code rotation, re-test scheduling and print view** (spec §3 P4 row) are not in this workstream; the console links out to the existing Förderplan print exports.
- **Playwright specs need the live project + a pilot teacher credential**; they are the UI acceptance harness, not a CI unit suite (dashboard has no jest/vitest, and none is added).
