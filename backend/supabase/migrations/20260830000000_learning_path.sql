-- ============================================================
-- P1 — Lernpfad: tables, columns, indexes, class-code rotation.
-- Additive only. Nothing existing changes shape, so diagnostic
-- sessions already on this project keep rendering.
-- ============================================================

create table public.learning_paths (
  id                uuid primary key default gen_random_uuid(),
  student_id        uuid not null references public.students on delete cascade,
  source_session_id uuid references public.diagnostic_sessions on delete set null,
  status            text not null default 'draft'
                      check (status in ('draft','active','completed','archived')),
  unlock_width      int  not null default 3 check (unlock_width between 1 and 10),
  created_by        uuid references public.teachers on delete set null,
  created_at        timestamptz not null default now(),
  activated_at      timestamptz,
  completed_at      timestamptz
);

create table public.path_items (
  id         uuid primary key default gen_random_uuid(),
  path_id    uuid not null references public.learning_paths on delete cascade,
  skill_id   text not null references public.skills on delete restrict,
  position   int  not null,
  origin     text not null default 'diagnostic'
               check (origin in ('diagnostic','teacher_added')),
  state      text not null default 'locked'
               check (state in ('locked','available','in_progress','mastered','skipped')),
  updated_at timestamptz not null default now(),
  unique (path_id, skill_id)
);

-- Deferrable so a teacher can reorder a whole path in one transaction
-- without tripping the constraint on every intermediate position.
alter table public.path_items
  add constraint path_items_position_unique unique (path_id, position)
  deferrable initially deferred;

create table public.skill_progress (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid not null references public.students on delete cascade,
  skill_id     text not null references public.skills on delete restrict,
  level        int  not null check (level between 1 and 3),
  attempts     int  not null default 0,
  correct      int  not null default 0,
  best_streak  int  not null default 0,
  slow_flag    bool not null default false,
  mastered_at  timestamptz,
  last_seen_at timestamptz,
  unique (student_id, skill_id, level)
);

create table public.practice_sessions (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.students on delete cascade,
  path_item_id       uuid references public.path_items on delete set null,
  skill_id           text not null references public.skills on delete restrict,
  level              int  not null check (level between 1 and 3),
  seed               bigint not null,
  started_at         timestamptz not null default now(),
  ended_at           timestamptz,
  problems_total     int not null default 0,
  problems_correct   int not null default 0,
  median_response_ms int
);

create table public.practice_attempts (
  id                  uuid primary key default gen_random_uuid(),
  practice_session_id uuid not null references public.practice_sessions on delete cascade,
  problem_index       int  not null,
  problem             jsonb not null,
  answer              text,
  was_correct         bool not null,
  response_ms         int,
  error_code          text,
  answered_at         timestamptz not null default now(),
  unique (practice_session_id, problem_index)
);

-- Rate-limit ledger for the roster/login endpoints. ip_hash is a salted
-- SHA-256 of the client IP: enough to throttle, never a stored address.
create table public.login_attempts (
  id           uuid primary key default gen_random_uuid(),
  ip_hash      text not null,
  school_slug  text,
  succeeded    bool not null default false,
  attempted_at timestamptz not null default now()
);

alter table public.classes
  add column if not exists class_code      text unique,
  add column if not exists code_rotated_at timestamptz,
  add column if not exists require_pin     bool not null default false;

alter table public.students
  add column if not exists avatar   text,
  add column if not exists pin_hash text;

create index on public.learning_paths (student_id, status);
create index on public.path_items (path_id, position);
create index on public.skill_progress (student_id, skill_id);
create index on public.practice_sessions (student_id, started_at desc);
create index on public.practice_attempts (practice_session_id);
create index on public.classes (class_code);
create index on public.login_attempts (ip_hash, attempted_at desc);

-- ------------------------------------------------------------
-- Class code: 4 characters from an alphabet with no 0/O/1/I/L,
-- so a child reading it off the board cannot pick the wrong one.
-- ------------------------------------------------------------
create or replace function public.rotate_class_code(p_class_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  candidate text;
  found     boolean := false;
  -- `_attempt` and `j` are the FOR loops' own implicitly-declared variables.
begin
  if not exists (
    select 1 from public.classes
    where id = p_class_id and school_id = public.teacher_school_id()
  ) then
    raise exception 'Klasse nicht gefunden oder kein Zugriff';
  end if;

  for _attempt in 1..50 loop
    candidate := '';
    for j in 1..4 loop
      candidate := candidate
        || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;

    if not exists (select 1 from public.classes where class_code = candidate) then
      found := true;
      exit;
    end if;
  end loop;

  if not found then
    raise exception 'Kein freier Klassencode verfügbar';
  end if;

  update public.classes
  set class_code = candidate, code_rotated_at = now()
  where id = p_class_id;

  return candidate;
end $$;

revoke all on function public.rotate_class_code(uuid) from public;
grant execute on function public.rotate_class_code(uuid) to authenticated;

-- Back-fill a code for every class that predates this migration.
do $$
declare r record;
begin
  for r in select id from public.classes where class_code is null loop
    update public.classes
    set class_code = upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4)),
        code_rotated_at = now()
    where id = r.id;
  end loop;
end $$;
