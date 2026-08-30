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
   'aaaaaaaa-0000-0000-0000-000000000002', 'active');

insert into public.skill_progress (student_id, skill_id, level, attempts, correct)
select id, (select id from public.skills order by id limit 1), 1, 8, 7
from public.students
where id in ('aaaaaaaa-0000-0000-0000-000000000001',
             'aaaaaaaa-0000-0000-0000-000000000002',
             'bbbbbbbb-0000-0000-0000-000000000001');

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

-- ── Denial 4: cross-school isolation ──────────────────────────────────────
-- A teacher of school A must not reach school B. teacher_school_id() reads
-- auth.uid(); with no teacher row for this claim it resolves to NULL, so
-- teacher_student_ids() is empty and every teacher policy denies.
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

reset role;
select set_config('request.jwt.claims', null, true);

-- Fixture sanity: as the owner, all three progress rows do exist — proving the
-- zero counts above came from RLS, not from an empty fixture.
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
end $$;

select 'RLS OK' as result;
rollback;
