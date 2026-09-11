-- ============================================================
-- v2 pilot: verdoppeln-halbieren diagnostic items (ZR10/ZR20/ZR100)
-- ============================================================
--
-- WHY: Jakob flagged (2026-09-11) that the single ZR10 pilot item
-- ("Rechne: 4 + 4") tests addition, not the doubling construct, and that
-- the diagnostic has no item at all for doubling across a tens boundary
-- (ZR20) or two-digit doubling (ZR100). docs/clean-room/v2/10-deckungsmatrix.md
-- and the item files under docs/clean-room/v2/items/ were updated to match;
-- this migration is the corresponding runtime change.
--
-- The client CSV (math_app/Research/diagnostic_v2_verdoppeln_halbieren.csv)
-- renumbered the existing item to ListNumber 92 and appended four new rows
-- at 93-96. diagnostic-results/index.ts resolves a submitted answer by
-- matching (diagnostic_id, question_number) exactly against this table
-- (functions/diagnostic-results/index.ts:66), and completion fires once
-- answeredCount >= diagnostics.question_count (line 105) -- so both the rows
-- below AND the question_count bump are required, or a submitted answer
-- 409s against an already-"completed" session, exactly as happened when
-- only the CSV was changed without this migration.
--
-- WHY 92-96, NOT 60-64: an earlier version of this migration used 60-64,
-- assuming the core tier's max (59) marked the start of free numbers. It
-- does not: 20260829000000_cleanroom_v1_bank.sql already occupies
-- 60-91 with the deep-dive tier (same unique index on
-- (diagnostic_id, question_number), tier is not part of the key), and 900
-- holds the one retired core item. That attempt failed atomically on
-- question_number=60 already existing and rolled back cleanly. 92-96 sits
-- after the deep-dive block and before the retired parking spot (900), so
-- it does not collide with either. The core tier is intentionally
-- non-contiguous after this (1-59, then 92-96) -- the completion check is a
-- pure row-count comparison against question_count, not a numbering
-- assumption, so this is safe.

do $$
declare
  v_diag  uuid := '00000000-0000-0000-0000-000000000002';
  v_qc    int;
  v_taken int;
begin
  select question_count into v_qc from public.diagnostics where id = v_diag;
  if v_qc <> 59 then
    raise exception 'Aborting: expected question_count=59, found % (already migrated?)', v_qc;
  end if;

  select count(*) into v_taken from public.diagnostic_questions
   where diagnostic_id = v_diag and question_number between 92 and 96;
  if v_taken <> 0 then
    raise exception 'Aborting: % of question_number 92-96 already taken', v_taken;
  end if;
end $$;

insert into public.diagnostic_questions (
  diagnostic_id, question_number, source_type, prompt_de, prompt_en, answer_format,
  correct_answer, if_wrong_practice_skills, if_wrong_skip, notes, tier, audio_asset)
values
  ('00000000-0000-0000-0000-000000000002', 92, 'text', 'Was ist das Doppelte von 4?', 'What is double 4?', 'single', '"8"'::jsonb, ARRAY['verdoppeln-halbieren.ZR10'], NULL, 'medium; verdoppeln-halbieren.ZR10 Verdoppeln im ZR10', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 93, 'text', 'Was ist das Doppelte von 7?', 'What is double 7?', 'single', '"14"'::jsonb, ARRAY['verdoppeln-halbieren.ZR20'], NULL, 'medium; verdoppeln-halbieren.ZR20 Verdoppeln im ZR20 (Zehnerübergang)', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 94, 'text', 'Was ist das Doppelte von 20?', 'What is double 20?', 'single', '"40"'::jsonb, ARRAY['verdoppeln-halbieren.ZR100'], NULL, 'medium; verdoppeln-halbieren.ZR100 Verdoppeln im ZR100 (glatte Zehnerzahl)', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 95, 'text', 'Was ist das Doppelte von 43?', 'What is double 43?', 'single', '"86"'::jsonb, ARRAY['verdoppeln-halbieren.ZR100'], NULL, 'hard; verdoppeln-halbieren.ZR100 Verdoppeln im ZR100 (ohne Übertrag)', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 96, 'text', 'Was ist das Doppelte von 27?', 'What is double 27?', 'single', '"54"'::jsonb, ARRAY['verdoppeln-halbieren.ZR100'], NULL, 'hard; verdoppeln-halbieren.ZR100 Verdoppeln im ZR100 (mit Übertrag)', 'core', NULL);

update public.diagnostics
   set question_count = 64,
       version        = version + 1
 where id = '00000000-0000-0000-0000-000000000002';

do $$
declare
  v_diag uuid := '00000000-0000-0000-0000-000000000002';
  v_core int; v_qc int;
begin
  select count(*) into v_core from public.diagnostic_questions
   where diagnostic_id = v_diag and tier = 'core';
  select question_count into v_qc from public.diagnostics where id = v_diag;

  if v_core <> 64 then raise exception 'Post-check: core is %, expected 64', v_core; end if;
  if v_qc   <> 64 then raise exception 'Post-check: question_count is %, expected 64', v_qc; end if;

  raise notice 'cleanroom-v1: core tier now 64 rows (1-59, 92-96 = verdoppeln-halbieren ZR10/ZR20/ZR100), question_count=64';
end $$;
