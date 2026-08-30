-- ============================================================
-- P1 — Lernpfad: row-level security.
-- Teachers reach everything inside their own school; a child
-- reaches only their own rows, via the student_id claim that
-- ticket_student_id() reads from the JWT.
-- ============================================================

alter table public.learning_paths    enable row level security;
alter table public.path_items        enable row level security;
alter table public.skill_progress    enable row level security;
alter table public.practice_sessions enable row level security;
alter table public.practice_attempts enable row level security;
alter table public.login_attempts    enable row level security;

-- Every student in the authenticated teacher's school.
create or replace function public.teacher_student_ids()
returns setof uuid language sql stable security definer
set search_path = public as $$
  select s.id from public.students s
  join public.classes c on c.id = s.class_id
  where c.school_id = public.teacher_school_id()
$$;

-- ---- learning_paths ----------------------------------------
create policy "teacher manages paths in own school"
  on public.learning_paths for all
  using (student_id in (select public.teacher_student_ids()))
  with check (student_id in (select public.teacher_student_ids()));

create policy "child reads own active path"
  on public.learning_paths for select
  using (student_id = public.ticket_student_id() and status = 'active');

-- ---- path_items: teacher writes, child only reads -----------
create policy "teacher manages path items in own school"
  on public.path_items for all
  using (path_id in (select id from public.learning_paths
                     where student_id in (select public.teacher_student_ids())))
  with check (path_id in (select id from public.learning_paths
                          where student_id in (select public.teacher_student_ids())));

create policy "child reads own path items"
  on public.path_items for select
  using (path_id in (select id from public.learning_paths
                     where student_id = public.ticket_student_id()
                       and status = 'active'));

-- ---- skill_progress ----------------------------------------
create policy "teacher reads progress in own school"
  on public.skill_progress for select
  using (student_id in (select public.teacher_student_ids()));

create policy "child reads own progress"
  on public.skill_progress for select
  using (student_id = public.ticket_student_id());

-- ---- practice_sessions -------------------------------------
create policy "teacher reads practice sessions in own school"
  on public.practice_sessions for select
  using (student_id in (select public.teacher_student_ids()));

create policy "child reads own practice sessions"
  on public.practice_sessions for select
  using (student_id = public.ticket_student_id());

-- ---- practice_attempts -------------------------------------
create policy "teacher reads attempts in own school"
  on public.practice_attempts for select
  using (practice_session_id in (
    select id from public.practice_sessions
    where student_id in (select public.teacher_student_ids())));

create policy "child reads own attempts"
  on public.practice_attempts for select
  using (practice_session_id in (
    select id from public.practice_sessions
    where student_id = public.ticket_student_id()));

-- ---- login_attempts ----------------------------------------
-- Deliberately no policy: RLS is enabled and nothing matches, so only the
-- service role (which bypasses RLS) can read or write the rate-limit ledger.
-- This is the intended design, not a missing policy.

-- Writes to skill_progress, practice_sessions and practice_attempts go
-- through the service-role `practice-session` function, which verifies the
-- student token itself. Children therefore get no INSERT/UPDATE policy on
-- any of them: the function is the only writer.
