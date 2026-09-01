# P4 Task 1 — Backend fixes (reset re-open + archive action)

**Status:** COMPLETE

**Date:** 2026-09-01

## Changes

- `backend/supabase/functions/learning-path/index.ts`
  - `reset_progress`: now re-opens the unlock window after deleting
    `skill_progress` and locking every item — the first `unlock_width` items by
    `position` become `available`, the rest stay `locked`, mirroring
    `/generate`'s `idx < unlock_width → available` rule. A reset path is
    immediately playable by the child.
  - New PATCH action `archive`: sets `status = 'archived'` (schema-allowed
    values: draft/active/completed/archived). Teacher-scoped by the existing
    pre-switch `pathStudentId`/`studentSchoolId` check (unchanged). Idempotent:
    archiving an already-archived path is a no-op `{ ok: true }`.
  - Header comment now lists `archive`.
- `backend/supabase/functions/_shared/path_actions.ts` (NEW) — pure, testable
  helpers wired into index.ts:
  - `unlockWindowStates(items, unlockWidth)` — the reset-window computation.
  - `archiveTransitionError(status)` — archive validation against the schema
    status set.
- `backend/supabase/functions/_shared/path_actions_test.ts` (NEW) — 7 unit
  tests for the above.

## Scope note

- **`completed` auto-completion:** deferred, per plan §8 ("auto-completion when
  all items are mastered is deferred to the integration phase"). Not implemented
  in this task.
- **Contract curl script** (`learning_path_contract.sh`, plan Task 1 Step 4)
  requires the live project + teacher credentials and is outside this task's
  verify list; the pure logic is covered by the Deno unit tests instead.

## Tests

- `cd backend/supabase/functions && deno test --allow-net _shared/` → **30 passed,
  0 failed** (23 existing + 7 new).
- `deno check learning-path/index.ts` → clean.
- RLS SQL tests: **unchanged** (zero SQL touched); not run locally
  (`SUPABASE_DB_URL` unset in this environment, requires live project).
- Legal gate: `rg -i "imint|pikas|senbjf|schulz|lisum|kaufen|Lizenz kaufen"` on
  all changed/new files → zero hits.

## Output

```
ok | 30 passed | 0 failed (608ms)
Check file:///.../_shared/path_actions_test.ts ... ok
Check learning-path/index.ts ... ok
```

## Concerns

- `completed` status still unreachable (deferred by plan).
- Archive of a `completed` path is permitted (schema-legal); console only offers
  archive on draft/active views — acceptable.
- Live RLS SQL + contract checks need `$SUPABASE_DB_URL` and a pilot teacher;
  verify in the deployment gate (Task 10).
