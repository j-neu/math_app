-- ============================================================
-- v2 pilot: item-quality-fix diagnostic items (97-102)
-- ============================================================
--
-- WHY: docs/clean-room/00-v1-assessment.md Anhang A found three v1 core
-- items unusable as written (Q18: unmeasured decorative sentence; Q22:
-- three answer fields for a single-number answer; Q23: prompt says
-- "Stäbchen", widget shows Dienes rods/cubes since the redesign) and two
-- coverage gaps (Q11/A2.3 has no symbolic counterpart; Q26/B2.2 jumps
-- straight to a 0-100 number line with no 0-10/0-20 step). The v1 CSV and
-- item files are frozen (Jakob decision, 2026-09-11 session), so the fix is
-- client-side exclusion of list numbers 18/22/23
-- (`_kSupersededByV2` in diagnostic_service.dart) plus six new v2-authored
-- items appended at 97-102 (docs/clean-room/v2/items/, math_app/Research/
-- diagnostic_v2_item_quality_fixes.csv).
--
-- ARITHMETIC (worked by hand, then re-verified by counting
-- loadQuestions()'s actual returned length via the full Flutter test suite,
-- per this plan's own caution against the exact bug fixed earlier today):
-- 59 v1 core rows - 3 excluded (18, 22, 23) = 56
-- + 5 verdoppeln-halbieren (92-96, already live, question_count=64)
-- + 6 item-quality-fix (97-102, this migration)
-- = 67. Use question_count = 67 — NOT 64+6=70 (would ignore the 3
-- exclusions) and NOT 64+3=67-by-coincidence-only reasoning; the number
-- is exactly what math_app/test/diagnostic_service_test.dart's
-- "loadQuestions merges the v2 item-quality-fix CSV" test run confirms
-- the client actually returns (8 tests, all passing, 2026-09-11).

do $$
declare
  v_diag  uuid := '00000000-0000-0000-0000-000000000002';
  v_qc    int;
  v_taken int;
begin
  select question_count into v_qc from public.diagnostics where id = v_diag;
  if v_qc <> 64 then
    raise exception 'Aborting: expected question_count=64, found % (already migrated, or verdoppeln-halbieren migration not yet applied?)', v_qc;
  end if;

  select count(*) into v_taken from public.diagnostic_questions
   where diagnostic_id = v_diag and question_number between 97 and 102;
  if v_taken <> 0 then
    raise exception 'Aborting: % of question_number 97-102 already taken', v_taken;
  end if;
end $$;

insert into public.diagnostic_questions (
  diagnostic_id, question_number, source_type, prompt_de, prompt_en, answer_format,
  correct_answer, if_wrong_practice_skills, if_wrong_skip, notes, tier, audio_asset)
values
  ('00000000-0000-0000-0000-000000000002', 97, 'text', 'Welche Zahl ist doppelt so groß wie die 4?', 'Which number is twice as large as 4?', 'single', '"8"'::jsonb, ARRAY['A3.3', 'A3.1'], NULL, 'easy; A3.3 Zahlbeziehungen (Verdopplungen) -- v2-Ersatz fuer A3.3-01 (Beiwerk entfernt)', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 98, 'text', 'Wie viel ist das insgesamt?', 'How much is this altogether?', 'single', '"41"'::jsonb, ARRAY['B1.2', 'B1.3', 'B2.3'], NULL, 'hard; B1.2 Buendelung -- v2-Ersatz fuer B1.2-02 (ein Feld statt drei)', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 99, 'text', 'Öffne die Zehnerstange. Wie viele einzelne Würfel hast du dann?', 'Open the ten-rod. How many single cubes do you have then?', 'single', '"13"'::jsonb, ARRAY['B1.3', 'B1.1', 'B2.3'], NULL, 'medium; B1.3 Entbuendelung -- v2-Ersatz fuer B1.3-01 (Wortwahl korrigiert)', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 100, 'text', 'Welche Zahl ist größer: 6 oder 8?', 'Which number is larger: 6 or 8?', 'single', '"8"'::jsonb, ARRAY['A2.3', 'A2.2'], NULL, 'medium; A2.3 Anzahlvergleich -- symbolische Entsprechung zu A2.3-01', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 101, 'text', 'Auf welche Zahl zeigt der Pfeil?', 'What number does the arrow point to?', 'single', '"7"'::jsonb, ARRAY['B2.2', 'B1.1', 'A1.5'], NULL, 'easy; B2.2 Zahlenstrahl -- ZR10-Stufe vor B2.2-01', 'core', NULL),
  ('00000000-0000-0000-0000-000000000002', 102, 'text', 'Auf welche Zahl zeigt der Pfeil?', 'What number does the arrow point to?', 'single', '"14"'::jsonb, ARRAY['B2.2', 'B1.1', 'A1.5'], NULL, 'medium; B2.2 Zahlenstrahl -- ZR20-Stufe vor B2.2-01', 'core', NULL);

update public.diagnostics
   set question_count = 67,
       version        = version + 1
 where id = '00000000-0000-0000-0000-000000000002';

do $$
declare
  v_diag uuid := '00000000-0000-0000-0000-000000000002';
  v_new  int; v_qc int;
begin
  select count(*) into v_new from public.diagnostic_questions
   where diagnostic_id = v_diag and question_number between 97 and 102 and tier = 'core';
  select question_count into v_qc from public.diagnostics where id = v_diag;

  if v_new <> 6 then raise exception 'Post-check: % of 97-102 inserted, expected 6', v_new; end if;
  if v_qc  <> 67 then raise exception 'Post-check: question_count is %, expected 67', v_qc; end if;

  raise notice 'cleanroom-v1: 6 item-quality-fix rows added (97-102), question_count=67';
end $$;
