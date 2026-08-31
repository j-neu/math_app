-- ============================================================
-- P1 — Lernpfad: secondary rate-limit keys (final security review).
--
-- checkRateLimit in student-auth/index.ts previously keyed solely on a
-- hashed client IP (ip_hash). That is correct today — Supabase's gateway
-- supplies the genuine leftmost x-forwarded-for hop, verified empirically
-- 2026-08-31 — but it is a single line of defence resting entirely on
-- undocumented gateway behaviour. This migration adds two IP-independent
-- dimensions so throttling does not collapse to nothing if that behaviour
-- ever changes, or if some other caller reaches this function by a path
-- that doesn't carry a trustworthy x-forwarded-for at all:
--
--   - class_code: the /roster brute-force target. 31^4 = 923,521 possible
--     codes; failed attempts are now also counted per attempted code.
--   - student_id: the /login picture-PIN brute-force target. At most 4096
--     combinations; failed attempts are now also counted per targeted
--     student.
--
-- Deliberately NO foreign key on either column. student-auth/index.ts
-- records a provisional failure row before validating the request (see the
-- comment on checkRateLimit), so an attacker-forged class_code or a
-- nonexistent student_id must still insert cleanly — throttling wrong
-- guesses is the entire point, and a failing FK constraint would silently
-- break the "record first" concurrency safety that insert depends on.
-- ============================================================

alter table public.login_attempts
  add column if not exists class_code text,
  add column if not exists student_id uuid;

create index if not exists login_attempts_class_code_idx
  on public.login_attempts (class_code, attempted_at desc);

create index if not exists login_attempts_student_id_idx
  on public.login_attempts (student_id, attempted_at desc);

-- No RLS change needed: login_attempts already has RLS enabled with no
-- policies at all (service-role only — see 20260830000001_learning_path_rls.sql),
-- and that continues to cover these two new columns.
