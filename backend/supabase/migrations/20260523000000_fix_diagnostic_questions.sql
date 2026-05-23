-- Phase 1.1 data fixes.
-- Deletes Q39, Q40, Q57, Q62, Q66, Q67.
-- Updates doubling Q54–Q61 and halving Q63–Q71 with correct numbers.
-- New total: 92 questions.

begin;

-- ---- Deletions ----

delete from public.diagnostic_questions
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number in (39, 40, 57, 62, 66, 67);

-- ---- Doubling ZR20: Q54=3, Q55=6, Q56=8 ----

update public.diagnostic_questions
  set prompt_de = 'Was ist das Doppelte von 3?',
      prompt_en = 'What is the double of 3?',
      correct_answer = '"6"'::jsonb,
      notes = 'Card 18 Verdoppeln bis 20'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 54;

update public.diagnostic_questions
  set prompt_de = 'Was ist das Doppelte von 6?',
      prompt_en = 'What is the double of 6?',
      correct_answer = '"12"'::jsonb,
      notes = 'Card 18 Verdoppeln bis 20'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 55;

update public.diagnostic_questions
  set prompt_de = 'Was ist das Doppelte von 8?',
      prompt_en = 'What is the double of 8?',
      correct_answer = '"16"'::jsonb,
      notes = 'Card 18 Verdoppeln bis 20'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 56;

-- ---- Doubling ZR100: Q58=20, Q59=35, Q60=42, Q61=27 ----
-- Q58 was ZR20 (Doppelte von 10); repurposed to ZR100.

update public.diagnostic_questions
  set prompt_de = 'Was ist das Doppelte von 20?',
      prompt_en = 'What is the double of 20?',
      correct_answer = '"40"'::jsonb,
      if_wrong_practice_skills = ARRAY['basic_strategy_10'],
      notes = 'Card 19 Verdoppeln bis 100'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 58;

update public.diagnostic_questions
  set prompt_de = 'Was ist das Doppelte von 35?',
      prompt_en = 'What is the double of 35?',
      correct_answer = '"70"'::jsonb,
      notes = 'Card 19 Verdoppeln bis 100'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 59;

update public.diagnostic_questions
  set prompt_de = 'Was ist das Doppelte von 42?',
      prompt_en = 'What is the double of 42?',
      correct_answer = '"84"'::jsonb,
      if_wrong_practice_skills = ARRAY['combined_strategy_17'],
      notes = 'Card 19 Verdoppeln bis 100'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 60;

update public.diagnostic_questions
  set prompt_de = 'Was ist das Doppelte von 27?',
      prompt_en = 'What is the double of 27?',
      correct_answer = '"54"'::jsonb,
      notes = 'Card 19 Verdoppeln bis 100'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 61;

-- ---- Halving ZR100: Q68=40, Q69=64, Q70 unchanged, Q71=58 ----

update public.diagnostic_questions
  set prompt_de = 'Was ist die Hälfte von 40?',
      prompt_en = 'What is half of 40?',
      correct_answer = '"20"'::jsonb,
      notes = 'Card 21 Halbieren bis 100'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 68;

update public.diagnostic_questions
  set prompt_de = 'Was ist die Hälfte von 64?',
      prompt_en = 'What is half of 64?',
      correct_answer = '"32"'::jsonb,
      if_wrong_practice_skills = ARRAY['combined_strategy_18'],
      notes = 'Card 21 Halbieren bis 100'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 69;

update public.diagnostic_questions
  set prompt_de = 'Was ist die Hälfte von 58?',
      prompt_en = 'What is half of 58?',
      correct_answer = '"29"'::jsonb,
      notes = 'Card 21 Halbieren bis 100'
  where diagnostic_id = '00000000-0000-0000-0000-000000000001'
    and question_number = 71;

-- ---- Update question count ----

update public.diagnostics
  set question_count = 92, version = version + 1
  where id = '00000000-0000-0000-0000-000000000001';

commit;
