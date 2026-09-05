-- ============================================================
-- cleanroom-v1: strip the wrapping quote marks from prompt_de
-- ============================================================
--
-- WHY: Workstream-A Task 2 (diagnostic usability rework §4.2, merged and
-- deployed 2026-09-05) decided the wrapping quotes every item file puts
-- around its Wording — a holdover from assessor-script authoring — have no
-- meaning in a UI that renders the text directly. The runtime CSVs are
-- generated through strip_quotation_wrapping(), so the child client already
-- shows quote-free prompts. The live database rows were synced BEFORE that
-- change (20260904000001) and still carry the wraps on all 92 rows of the
-- cleanroom-v1 bank, so the teacher side (dashboard detail tables render
-- prompt_de from these rows) shows „…" / "…" / »…« around every prompt.
-- Same datum, two stores, cosmetic but real drift (gauntlet §3 rule 3).
--
-- This migration strips one outer wrapping pair — mirroring the generator's
-- strip_quotation_wrapping() semantics exactly (only the outermost pair,
-- nested quotes inside a prompt are left alone) — and is idempotent.
--
-- Typography only; approved by Jakob 2026-09-05.

update public.diagnostic_questions
   set prompt_de = btrim(case
         when left(prompt_de, 1) = '„' and right(prompt_de, 1) in ('”', '“', '"')
           then substr(prompt_de, 2, length(prompt_de) - 2)
         when left(prompt_de, 1) = '"' and right(prompt_de, 1) = '"'
           then substr(prompt_de, 2, length(prompt_de) - 2)
         when left(prompt_de, 1) = '»' and right(prompt_de, 1) = '«'
           then substr(prompt_de, 2, length(prompt_de) - 2)
         else prompt_de
       end)
 where diagnostic_id = '00000000-0000-0000-0000-000000000002';

do $$
declare
  v_left int;
  v_total int;
begin
  select count(*) into v_left from public.diagnostic_questions
   where diagnostic_id = '00000000-0000-0000-0000-000000000002'
     and left(prompt_de, 1) in ('„', '"', '»', '“', '”', '«');
  if v_left <> 0 then
    raise exception 'Still % prompt_de rows starting with a quote after the strip', v_left;
  end if;
  select count(*) into v_total from public.diagnostic_questions
   where diagnostic_id = '00000000-0000-0000-0000-000000000002';
  raise notice 'quote wraps stripped from prompt_de (% rows checked)', v_total;
end $$;
