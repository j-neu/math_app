-- ============================================================
-- cleanroom-v1: sync prompt_de with the signed item bank
-- ============================================================
--
-- WHY: the runtime CSVs are generated from docs/clean-room/items/*.md, but the
-- database rows were seeded once (20260829000000) and never re-synced. The R2.9
-- review shortened the German wording of the visual items -- the picture already
-- carries the description, so the prompt stopped repeating it -- and that change
-- never reached the database.
--
-- The split mattered because the two are read by different audiences: the child
-- sees the bundled CSV (DiagnosticService), while the teacher's Foerderplan
-- detail table renders prompt_de straight from these rows
-- (dashboard/app/dashboard/foerderplan/[sessionId]/page.tsx:120). Left alone,
-- teachers would review answers against wording the child never saw.
--
-- 27 rows differ. prompt_en was already in sync (0 differences) and is
-- left untouched. Generated from the CSVs, not hand-typed.

update public.diagnostic_questions set prompt_de = '„Zähle von der Zahl 12 weiter, bis zur Zahl 20.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 1;  -- core
update public.diagnostic_questions set prompt_de = '„Zähle von der Zahl 48 weiter, bis zur Zahl 63.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 2;  -- core
update public.diagnostic_questions set prompt_de = '„Zähle von der Zahl 21 rückwärts, bis zur Zahl 16.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 3;  -- core
update public.diagnostic_questions set prompt_de = '„Zähle von der Zahl 59 rückwärts, bis zur Zahl 51.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 4;  -- core
update public.diagnostic_questions set prompt_de = '„Zähle in Zweierschritten von der Zahl 26 weiter. Nenne die nächsten vier Zahlen.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 5;  -- core
update public.diagnostic_questions set prompt_de = '„Zähle in Fünferschritten rückwärts von der Zahl 45. Nenne die nächsten fünf Zahlen.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 6;  -- core
update public.diagnostic_questions set prompt_de = '„Welche Zahl kommt direkt vor der 37, und welche Zahl kommt direkt nach der 37?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 7;  -- core
update public.diagnostic_questions set prompt_de = '„Schau genau hin! Wie viele Perlen waren es?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 8;  -- core
update public.diagnostic_questions set prompt_de = '„Wie viele Felder sind gefüllt?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 9;  -- core
update public.diagnostic_questions set prompt_de = '„Wie viele Finger sind es insgesamt?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 10;  -- core
update public.diagnostic_questions set prompt_de = '„Wo sind mehr Felder gefüllt — links oder rechts?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 11;  -- core
update public.diagnostic_questions set prompt_de = '"Finde drei verschiedene Wege 8 zu rechnen. Schreib sie so auf: 8 = ___ + ___."'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 15;  -- core
update public.diagnostic_questions set prompt_de = '»Wie heißt die Zahl, die hier dargestellt ist?«'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 21;  -- core
update public.diagnostic_questions set prompt_de = '»Wie viele Stäbchen sind das zusammen? Und wenn du neu bündelst: Wie viele Zehner und wie viele Einer sind es dann?«'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 22;  -- core
update public.diagnostic_questions set prompt_de = '»Öffne das Bündel. Wie viele einzelne Stäbchen hast du dann?«'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 23;  -- core
update public.diagnostic_questions set prompt_de = '»Trage die Zahl 47 in die Tafel ein.«'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 24;  -- core
update public.diagnostic_questions set prompt_de = '»Welche Zahl steht in der Tafel? Schreib sie auf.«'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 25;  -- core
update public.diagnostic_questions set prompt_de = '»Auf welche Zahl zeigt der Pfeil?«'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 26;  -- core
update public.diagnostic_questions set prompt_de = '„Beim Schwimmunterricht im Hallenbad schwimmen die Kinder Bahnen. Luna schwimmt in der ersten Übung 8 Bahnen. Nach der Pause schwimmt sie noch 5 Bahnen. Wie viele Bahnen hat Luna insgesamt geschwommen? Schreibe die passende Rechnung auf und rechne sie aus.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 58;  -- core
update public.diagnostic_questions set prompt_de = '„Im Schulgarten haben die Kinder der 2b Bohnen gesät. Heute Morgen zählt Leo 9 Bohnenpflanzen in seinem Beet. Am Nachmittag sieht er: Es sind 4 Pflanzen mehr. Wie viele Bohnenpflanzen stehen jetzt in Leos Beet? Kreuze die passende Rechnung an und rechne sie aus: 9 + 4 · 9 − 4 · 4 − 9.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 59;  -- core
update public.diagnostic_questions set prompt_de = '„Wie viele Felder sind gefüllt?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 63;  -- deepdive
update public.diagnostic_questions set prompt_de = '„Wie viele Perlen sind links?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 64;  -- deepdive
update public.diagnostic_questions set prompt_de = '„Auf welchem Brett sind mehr Perlen? Wie viele mehr?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 65;  -- deepdive
update public.diagnostic_questions set prompt_de = '„Wie heißt die Zahl, die hier dargestellt ist?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 70;  -- deepdive
update public.diagnostic_questions set prompt_de = '„Tausche einen Zehner in zehn einzelne Stäbchen. Wie viele Zehner und wie viele Einer hast du jetzt?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 71;  -- deepdive
update public.diagnostic_questions set prompt_de = '„Wie heißt die Zahl?“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 73;  -- deepdive
update public.diagnostic_questions set prompt_de = '„Markiere die Zahl 75 auf dem Zahlenstrahl.“'
 where diagnostic_id = '00000000-0000-0000-0000-000000000002' and question_number = 74;  -- deepdive

do $$
declare v_n int;
begin
  select count(*) into v_n from public.diagnostic_questions
   where diagnostic_id = '00000000-0000-0000-0000-000000000002';
  if v_n <> 92 then raise exception 'Expected 92 question rows, found %', v_n; end if;
  raise notice 'prompt_de synced for 27 rows';
end $$;
