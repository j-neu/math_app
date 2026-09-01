# P4 Tasks 5-8 — PathConsole (read/write) + Playwright teacher-console smoke

**Status:** COMPLETE

**Date:** 2026-09-01

**Branch:** `gauntlet/p2-p3-p4`

## Changes

- `dashboard/lib/lernpfad/api.ts` (NEW) — client PATCH wrapper `patchPath(supabase, body)`.
  Calls `supabase.functions.invoke("learning-path", { method: "PATCH", body })` so the edge
  function's PATCH switch (activate/archive/set_unlock_width/add_skill/remove_skill/
  set_state/reorder/reset_progress) is hit — `functions.invoke` defaults to POST, which would
  fall into the function's `/generate` branch and fail with "session_id fehlt". The browser
  supabase client attaches the teacher JWT as Bearer automatically. Non-2xx responses are
  parsed via `FunctionsHttpError.context.json()` and surfaced **verbatim** (409 activation
  message, 400 unlock_width message). The caller forces `router.refresh()` on 401.
- `dashboard/components/PathConsole.tsx` (MODIFY, `"use client"`) — the full interactive console:
  - Read view: items ordered by `position` (number, `skills.title_de`, colour dot from
    `skills.color`, description in the disclosure, state badge with label + icon + colour for
    Gesperrt/Freigeschaltet/In Bearbeitung/Gemeistert/Übersprungen, "Hinzugefügt" chip for
    `teacher_added`), per-item amber "Langsames Bearbeiten" chip, path status via
    `PathStatusBadge`.
  - Per-skill disclosure (Task 5/7 deliverable 4): levels 1-3 from `levelRowsBySkill(progress)`
    — "Stufe N", "X Versuche, Y richtig", "Gemeistert" badge on `mastered_at`, amber labelled
    "Langsames Bearbeiten" chip on `slow_flag`, "Noch nicht bearbeitet" for absent rows (real
    absence, never zero padding).
  - Writes via `patchPath` only (no direct PostgREST writes): Aktivieren (confirm states the
    outcome; on 409 the backend message renders verbatim plus a hint to archive the active
    path), Archivieren (confirm "Archivieren? Der Lernpfad wird für das Kind unsichtbar."),
    unlock width (number input 1-10, client-side German validation, backend 400 backstop),
    add skill (picker from `allSkills`, the not-on-path catalog; locked at the end), remove
    (confirm "…wird nicht wiederhergestellt"), skip (confirm "Als übersprungen markieren?")
    / unskip ("Wieder freigeben") / "Freischalten" for locked items (covers the just-added
    skill), reorder via "Nach oben"/"Nach unten" (≥44 px, disabled at ends; sends the complete
    `skill_ids` list), reset (two-step German confirm naming N = current unlock_width).
  - Every mutation: pending "Wird gespeichert…" → `router.refresh()` on success → inline
    `role="alert"` error box with the server message on failure. All strings German.
- `dashboard/app/dashboard/lernpfade/[pathId]/page.tsx` (MODIFY) — the placeholder wiring was
  already in place from Task 4; the page passes `path/items/progress/allSkills` into the now
  real console unchanged (no other edits required).
- `dashboard/e2e/playwright.config.ts` (NEW) — `testDir: "."` (config lives in `e2e/`),
  chromium project, `baseURL: http://localhost:3000`, `workers: 1`,
  `globalSetup: ./global-setup.mjs`, `globalTeardown: ./global-teardown.mjs`.
- `dashboard/e2e/global-setup.mjs` / `global-teardown.mjs` (NEW) — run the seed / cleanup.
- `dashboard/e2e/seed-fixture.mjs` (NEW) — programmatic fixture via the Supabase REST + Auth
  admin APIs with the service role key from `dashboard/.env.local` (no psql): creates a
  dedicated confirmed e2e teacher (`POST /auth/v1/admin/users`), a school, a class, a student,
  a DRAFT learning path A with 4 real `path_items` (first `unlock_width` available) and
  `skill_progress` level 1 (8/7, slow) + level 3 (not slow, level 2 absent), plus a second
  DRAFT path B for the second-activate 409 check. Idempotent: purges prior `e2e-teacher-*`
  users and `E2E Schule *` schools first. Writes `e2e/.fixture.json`.
- `dashboard/e2e/cleanup-fixture.mjs` (NEW) — deletes exactly those rows (FK order) and the
  fixture file; a no-op when nothing is registered.
- `dashboard/e2e/teacher-console.spec.ts` (NEW) — 5 resilient German-text smoke specs:
  class overview shows the draft + slow-flag chip; console read view with expanded level
  detail; writes (unlock width 2, skip, reorder, activate → "Aktiv" + draft banner gone);
  second activate on path B → exact 409 message; archive (confirm) → "Archiviert".
- `dashboard/package.json` / `package-lock.json` (MODIFY) — `@playwright/test` devDependency;
  scripts `e2e`, `e2e:seed`, `e2e:cleanup`.
- `dashboard/.gitignore` (MODIFY) — `/test-results/`, `/playwright-report/`, `/e2e/.fixture.json`.
- `backend/supabase/functions/learning-path/index.ts` (MODIFY) — the deployed function's CORS
  preflight lacked `Access-Control-Allow-Methods`, so the browser blocked the PATCH preflight
  (`functions.invoke` POST passes the gateway, PATCH does not). Added
  `Access-Control-Allow-Methods: POST, GET, PUT, PATCH, DELETE, OPTIONS` to `corsHeaders` and
  deployed (`supabase functions deploy learning-path`). Verified via a raw preflight probe
  (allow-methods now returned) and the green e2e write specs.

## Verify

```
cd dashboard && npx tsc --noEmit                 → clean (exit 0)
cd dashboard && npm run build                    → clean (exit 0)
cd backend/supabase/functions && deno check learning-path/index.ts → clean
cd dashboard && npx playwright test --config e2e/playwright.config.ts → 5 passed (28.5s)
```
(e2e ran against `npm run dev` + the live Supabase project; fixture seeded/cleaned by
globalSetup/globalTeardown, so the run leaves the DB as it was. One gotcha: `npm run build`
must not run while `next dev` is up — they share `.next`; noted in the report below.)

Legal gate over `dashboard/lib/lernpfad`, `dashboard/components/PathConsole.tsx`,
`dashboard/app/dashboard/lernpfade`, `dashboard/e2e`:
`imint|pikas|senbjf|schulz|lisum|kaufen` → zero hits.

## Concerns

- **Backend CORS deploy was required for the dashboard deliverable.** The console's PATCH
  writes were blocked by the deployed function's preflight response; the fix
  (Access-Control-Allow-Methods) is a one-line backend change already deployed. Without it the
  browser never lets PATCH through, so the write console cannot work — flagged because Tasks 5-8
  are nominally dashboard-only.
- **`.fixture.json` is a runtime artifact** (gitignored); the spec loads it in `beforeAll` after
  globalSetup. Running the spec without the seed (e.g. `--no-global-setup`) fails with a clear
  German message.
- The e2e suite is a live-project smoke (per plan §8), not a CI unit suite: tests are ordered
  and share one fixture, so a failure in the write test cascades into the later ones.
- The `role="status"` badges render fine for assistive tech (verified via the accessibility
  snapshot), but Playwright's `getByRole(name)` filter does not match their computed name; the
  spec uses `getByRole("status").filter({ hasText })` instead — a test-side workaround only.
- `getStudentOverviewLink` (Task 2) is still not wired to the student page (additive link lands
  in a later task per plan §5).
