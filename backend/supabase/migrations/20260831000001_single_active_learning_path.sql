-- ============================================================
-- P1 — Lernpfad: at most one active learning path per student
-- (final security review, correctness fix).
--
-- Nothing previously stopped two learning_paths rows for the same student
-- both being 'active' at once. GET /learning-path selects the active path
-- with .eq("status","active").maybeSingle() — a second active row makes
-- that query's result ambiguous rather than a clear error, and PostgREST's
-- .maybeSingle() would surface it as a generic failure instead of the
-- child simply seeing their path.
--
-- A partial unique index (rather than a plain unique constraint on
-- student_id) is used deliberately: it only constrains rows where
-- status = 'active', so a student can still have any number of 'draft',
-- 'completed' or 'archived' paths.
-- ============================================================

create unique index if not exists learning_paths_one_active_per_student
  on public.learning_paths (student_id)
  where status = 'active';
