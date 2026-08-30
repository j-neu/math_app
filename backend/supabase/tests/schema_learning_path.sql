-- Schema shape assertions for the Lernpfad tables (plan Task 2).
-- Safe against any database: asserts only, then rolls back.
begin;

do $$
declare
  missing text;
begin
  select string_agg(t, ', ') into missing
  from unnest(array[
    'learning_paths','path_items','skill_progress',
    'practice_sessions','practice_attempts','login_attempts','student_pins'
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

  -- I5: pin_hash must live in student_pins (service-role only, no RLS
  -- policies), never on students, where it would sit behind the
  -- pre-existing row-level "teacher select students" policy.
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'student_pins' and column_name = 'pin_hash'
  ) then raise exception 'FAIL student_pins.pin_hash missing'; end if;

  if exists (
    select 1 from information_schema.columns
    where table_name = 'students' and column_name = 'pin_hash'
  ) then raise exception 'FAIL students.pin_hash still present — must live only in student_pins'; end if;

  if to_regprocedure('public.rotate_class_code(uuid)') is null then
    raise exception 'FAIL rotate_class_code(uuid) missing';
  end if;

  if to_regprocedure('public.reorder_path_items(uuid, text[])') is null then
    raise exception 'FAIL reorder_path_items(uuid, text[]) missing';
  end if;
end $$;

-- unlock_width must reject nonsense. Insert against a REAL student so the
-- check constraint is what fires, not a foreign-key violation.
--
-- I4: a green "SCHEMA OK" that silently skipped this assertion because the
-- database happened to have no students is worse than a red failure — it
-- reports a check as passed when nothing was actually verified. So this
-- FAILS loudly instead of skipping when there is no student to test against;
-- the live project always has pilot data, so this should never fire there.
do $$
declare s_id uuid;
begin
  select id into s_id from public.students limit 1;
  if s_id is null then
    raise exception 'FAIL unlock_width check: no students on this database to test against';
  end if;

  begin
    insert into public.learning_paths (student_id, unlock_width) values (s_id, 0);
    raise exception 'FAIL unlock_width=0 was accepted';
  exception
    when check_violation then null;  -- expected
  end;

  begin
    insert into public.learning_paths (student_id, unlock_width) values (s_id, 11);
    raise exception 'FAIL unlock_width=11 was accepted';
  exception
    when check_violation then null;  -- expected
  end;
end $$;

-- RLS must be enabled on every new table.
do $$
declare unprotected text;
begin
  select string_agg(c.relname, ', ') into unprotected
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('learning_paths','path_items','skill_progress',
                      'practice_sessions','practice_attempts','login_attempts',
                      'student_pins')
    and c.relrowsecurity = false;

  if unprotected is not null then
    raise exception 'FAIL RLS not enabled on: %', unprotected;
  end if;
end $$;

select 'SCHEMA OK' as result;
rollback;
