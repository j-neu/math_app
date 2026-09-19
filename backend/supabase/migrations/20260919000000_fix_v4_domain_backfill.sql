-- ============================================================================
-- Root cause: 20260517000001_seed_data.sql seeded 7 skill rows (ordinal_1,
-- operation_sense_add/sub/story, number_line_rechenstrich/strategies/
-- zahlenstrahl) with no `domain` column at all (it did not exist yet).
-- 20260913000000_v4_imint_pikas_bank.sql tried to bring these 7 up to the
-- v4 taxonomy (domain letter + construct_id + refreshed wording) but used
-- `on conflict (id) do nothing`, so -- because a row with each id already
-- existed from May -- every one of those 7 updates was silently skipped.
-- The stale rows (domain = NULL) survived into production.
--
-- Effect: `domainLabel()`/`catLabel()` (foerderplan-generate, foerderplan-pdf,
-- the dashboard Foerderplan and Klassen pages) all fall back to the raw,
-- untranslated `category` text whenever `domain` is NULL -- leaking English
-- category names ("Ordinal Numbers", "Operational Sense", "Advanced Number
-- Line") into teacher-facing screens and PDFs. Jakob caught this 2026-09-19
-- on the Foerderplan page and the Klassen overview.
--
-- Fix, in two parts:
--   1. Bring the 7 skills rows up to the exact v4 values (matching
--      20260913000000's intended row content) via explicit UPDATEs.
--   2. Repair `foerderplaene.category_stats`, which caches
--      `domainLabel()`'s output *as JSON keys* at generation time -- any
--      plan generated while these 7 rows were broken baked the raw English
--      category text into its cached stats and will keep showing it even
--      after part 1, since completed sessions never regenerate their plan.
--      Merge each mistranslated key into its correct German domain label,
--      summing failed/total if that domain key already has stats from
--      other skills in the same plan.
-- ============================================================================

update public.skills set
  color = 'amber', card_number = 0,
  title_de = 'Ordnungszahlen verwenden',
  title_en = 'Use ordinal numbers',
  description_de = 'Das Kind verwendet Ordnungszahlen (z. B. der dritte), um die Position in einer Reihe zu benennen.',
  description_en = 'The child uses ordinal numbers (e.g. "the third") to name a position within a sequence.',
  domain = 'A', construct_id = 'ordinal'
where id = 'ordinal_1';

update public.skills set
  color = 'violet', card_number = 0,
  title_de = 'Addition im Kontext verstehen',
  title_en = 'Understand addition in context',
  description_de = 'Das Kind erkennt in einer Sachsituation eine Additionshandlung und stellt sie als Rechnung dar.',
  description_en = 'The child recognizes an addition action in a story situation and expresses it as a calculation.',
  domain = 'D', construct_id = 'operation_sense'
where id = 'operation_sense_add';

update public.skills set
  color = 'violet', card_number = 0,
  title_de = 'Subtraktion im Kontext verstehen (wegnehmen und vergleichen)',
  title_en = 'Understand subtraction in context (take-away and compare)',
  description_de = 'Das Kind erkennt in einer Sachsituation eine Subtraktionshandlung (Wegnehmen oder Vergleichen) und stellt sie als Rechnung dar.',
  description_en = 'The child recognizes a subtraction action (taking away or comparing) in a story situation and expresses it as a calculation.',
  domain = 'D', construct_id = 'operation_sense'
where id = 'operation_sense_sub';

update public.skills set
  color = 'violet', card_number = 0,
  title_de = 'Rechengeschichten in Gleichungen übersetzen',
  title_en = 'Translate story problems into equations',
  description_de = 'Das Kind übersetzt eine Rechengeschichte in die passende Gleichung.',
  description_en = 'The child translates a story problem into the matching equation.',
  domain = 'D', construct_id = 'operation_sense'
where id = 'operation_sense_story';

update public.skills set
  color = 'indigo', card_number = 0,
  title_de = 'Rechenstrich zum Rechnen nutzen',
  title_en = 'Use the empty number line for calculation',
  description_de = 'Das Kind nutzt den leeren Rechenstrich, um eine Rechnung im ZR100 über gedankliche Sprünge zu lösen.',
  description_en = 'The child uses the empty number line to solve a calculation within 100 through mental jumps.',
  domain = 'B', construct_id = 'number_line_strategy'
where id = 'number_line_rechenstrich';

update public.skills set
  color = 'indigo', card_number = 0,
  title_de = 'Zahlenstrahl-Strategien: Zahl über Ungleichungen eingrenzen',
  title_en = 'Number-line strategies: narrow a number via inequalities',
  description_de = 'Das Kind grenzt eine gesuchte Zahl im ZR100 über Ungleichungen auf dem Zahlenstrahl ein.',
  description_en = 'The child narrows down a target number within 100 on the number line using inequalities.',
  domain = 'B', construct_id = 'number_line_strategy'
where id = 'number_line_strategies';

update public.skills set
  color = 'indigo', card_number = 0,
  title_de = 'Zahlenstrahl zur Positionierung nutzen (Mitte finden)',
  title_en = 'Use the marked number line for positioning (find the midpoint)',
  description_de = 'Das Kind nutzt den beschrifteten Zahlenstrahl, um die Mitte zwischen zwei Zahlen im ZR100 zu bestimmen.',
  description_en = 'The child uses the labelled number line to find the midpoint between two numbers within 100.',
  domain = 'B', construct_id = 'number_line_strategy'
where id = 'number_line_zahlenstrahl';

-- Part 2: repair already-cached category_stats on existing foerderplaene
-- rows so completed sessions do not keep showing the pre-fix English keys
-- forever (they never regenerate their plan once one exists).
do $$
declare
  plan_row record;
  fixed jsonb;
  m record;
  mapping jsonb := '{
    "Ordinal Numbers": "Domäne A — Zahlbegriff",
    "Operational Sense": "Domäne D — Sachsituationen",
    "Advanced Number Line": "Domäne B — Stellenwertverständnis"
  }'::jsonb;
  old_stat jsonb;
  existing_stat jsonb;
  merged_failed int;
  merged_total int;
begin
  for plan_row in select session_id, category_stats from public.foerderplaene loop
    fixed := plan_row.category_stats;
    for m in select key as old_key, value as new_key from jsonb_each_text(mapping) loop
      if fixed ? m.old_key then
        old_stat := fixed -> m.old_key;
        existing_stat := fixed -> m.new_key;
        merged_failed := coalesce((old_stat ->> 'failed')::int, 0) + coalesce((existing_stat ->> 'failed')::int, 0);
        merged_total := coalesce((old_stat ->> 'total')::int, 0) + coalesce((existing_stat ->> 'total')::int, 0);
        fixed := fixed - m.old_key;
        fixed := jsonb_set(
          fixed,
          array[m.new_key],
          jsonb_build_object('failed', merged_failed, 'total', merged_total)
        );
      end if;
    end loop;
    if fixed is distinct from plan_row.category_stats then
      update public.foerderplaene set category_stats = fixed where session_id = plan_row.session_id;
    end if;
  end loop;
end $$;
