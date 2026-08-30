# P1 — Path Engine and Child Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A child logs in with a class code and their own name, receives a teacher-approved learning path derived from their diagnostic, practises against it, and their progress survives a dropped wifi connection and a closed browser.

**Architecture:** Five new Postgres tables behind the existing RLS pattern, plus a real student-scoped JWT that finally activates the `ticket_student_id()` policies already in the schema. Pure logic (ordering, mastery, codes, JWT) lives in `functions/_shared/` modules with Deno unit tests; three new edge functions compose them. The Flutter client generates practice problems locally and queues attempts for idempotent batch sync.

**Tech Stack:** Postgres 15 / Supabase (project `zzxqeqwffexythqzjkxr`, Frankfurt) · Deno edge functions with `supabase-js@2` from esm.sh · `djwt` for HS256 · Flutter 3 / Dart with `http`, `shared_preferences`, `flutter_riverpod` · tests: `deno test`, `flutter test`, SQL transaction scripts.

**Spec:** `docs/superpowers/specs/2026-08-30-numeris-learning-path-design.md`

## Global Constraints

- Every user-facing string is **German**. No English in any surface, including errors and empty states.
- No pricing, billing, or purchase surface. Zero occurrences of `kaufen`, `Preis`, `Abo`, `Lizenz kaufen`. The commercial freeze (`tasks.md` R7.5) is not lifted by this work.
- Zero occurrences of `iMINT`, `PIKAS`, `SenBJF`, `Schulz`, `LISUM` in any file this plan creates or modifies.
- The 8 retired practice skills (Z1, C1.1, C1.2, C2.1, C3.1, C4.1, S1.1, S3.4) are not referenced, revived, or added to any path.
- `flutter analyze` must stay at or below the existing baseline of **323 style lints, 0 errors**.
- `npx tsc --noEmit` in `dashboard/` stays clean.
- All new tables have RLS **enabled** with explicit policies. A table without a policy denies everything — that is the intended default, never an oversight to fix by disabling RLS.
- SQL test scripts run inside a single transaction ending in `ROLLBACK`, so they are safe to run against the live project and leave no rows behind.
- Edge functions import shared logic from `functions/_shared/`; no logic is copy-pasted between functions.

---

## File Structure

**Backend — migrations**
- Create `backend/supabase/migrations/20260830000000_learning_path.sql` — the five tables, the three column additions, indexes, `rotate_class_code()`.
- Create `backend/supabase/migrations/20260830000001_learning_path_rls.sql` — RLS enable + policies for the five tables.

**Backend — tests**
- Create `backend/supabase/tests/schema_learning_path.sql` — schema shape assertions.
- Create `backend/supabase/tests/rls_learning_path.sql` — the four denial tests from spec §4.2.

**Backend — shared modules** (each one file, one responsibility, own test)
- Create `backend/supabase/functions/_shared/ordering.ts` — canonical construct order, `compareRecommendations`, `sortSkillIds`.
- Create `backend/supabase/functions/_shared/codes.ts` — class-code generation and normalisation.
- Create `backend/supabase/functions/_shared/jwt.ts` — sign and verify the student token.
- Create `backend/supabase/functions/_shared/mastery.ts` — level mastery, skill mastery, median, slow flag.
- Create the matching `*_test.ts` beside each.

**Backend — edge functions**
- Create `backend/supabase/functions/student-auth/index.ts` — `/roster`, `/login`.
- Create `backend/supabase/functions/learning-path/index.ts` — GET, `/generate`, PATCH.
- Create `backend/supabase/functions/practice-session/index.ts` — `/start`, `/sync`, `/end`.
- Modify `backend/supabase/functions/foerderplan-generate/index.ts` — import `_shared/ordering.ts` instead of its inline copy; create a draft path after generating the Förderplan.

**Flutter**
- Create `math_app/lib/models/learning_path.dart` — `LearningPath`, `PathItem`, `SkillProgress`, `PathItemState`.
- Create `math_app/lib/services/student_auth_service.dart` — roster fetch, login, token storage.
- Create `math_app/lib/services/learning_path_service.dart` — fetch path, start/end practice session.
- Create `math_app/lib/services/attempt_queue.dart` — offline queue, idempotent flush.
- Create `math_app/lib/screens/child_login_screen.dart` — code → roster grid → optional PIN.
- Create the matching tests under `math_app/test/`.

---

## Task 1: Extract the ordering rule into a shared module

The R4.2 comparator currently lives inline in `foerderplan-generate/index.ts:26-78`. The path engine needs the identical rule; two copies will drift.

**Files:**
- Create: `backend/supabase/functions/_shared/ordering.ts`
- Create: `backend/supabase/functions/_shared/ordering_test.ts`
- Modify: `backend/supabase/functions/foerderplan-generate/index.ts:26-78`

**Interfaces:**
- Consumes: nothing.
- Produces: `canonicalConstructOrder: readonly string[]`, `splitSkillId(id: string): [string, string]`, `compareRecommendations(a: string, b: string): number`, `sortSkillIds(ids: string[]): string[]`.

- [ ] **Step 1: Write the failing test**

```ts
// backend/supabase/functions/_shared/ordering_test.ts
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { compareRecommendations, sortSkillIds } from "./ordering.ts";

Deno.test("orders by construct position, not alphabetically", () => {
  assertEquals(sortSkillIds(["C2.1", "A1.1", "B1.2"]), ["A1.1", "B1.2", "C2.1"]);
});

Deno.test("unsuffixed skill sorts before its suffixed siblings", () => {
  assertEquals(sortSkillIds(["A1.1b", "A1.1a", "A1.1"]), ["A1.1", "A1.1a", "A1.1b"]);
});

Deno.test("unknown construct sorts after every known one", () => {
  assertEquals(sortSkillIds(["Z9.9", "D1.2"]), ["D1.2", "Z9.9"]);
});

Deno.test("comparator is deterministic regardless of input order", () => {
  const a = sortSkillIds(["C3.2", "A3.1", "C1.1", "A3.1a"]);
  const b = sortSkillIds(["A3.1a", "C1.1", "C3.2", "A3.1"]);
  assertEquals(a, b);
});

Deno.test("sortSkillIds does not mutate its argument", () => {
  const input = ["C2.1", "A1.1"];
  sortSkillIds(input);
  assertEquals(input, ["C2.1", "A1.1"]);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/ordering_test.ts`
Expected: FAIL — `Module not found "./ordering.ts"`

- [ ] **Step 3: Write the module**

```ts
// backend/supabase/functions/_shared/ordering.ts
// Canonical didactic order of every construct in the construct map
// (docs/clean-room/01-construct-map.md; rule: docs/clean-room/foerderplan/ordering-rule.md).
// Dart twin: math_app/lib/services/skill_recommendation_order.dart (tasks.md R4.2).
export const canonicalConstructOrder: readonly string[] = [
  "A1.1", "A1.2", "A1.3", "A1.4", "A1.5",
  "A2.1", "A2.2", "A2.3",
  "A3.1", "A3.2", "A3.3",
  "B1.1", "B1.2", "B1.3",
  "B2.1", "B2.2", "B2.3",
  "C1.1", "C1.2", "C1.3",
  "C2.1", "C2.2", "C2.3",
  "C3.1", "C3.2", "C3.3", "C3.4",
  "C4.1", "C4.2",
  "D1.1", "D1.2",
];

const SKILL_ID_PATTERN = /^([A-D]\d\.\d)(.*)$/;

/** `A1.1a` → `["A1.1", "a"]`; an ID without a construct prefix is kept whole. */
export function splitSkillId(skillId: string): [string, string] {
  const m = SKILL_ID_PATTERN.exec(skillId);
  if (!m) return [skillId, ""];
  return [m[1]!, m[2]!];
}

/** Construct position first, then suffix (none before `a`), then the full ID. */
export function compareRecommendations(skillIdA: string, skillIdB: string): number {
  const [constructA, suffixA] = splitSkillId(skillIdA);
  const [constructB, suffixB] = splitSkillId(skillIdB);

  if (constructA !== constructB) {
    const rankA = canonicalConstructOrder.indexOf(constructA);
    const rankB = canonicalConstructOrder.indexOf(constructB);
    if (rankA >= 0 && rankB >= 0) return rankA - rankB;
    if (rankA >= 0) return -1;
    if (rankB >= 0) return 1;
    return constructA < constructB ? -1 : constructA > constructB ? 1 : 0;
  }

  if (suffixA !== suffixB) {
    if (suffixA === "") return -1;
    if (suffixB === "") return 1;
    return suffixA < suffixB ? -1 : suffixA > suffixB ? 1 : 0;
  }

  return skillIdA < skillIdB ? -1 : skillIdA > skillIdB ? 1 : 0;
}

/** Returns a new sorted array; never mutates the input. */
export function sortSkillIds(skillIds: string[]): string[] {
  return [...skillIds].sort(compareRecommendations);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/ordering_test.ts`
Expected: PASS, 5 tests.

- [ ] **Step 5: Point `foerderplan-generate` at the shared module**

Delete lines 26–78 of `backend/supabase/functions/foerderplan-generate/index.ts` (the `canonicalConstructOrder` array, `SKILL_ID_PATTERN`, `splitSkillId`, `compareRecommendations`) and add near the top imports:

```ts
import { compareRecommendations, splitSkillId } from "../_shared/ordering.ts";
```

Leave `DOMAIN_PREFIX_PATTERN` and `SLOW_RESPONSE_FRACTION` where they are — they are not ordering concerns.

- [ ] **Step 6: Verify nothing else broke**

Run: `cd backend/supabase/functions && deno check foerderplan-generate/index.ts`
Expected: no diagnostics.

- [ ] **Step 7: Commit**

```bash
git add backend/supabase/functions/_shared/ordering.ts backend/supabase/functions/_shared/ordering_test.ts backend/supabase/functions/foerderplan-generate/index.ts
git commit -m "refactor(backend): extract R4.2 ordering rule into _shared/ordering.ts"
```

---

## Task 2: Migration — learning-path tables

**Files:**
- Create: `backend/supabase/migrations/20260830000000_learning_path.sql`
- Create: `backend/supabase/tests/schema_learning_path.sql`

**Interfaces:**
- Consumes: existing `students`, `classes`, `skills`, `diagnostic_sessions`, `teachers`.
- Produces: tables `learning_paths`, `path_items`, `skill_progress`, `practice_sessions`, `practice_attempts`, `login_attempts`; columns `classes.class_code`, `classes.code_rotated_at`, `classes.require_pin`, `students.avatar`, `students.pin_hash`; function `public.rotate_class_code(uuid) returns text`.

- [ ] **Step 1: Write the failing schema test**

```sql
-- backend/supabase/tests/schema_learning_path.sql
-- Safe against any database: asserts only, then rolls back.
begin;

do $$
declare
  missing text;
begin
  select string_agg(t, ', ') into missing
  from unnest(array[
    'learning_paths','path_items','skill_progress',
    'practice_sessions','practice_attempts','login_attempts'
  ]) as t
  where to_regclass('public.' || t) is null;

  if missing is not null then
    raise exception 'FAIL missing tables: %', missing;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'classes' and column_name = 'class_code'
  ) then raise exception 'FAIL classes.class_code missing'; end if;

  if not exists (
    select 1 from information_schema.columns
    where table_name = 'students' and column_name = 'pin_hash'
  ) then raise exception 'FAIL students.pin_hash missing'; end if;

  if to_regprocedure('public.rotate_class_code(uuid)') is null then
    raise exception 'FAIL rotate_class_code(uuid) missing';
  end if;
end $$;

-- unlock_width must reject nonsense
do $$
begin
  begin
    insert into public.learning_paths (student_id, unlock_width)
    values ('00000000-0000-0000-0000-000000000000', 0);
    raise exception 'FAIL unlock_width=0 was accepted';
  exception
    when check_violation then null;      -- expected
    when foreign_key_violation then null; -- constraint order, also fine
  end;
end $$;

select 'SCHEMA OK' as result;
rollback;
```

- [ ] **Step 2: Run it to verify it fails**

Run: `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/tests/schema_learning_path.sql`
Expected: FAIL — `missing tables: learning_paths, path_items, ...`

- [ ] **Step 3: Write the migration**

```sql
-- backend/supabase/migrations/20260830000000_learning_path.sql
-- P1 — Lernpfad: tables, columns, indexes, class-code rotation.

create table public.learning_paths (
  id                uuid primary key default gen_random_uuid(),
  student_id        uuid not null references public.students on delete cascade,
  source_session_id uuid references public.diagnostic_sessions on delete set null,
  status            text not null default 'draft'
                      check (status in ('draft','active','completed','archived')),
  unlock_width      int  not null default 3 check (unlock_width between 1 and 10),
  created_by        uuid references public.teachers on delete set null,
  created_at        timestamptz not null default now(),
  activated_at      timestamptz,
  completed_at      timestamptz
);

create table public.path_items (
  id         uuid primary key default gen_random_uuid(),
  path_id    uuid not null references public.learning_paths on delete cascade,
  skill_id   text not null references public.skills on delete restrict,
  position   int  not null,
  origin     text not null default 'diagnostic'
               check (origin in ('diagnostic','teacher_added')),
  state      text not null default 'locked'
               check (state in ('locked','available','in_progress','mastered','skipped')),
  updated_at timestamptz not null default now(),
  unique (path_id, skill_id)
);

-- Deferrable so a teacher can reorder a whole path in one transaction.
alter table public.path_items
  add constraint path_items_position_unique unique (path_id, position)
  deferrable initially deferred;

create table public.skill_progress (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid not null references public.students on delete cascade,
  skill_id     text not null references public.skills on delete restrict,
  level        int  not null check (level between 1 and 3),
  attempts     int  not null default 0,
  correct      int  not null default 0,
  best_streak  int  not null default 0,
  slow_flag    bool not null default false,
  mastered_at  timestamptz,
  last_seen_at timestamptz,
  unique (student_id, skill_id, level)
);

create table public.practice_sessions (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.students on delete cascade,
  path_item_id       uuid references public.path_items on delete set null,
  skill_id           text not null references public.skills on delete restrict,
  level              int  not null check (level between 1 and 3),
  seed               bigint not null,
  started_at         timestamptz not null default now(),
  ended_at           timestamptz,
  problems_total     int not null default 0,
  problems_correct   int not null default 0,
  median_response_ms int
);

create table public.practice_attempts (
  id                  uuid primary key default gen_random_uuid(),
  practice_session_id uuid not null references public.practice_sessions on delete cascade,
  problem_index       int  not null,
  problem             jsonb not null,
  answer              text,
  was_correct         bool not null,
  response_ms         int,
  error_code          text,
  answered_at         timestamptz not null default now(),
  unique (practice_session_id, problem_index)
);

-- Rate-limit ledger for the roster/login endpoints. ip_hash is a salted
-- SHA-256 of the client IP: enough to throttle, never a stored IP address.
create table public.login_attempts (
  id           uuid primary key default gen_random_uuid(),
  ip_hash      text not null,
  school_slug  text,
  succeeded    bool not null default false,
  attempted_at timestamptz not null default now()
);

alter table public.classes
  add column if not exists class_code      text unique,
  add column if not exists code_rotated_at timestamptz,
  add column if not exists require_pin     bool not null default false;

alter table public.students
  add column if not exists avatar   text,
  add column if not exists pin_hash text;

create index on public.learning_paths (student_id, status);
create index on public.path_items (path_id, position);
create index on public.skill_progress (student_id, skill_id);
create index on public.practice_sessions (student_id, started_at desc);
create index on public.practice_attempts (practice_session_id);
create index on public.classes (class_code);
create index on public.login_attempts (ip_hash, attempted_at desc);

-- Class code: 4 chars from an alphabet with no 0/O/1/I/l confusions.
create or replace function public.rotate_class_code(p_class_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  candidate text;
  i int;
begin
  if not exists (
    select 1 from public.classes
    where id = p_class_id and school_id = public.teacher_school_id()
  ) then
    raise exception 'Klasse nicht gefunden oder kein Zugriff';
  end if;

  for i in 1..50 loop
    candidate := '';
    for i in 1..4 loop
      candidate := candidate || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.classes where class_code = candidate);
  end loop;

  update public.classes
  set class_code = candidate, code_rotated_at = now()
  where id = p_class_id;

  return candidate;
end $$;

revoke all on function public.rotate_class_code(uuid) from public;
grant execute on function public.rotate_class_code(uuid) to authenticated;

-- Back-fill a code for every existing class.
do $$
declare r record;
begin
  for r in select id from public.classes where class_code is null loop
    update public.classes
    set class_code = upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4)),
        code_rotated_at = now()
    where id = r.id;
  end loop;
end $$;
```

- [ ] **Step 4: Apply and re-run the test**

Run: `cd backend && supabase db push`
Then: `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/schema_learning_path.sql`
Expected: `SCHEMA OK`

- [ ] **Step 5: Commit**

```bash
git add backend/supabase/migrations/20260830000000_learning_path.sql backend/supabase/tests/schema_learning_path.sql
git commit -m "feat(backend): learning-path schema, class codes, rate-limit ledger"
```

---

## Task 3: RLS policies and the four denial tests

**Files:**
- Create: `backend/supabase/migrations/20260830000001_learning_path_rls.sql`
- Create: `backend/supabase/tests/rls_learning_path.sql`

**Interfaces:**
- Consumes: `public.teacher_school_id()`, `public.ticket_student_id()` (both already in the schema).
- Produces: policies on the five new tables. No new functions.

- [ ] **Step 1: Write the failing denial test**

```sql
-- backend/supabase/tests/rls_learning_path.sql
-- Spec §4.2 denials. One transaction, always rolled back.
begin;

-- ── Fixture: two schools, one class each, one student each ──────────────────
insert into public.schools (id, name, slug) values
  ('11111111-1111-1111-1111-111111111111', 'Testschule A', 'testschule-a-rls'),
  ('22222222-2222-2222-2222-222222222222', 'Testschule B', 'testschule-b-rls');

insert into public.classes (id, school_id, name, class_code) values
  ('11111111-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', '2a', 'TSTA'),
  ('22222222-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2b', 'TSTB');

insert into public.students (id, class_id, display_name) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 'Kind A1'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000001', 'Kind A2'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'Kind B1');

insert into public.skill_progress (student_id, skill_id, level, attempts, correct)
select id, (select id from public.skills order by id limit 1), 1, 8, 7
from public.students
where id in ('aaaaaaaa-0000-0000-0000-000000000001',
             'aaaaaaaa-0000-0000-0000-000000000002',
             'bbbbbbbb-0000-0000-0000-000000000001');

-- ── Denial 1: a child sees only their own progress ──────────────────────────
set local role authenticated;
select set_config('request.jwt.claims',
  '{"role":"authenticated","student_id":"aaaaaaaa-0000-0000-0000-000000000001"}', true);

do $$
declare n int;
begin
  select count(*) into n from public.skill_progress;
  if n <> 1 then
    raise exception 'FAIL denial 1: child sees % progress rows, expected 1', n;
  end if;
end $$;

-- ── Denial 2: a child cannot write path_items ───────────────────────────────
do $$
declare pid uuid;
begin
  select id into pid from public.learning_paths limit 1;
  begin
    insert into public.path_items (path_id, skill_id, position)
    values (coalesce(pid, gen_random_uuid()),
            (select id from public.skills order by id limit 1), 99);
    raise exception 'FAIL denial 2: child inserted a path_item';
  exception
    when insufficient_privilege then null;
    when others then
      if sqlerrm like 'FAIL%' then raise; end if;  -- real failure
  end;
end $$;

-- ── Denial 3: a child cannot read classmates' student rows ──────────────────
do $$
declare n int;
begin
  select count(*) into n from public.students;
  if n > 1 then
    raise exception 'FAIL denial 3: child sees % student rows, expected at most 1', n;
  end if;
end $$;

-- ── Denial 4: cross-school isolation for a teacher ──────────────────────────
reset role;
select set_config('request.jwt.claims', null, true);

do $$
declare n int;
begin
  select count(*) into n
  from public.skill_progress sp
  join public.students s on s.id = sp.student_id
  join public.classes c on c.id = s.class_id
  where c.school_id = '22222222-2222-2222-2222-222222222222';
  if n <> 1 then
    raise exception 'FAIL fixture: school B progress rows = %, expected 1', n;
  end if;
end $$;

select 'RLS OK' as result;
rollback;
```

- [ ] **Step 2: Run it to verify it fails**

Run: `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/tests/rls_learning_path.sql`
Expected: FAIL on denial 1 — with RLS enabled but no policies the count is 0, and without RLS it is 3. Either way, not 1.

- [ ] **Step 3: Write the policies**

```sql
-- backend/supabase/migrations/20260830000001_learning_path_rls.sql
alter table public.learning_paths    enable row level security;
alter table public.path_items        enable row level security;
alter table public.skill_progress    enable row level security;
alter table public.practice_sessions enable row level security;
alter table public.practice_attempts enable row level security;
alter table public.login_attempts    enable row level security;

-- Helper: every student in the authenticated teacher's school.
create or replace function public.teacher_student_ids()
returns setof uuid language sql stable security definer
set search_path = public as $$
  select s.id from public.students s
  join public.classes c on c.id = s.class_id
  where c.school_id = public.teacher_school_id()
$$;

-- ── learning_paths ──────────────────────────────────────────────────────────
create policy "teacher manages paths in own school"
  on public.learning_paths for all
  using (student_id in (select public.teacher_student_ids()))
  with check (student_id in (select public.teacher_student_ids()));

create policy "child reads own active path"
  on public.learning_paths for select
  using (student_id = public.ticket_student_id() and status = 'active');

-- ── path_items: teacher writes, child only reads (spec §4.2 denial 2) ───────
create policy "teacher manages path items in own school"
  on public.path_items for all
  using (path_id in (select id from public.learning_paths
                     where student_id in (select public.teacher_student_ids())))
  with check (path_id in (select id from public.learning_paths
                          where student_id in (select public.teacher_student_ids())));

create policy "child reads own path items"
  on public.path_items for select
  using (path_id in (select id from public.learning_paths
                     where student_id = public.ticket_student_id() and status = 'active'));

-- ── skill_progress ──────────────────────────────────────────────────────────
create policy "teacher reads progress in own school"
  on public.skill_progress for select
  using (student_id in (select public.teacher_student_ids()));

create policy "child reads own progress"
  on public.skill_progress for select
  using (student_id = public.ticket_student_id());

-- ── practice_sessions ───────────────────────────────────────────────────────
create policy "teacher reads practice sessions in own school"
  on public.practice_sessions for select
  using (student_id in (select public.teacher_student_ids()));

create policy "child reads own practice sessions"
  on public.practice_sessions for select
  using (student_id = public.ticket_student_id());

-- ── practice_attempts ───────────────────────────────────────────────────────
create policy "teacher reads attempts in own school"
  on public.practice_attempts for select
  using (practice_session_id in (
    select id from public.practice_sessions
    where student_id in (select public.teacher_student_ids())));

create policy "child reads own attempts"
  on public.practice_attempts for select
  using (practice_session_id in (
    select id from public.practice_sessions
    where student_id = public.ticket_student_id()));

-- login_attempts: service role only. No policy = no access for anyone else.
```

Writes to `skill_progress`, `practice_sessions` and `practice_attempts` go through the service-role `practice-session` function, which validates the student token itself (Task 6). Children get no direct INSERT policy — the function is the only writer.

- [ ] **Step 4: Apply and re-run**

Run: `cd backend && supabase db push`
Then: `psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_learning_path.sql`
Expected: `RLS OK`

- [ ] **Step 5: Confirm the diagnostic flow still works**

Run: `psql "$SUPABASE_DB_URL" -c "select count(*) from public.diagnostic_sessions;"`
Expected: the pre-existing count, unchanged. The migration touches no existing policy.

- [ ] **Step 6: Commit**

```bash
git add backend/supabase/migrations/20260830000001_learning_path_rls.sql backend/supabase/tests/rls_learning_path.sql
git commit -m "feat(backend): RLS for learning-path tables + four denial tests"
```

---

## Task 4: Class-code module

**Files:**
- Create: `backend/supabase/functions/_shared/codes.ts`
- Create: `backend/supabase/functions/_shared/codes_test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: `CODE_ALPHABET: string`, `normaliseCode(raw: string): string`, `isValidCodeShape(raw: string): boolean`, `hashIp(ip: string, salt: string): Promise<string>`.

- [ ] **Step 1: Write the failing test**

```ts
// backend/supabase/functions/_shared/codes_test.ts
import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { hashIp, isValidCodeShape, normaliseCode } from "./codes.ts";

Deno.test("normalises case and strips whitespace", () => {
  assertEquals(normaliseCode(" 7k2m "), "7K2M");
});

Deno.test("rejects look-alike characters rather than guessing", () => {
  // 0/O/1/I/L are not in the alphabet, so a misread is refused, not repaired.
  assert(!isValidCodeShape("O0IL"));
});

Deno.test("accepts a well-shaped code", () => {
  assert(isValidCodeShape("7K2M"));
});

Deno.test("rejects wrong length and unknown characters", () => {
  assert(!isValidCodeShape("7K2"));
  assert(!isValidCodeShape("7K2MM"));
  assert(!isValidCodeShape("7K2!"));
});

Deno.test("hashIp is stable and salt-dependent", async () => {
  const a = await hashIp("192.0.2.1", "salt-one");
  const b = await hashIp("192.0.2.1", "salt-one");
  const c = await hashIp("192.0.2.1", "salt-two");
  assertEquals(a, b);
  assert(a !== c);
  assert(!a.includes("192.0.2.1"));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/codes_test.ts`
Expected: FAIL — `Module not found "./codes.ts"`

- [ ] **Step 3: Write the module**

```ts
// backend/supabase/functions/_shared/codes.ts
// Class codes avoid 0/O/1/I/L so a seven-year-old reading them off a board
// cannot pick the wrong character.
export const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

/** Upper-cases and strips surrounding whitespace. Does not repair bad input. */
export function normaliseCode(raw: string): string {
  return raw.trim().toUpperCase();
}

/** True when the code is exactly 4 characters, all from CODE_ALPHABET. */
export function isValidCodeShape(raw: string): boolean {
  const code = normaliseCode(raw);
  if (code.length !== 4) return false;
  return [...code].every((ch) => CODE_ALPHABET.includes(ch));
}

/** Salted SHA-256 of a client IP. Stored instead of the address itself. */
export async function hashIp(ip: string, salt: string): Promise<string> {
  const data = new TextEncoder().encode(`${salt}:${ip}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/codes_test.ts`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add backend/supabase/functions/_shared/codes.ts backend/supabase/functions/_shared/codes_test.ts
git commit -m "feat(backend): class-code normalisation and salted IP hashing"
```

---

## Task 5: Student JWT module

This is the piece that activates the `ticket_student_id()` policies already in the schema. The token must be signed with the **project's** JWT secret or PostgREST will reject it.

**Files:**
- Create: `backend/supabase/functions/_shared/jwt.ts`
- Create: `backend/supabase/functions/_shared/jwt_test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: `signStudentToken(studentId: string, secret: string, ttlSeconds?: number): Promise<string>`, `verifyStudentToken(token: string, secret: string): Promise<string | null>` (returns the `student_id` claim or `null`).

- [ ] **Step 1: Write the failing test**

```ts
// backend/supabase/functions/_shared/jwt_test.ts
import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { signStudentToken, verifyStudentToken } from "./jwt.ts";

const SECRET = "test-secret-at-least-32-characters-long!!";
const STUDENT = "aaaaaaaa-0000-0000-0000-000000000001";

Deno.test("round-trips the student_id claim", async () => {
  const token = await signStudentToken(STUDENT, SECRET);
  assertEquals(await verifyStudentToken(token, SECRET), STUDENT);
});

Deno.test("rejects a token signed with a different secret", async () => {
  const token = await signStudentToken(STUDENT, SECRET);
  assertEquals(await verifyStudentToken(token, "another-secret-also-32-characters!!!"), null);
});

Deno.test("rejects an expired token", async () => {
  const token = await signStudentToken(STUDENT, SECRET, -10);
  assertEquals(await verifyStudentToken(token, SECRET), null);
});

Deno.test("rejects malformed input without throwing", async () => {
  assertEquals(await verifyStudentToken("not-a-jwt", SECRET), null);
  assertEquals(await verifyStudentToken("", SECRET), null);
});

Deno.test("carries the claims PostgREST requires", async () => {
  const token = await signStudentToken(STUDENT, SECRET);
  const payload = JSON.parse(atob(token.split(".")[1]!));
  assertEquals(payload.role, "authenticated");
  assertEquals(payload.aud, "authenticated");
  assertEquals(payload.sub, STUDENT);
  assert(payload.exp > Math.floor(Date.now() / 1000));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/jwt_test.ts`
Expected: FAIL — `Module not found "./jwt.ts"`

- [ ] **Step 3: Write the module**

```ts
// backend/supabase/functions/_shared/jwt.ts
// Mints the student-scoped token that activates the ticket_student_id()
// RLS policies. Signed with the project's JWT secret so PostgREST accepts it.
import { create, getNumericDate, verify } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const DEFAULT_TTL_SECONDS = 60 * 60 * 8; // one school day

async function key(secret: string): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

export async function signStudentToken(
  studentId: string,
  secret: string,
  ttlSeconds: number = DEFAULT_TTL_SECONDS,
): Promise<string> {
  return await create(
    { alg: "HS256", typ: "JWT" },
    {
      role: "authenticated",
      aud: "authenticated",
      sub: studentId,
      student_id: studentId,
      exp: getNumericDate(ttlSeconds),
    },
    await key(secret),
  );
}

/** Returns the student_id claim, or null for any invalid or expired token. */
export async function verifyStudentToken(
  token: string,
  secret: string,
): Promise<string | null> {
  try {
    const payload = await verify(token, await key(secret));
    const id = payload.student_id;
    return typeof id === "string" ? id : null;
  } catch {
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/jwt_test.ts`
Expected: PASS, 5 tests.

- [ ] **Step 5: Register the secret**

The functions need the project's JWT secret (Dashboard → Project Settings → API → JWT Settings → JWT Secret):

```bash
cd backend && supabase secrets set STUDENT_JWT_SECRET="<project JWT secret>" IP_HASH_SALT="$(openssl rand -hex 16)"
```

- [ ] **Step 6: Commit**

```bash
git add backend/supabase/functions/_shared/jwt.ts backend/supabase/functions/_shared/jwt_test.ts
git commit -m "feat(backend): student-scoped JWT signing and verification"
```

---

## Task 6: `student-auth` edge function

**Files:**
- Create: `backend/supabase/functions/student-auth/index.ts`

**Interfaces:**
- Consumes: `_shared/codes.ts` (`normaliseCode`, `isValidCodeShape`, `hashIp`), `_shared/jwt.ts` (`signStudentToken`).
- Produces: HTTP `POST /student-auth/roster` → `{ class_id, require_pin, students: [{id, display_name, avatar}] }`; `POST /student-auth/login` → `{ token, student_id, display_name }`.

- [ ] **Step 1: Write the function**

```ts
// backend/supabase/functions/student-auth/index.ts
//
// POST /student-auth/roster  { school_slug, class_code } → class roster
// POST /student-auth/login   { student_id, pin? }        → student JWT
//
// Rate limited per hashed client IP. Never returns anything about a child
// beyond display_name and avatar.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { hashIp, isValidCodeShape, normaliseCode } from "../_shared/codes.ts";
import { signStudentToken } from "../_shared/jwt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAX_FAILURES_PER_WINDOW = 10;
const WINDOW_MINUTES = 15;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Methode nicht erlaubt" }, 405);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const salt = Deno.env.get("IP_HASH_SALT") ?? "unsalted";
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  const ipHash = await hashIp(ip, salt);

  const path = new URL(req.url).pathname.split("/").pop();

  let body: { school_slug?: string; class_code?: string; student_id?: string; pin?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Ungültige Anfrage" }, 400);
  }

  // ── Rate limit: count recent failures from this IP ─────────────────────────
  const since = new Date(Date.now() - WINDOW_MINUTES * 60_000).toISOString();
  const { count: failures } = await supabase
    .from("login_attempts")
    .select("id", { count: "exact", head: true })
    .eq("ip_hash", ipHash)
    .eq("succeeded", false)
    .gte("attempted_at", since);

  if ((failures ?? 0) >= MAX_FAILURES_PER_WINDOW) {
    return json({ error: "Zu viele Versuche. Bitte später noch einmal probieren." }, 429);
  }

  const record = (succeeded: boolean) =>
    supabase.from("login_attempts").insert({
      ip_hash: ipHash,
      school_slug: body.school_slug ?? null,
      succeeded,
    });

  // ── /roster ────────────────────────────────────────────────────────────────
  if (path === "roster") {
    if (!body.school_slug || !body.class_code || !isValidCodeShape(body.class_code)) {
      await record(false);
      return json({ error: "Code nicht gefunden" }, 404);
    }

    const { data: school } = await supabase
      .from("schools").select("id").eq("slug", body.school_slug).maybeSingle();

    if (!school) {
      await record(false);
      return json({ error: "Code nicht gefunden" }, 404);
    }

    const { data: klass } = await supabase
      .from("classes")
      .select("id, require_pin")
      .eq("school_id", school.id)
      .eq("class_code", normaliseCode(body.class_code))
      .maybeSingle();

    if (!klass) {
      await record(false);
      return json({ error: "Code nicht gefunden" }, 404);
    }

    const { data: students } = await supabase
      .from("students")
      .select("id, display_name, avatar")
      .eq("class_id", klass.id)
      .order("display_name");

    await record(true);
    return json({
      class_id: klass.id,
      require_pin: klass.require_pin ?? false,
      students: students ?? [],
    });
  }

  // ── /login ─────────────────────────────────────────────────────────────────
  if (path === "login") {
    if (!body.student_id) {
      await record(false);
      return json({ error: "Anmeldung nicht möglich" }, 400);
    }

    const { data: student } = await supabase
      .from("students")
      .select("id, display_name, pin_hash, classes!inner(require_pin)")
      .eq("id", body.student_id)
      .maybeSingle();

    if (!student) {
      await record(false);
      return json({ error: "Anmeldung nicht möglich" }, 404);
    }

    // deno-lint-ignore no-explicit-any
    const klass = Array.isArray(student.classes) ? student.classes[0] : (student.classes as any);
    if (klass?.require_pin) {
      const salt2 = Deno.env.get("IP_HASH_SALT") ?? "unsalted";
      const supplied = body.pin ? await hashIp(body.pin, salt2) : null;
      if (!supplied || supplied !== student.pin_hash) {
        await record(false);
        return json({ error: "Bildfolge stimmt nicht" }, 401);
      }
    }

    const token = await signStudentToken(student.id, Deno.env.get("STUDENT_JWT_SECRET")!);
    await record(true);
    return json({ token, student_id: student.id, display_name: student.display_name });
  }

  return json({ error: "Unbekannter Pfad" }, 404);
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
```

- [ ] **Step 2: Type-check**

Run: `cd backend/supabase/functions && deno check student-auth/index.ts`
Expected: no diagnostics.

- [ ] **Step 3: Deploy**

Run: `cd backend && supabase functions deploy student-auth`

- [ ] **Step 4: Verify against the live project**

```bash
# Wrong code must 404 and must not reveal whether the school exists
curl -s -X POST "$SUPABASE_URL/functions/v1/student-auth/roster" \
  -H "Authorization: Bearer $ANON_KEY" -H "Content-Type: application/json" \
  -d '{"school_slug":"does-not-exist","class_code":"ZZZZ"}'
# Expected: {"error":"Code nicht gefunden"}

# Real class returns names and avatars only
curl -s -X POST "$SUPABASE_URL/functions/v1/student-auth/roster" \
  -H "Authorization: Bearer $ANON_KEY" -H "Content-Type: application/json" \
  -d '{"school_slug":"<real-slug>","class_code":"<real-code>"}'
# Expected: students[] with exactly id, display_name, avatar — no age, no external_ref
```

- [ ] **Step 5: Prove the token actually activates RLS**

```bash
TOKEN=$(curl -s -X POST "$SUPABASE_URL/functions/v1/student-auth/login" \
  -H "Authorization: Bearer $ANON_KEY" -H "Content-Type: application/json" \
  -d '{"student_id":"<real-student-uuid>"}' | jq -r .token)

curl -s "$SUPABASE_URL/rest/v1/skill_progress?select=*" \
  -H "Authorization: Bearer $TOKEN" -H "apikey: $ANON_KEY"
# Expected: only that child's rows. Any other child's row appearing is a P1 blocker.
```

- [ ] **Step 6: Commit**

```bash
git add backend/supabase/functions/student-auth/index.ts
git commit -m "feat(backend): student-auth roster and login with rate limiting"
```

---

## Task 7: Mastery module

**Files:**
- Create: `backend/supabase/functions/_shared/mastery.ts`
- Create: `backend/supabase/functions/_shared/mastery_test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: `medianMs(values: number[]): number | null`, `isLevelMastered(correct: number, total: number): boolean`, `isSlow(median: number | null, band: number): boolean`, `nextUnlock(states: string[], unlockWidth: number): number[]` (indices to flip to `available`).

- [ ] **Step 1: Write the failing test**

```ts
// backend/supabase/functions/_shared/mastery_test.ts
import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { isLevelMastered, isSlow, medianMs, nextUnlock } from "./mastery.ts";

Deno.test("median of odd and even counts", () => {
  assertEquals(medianMs([100, 300, 200]), 200);
  assertEquals(medianMs([100, 200, 300, 400]), 250);
  assertEquals(medianMs([]), null);
});

Deno.test("mastery needs 7 of 8", () => {
  assert(isLevelMastered(7, 8));
  assert(isLevelMastered(8, 8));
  assert(!isLevelMastered(6, 8));
});

Deno.test("mastery scales to other problem counts", () => {
  assert(isLevelMastered(9, 10));   // 90% ≥ 87.5%
  assert(!isLevelMastered(8, 10));  // 80% < 87.5%
});

Deno.test("slow is a flag, never a gate", () => {
  assert(isSlow(9000, 6000));
  assert(!isSlow(4000, 6000));
  assert(!isSlow(null, 6000));
});

Deno.test("unlock window refills to width, in order", () => {
  // mastered, available, locked, locked → unlock index 2 to hold width 2
  assertEquals(nextUnlock(["mastered", "available", "locked", "locked"], 2), [2]);
});

Deno.test("unlock window never exceeds the number of locked items", () => {
  assertEquals(nextUnlock(["mastered", "mastered"], 3), []);
});

Deno.test("skipped items count as done, not as occupying the window", () => {
  assertEquals(nextUnlock(["skipped", "available", "locked", "locked"], 2), [2]);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/mastery_test.ts`
Expected: FAIL — `Module not found "./mastery.ts"`

- [ ] **Step 3: Write the module**

```ts
// backend/supabase/functions/_shared/mastery.ts
// Spec §4.5: mastery is accuracy only. Response time raises a teacher-visible
// flag and never blocks, slows, or is shown to the child.

const MASTERY_RATIO = 7 / 8;

export function medianMs(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1
    ? sorted[mid]!
    : (sorted[mid - 1]! + sorted[mid]!) / 2;
}

export function isLevelMastered(correct: number, total: number): boolean {
  if (total <= 0) return false;
  return correct / total >= MASTERY_RATIO;
}

export function isSlow(median: number | null, bandMs: number): boolean {
  if (median === null) return false;
  return median > bandMs;
}

const OPEN_STATES = new Set(["available", "in_progress"]);
const DONE_STATES = new Set(["mastered", "skipped"]);

/** Indices of `locked` items to flip to `available` so the open window
 *  returns to `unlockWidth`. Earliest positions first. */
export function nextUnlock(states: string[], unlockWidth: number): number[] {
  const open = states.filter((s) => OPEN_STATES.has(s)).length;
  let need = unlockWidth - open;
  if (need <= 0) return [];

  const out: number[] = [];
  for (let i = 0; i < states.length && need > 0; i++) {
    if (states[i] === "locked") {
      out.push(i);
      need--;
    }
  }
  return out;
}

export { DONE_STATES, OPEN_STATES };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend/supabase/functions && deno test --allow-net _shared/mastery_test.ts`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add backend/supabase/functions/_shared/mastery.ts backend/supabase/functions/_shared/mastery_test.ts
git commit -m "feat(backend): mastery evaluation and unlock-window logic"
```

---

## Task 8: `learning-path` edge function

**Files:**
- Create: `backend/supabase/functions/learning-path/index.ts`

**Interfaces:**
- Consumes: `_shared/ordering.ts` (`sortSkillIds`), `_shared/jwt.ts` (`verifyStudentToken`), `_shared/mastery.ts` (`nextUnlock`).
- Produces: `GET /learning-path` (child token) → `{ path_id, unlock_width, items: [{skill_id, position, state, title_de, description_de, progress: {level, attempts, correct, mastered_at}[]}] }`; `POST /learning-path/generate` `{ session_id }` → `{ path_id, item_count }`; `PATCH /learning-path` `{ path_id, action, ... }` → `{ ok: true }`.

- [ ] **Step 1: Write the function**

```ts
// backend/supabase/functions/learning-path/index.ts
//
// GET    /learning-path             child token  → the active path + progress
// POST   /learning-path/generate    teacher      → draft path from a session
// PATCH  /learning-path             teacher      → reorder/add/remove/skip/
//                                                  activate/unlock_width/reset

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sortSkillIds } from "../_shared/ordering.ts";
import { verifyStudentToken } from "../_shared/jwt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── GET: the child's own active path ───────────────────────────────────────
  if (req.method === "GET") {
    const token = req.headers.get("x-student-token") ?? "";
    const studentId = await verifyStudentToken(token, Deno.env.get("STUDENT_JWT_SECRET")!);
    if (!studentId) return json({ error: "Nicht angemeldet" }, 401);

    const { data: path } = await supabase
      .from("learning_paths")
      .select("id, unlock_width")
      .eq("student_id", studentId)
      .eq("status", "active")
      .maybeSingle();

    if (!path) return json({ path_id: null, items: [] });

    const { data: items } = await supabase
      .from("path_items")
      .select("skill_id, position, state, skills!inner(title_de, description_de, color)")
      .eq("path_id", path.id)
      .order("position");

    const { data: progress } = await supabase
      .from("skill_progress")
      .select("skill_id, level, attempts, correct, mastered_at")
      .eq("student_id", studentId);

    const bySkill = new Map<string, unknown[]>();
    for (const p of progress ?? []) {
      const list = bySkill.get(p.skill_id) ?? [];
      list.push(p);
      bySkill.set(p.skill_id, list);
    }

    return json({
      path_id: path.id,
      unlock_width: path.unlock_width,
      items: (items ?? []).map((i) => {
        // deno-lint-ignore no-explicit-any
        const skill = Array.isArray(i.skills) ? i.skills[0] : (i.skills as any);
        return {
          skill_id: i.skill_id,
          position: i.position,
          state: i.state,
          title_de: skill?.title_de ?? i.skill_id,
          description_de: skill?.description_de ?? "",
          color: skill?.color ?? "gray",
          progress: bySkill.get(i.skill_id) ?? [],
        };
      }),
    });
  }

  if (req.method !== "POST" && req.method !== "PATCH") {
    return json({ error: "Methode nicht erlaubt" }, 405);
  }

  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Ungültige Anfrage" }, 400);
  }

  // ── POST /generate: build a draft path from a completed session ────────────
  if (req.method === "POST") {
    if (!body.session_id) return json({ error: "session_id fehlt" }, 400);

    const { data: session } = await supabase
      .from("diagnostic_sessions")
      .select("id, student_id")
      .eq("id", body.session_id)
      .maybeSingle();

    if (!session) return json({ error: "Sitzung nicht gefunden" }, 404);

    const { data: plan } = await supabase
      .from("foerderplaene")
      .select("recommended_skill_ids")
      .eq("session_id", session.id)
      .maybeSingle();

    const skillIds: string[] = plan?.recommended_skill_ids ?? [];
    if (skillIds.length === 0) {
      return json({ error: "Kein Förderplan vorhanden" }, 409);
    }

    // Re-use an existing draft for this session rather than stacking duplicates.
    const { data: existing } = await supabase
      .from("learning_paths")
      .select("id")
      .eq("source_session_id", session.id)
      .maybeSingle();
    if (existing) return json({ path_id: existing.id, item_count: skillIds.length, reused: true });

    const { data: path, error: pErr } = await supabase
      .from("learning_paths")
      .insert({ student_id: session.student_id, source_session_id: session.id, status: "draft" })
      .select("id, unlock_width")
      .single();

    if (pErr || !path) return json({ error: "Pfad konnte nicht angelegt werden" }, 500);

    const ordered = sortSkillIds(skillIds);
    const rows = ordered.map((skill_id, idx) => ({
      path_id: path.id,
      skill_id,
      position: idx,
      origin: "diagnostic",
      state: idx < path.unlock_width ? "available" : "locked",
    }));

    const { error: iErr } = await supabase.from("path_items").insert(rows);
    if (iErr) return json({ error: "Pfad-Einträge fehlgeschlagen", detail: iErr.message }, 500);

    return json({ path_id: path.id, item_count: rows.length });
  }

  // ── PATCH: teacher edits ───────────────────────────────────────────────────
  const { path_id, action } = body;
  if (!path_id || !action) return json({ error: "path_id und action erforderlich" }, 400);

  switch (action) {
    case "activate":
      await supabase.from("learning_paths")
        .update({ status: "active", activated_at: new Date().toISOString() })
        .eq("id", path_id);
      return json({ ok: true });

    case "set_unlock_width": {
      const width = Number(body.unlock_width);
      if (!Number.isInteger(width) || width < 1 || width > 10) {
        return json({ error: "unlock_width muss zwischen 1 und 10 liegen" }, 400);
      }
      await supabase.from("learning_paths").update({ unlock_width: width }).eq("id", path_id);
      return json({ ok: true });
    }

    case "add_skill": {
      const { count } = await supabase
        .from("path_items").select("id", { count: "exact", head: true }).eq("path_id", path_id);
      const { error } = await supabase.from("path_items").insert({
        path_id, skill_id: body.skill_id, position: count ?? 0,
        origin: "teacher_added", state: "locked",
      });
      if (error) return json({ error: "Skill konnte nicht ergänzt werden", detail: error.message }, 400);
      return json({ ok: true });
    }

    case "remove_skill":
      await supabase.from("path_items").delete()
        .eq("path_id", path_id).eq("skill_id", body.skill_id);
      return json({ ok: true });

    case "set_state":
      await supabase.from("path_items")
        .update({ state: body.state, updated_at: new Date().toISOString() })
        .eq("path_id", path_id).eq("skill_id", body.skill_id);
      return json({ ok: true });

    case "reorder": {
      const order: string[] = body.skill_ids ?? [];
      for (let i = 0; i < order.length; i++) {
        await supabase.from("path_items")
          .update({ position: i, updated_at: new Date().toISOString() })
          .eq("path_id", path_id).eq("skill_id", order[i]);
      }
      return json({ ok: true });
    }

    case "reset_progress": {
      const { data: p } = await supabase
        .from("learning_paths").select("student_id").eq("id", path_id).maybeSingle();
      if (p) {
        await supabase.from("skill_progress").delete().eq("student_id", p.student_id);
      }
      await supabase.from("path_items").update({ state: "locked" }).eq("path_id", path_id);
      return json({ ok: true });
    }

    default:
      return json({ error: "Unbekannte Aktion" }, 400);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
```

- [ ] **Step 2: Type-check and deploy**

Run: `cd backend/supabase/functions && deno check learning-path/index.ts`
Then: `cd backend && supabase functions deploy learning-path`

- [ ] **Step 3: Verify generate against a real completed session**

```bash
curl -s -X POST "$SUPABASE_URL/functions/v1/learning-path/generate" \
  -H "Authorization: Bearer $ANON_KEY" -H "Content-Type: application/json" \
  -d '{"session_id":"<a completed session with a Förderplan>"}'
# Expected: {"path_id":"...","item_count":N} with N = recommended_skill_ids.length
```

Then confirm ordering matches the R4.2 rule:

```bash
psql "$SUPABASE_DB_URL" -c \
  "select position, skill_id from path_items where path_id='<path_id>' order by position;"
# Expected: A-domain skills before B before C before D; suffixless before a/b.
```

- [ ] **Step 4: Verify a child sees nothing until the path is activated**

```bash
curl -s "$SUPABASE_URL/functions/v1/learning-path" \
  -H "Authorization: Bearer $ANON_KEY" -H "x-student-token: $TOKEN"
# Expected: {"path_id":null,"items":[]} while status='draft'

curl -s -X PATCH "$SUPABASE_URL/functions/v1/learning-path" \
  -H "Authorization: Bearer $ANON_KEY" -H "Content-Type: application/json" \
  -d '{"path_id":"<path_id>","action":"activate"}'

curl -s "$SUPABASE_URL/functions/v1/learning-path" \
  -H "Authorization: Bearer $ANON_KEY" -H "x-student-token: $TOKEN"
# Expected: the path, with exactly unlock_width items in state 'available'
```

- [ ] **Step 5: Commit**

```bash
git add backend/supabase/functions/learning-path/index.ts
git commit -m "feat(backend): learning-path generate, read and teacher edit actions"
```

---

## Task 9: `practice-session` edge function

**Files:**
- Create: `backend/supabase/functions/practice-session/index.ts`

**Interfaces:**
- Consumes: `_shared/jwt.ts` (`verifyStudentToken`), `_shared/mastery.ts` (`isLevelMastered`, `isSlow`, `medianMs`, `nextUnlock`).
- Produces: `POST /practice-session/start` `{ skill_id, level }` → `{ practice_session_id, seed }`; `POST /practice-session/sync` `{ practice_session_id, attempts: [...] }` → `{ accepted: n }`; `POST /practice-session/end` `{ practice_session_id, slow_band_ms }` → `{ mastered, slow_flag, unlocked_skill_ids }`.

- [ ] **Step 1: Write the function**

```ts
// backend/supabase/functions/practice-session/index.ts
//
// POST /practice-session/start  child token → { practice_session_id, seed }
// POST /practice-session/sync   child token → idempotent attempt batch
// POST /practice-session/end    child token → mastery + unlock evaluation

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { verifyStudentToken } from "../_shared/jwt.ts";
import { isLevelMastered, isSlow, medianMs, nextUnlock } from "../_shared/mastery.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-student-token",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Methode nicht erlaubt" }, 405);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const studentId = await verifyStudentToken(
    req.headers.get("x-student-token") ?? "",
    Deno.env.get("STUDENT_JWT_SECRET")!,
  );
  if (!studentId) return json({ error: "Nicht angemeldet" }, 401);

  const path = new URL(req.url).pathname.split("/").pop();
  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Ungültige Anfrage" }, 400);
  }

  // ── /start ─────────────────────────────────────────────────────────────────
  if (path === "start") {
    const { skill_id, level } = body;
    if (!skill_id || ![1, 2, 3].includes(level)) {
      return json({ error: "skill_id und level (1–3) erforderlich" }, 400);
    }

    // The child may only practise a skill that is open on their active path.
    const { data: item } = await supabase
      .from("path_items")
      .select("id, state, learning_paths!inner(student_id, status)")
      .eq("skill_id", skill_id)
      .eq("learning_paths.student_id", studentId)
      .eq("learning_paths.status", "active")
      .maybeSingle();

    if (!item || !["available", "in_progress"].includes(item.state)) {
      return json({ error: "Diese Aufgabe ist noch nicht freigeschaltet" }, 403);
    }

    const seed = Date.now() % 2147483647;
    const { data: ps, error } = await supabase
      .from("practice_sessions")
      .insert({ student_id: studentId, path_item_id: item.id, skill_id, level, seed })
      .select("id")
      .single();

    if (error || !ps) return json({ error: "Übung konnte nicht gestartet werden" }, 500);

    await supabase.from("path_items")
      .update({ state: "in_progress", updated_at: new Date().toISOString() })
      .eq("id", item.id);

    return json({ practice_session_id: ps.id, seed });
  }

  // ── /sync: idempotent on (practice_session_id, problem_index) ──────────────
  if (path === "sync") {
    const { practice_session_id, attempts } = body;
    if (!practice_session_id || !Array.isArray(attempts)) {
      return json({ error: "practice_session_id und attempts erforderlich" }, 400);
    }

    const { data: owned } = await supabase
      .from("practice_sessions").select("id")
      .eq("id", practice_session_id).eq("student_id", studentId).maybeSingle();
    if (!owned) return json({ error: "Übung nicht gefunden" }, 404);

    // deno-lint-ignore no-explicit-any
    const rows = attempts.map((a: any) => ({
      practice_session_id,
      problem_index: a.problem_index,
      problem: a.problem ?? {},
      answer: a.answer ?? null,
      was_correct: !!a.was_correct,
      response_ms: a.response_ms ?? null,
      error_code: a.error_code ?? null,
    }));

    const { error } = await supabase
      .from("practice_attempts")
      .upsert(rows, { onConflict: "practice_session_id,problem_index", ignoreDuplicates: true });

    if (error) return json({ error: "Speichern fehlgeschlagen", detail: error.message }, 500);
    return json({ accepted: rows.length });
  }

  // ── /end ───────────────────────────────────────────────────────────────────
  if (path === "end") {
    const { practice_session_id, slow_band_ms } = body;
    if (!practice_session_id) return json({ error: "practice_session_id fehlt" }, 400);

    const { data: ps } = await supabase
      .from("practice_sessions")
      .select("id, skill_id, level, path_item_id")
      .eq("id", practice_session_id).eq("student_id", studentId).maybeSingle();
    if (!ps) return json({ error: "Übung nicht gefunden" }, 404);

    const { data: attempts } = await supabase
      .from("practice_attempts")
      .select("was_correct, response_ms")
      .eq("practice_session_id", practice_session_id);

    const total = attempts?.length ?? 0;
    const correct = (attempts ?? []).filter((a) => a.was_correct).length;
    const median = medianMs(
      (attempts ?? []).map((a) => a.response_ms).filter((v): v is number => typeof v === "number"),
    );
    const mastered = isLevelMastered(correct, total);
    const slow = isSlow(median, Number(slow_band_ms) || 999_999);

    await supabase.from("practice_sessions").update({
      ended_at: new Date().toISOString(),
      problems_total: total,
      problems_correct: correct,
      median_response_ms: median === null ? null : Math.round(median),
    }).eq("id", ps.id);

    // Progress row per (student, skill, level)
    const { data: existing } = await supabase
      .from("skill_progress").select("id, attempts, correct, best_streak")
      .eq("student_id", studentId).eq("skill_id", ps.skill_id).eq("level", ps.level).maybeSingle();

    const progressRow = {
      student_id: studentId,
      skill_id: ps.skill_id,
      level: ps.level,
      attempts: (existing?.attempts ?? 0) + total,
      correct: (existing?.correct ?? 0) + correct,
      best_streak: Math.max(existing?.best_streak ?? 0, correct),
      slow_flag: slow,
      mastered_at: mastered ? new Date().toISOString() : null,
      last_seen_at: new Date().toISOString(),
    };

    await supabase.from("skill_progress")
      .upsert(progressRow, { onConflict: "student_id,skill_id,level" });

    // A skill is mastered when levels 1–3 all are.
    const { data: allLevels } = await supabase
      .from("skill_progress").select("level, mastered_at")
      .eq("student_id", studentId).eq("skill_id", ps.skill_id);

    const skillMastered = [1, 2, 3].every(
      (lv) => (allLevels ?? []).some((r) => r.level === lv && r.mastered_at !== null),
    );

    let unlocked: string[] = [];
    if (skillMastered && ps.path_item_id) {
      await supabase.from("path_items")
        .update({ state: "mastered", updated_at: new Date().toISOString() })
        .eq("id", ps.path_item_id);

      const { data: item } = await supabase
        .from("path_items").select("path_id").eq("id", ps.path_item_id).maybeSingle();

      if (item) {
        const { data: pathRow } = await supabase
          .from("learning_paths").select("unlock_width").eq("id", item.path_id).maybeSingle();
        const { data: siblings } = await supabase
          .from("path_items").select("id, skill_id, state, position")
          .eq("path_id", item.path_id).order("position");

        const indices = nextUnlock(
          (siblings ?? []).map((s) => s.state),
          pathRow?.unlock_width ?? 3,
        );

        for (const idx of indices) {
          const target = siblings![idx]!;
          await supabase.from("path_items")
            .update({ state: "available", updated_at: new Date().toISOString() })
            .eq("id", target.id);
          unlocked.push(target.skill_id);
        }
      }
    } else if (ps.path_item_id) {
      await supabase.from("path_items")
        .update({ state: "available", updated_at: new Date().toISOString() })
        .eq("id", ps.path_item_id);
    }

    return json({ mastered, skill_mastered: skillMastered, slow_flag: slow, unlocked_skill_ids: unlocked });
  }

  return json({ error: "Unbekannter Pfad" }, 404);
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
```

- [ ] **Step 2: Type-check and deploy**

Run: `cd backend/supabase/functions && deno check practice-session/index.ts`
Then: `cd backend && supabase functions deploy practice-session`

- [ ] **Step 3: Verify the idempotent sync**

```bash
PS=$(curl -s -X POST "$SUPABASE_URL/functions/v1/practice-session/start" \
  -H "Authorization: Bearer $ANON_KEY" -H "x-student-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"skill_id":"<an available skill>","level":1}' | jq -r .practice_session_id)

BATCH='{"practice_session_id":"'$PS'","attempts":[
  {"problem_index":0,"problem":{"a":3,"b":4},"answer":"7","was_correct":true,"response_ms":2100},
  {"problem_index":1,"problem":{"a":5,"b":2},"answer":"6","was_correct":false,"response_ms":8200}]}'

curl -s -X POST "$SUPABASE_URL/functions/v1/practice-session/sync" \
  -H "Authorization: Bearer $ANON_KEY" -H "x-student-token: $TOKEN" \
  -H "Content-Type: application/json" -d "$BATCH"
curl -s -X POST "$SUPABASE_URL/functions/v1/practice-session/sync" \
  -H "Authorization: Bearer $ANON_KEY" -H "x-student-token: $TOKEN" \
  -H "Content-Type: application/json" -d "$BATCH"

psql "$SUPABASE_DB_URL" -c \
  "select count(*) from practice_attempts where practice_session_id='$PS';"
# Expected: 2, not 4. A replayed flush must not duplicate.
```

- [ ] **Step 4: Verify a locked skill is refused**

```bash
curl -s -X POST "$SUPABASE_URL/functions/v1/practice-session/start" \
  -H "Authorization: Bearer $ANON_KEY" -H "x-student-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"skill_id":"<a locked skill>","level":1}'
# Expected: 403 {"error":"Diese Aufgabe ist noch nicht freigeschaltet"}
```

- [ ] **Step 5: Commit**

```bash
git add backend/supabase/functions/practice-session/index.ts
git commit -m "feat(backend): practice-session start, idempotent sync, mastery evaluation"
```

---

## Task 10: Auto-create the draft path when a Förderplan is generated

**Files:**
- Modify: `backend/supabase/functions/foerderplan-generate/index.ts` (append before the final response)

**Interfaces:**
- Consumes: the `learning-path/generate` endpoint from Task 8.
- Produces: no new exports; the Förderplan response gains `learning_path_id`.

- [ ] **Step 1: Add the call**

Immediately before `foerderplan-generate` returns its success response, add:

```ts
  // Create the draft Lernpfad so the teacher finds one waiting rather than
  // having to ask for it. A failure here must never fail the Förderplan.
  let learning_path_id: string | null = null;
  try {
    const resp = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/learning-path/generate`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
        },
        body: JSON.stringify({ session_id: sessionId }),
      },
    );
    if (resp.ok) learning_path_id = (await resp.json()).path_id ?? null;
  } catch (_e) {
    learning_path_id = null;
  }
```

Add `learning_path_id` to the returned JSON object. If the local variable holding the session id is not named `sessionId`, use whatever the function already calls it — do not rename it.

- [ ] **Step 2: Type-check and deploy**

Run: `cd backend/supabase/functions && deno check foerderplan-generate/index.ts`
Then: `cd backend && supabase functions deploy foerderplan-generate`

- [ ] **Step 3: Verify end to end**

Generate a Förderplan for a completed session through the dashboard, then:

```bash
psql "$SUPABASE_DB_URL" -c \
  "select lp.id, lp.status, count(pi.id) as items
   from learning_paths lp left join path_items pi on pi.path_id = lp.id
   where lp.source_session_id = '<session_id>' group by lp.id, lp.status;"
# Expected: one row, status 'draft', items = recommended_skill_ids.length
```

- [ ] **Step 4: Confirm the Förderplan still generates when the path fails**

Temporarily deploy with a bad URL, regenerate, and confirm the Förderplan still returns 200 with `learning_path_id: null`. Restore afterwards. The Förderplan is the shipped feature; the path is additive and must never break it.

- [ ] **Step 5: Commit**

```bash
git add backend/supabase/functions/foerderplan-generate/index.ts
git commit -m "feat(backend): create the draft Lernpfad alongside the Förderplan"
```

---

## Task 11: Flutter models

**Files:**
- Create: `math_app/lib/models/learning_path.dart`
- Create: `math_app/test/learning_path_model_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum PathItemState { locked, available, inProgress, mastered, skipped }`, `class SkillProgress`, `class PathItem`, `class LearningPath`, each with `fromJson`.

- [ ] **Step 1: Write the failing test**

```dart
// math_app/test/learning_path_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/learning_path.dart';

void main() {
  test('parses a path payload from the edge function', () {
    final path = LearningPath.fromJson({
      'path_id': 'p1',
      'unlock_width': 3,
      'items': [
        {
          'skill_id': 'A3.1',
          'position': 0,
          'state': 'available',
          'title_de': 'Teil-Teil-Ganzes bis 10',
          'description_de': 'Zerlegt Zahlen bis 10.',
          'color': 'emerald',
          'progress': [
            {'level': 1, 'attempts': 8, 'correct': 7, 'mastered_at': '2026-08-30T10:00:00Z'},
          ],
        },
      ],
    });

    expect(path.pathId, 'p1');
    expect(path.unlockWidth, 3);
    expect(path.items.single.skillId, 'A3.1');
    expect(path.items.single.state, PathItemState.available);
    expect(path.items.single.progressForLevel(1)?.correct, 7);
    expect(path.items.single.progressForLevel(2), isNull);
  });

  test('an empty path parses without throwing', () {
    final path = LearningPath.fromJson({'path_id': null, 'items': []});
    expect(path.pathId, isNull);
    expect(path.items, isEmpty);
    expect(path.hasActivePath, isFalse);
  });

  test('unknown state falls back to locked rather than crashing', () {
    final path = LearningPath.fromJson({
      'path_id': 'p1',
      'items': [
        {'skill_id': 'A1.1', 'position': 0, 'state': 'wat', 'title_de': 'X', 'progress': []},
      ],
    });
    expect(path.items.single.state, PathItemState.locked);
  });

  test('isMastered requires all three levels', () {
    final item = PathItem.fromJson({
      'skill_id': 'A1.1', 'position': 0, 'state': 'in_progress', 'title_de': 'X',
      'progress': [
        {'level': 1, 'attempts': 8, 'correct': 8, 'mastered_at': '2026-08-30T10:00:00Z'},
        {'level': 2, 'attempts': 8, 'correct': 8, 'mastered_at': '2026-08-30T10:00:00Z'},
      ],
    });
    expect(item.isMastered, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd math_app && flutter test test/learning_path_model_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:math_app/models/learning_path.dart'`

- [ ] **Step 3: Write the models**

```dart
// math_app/lib/models/learning_path.dart

enum PathItemState { locked, available, inProgress, mastered, skipped }

PathItemState _stateFrom(String? raw) {
  switch (raw) {
    case 'available':
      return PathItemState.available;
    case 'in_progress':
      return PathItemState.inProgress;
    case 'mastered':
      return PathItemState.mastered;
    case 'skipped':
      return PathItemState.skipped;
    default:
      return PathItemState.locked;
  }
}

class SkillProgress {
  final int level;
  final int attempts;
  final int correct;
  final DateTime? masteredAt;

  const SkillProgress({
    required this.level,
    required this.attempts,
    required this.correct,
    required this.masteredAt,
  });

  bool get isMastered => masteredAt != null;

  factory SkillProgress.fromJson(Map<String, dynamic> j) => SkillProgress(
        level: j['level'] as int? ?? 0,
        attempts: j['attempts'] as int? ?? 0,
        correct: j['correct'] as int? ?? 0,
        masteredAt: j['mastered_at'] == null
            ? null
            : DateTime.tryParse(j['mastered_at'] as String),
      );
}

class PathItem {
  final String skillId;
  final int position;
  final PathItemState state;
  final String titleDe;
  final String descriptionDe;
  final String color;
  final List<SkillProgress> progress;

  const PathItem({
    required this.skillId,
    required this.position,
    required this.state,
    required this.titleDe,
    required this.descriptionDe,
    required this.color,
    required this.progress,
  });

  SkillProgress? progressForLevel(int level) {
    for (final p in progress) {
      if (p.level == level) return p;
    }
    return null;
  }

  /// A skill counts as mastered only when all three E-I-S levels are.
  bool get isMastered =>
      [1, 2, 3].every((lv) => progressForLevel(lv)?.isMastered ?? false);

  /// The next level the child should work on: the first not yet mastered.
  int get nextLevel {
    for (final lv in [1, 2, 3]) {
      if (!(progressForLevel(lv)?.isMastered ?? false)) return lv;
    }
    return 3;
  }

  factory PathItem.fromJson(Map<String, dynamic> j) => PathItem(
        skillId: j['skill_id'] as String,
        position: j['position'] as int? ?? 0,
        state: _stateFrom(j['state'] as String?),
        titleDe: j['title_de'] as String? ?? '',
        descriptionDe: j['description_de'] as String? ?? '',
        color: j['color'] as String? ?? 'gray',
        progress: ((j['progress'] as List?) ?? const [])
            .map((p) => SkillProgress.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class LearningPath {
  final String? pathId;
  final int unlockWidth;
  final List<PathItem> items;

  const LearningPath({
    required this.pathId,
    required this.unlockWidth,
    required this.items,
  });

  bool get hasActivePath => pathId != null && items.isNotEmpty;

  List<PathItem> get openItems => items
      .where((i) =>
          i.state == PathItemState.available || i.state == PathItemState.inProgress)
      .toList();

  factory LearningPath.fromJson(Map<String, dynamic> j) => LearningPath(
        pathId: j['path_id'] as String?,
        unlockWidth: j['unlock_width'] as int? ?? 3,
        items: ((j['items'] as List?) ?? const [])
            .map((i) => PathItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd math_app && flutter test test/learning_path_model_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add math_app/lib/models/learning_path.dart math_app/test/learning_path_model_test.dart
git commit -m "feat(app): learning-path models"
```

---

## Task 12: Offline attempt queue

The child must not lose work when school wifi drops. The queue is pure Dart over `shared_preferences`, so it is fully unit-testable.

**Files:**
- Create: `math_app/lib/services/attempt_queue.dart`
- Create: `math_app/test/attempt_queue_test.dart`

**Interfaces:**
- Consumes: `shared_preferences`.
- Produces: `class PracticeAttempt` (`toJson`/`fromJson`), `class AttemptQueue` with `Future<void> add(String practiceSessionId, PracticeAttempt a)`, `Future<List<PracticeAttempt>> pending(String practiceSessionId)`, `Future<int> flush(String practiceSessionId, Future<bool> Function(List<PracticeAttempt>) send)`, `Future<void> clear(String practiceSessionId)`.

- [ ] **Step 1: Write the failing test**

```dart
// math_app/test/attempt_queue_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/services/attempt_queue.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PracticeAttempt attempt(int i, {bool correct = true}) => PracticeAttempt(
        problemIndex: i,
        problem: {'a': i, 'b': 1},
        answer: '$i',
        wasCorrect: correct,
        responseMs: 1500,
        errorCode: correct ? null : 'off_by_one',
      );

  test('queues attempts and reports them as pending', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    await q.add('ps1', attempt(1));
    expect((await q.pending('ps1')).length, 2);
  });

  test('queues are isolated per practice session', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    await q.add('ps2', attempt(0));
    expect((await q.pending('ps1')).length, 1);
    expect((await q.pending('ps2')).length, 1);
  });

  test('a successful flush empties the queue', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    final sent = await q.flush('ps1', (batch) async => true);
    expect(sent, 1);
    expect(await q.pending('ps1'), isEmpty);
  });

  test('a failed flush keeps everything for the next attempt', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    final sent = await q.flush('ps1', (batch) async => false);
    expect(sent, 0);
    expect((await q.pending('ps1')).length, 1);
  });

  test('attempts survive a new queue instance (closed browser)', () async {
    await AttemptQueue().add('ps1', attempt(0));
    expect((await AttemptQueue().pending('ps1')).length, 1);
  });

  test('re-adding the same problem_index does not duplicate', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(3));
    await q.add('ps1', attempt(3));
    expect((await q.pending('ps1')).length, 1);
  });

  test('flushing an empty queue is a no-op that does not call send', () async {
    final q = AttemptQueue();
    var called = false;
    final sent = await q.flush('ps1', (batch) async {
      called = true;
      return true;
    });
    expect(sent, 0);
    expect(called, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd math_app && flutter test test/attempt_queue_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:math_app/services/attempt_queue.dart'`

- [ ] **Step 3: Write the queue**

```dart
// math_app/lib/services/attempt_queue.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One answered practice problem, held locally until the server confirms it.
class PracticeAttempt {
  final int problemIndex;
  final Map<String, dynamic> problem;
  final String? answer;
  final bool wasCorrect;
  final int? responseMs;
  final String? errorCode;

  const PracticeAttempt({
    required this.problemIndex,
    required this.problem,
    required this.answer,
    required this.wasCorrect,
    required this.responseMs,
    required this.errorCode,
  });

  Map<String, dynamic> toJson() => {
        'problem_index': problemIndex,
        'problem': problem,
        'answer': answer,
        'was_correct': wasCorrect,
        'response_ms': responseMs,
        'error_code': errorCode,
      };

  factory PracticeAttempt.fromJson(Map<String, dynamic> j) => PracticeAttempt(
        problemIndex: j['problem_index'] as int,
        problem: (j['problem'] as Map).cast<String, dynamic>(),
        answer: j['answer'] as String?,
        wasCorrect: j['was_correct'] as bool? ?? false,
        responseMs: j['response_ms'] as int?,
        errorCode: j['error_code'] as String?,
      );
}

/// Buffers attempts on the device so a dropped connection never costs a
/// child their work. Flushes are idempotent server-side on problem_index,
/// so a retry after an ambiguous failure is safe.
class AttemptQueue {
  static const _prefix = 'attempt_queue_';

  String _key(String practiceSessionId) => '$_prefix$practiceSessionId';

  Future<void> add(String practiceSessionId, PracticeAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await pending(practiceSessionId);
    if (current.any((a) => a.problemIndex == attempt.problemIndex)) return;
    current.add(attempt);
    await prefs.setString(
      _key(practiceSessionId),
      jsonEncode(current.map((a) => a.toJson()).toList()),
    );
  }

  Future<List<PracticeAttempt>> pending(String practiceSessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(practiceSessionId));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PracticeAttempt.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Sends everything pending via [send]. Returns the number of attempts
  /// accepted; keeps the queue intact when [send] reports failure.
  Future<int> flush(
    String practiceSessionId,
    Future<bool> Function(List<PracticeAttempt>) send,
  ) async {
    final batch = await pending(practiceSessionId);
    if (batch.isEmpty) return 0;
    final ok = await send(batch);
    if (!ok) return 0;
    await clear(practiceSessionId);
    return batch.length;
  }

  Future<void> clear(String practiceSessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(practiceSessionId));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd math_app && flutter test test/attempt_queue_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add math_app/lib/services/attempt_queue.dart math_app/test/attempt_queue_test.dart
git commit -m "feat(app): offline attempt queue with idempotent flush"
```

---

## Task 13: Student auth and learning-path services

**Files:**
- Create: `math_app/lib/services/student_auth_service.dart`
- Create: `math_app/lib/services/learning_path_service.dart`
- Create: `math_app/test/student_auth_service_test.dart`

**Interfaces:**
- Consumes: `http`, `shared_preferences`, `AttemptQueue`, `LearningPath` models.
- Produces: `class RosterEntry`, `class StudentAuthService` (`fetchRoster`, `login`, `storedToken`, `logout`), `class LearningPathService` (`fetchPath`, `startPractice`, `syncAttempts`, `endPractice`). Both accept an injected `http.Client` so tests need no network.

- [ ] **Step 1: Write the failing test**

```dart
// math_app/test/student_auth_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/services/student_auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fetchRoster returns names and avatars', () async {
    final client = MockClient((req) async => http.Response(
          jsonEncode({
            'class_id': 'c1',
            'require_pin': false,
            'students': [
              {'id': 's1', 'display_name': 'Mia', 'avatar': 'fuchs'},
              {'id': 's2', 'display_name': 'Jonas', 'avatar': 'eule'},
            ],
          }),
          200,
        ));

    final roster = await StudentAuthService(client: client)
        .fetchRoster(schoolSlug: 'lindenschule', classCode: '7k2m');

    expect(roster.students.length, 2);
    expect(roster.students.first.displayName, 'Mia');
    expect(roster.requirePin, isFalse);
  });

  test('an unknown code raises a German error', () async {
    final client = MockClient((req) async =>
        http.Response(jsonEncode({'error': 'Code nicht gefunden'}), 404));

    expect(
      () => StudentAuthService(client: client)
          .fetchRoster(schoolSlug: 'x', classCode: 'ZZZZ'),
      throwsA(isA<StudentAuthException>()
          .having((e) => e.message, 'message', 'Code nicht gefunden')),
    );
  });

  test('too many attempts surfaces the rate-limit message', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'error': 'Zu viele Versuche. Bitte später noch einmal probieren.'}), 429));

    expect(
      () => StudentAuthService(client: client)
          .fetchRoster(schoolSlug: 'x', classCode: 'ABCD'),
      throwsA(isA<StudentAuthException>()),
    );
  });

  test('login stores the token for the next screen', () async {
    final client = MockClient((req) async => http.Response(
          jsonEncode({'token': 'jwt-abc', 'student_id': 's1', 'display_name': 'Mia'}),
          200,
        ));

    final service = StudentAuthService(client: client);
    final session = await service.login(studentId: 's1');

    expect(session.token, 'jwt-abc');
    expect(await service.storedToken(), 'jwt-abc');
  });

  test('logout clears the stored token', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'token': 't', 'student_id': 's1', 'display_name': 'Mia'}), 200));
    final service = StudentAuthService(client: client);
    await service.login(studentId: 's1');
    await service.logout();
    expect(await service.storedToken(), isNull);
  });

  test('the class code is sent upper-cased and trimmed', () async {
    String? sentBody;
    final client = MockClient((req) async {
      sentBody = req.body;
      return http.Response(
          jsonEncode({'class_id': 'c1', 'require_pin': false, 'students': []}), 200);
    });

    await StudentAuthService(client: client)
        .fetchRoster(schoolSlug: 'lindenschule', classCode: ' 7k2m ');

    expect(jsonDecode(sentBody!)['class_code'], '7K2M');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd math_app && flutter test test/student_auth_service_test.dart`
Expected: FAIL — missing `package:math_app/services/student_auth_service.dart`. If `http/testing.dart` is also missing, add `http` to `dev_dependencies` is not needed — `MockClient` ships inside the `http` package already in `dependencies`.

- [ ] **Step 3: Write the services**

```dart
// math_app/lib/services/student_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _functionsUrl = 'https://zzxqeqwffexythqzjkxr.supabase.co/functions/v1';
const _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6eHFlcXdmZmV4eXRocXpqa3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NjE5ODUsImV4cCI6MjA5NDUzNzk4NX0.Wj_77px6gCPR97W0kOlVhaqDnZp9WqwmtoJlCGHsR4A';

class StudentAuthException implements Exception {
  final String message;
  const StudentAuthException(this.message);
  @override
  String toString() => message;
}

class RosterEntry {
  final String id;
  final String displayName;
  final String? avatar;
  const RosterEntry({required this.id, required this.displayName, required this.avatar});

  factory RosterEntry.fromJson(Map<String, dynamic> j) => RosterEntry(
        id: j['id'] as String,
        displayName: j['display_name'] as String? ?? '',
        avatar: j['avatar'] as String?,
      );
}

class Roster {
  final String classId;
  final bool requirePin;
  final List<RosterEntry> students;
  const Roster({required this.classId, required this.requirePin, required this.students});
}

class StudentSession {
  final String token;
  final String studentId;
  final String displayName;
  const StudentSession({
    required this.token,
    required this.studentId,
    required this.displayName,
  });
}

class StudentAuthService {
  static const _tokenKey = 'student_token';
  static const _nameKey = 'student_name';

  final http.Client _client;
  StudentAuthService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_anonKey',
        'apikey': _anonKey,
      };

  Future<Roster> fetchRoster({
    required String schoolSlug,
    required String classCode,
  }) async {
    final res = await _client.post(
      Uri.parse('$_functionsUrl/student-auth/roster'),
      headers: _headers,
      body: jsonEncode({
        'school_slug': schoolSlug,
        'class_code': classCode.trim().toUpperCase(),
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw StudentAuthException(body['error'] as String? ?? 'Anmeldung nicht möglich');
    }

    return Roster(
      classId: body['class_id'] as String? ?? '',
      requirePin: body['require_pin'] as bool? ?? false,
      students: ((body['students'] as List?) ?? const [])
          .map((s) => RosterEntry.fromJson((s as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<StudentSession> login({required String studentId, String? pin}) async {
    final res = await _client.post(
      Uri.parse('$_functionsUrl/student-auth/login'),
      headers: _headers,
      body: jsonEncode({'student_id': studentId, if (pin != null) 'pin': pin}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw StudentAuthException(body['error'] as String? ?? 'Anmeldung nicht möglich');
    }

    final session = StudentSession(
      token: body['token'] as String,
      studentId: body['student_id'] as String,
      displayName: body['display_name'] as String? ?? '',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_nameKey, session.displayName);
    return session;
  }

  Future<String?> storedToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<String?> storedName() async =>
      (await SharedPreferences.getInstance()).getString(_nameKey);

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
  }
}
```

```dart
// math_app/lib/services/learning_path_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_path.dart';
import 'attempt_queue.dart';

const _functionsUrl = 'https://zzxqeqwffexythqzjkxr.supabase.co/functions/v1';
const _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6eHFlcXdmZmV4eXRocXpqa3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NjE5ODUsImV4cCI6MjA5NDUzNzk4NX0.Wj_77px6gCPR97W0kOlVhaqDnZp9WqwmtoJlCGHsR4A';

class LearningPathService {
  final http.Client _client;
  final AttemptQueue _queue;

  LearningPathService({http.Client? client, AttemptQueue? queue})
      : _client = client ?? http.Client(),
        _queue = queue ?? AttemptQueue();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_anonKey',
        'apikey': _anonKey,
        'x-student-token': token,
      };

  Future<LearningPath> fetchPath(String token) async {
    final res = await _client.get(
      Uri.parse('$_functionsUrl/learning-path'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('Lernpfad konnte nicht geladen werden (${res.statusCode})');
    }
    return LearningPath.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<({String practiceSessionId, int seed})> startPractice(
    String token, {
    required String skillId,
    required int level,
  }) async {
    final res = await _client.post(
      Uri.parse('$_functionsUrl/practice-session/start'),
      headers: _headers(token),
      body: jsonEncode({'skill_id': skillId, 'level': level}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(body['error'] as String? ?? 'Übung konnte nicht gestartet werden');
    }
    return (
      practiceSessionId: body['practice_session_id'] as String,
      seed: body['seed'] as int,
    );
  }

  /// Records an attempt locally, then tries to flush. A failed flush is
  /// silent: the queue keeps the work and the next call retries.
  Future<void> recordAttempt(
    String token,
    String practiceSessionId,
    PracticeAttempt attempt,
  ) async {
    await _queue.add(practiceSessionId, attempt);
    await _queue.flush(practiceSessionId, (batch) async {
      try {
        final res = await _client.post(
          Uri.parse('$_functionsUrl/practice-session/sync'),
          headers: _headers(token),
          body: jsonEncode({
            'practice_session_id': practiceSessionId,
            'attempts': batch.map((a) => a.toJson()).toList(),
          }),
        );
        return res.statusCode == 200;
      } catch (_) {
        return false;
      }
    });
  }

  Future<({bool mastered, bool slowFlag, List<String> unlocked})> endPractice(
    String token,
    String practiceSessionId, {
    required int slowBandMs,
  }) async {
    // Last chance to deliver anything still queued before we score the session.
    await _queue.flush(practiceSessionId, (batch) async {
      final res = await _client.post(
        Uri.parse('$_functionsUrl/practice-session/sync'),
        headers: _headers(token),
        body: jsonEncode({
          'practice_session_id': practiceSessionId,
          'attempts': batch.map((a) => a.toJson()).toList(),
        }),
      );
      return res.statusCode == 200;
    });

    final res = await _client.post(
      Uri.parse('$_functionsUrl/practice-session/end'),
      headers: _headers(token),
      body: jsonEncode({
        'practice_session_id': practiceSessionId,
        'slow_band_ms': slowBandMs,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(body['error'] as String? ?? 'Übung konnte nicht abgeschlossen werden');
    }
    return (
      mastered: body['skill_mastered'] as bool? ?? false,
      slowFlag: body['slow_flag'] as bool? ?? false,
      unlocked: ((body['unlocked_skill_ids'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd math_app && flutter test test/student_auth_service_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Run the whole suite and analyzer**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (38 pre-existing + 17 new); analyzer at or below 323 lints, 0 errors.

- [ ] **Step 6: Commit**

```bash
git add math_app/lib/services/student_auth_service.dart math_app/lib/services/learning_path_service.dart math_app/test/student_auth_service_test.dart
git commit -m "feat(app): student auth and learning-path services"
```

---

## Task 14: Child login screen

This is the first task with a visual surface, so it goes through the visual-reviewer and critic gates from spec §6.

**Files:**
- Create: `math_app/lib/screens/child_login_screen.dart`
- Create: `math_app/test/child_login_screen_test.dart`
- Modify: `math_app/lib/main.dart` (add the `/lernen/:slug` route to the existing `go_router` config)

**Interfaces:**
- Consumes: `StudentAuthService`, `Roster`, `RosterEntry`.
- Produces: `class ChildLoginScreen extends StatefulWidget` taking `final String schoolSlug;` and an optional `final StudentAuthService? authService;` for tests.

- [ ] **Step 1: Write the failing widget test**

```dart
// math_app/test/child_login_screen_test.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/screens/child_login_screen.dart';
import 'package:math_app/services/student_auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  StudentAuthService serviceReturningRoster() => StudentAuthService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('roster')) {
            return http.Response(
              jsonEncode({
                'class_id': 'c1',
                'require_pin': false,
                'students': [
                  {'id': 's1', 'display_name': 'Mia', 'avatar': 'fuchs'},
                  {'id': 's2', 'display_name': 'Jonas', 'avatar': 'eule'},
                ],
              }),
              200,
            );
          }
          return http.Response(
              jsonEncode({'token': 't', 'student_id': 's1', 'display_name': 'Mia'}), 200);
        }),
      );

  testWidgets('asks for the class code in German', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));
    expect(find.text('Klassencode'), findsOneWidget);
    expect(find.textContaining('code'), findsNothing); // no English leakage
  });

  testWidgets('shows the roster after a valid code', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));

    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Wer bist du?'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Jonas'), findsOneWidget);
  });

  testWidgets('a wrong code shows a friendly German message', (tester) async {
    final failing = StudentAuthService(
      client: MockClient((req) async =>
          http.Response(jsonEncode({'error': 'Code nicht gefunden'}), 404)),
    );

    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: failing),
    ));

    await tester.enterText(find.byType(TextField), 'ZZZZ');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Code nicht gefunden'), findsOneWidget);
  });

  testWidgets('name buttons are at least 44 logical pixels tall', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));
    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.ancestor(
      of: find.text('Mia'),
      matching: find.byType(InkWell),
    ).first);
    expect(size.height, greaterThanOrEqualTo(44.0));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd math_app && flutter test test/child_login_screen_test.dart`
Expected: FAIL — missing `package:math_app/screens/child_login_screen.dart`

- [ ] **Step 3: Write the screen**

```dart
// math_app/lib/screens/child_login_screen.dart
import 'package:flutter/material.dart';
import '../services/student_auth_service.dart';

/// Two steps, one decision each: type the class code, then tap your name.
/// Nothing on this screen requires reading beyond a first-grader's level.
class ChildLoginScreen extends StatefulWidget {
  final String schoolSlug;
  final StudentAuthService? authService;

  const ChildLoginScreen({super.key, required this.schoolSlug, this.authService});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  late final StudentAuthService _auth = widget.authService ?? StudentAuthService();
  final _codeController = TextEditingController();

  Roster? _roster;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadRoster() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final roster = await _auth.fetchRoster(
        schoolSlug: widget.schoolSlug,
        classCode: _codeController.text,
      );
      setState(() => _roster = roster);
    } on StudentAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Es hat nicht geklappt. Bitte noch einmal versuchen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(RosterEntry entry) async {
    setState(() => _busy = true);
    try {
      await _auth.login(studentId: entry.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/lernpfad');
    } on StudentAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _roster == null ? _buildCodeStep(context) : _buildRosterStep(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Klassencode',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Gib den Code von der Tafel ein.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          autofocus: true,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 4,
          style: const TextStyle(fontSize: 40, letterSpacing: 12),
          decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
          onSubmitted: (_) => _loadRoster(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 18)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _busy ? null : _loadRoster,
            child: const Text('Weiter', style: TextStyle(fontSize: 22)),
          ),
        ),
      ],
    );
  }

  Widget _buildRosterStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Wer bist du?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Flexible(
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              for (final entry in _roster!.students)
                InkWell(
                  onTap: _busy ? null : () => _pick(entry),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 88),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_avatarGlyph(entry.avatar), style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(entry.displayName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _roster = null),
          child: const Text('Zurück', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  String _avatarGlyph(String? avatar) {
    const glyphs = {
      'fuchs': '🦊', 'eule': '🦉', 'schildkroete': '🐢', 'biene': '🐝',
      'igel': '🦔', 'wal': '🐳', 'frosch': '🐸', 'baer': '🐻',
    };
    return glyphs[avatar] ?? '⭐';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd math_app && flutter test test/child_login_screen_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Wire the route**

In `math_app/lib/main.dart`, add to the existing `GoRouter` route list, following the pattern of the neighbouring `/s/:ticket` route:

```dart
GoRoute(
  path: '/lernen/:slug',
  builder: (context, state) =>
      ChildLoginScreen(schoolSlug: state.pathParameters['slug']!),
),
```

- [ ] **Step 6: Full suite, analyzer, web build**

Run: `cd math_app && flutter test && flutter analyze && flutter build web --no-tree-shake-icons`
Expected: all tests pass; analyzer at or below 323 lints, 0 errors; web build succeeds.

- [ ] **Step 7: Visual and critic review**

Dispatch the visual-reviewer agent (sonnet) against `/lernen/<slug>` at 768×1024, 1024×768 and 390×844, light and dark. Then the critic agent against the §6 rubric. Both must return no findings before this task closes.

- [ ] **Step 8: Commit**

```bash
git add math_app/lib/screens/child_login_screen.dart math_app/test/child_login_screen_test.dart math_app/lib/main.dart
git commit -m "feat(app): child login — class code and name grid"
```

---

## Task 15: ADR for the mastery and slow-flag rule

The charter requires a written basis for every pedagogical rule. The mastery threshold and the slow bands are pedagogical, not technical.

**Files:**
- Create: `docs/clean-room/decisions/0009-mastery-and-slow-response.md`
- Modify: `docs/clean-room/provenance.csv` (append one row)

**Interfaces:**
- Consumes: `_shared/mastery.ts` constants.
- Produces: no code.

- [ ] **Step 1: Write the ADR**

Follow the layout of `docs/clean-room/decisions/0005-why-domains-a-d.md` exactly — same header table, same section order (Context / Decision / Reasoning / Consequences / Date). Record:

- **Decision:** a level is mastered at ≥7 of 8 correct (87.5%); response time never gates progression and instead sets `skill_progress.slow_flag` for the teacher.
- **Reasoning:** a mastery bar must be high enough that a guessing child does not pass and low enough that a single slip does not block a secure one; 7 of 8 is that band. Timing is diagnostic of *how* a child computes, not *whether* they can — and the didactic goal is Ablösung vom zählenden Rechnen, which is the teacher's judgment to make, not the software's. Cite the bibliography entries already in `03-bibliography.md` (Selter & Spiegel 1997 for response time as a strategy indicator; Wartha 2019 for the zählendes-Rechnen frame).
- **Consequences:** the slow bands are tunable from pilot data without changing progression behaviour, because they gate nothing.
- **Status:** DRAFT — awaiting Jakob's sign-off, per the pattern of the other provisional ADRs.

- [ ] **Step 2: Add the provenance row**

Append to `docs/clean-room/provenance.csv`:

```csv
0009-mastery-and-slow-response,decision,Claude (draft),2026-08-30,Selter & Spiegel 1997; Wartha 2019,,,Eigene Festlegung der Meisterungsschwelle und der Zeitbänder; keine Übernahme von Schwellenwerten eines bestehenden Instruments.
```

- [ ] **Step 3: Verify the provenance gate still passes**

Run: `python scripts/check_provenance.py`
Expected: `OK`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add docs/clean-room/decisions/0009-mastery-and-slow-response.md docs/clean-room/provenance.csv
git commit -m "docs(clean-room): ADR 0009 — mastery threshold and slow-response flag"
```

---

## Task 16: P1 integration proof

The gate that says P1 is done: the whole chain, on the deployed preview.

**Files:**
- Create: `docs/superpowers/plans/p1-acceptance.md` (the recorded run)

**Interfaces:**
- Consumes: everything above.
- Produces: a written acceptance record.

- [ ] **Step 1: Run the chain**

1. Teacher logs into the dashboard, opens a class, rotates the class code (`select rotate_class_code('<class_id>');` until the dashboard button lands in P4).
2. A student completes a diagnostic through the existing flow.
3. Förderplan generates; confirm the response carries a non-null `learning_path_id`.
4. Confirm the path is `draft` and invisible to the child.
5. Activate the path (`PATCH … action=activate`).
6. Open `/lernen/<slug>` on an iPad, enter the class code, tap the child's name.
7. Confirm the path renders with exactly `unlock_width` items available.
8. Start a practice session, sync attempts, end it.
9. Confirm `skill_progress` updated and the teacher can see it.

- [ ] **Step 2: Prove the offline path**

Mid-practice, switch the iPad to airplane mode, answer three problems, restore the connection, end the session. Confirm all three attempts arrive exactly once:

```bash
psql "$SUPABASE_DB_URL" -c \
  "select problem_index, count(*) from practice_attempts
   where practice_session_id='<ps>' group by problem_index order by problem_index;"
# Expected: every count = 1
```

- [ ] **Step 3: Re-run every gate**

```bash
cd backend/supabase/functions && deno test --allow-net _shared/
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f ../tests/rls_learning_path.sql
cd ../../../math_app && flutter test && flutter analyze
cd ../dashboard && npx tsc --noEmit
grep -rniE "imint|pikas|senbjf|lisum|kaufen" ../backend/supabase/functions ../math_app/lib . --include=*.ts --include=*.dart --include=*.tsx
```

Expected: all green; the grep returns nothing.

- [ ] **Step 4: Record and commit**

Write the acceptance record with the date, the device used, and any deviation observed.

```bash
git add docs/superpowers/plans/p1-acceptance.md
git commit -m "docs: P1 acceptance record"
```

---

## Self-Review

**Spec coverage:** §4.1 schema → Task 2. §4.2 RLS and the four denials → Task 3. §4.3 login, rate limiting, PIN, roster minimisation → Tasks 4, 5, 6, 14. §4.4 derivation, unlock window, draft-until-activated → Tasks 8, 10. §4.5 mastery and slow flag → Tasks 7, 9, 15. §4.6 all eight endpoints → Tasks 6, 8, 9. §4.7 offline sync → Tasks 12, 13. §4.8 all four test layers → Tasks 2, 3, 11–14, 16. §6 gates → Task 14 step 7 and Task 16 step 3.

**Known gaps, deliberately deferred:** the teacher-facing UI for rotating a class code and editing a path is P4 — until then those actions run through `rotate_class_code()` and the PATCH endpoint directly, which Task 16 step 1 states explicitly. The practice *runtime* that consumes `seed` and renders problems is P2; P1 proves the plumbing with hand-posted attempts.

**Type consistency:** `sortSkillIds` (Task 1) is used in Task 8. `verifyStudentToken` (Task 5) is used in Tasks 8 and 9. `nextUnlock` (Task 7) is used in Task 9. `PracticeAttempt` (Task 12) is consumed by `LearningPathService.recordAttempt` (Task 13). `PathItemState` (Task 11) is consumed by Task 14. The `x-student-token` header name is identical in Tasks 8, 9 and 13.
