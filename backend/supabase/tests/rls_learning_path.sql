-- Spec §4.2 denial tests. One transaction, always rolled back, so this is
-- safe to run against the live project: it leaves no rows behind.
begin;

-- ── Fixture: two schools, one class each, students in both ────────────────
insert into public.schools (id, name, slug) values
  ('11111111-1111-1111-1111-111111111111', 'Testschule A', 'testschule-a-rls'),
  ('22222222-2222-2222-2222-222222222222', 'Testschule B', 'testschule-b-rls');

insert into public.classes (id, school_id, name, class_code) values
  ('11111111-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111', '2a', 'TSTA'),
  ('22222222-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222', '2b', 'TSTB');

insert into public.students (id, class_id, display_name) values
  ('aaaaaaaa-0000-0000-0000-000000000001',
   '11111111-0000-0000-0000-000000000001', 'Kind A1'),
  ('aaaaaaaa-0000-0000-0000-000000000002',
   '11111111-0000-0000-0000-000000000001', 'Kind A2'),
  ('bbbbbbbb-0000-0000-0000-000000000001',
   '22222222-0000-0000-0000-000000000001', 'Kind B1');

insert into public.learning_paths (id, student_id, status) values
  ('cccccccc-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-000000000001', 'active'),
  ('cccccccc-0000-0000-0000-000000000002',
   'aaaaaaaa-0000-0000-0000-000000000002', 'active'),
  ('cccccccc-0000-0000-0000-000000000099',
   'bbbbbbbb-0000-0000-0000-000000000001', 'active');

insert into public.skill_progress (student_id, skill_id, level, attempts, correct)
select id, (select id from public.skills order by id limit 1), 1, 8, 7
from public.students
where id in ('aaaaaaaa-0000-0000-0000-000000000001',
             'aaaaaaaa-0000-0000-0000-000000000002',
             'bbbbbbbb-0000-0000-0000-000000000001');

-- ── Fixture: a real teacher of school A ────────────────────────────────────
-- C1: the cross-school boundary is untested unless a genuine teachers row
-- exists — a principal with NO teachers row (denial 4, below) only proves
-- "a stranger is denied", not "a teacher is scoped to their own school",
-- which is the single most important boundary in a multi-tenant school
-- product. teacher_school_id() reads auth.uid(), which Supabase's auth.uid()
-- resolves from the `sub` claim of request.jwt.claims — so the `sub` here
-- must match this teachers row's id, and a matching auth.users row must
-- exist first to satisfy teachers.id's foreign key.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, recovery_sent_at, last_sign_in_at,
  raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
) values (
  '00000000-0000-0000-0000-000000000000',
  '33333333-3333-3333-3333-333333333333',
  'authenticated', 'authenticated',
  'rls-test-teacher-a@example.invalid',
  crypt('not-used-not-logged-in-with', gen_salt('bf')),
  now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{}',
  now(), now(),
  '', '', '', ''
);

insert into public.teachers (id, school_id, display_name, role) values
  ('33333333-3333-3333-3333-333333333333',
   '11111111-1111-1111-1111-111111111111', 'Frau Testlehrerin', 'teacher');

-- ── Act as child A1 ───────────────────────────────────────────────────────
set local role authenticated;
select set_config('request.jwt.claims',
  '{"role":"authenticated","student_id":"aaaaaaaa-0000-0000-0000-000000000001"}',
  true);

-- Denial 1: a child sees only their own progress, never a classmate's.
do $$
declare n int;
begin
  select count(*) into n from public.skill_progress;
  if n <> 1 then
    raise exception 'FAIL denial 1: child sees % progress rows, expected exactly 1', n;
  end if;
end $$;

-- Denial 2: a child cannot write path_items — only teacher/service role orders a path.
do $$
begin
  begin
    insert into public.path_items (path_id, skill_id, position)
    values ('cccccccc-0000-0000-0000-000000000001',
            (select id from public.skills order by id limit 1), 99);
    raise exception 'FAIL denial 2: child inserted a path_item';
  exception
    when insufficient_privilege then null;  -- expected: RLS refused the write
  end;
end $$;

-- Denial 3: a child cannot read classmates' student rows. The roster endpoint
-- is the only route to classmate names, and it returns name + avatar only.
do $$
declare n int;
begin
  select count(*) into n from public.students;
  if n > 1 then
    raise exception 'FAIL denial 3: child sees % student rows, expected at most 1', n;
  end if;
end $$;

-- Denial 3b: a child cannot read another child's learning path.
do $$
declare n int;
begin
  select count(*) into n from public.learning_paths;
  if n > 1 then
    raise exception 'FAIL denial 3b: child sees % paths, expected at most 1', n;
  end if;
end $$;

-- ── Denial 4: a stranger (no teacher row, no student claim) is denied ──────
-- teacher_school_id() reads auth.uid(); with no teacher row for this claim
-- it resolves to NULL, so teacher_student_ids() is empty and every teacher
-- policy denies. This proves "an unrecognised principal sees nothing" — it
-- does NOT prove school scoping, which is asserted separately below.
select set_config('request.jwt.claims',
  '{"role":"authenticated","sub":"99999999-9999-9999-9999-999999999999"}', true);

do $$
declare n int;
begin
  select count(*) into n from public.skill_progress;
  if n <> 0 then
    raise exception 'FAIL denial 4: non-teacher, non-child principal saw % rows', n;
  end if;
end $$;

-- ── Denial 5: a REAL teacher of school A is scoped to school A only ───────
-- This is the boundary denial 4 could not test: a genuine teachers row,
-- authenticated as that teacher (sub = teachers.id), must see every one of
-- school A's rows and exactly zero of school B's. Both directions, exact
-- counts — not a bare "> 1".
select set_config('request.jwt.claims',
  '{"role":"authenticated","sub":"33333333-3333-3333-3333-333333333333"}', true);

do $$
declare n int;
begin
  -- Sees both of school A's progress rows (Kind A1 + Kind A2).
  select count(*) into n from public.skill_progress
  where student_id in ('aaaaaaaa-0000-0000-0000-000000000001',
                       'aaaaaaaa-0000-0000-0000-000000000002');
  if n <> 2 then
    raise exception
      'FAIL denial 5a: teacher A sees % of school A''s 2 progress rows', n;
  end if;

  -- Sees exactly zero of school B's progress rows.
  select count(*) into n from public.skill_progress
  where student_id = 'bbbbbbbb-0000-0000-0000-000000000001';
  if n <> 0 then
    raise exception
      'FAIL denial 5b: teacher A saw % of school B''s progress rows, expected 0', n;
  end if;

  -- Total visible progress rows must be exactly school A's 2 — no leakage.
  select count(*) into n from public.skill_progress;
  if n <> 2 then
    raise exception
      'FAIL denial 5c: teacher A sees % total progress rows, expected exactly 2', n;
  end if;

  -- Sees both of school A's learning paths.
  select count(*) into n from public.learning_paths
  where student_id in ('aaaaaaaa-0000-0000-0000-000000000001',
                       'aaaaaaaa-0000-0000-0000-000000000002');
  if n <> 2 then
    raise exception
      'FAIL denial 5d: teacher A sees % of school A''s 2 learning paths', n;
  end if;

  -- Sees exactly zero of school B's learning paths.
  select count(*) into n from public.learning_paths
  where student_id = 'bbbbbbbb-0000-0000-0000-000000000001';
  if n <> 0 then
    raise exception
      'FAIL denial 5e: teacher A saw % of school B''s learning paths, expected 0', n;
  end if;

  -- Total visible learning paths must be exactly school A's 2 — no leakage.
  select count(*) into n from public.learning_paths;
  if n <> 2 then
    raise exception
      'FAIL denial 5f: teacher A sees % total learning paths, expected exactly 2', n;
  end if;
end $$;

reset role;
select set_config('request.jwt.claims', null, true);

-- Fixture sanity: as the owner, all rows do exist — proving the zero/exact
-- counts above came from RLS, not from an empty or partial fixture.
do $$
declare n int;
begin
  select count(*) into n from public.skill_progress
  where student_id in ('aaaaaaaa-0000-0000-0000-000000000001',
                       'aaaaaaaa-0000-0000-0000-000000000002',
                       'bbbbbbbb-0000-0000-0000-000000000001');
  if n <> 3 then
    raise exception 'FAIL fixture: expected 3 progress rows, found %', n;
  end if;

  select count(*) into n from public.learning_paths
  where student_id in ('aaaaaaaa-0000-0000-0000-000000000001',
                       'aaaaaaaa-0000-0000-0000-000000000002',
                       'bbbbbbbb-0000-0000-0000-000000000001');
  if n <> 3 then
    raise exception 'FAIL fixture: expected 3 learning paths, found %', n;
  end if;

  select count(*) into n from public.teachers
  where id = '33333333-3333-3333-3333-333333333333'
    and school_id = '11111111-1111-1111-1111-111111111111';
  if n <> 1 then
    raise exception 'FAIL fixture: test teacher row for school A missing';
  end if;
end $$;

select 'RLS OK' as result;
rollback;
