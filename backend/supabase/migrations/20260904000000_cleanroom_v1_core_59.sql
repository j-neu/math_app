-- ============================================================
-- cleanroom-v1: core tier 60 -> 59 (retire A1.5-01)
-- ============================================================
--
-- WHY: Jakob's R2.9 item review (2026-08-30) struck A1.5-01 as redundant
-- against A1.1-02, whose ZR100 counting sequence already crosses two Dekaden
-- and therefore already measures the Zehnerübergang. docs/clean-room/
-- 02-blueprint.md and provenance.csv were updated then; the runtime CSV and
-- this database were not. This migration closes that gap.
--
-- WHY NOT DELETE: public.diagnostic_results.question_id references
-- diagnostic_questions ON DELETE CASCADE. Deleting the A1.5-01 row would
-- silently destroy every answer any child has already given to it. The row is
-- therefore RETIRED (tier='retired', parked at question_number 900), never
-- removed. Old sessions keep rendering; no new session can reach it, because
-- the app only ever walks question_number 1..question_count.
--
-- WHY RENUMBER: the Flutter client posts `question_number` taken from the
-- CSV's ListNumber, and diagnostic-results resolves the question UUID by
-- matching that number (functions/diagnostic-results/index.ts:66). The CSV was
-- regenerated to 1..59 by scripts/generate_diagnostic_csv.py, so the database
-- MUST use the identical numbering or every answer from position 8 onward is
-- recorded against the wrong question. Deep-dive rows shift 61..92 -> 60..91
-- to stay contiguous behind the core tier.
--
-- ⚠️ IN-FLIGHT SESSIONS: a session that is `in_progress` against cleanroom-v1
-- when this runs will resume against the new numbering. Stored results are
-- keyed by question UUID and are NOT corrupted, but the resume cursor is
-- keyed by number, so a paused child could be shown a neighbouring question.
-- The pre-flight block below ABORTS if any in-progress session exists. Either
-- let them finish or force-complete them from the dashboard first.

-- NOTE: no explicit begin/commit — `supabase db push` already runs each
-- migration inside its own transaction, and every other migration in this
-- directory follows that convention. A RAISE EXCEPTION in any block below
-- therefore rolls the whole migration back and leaves the database untouched.

-- ---------- 1. Pre-flight guards (abort rather than corrupt) ----------
do $$
declare
  v_diag   uuid := '00000000-0000-0000-0000-000000000002';
  v_text   text;
  v_core   int;
  v_deep   int;
  v_live   int;
begin
  -- The row at 8 must be the A1.5-01 counting item we intend to retire.
  select prompt_de into v_text
    from public.diagnostic_questions
   where diagnostic_id = v_diag and question_number = 8;

  if v_text is null then
    raise exception 'Aborting: no question_number 8 on cleanroom-v1 (already migrated?)';
  end if;
  if position('17' in v_text) = 0 or position('23' in v_text) = 0 then
    raise exception 'Aborting: question 8 is not A1.5-01 (found: %). Numbering differs from expectation.', v_text;
  end if;

  select count(*) into v_core from public.diagnostic_questions
   where diagnostic_id = v_diag and tier = 'core';
  select count(*) into v_deep from public.diagnostic_questions
   where diagnostic_id = v_diag and tier = 'deepdive';

  if v_core <> 60 then
    raise exception 'Aborting: expected 60 core rows, found %', v_core;
  end if;
  if v_deep <> 32 then
    raise exception 'Aborting: expected 32 deep-dive rows, found %', v_deep;
  end if;

  select count(*) into v_live from public.diagnostic_sessions
   where diagnostic_id = v_diag and status = 'in_progress';
  if v_live > 0 then
    raise exception
      'Aborting: % in-progress session(s) on cleanroom-v1. Let them finish or force-complete them, then re-run.', v_live;
  end if;
end $$;

-- ---------- 2. Park the retired item out of the served range ----------
update public.diagnostic_questions
   set question_number = 900,
       tier            = 'retired',
       notes           = coalesce(notes || ' | ', '')
                         || 'Retired 2026-09-04 (R2.9): redundant against A1.1-02, '
                         || 'which already crosses two Dekaden. Kept, not deleted, so '
                         || 'existing diagnostic_results stay intact.'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002'
   and question_number = 8;

-- ---------- 3. Close the gap (two-step to dodge the unique index) ----------
-- unique (diagnostic_id, question_number) would trip on an in-place shift,
-- so park the block high, then bring it down one.
update public.diagnostic_questions
   set question_number = question_number + 1000
 where diagnostic_id = '00000000-0000-0000-0000-000000000002'
   and tier in ('core', 'deepdive')
   and question_number between 9 and 92;

update public.diagnostic_questions
   set question_number = question_number - 1001
 where diagnostic_id = '00000000-0000-0000-0000-000000000002'
   and tier in ('core', 'deepdive')
   and question_number between 1009 and 1092;

-- ---------- 4. The core tier is now 59 ----------
update public.diagnostics
   set question_count = 59,
       version        = version + 1
 where id = '00000000-0000-0000-0000-000000000002';

-- ---------- 5. Post-conditions (roll back if reality disagrees) ----------
do $$
declare
  v_diag uuid := '00000000-0000-0000-0000-000000000002';
  v_core int; v_deep int; v_ret int; v_max int; v_min int; v_gaps int; v_qc int;
begin
  select count(*) into v_core from public.diagnostic_questions
   where diagnostic_id = v_diag and tier = 'core';
  select count(*) into v_deep from public.diagnostic_questions
   where diagnostic_id = v_diag and tier = 'deepdive';
  select count(*) into v_ret  from public.diagnostic_questions
   where diagnostic_id = v_diag and tier = 'retired';
  select min(question_number), max(question_number) into v_min, v_max
    from public.diagnostic_questions
   where diagnostic_id = v_diag and tier = 'core';
  select question_count into v_qc from public.diagnostics where id = v_diag;

  if v_core <> 59 then raise exception 'Post-check: core is %, expected 59', v_core; end if;
  if v_deep <> 32 then raise exception 'Post-check: deep-dive is %, expected 32', v_deep; end if;
  if v_ret  <> 1  then raise exception 'Post-check: retired is %, expected 1', v_ret; end if;
  if v_min  <> 1 or v_max <> 59 then
    raise exception 'Post-check: core numbering is %..%, expected 1..59', v_min, v_max;
  end if;
  if v_qc <> 59 then raise exception 'Post-check: question_count is %, expected 59', v_qc; end if;

  -- Core numbering must be gapless, or the client walks off the end.
  select count(*) into v_gaps from (
    select question_number,
           row_number() over (order by question_number) as expected
      from public.diagnostic_questions
     where diagnostic_id = v_diag and tier = 'core'
  ) t where t.question_number <> t.expected;
  if v_gaps > 0 then raise exception 'Post-check: % gap(s) in core numbering', v_gaps; end if;

  raise notice 'cleanroom-v1 migrated: core 1..59, deep-dive 60..91, 1 retired, question_count=59';
end $$;

-- Verify after applying:
--   select tier, count(*), min(question_number), max(question_number)
--     from public.diagnostic_questions
--    where diagnostic_id = '00000000-0000-0000-0000-000000000002'
--    group by tier order by tier;
--   select slug, version, question_count from public.diagnostics
--    where slug = 'cleanroom-v1';
