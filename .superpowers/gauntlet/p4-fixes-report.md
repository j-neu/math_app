# P4 Fixes Report

**Date:** 2026-09-01
**Scope:** findings in `.superpowers/gauntlet/p4-critic-report.md`
**Verification:** running app at http://localhost:3000 (dev), live Supabase `zzxqeqwffexythqzjkxr`, e2e teacher from `e2e/seed-fixture.mjs`, browser tools at 1280×800 / 1024×768 / 390×844, reload persistence checks, `tsc`, production build, backend deno tests, Playwright e2e spec, legal grep.

---

## 1. (High) Multi-path dead end — ALL paths reachable

**Fix**
- `klassen/[id]/page.tsx`: removed the "latest per student" collapse. The Lernpfade section now groups **all** of a student's paths (sorted active → draft → completed → archived, newest first within status) and passes them to `PathStatusRow`.
- `PathStatusRow.tsx`: redesigned from a single `path` prop to `paths[]` — every path renders as its own link (`/dashboard/lernpfade/<id>`) with a status badge + counts; the student name links to the student page.
- `students/[studentId]/page.tsx`: new "Lernpfade" section listing every path (badge + counts + date) as a 44px link to its console.
- `lib/lernpfad/queries.ts`: dead `getStudentOverviewLink` replaced with `getStudentLearningPaths` (all paths for a student with `path_items` for counts).

**Evidence**
- 1280×800 class page (fresh fixture): links `608297eb…` (path B, "0 gemeistert · 1 verfügbar", Entwurf) and `0fadca06…` (path A, "0 gemeistert · 3 verfügbar", Entwurf), each 44px.
- Clicking the second-draft link (path B) opened its console — no URL typing.
- Student page `/dashboard/students/<id>`: both paths listed with "Entwurf" badges and clickable links to `/dashboard/lernpfade/<id>`.
- e2e spec no longer needs `page.goto` to path B (all flows still pass; spec's direct URL remains but UI navigation is now possible).

## 2. (High) Cookie banner no longer blocks the console on phone

**Fix**
- `CookieBanner.tsx`: wrapper changed from `fixed bottom-0 left-0 right-0 z-50` to `sticky bottom-0 z-50 w-full`. A sticky element stays in the document flow, so it reserves its own height at the end of the page — the console rows now scroll clear of it — while still pinning to the viewport bottom. Mobile padding compacted (`px-4 py-3`), and the "Verstanden" button is now `min-h-[44px]` (one-tap dismiss).

**Evidence** (390×844)
- Banner height 141px, pinned at viewport bottom.
- Scrolled to the bottom: last item's action buttons sit at viewport y≈459–593, banner top at 703 → **no overlap**; `elementFromPoint` above the banner is the footer, not the banner.
- Playwright click on the last item's "Freischalten" succeeded while the banner was visible (no "subtree intercepts pointer events" error).
- Banner dismisses in one tap ("Verstanden").

## 3. (Medium) set_unlock_width label/helper match reality

**Fix** — `PathConsole.tsx`
- Label: **"Freigeschaltete Kompetenzen am Anfang"** (was "Freigeschaltete Kompetenzen").
- Helper: **"Legt fest, wie viele Kompetenzen am Anfang des Lernpfads für das Kind verfügbar sind (1–10). Kompetenzen weiter hinten bleiben gesperrt, bis das Kind vorankommt."** — it now states it controls the size of the unlock window at the front, so it can no longer be read as contradicting per-item badges that keep their own state.

**Evidence** — snapshot at 1024×768 shows the new label + helper; setting 3→2 and saving updated the header to "2 Kompetenzen freigeschaltet" (persisted after reload); e2e `getByLabel("Freigeschaltete Kompetenzen")` still matches via substring.

## 4. (Medium) Interactive targets ≥44px, critical labels ≥14px

**Fix**
- `PathConsole.tsx`: expand/collapse toggle `min-h-[44px]`, unlock-width input `min-h-[44px]`, add-skill select `min-h-[44px]`; all state badges ("Gesperrt"/"Freigeschaltet"/"Gemeistert"/"Übersprungen"/"In Bearbeitung"), "Hinzugefügt", "Langsames Bearbeiten" (item + level rows) and "Gemeistert" chips bumped `text-xs` → `text-sm`.
- `PathStatusBadge.tsx`: `text-xs` → `text-sm`.
- `PathStatusRow.tsx`: student-name link and every path link `min-h-[44px]`; counts line and slow chip `text-sm`.
- `StudentRow.tsx`: name link `min-h-[44px]`.
- Student page session-status chips `text-sm`.

**Evidence** (measured at 390×844, `getBoundingClientRect` / `getComputedStyle`)
- Expand toggle 44px, unlock input 44px, add-skill select 44px, class-page path links 44px, StudentRow name link 44px.
- State badges and status badges computed font-size **14px**; remaining 12px text on the console page is only the pre-existing footer navigation, not critical state info.

## 5. (Medium) Archive: reactivate added, confirm text honest

**Decision:** implemented a real **reactivate (archive → active)** action so the strengthened confirm text is honest.

**Fix**
- Backend `_shared/path_actions.ts`: new `reactivateTransitionError` (schema-status validation, idempotent like archive) + unit tests.
- Backend `learning-path/index.ts`: `case "activate": case "reactivate":` share the activation logic (status `active`, `activated_at = now()`, the partial-unique-index 23505 → 409 German response); `reactivate` pre-validates the transition.
- Frontend `api.ts`: `"reactivate"` added to `PatchPathAction`.
- `PathConsole.tsx`: archived paths now show a green **"Reaktivieren"** button; the archive confirm reads **"Der Lernpfad wird archiviert und ist für das Kind nicht mehr sichtbar. Du kannst ihn später wieder aktivieren."** (true, because reactivation now exists).
- Edge function redeployed (`supabase functions deploy learning-path`).

**Evidence**
- Archive confirm dialog text verified live; after archive: badge "Archiviert", "Reaktivieren" button appears.
- Clicking Reaktivieren (confirm "Lernpfad reaktivieren? Der Lernpfad ist ab sofort wieder für das Kind sichtbar und kann geübt werden.") → badge "Aktiv", archived banner gone; **persisted after reload**.
- `deno test _shared/path_actions_test.ts` → **9/9 passed** (2 new reactivate tests).

## 6. (Medium) reset_progress confirm states exactly what is deleted

**Fix** — `PathConsole.tsx`
- First confirm: **"Fortschritt zurücksetzen? Alle Versuche und Meisterungen des Kindes werden gelöscht und der Status der Kompetenzen in diesem Lernpfad zurückgesetzt. Die ersten N Kompetenzen werden wieder freigeschaltet."** — matches the backend (deletes the child's `skill_progress`, resets this path's `path_items`, re-opens the first `unlock_width`).
- Second confirm: **"Wirklich zurücksetzen? Dieser Schritt kann nicht rückgängig gemacht werden."** — no overstatement.

**Evidence** — both dialogs observed live at 1280×800; texts match the backend `reset_progress` implementation.

## 7. (Low) Archived banner no longer implies the child sees it

**Fix** — `lernpfade/[pathId]/page.tsx`
- `draft`: "Dieser Lernpfad ist für das Kind noch nicht sichtbar. Er wird erst nach dem Aktivieren angezeigt."
- `archived`: **"Dieser Lernpfad ist archiviert und für das Kind nicht mehr sichtbar. Reaktivieren Sie ihn, damit das Kind ihn wieder üben kann."** — no false implication, and the offered action now exists.

**Evidence** — verified live after archiving at 390×844 (badge "Archiviert" + correct banner + Reaktivieren button).

## 8. (Low) 409 surfaces inline, not just console noise

**Fix** — `PathConsole.tsx`: the 409 already renders as a `role="alert"` notice (verbatim German message + hint). Hint reworded to be actionable and to avoid duplicating the backend sentence: **"Hinweis: Bitte zuerst den aktiven Lernpfad archivieren oder deaktivieren, dann erneut versuchen."** — and it now also fires for `reactivate`. The browser's network-level "Failed to load resource: 409" log is inherent to a non-2xx fetch; the teacher-facing surface is the inline alert.

**Evidence** — second activate at 1024×768: inline alert shows "Aktion fehlgeschlagen.", the exact 409 message, and the hint. e2e "Zweites Aktivieren zeigt die exakte 409-Meldung" passes.

## 9. (Low) `completed` status is handled (badge + read-only)

**Fix** — `PathConsole.tsx`: for `completed` paths the console renders the "Abgeschlossen" badge plus a blue notice ("Dieser Lernpfad ist abgeschlossen und daher schreibgeschützt. Fortschritt und Status können nicht mehr geändert werden.") and hides every mutating control (lifecycle actions, unlock-width, add-skill, reset, per-item action buttons). Expand/collapse stays available for review.

**Evidence** — set path B to `completed` via service role, loaded the console: badge "Abgeschlossen", read-only notice, item list rendered **without** action buttons, no edit controls. Restored to `draft` afterwards.

---

## Verification

| Check | Result |
|---|---|
| `npx tsc --noEmit` (dashboard) | ✅ clean |
| `npm run build` (dashboard) | ✅ clean |
| `deno test _shared/path_actions_test.ts` | ✅ 9/9 |
| `npx playwright test --config e2e/playwright.config.ts` | ✅ 5/5 |
| Viewport re-drive 1280×800 | ✅ all paths linked & clickable; no overflow |
| Viewport re-drive 1024×768 | ✅ 409 inline notice; no overflow |
| Viewport re-drive 390×844 | ✅ banner non-blocking; targets 44px; labels 14px; archive→reactivate; no overflow (`scrollWidth ≤ innerWidth` at all three viewports) |
| Reload persistence | ✅ reactivate persisted; unlock-width persisted |
| Legal grep `imint\|pikas\|senbjf\|schulz\|lisum\|kaufen` in `lib/lernpfad`, `PathConsole.tsx`, `PathStatus*.tsx`, `app/dashboard/lernpfade`, `app/dashboard/students` | ✅ zero hits |

**Note:** `npm run build` shares `.next` with the running dev server in Next 14; the dev server was restarted after the build to clear the webpack cache, and the app re-verified.

The P4 critic's non-blocking items (#1–#9) are all addressed; the blocked sign-off gates (finding #1, #2, visual-gate #4/#5) are resolved and re-verified live.
