-- Highest help stage (0-3) the child opened for this item (spec 2026-10-22).
-- Correct-after-stage-3 is already folded into was_correct by the client;
-- this column is for the teacher's Detail-Tabelle.
alter table public.diagnostic_results
  add column help_level smallint not null default 0
  check (help_level between 0 and 3);
