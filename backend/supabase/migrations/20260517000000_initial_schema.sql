-- ============================================================
-- Math School Platform — Initial Schema
-- ============================================================

-- Extensions
create extension if not exists "pgcrypto";

-- ============================================================
-- TABLES
-- ============================================================

create table public.schools (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  region      text not null default '',
  created_at  timestamptz not null default now()
);

create table public.teachers (
  id           uuid primary key references auth.users on delete cascade,
  school_id    uuid not null references public.schools on delete cascade,
  display_name text not null,
  role         text not null default 'teacher' check (role in ('teacher', 'school_admin'))
);

create table public.classes (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools on delete cascade,
  teacher_id uuid references public.teachers on delete set null,
  name       text not null,
  grade      int,
  created_at timestamptz not null default now()
);

create table public.students (
  id           uuid primary key default gen_random_uuid(),
  class_id     uuid not null references public.classes on delete cascade,
  display_name text not null,
  age          int,
  external_ref text,
  created_at   timestamptz not null default now()
);

create table public.diagnostics (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  name_de        text not null,
  version        int not null default 1,
  question_count int not null,
  created_at     timestamptz not null default now()
);

create table public.diagnostic_questions (
  id                      uuid primary key default gen_random_uuid(),
  diagnostic_id           uuid not null references public.diagnostics on delete cascade,
  question_number         int not null,
  source_type             text not null check (source_type in ('image', 'text', 'cards', 'picture')),
  prompt_de               text not null,
  prompt_en               text not null default '',
  answer_format           text not null check (answer_format in ('single', 'multiple', 'sort')),
  correct_answer          jsonb not null,
  if_wrong_practice_skills text[] not null default '{}',
  if_wrong_skip           text,
  notes                   text,
  unique (diagnostic_id, question_number)
);

create table public.session_tickets (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.students on delete cascade,
  diagnostic_id uuid not null references public.diagnostics on delete cascade,
  expires_at    timestamptz not null,
  consumed_at   timestamptz,
  jwt_jti       text unique,
  created_at    timestamptz not null default now()
);

create table public.diagnostic_sessions (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.students on delete cascade,
  diagnostic_id uuid not null references public.diagnostics on delete cascade,
  ticket_id     uuid references public.session_tickets on delete set null,
  started_at    timestamptz not null default now(),
  completed_at  timestamptz,
  status        text not null default 'in_progress' check (status in ('in_progress', 'completed', 'abandoned'))
);

create table public.diagnostic_results (
  id                    uuid primary key default gen_random_uuid(),
  session_id            uuid not null references public.diagnostic_sessions on delete cascade,
  question_id           uuid not null references public.diagnostic_questions on delete cascade,
  was_correct           bool not null,
  response_time_seconds float,
  status                text not null default 'attempted' check (status in ('attempted', 'skipped', 'timeout')),
  user_answer           text,
  answered_at           timestamptz not null default now(),
  unique (session_id, question_id)
);

create table public.foerderplaene (
  id                     uuid primary key default gen_random_uuid(),
  session_id             uuid not null unique references public.diagnostic_sessions on delete cascade,
  generated_at           timestamptz not null default now(),
  brief_skill_ids        text[] not null default '{}',
  recommended_skill_ids  text[] not null default '{}',
  category_stats         jsonb not null default '{}',
  slow_response_flag     bool not null default false,
  pdf_storage_path       text
);

create table public.skills (
  id             text primary key,
  category       text not null,
  color          text not null,
  card_number    int not null,
  title_de       text not null,
  title_en       text not null,
  description_de text not null,
  description_en text not null
);

-- ============================================================
-- INDEXES
-- ============================================================

create index on public.teachers (school_id);
create index on public.classes (school_id);
create index on public.students (class_id);
create index on public.session_tickets (student_id);
create index on public.diagnostic_sessions (student_id);
create index on public.diagnostic_sessions (status);
create index on public.diagnostic_results (session_id);

-- ============================================================
-- ROW-LEVEL SECURITY
-- ============================================================

alter table public.schools               enable row level security;
alter table public.teachers              enable row level security;
alter table public.classes               enable row level security;
alter table public.students              enable row level security;
alter table public.session_tickets       enable row level security;
alter table public.diagnostic_sessions   enable row level security;
alter table public.diagnostic_results    enable row level security;
alter table public.foerderplaene         enable row level security;
alter table public.skills                enable row level security;
alter table public.diagnostics           enable row level security;
alter table public.diagnostic_questions  enable row level security;

-- Helper: return the school_id of the authenticated teacher
create or replace function public.teacher_school_id()
returns uuid language sql stable security definer as $$
  select school_id from public.teachers where id = auth.uid()
$$;

-- Helper: extract student_id claim from session-ticket JWT
create or replace function public.ticket_student_id()
returns uuid language sql stable as $$
  select (auth.jwt() ->> 'student_id')::uuid
$$;

-- ---- schools: teacher sees own school ----
create policy "teachers see own school"
  on public.schools for select
  using (id = public.teacher_school_id());

-- ---- teachers: teacher sees colleagues in same school ----
create policy "teachers see own school teachers"
  on public.teachers for select
  using (school_id = public.teacher_school_id());

-- ---- classes: teacher CRUD for own school ----
create policy "teacher select classes"
  on public.classes for select
  using (school_id = public.teacher_school_id());

create policy "teacher insert classes"
  on public.classes for insert
  with check (school_id = public.teacher_school_id());

create policy "teacher update classes"
  on public.classes for update
  using (school_id = public.teacher_school_id());

create policy "teacher delete classes"
  on public.classes for delete
  using (school_id = public.teacher_school_id());

-- ---- students: teacher CRUD for classes in own school ----
create policy "teacher select students"
  on public.students for select
  using (
    class_id in (
      select id from public.classes where school_id = public.teacher_school_id()
    )
  );

create policy "teacher insert students"
  on public.students for insert
  with check (
    class_id in (
      select id from public.classes where school_id = public.teacher_school_id()
    )
  );

create policy "teacher update students"
  on public.students for update
  using (
    class_id in (
      select id from public.classes where school_id = public.teacher_school_id()
    )
  );

create policy "teacher delete students"
  on public.students for delete
  using (
    class_id in (
      select id from public.classes where school_id = public.teacher_school_id()
    )
  );

-- ---- session_tickets: teacher manages; student reads own ----
create policy "teacher manage tickets"
  on public.session_tickets for all
  using (
    student_id in (
      select s.id from public.students s
      join public.classes c on c.id = s.class_id
      where c.school_id = public.teacher_school_id()
    )
  );

create policy "student read own ticket"
  on public.session_tickets for select
  using (student_id = public.ticket_student_id());

-- ---- diagnostic_sessions: teacher reads; student writes own ----
create policy "teacher read sessions"
  on public.diagnostic_sessions for select
  using (
    student_id in (
      select s.id from public.students s
      join public.classes c on c.id = s.class_id
      where c.school_id = public.teacher_school_id()
    )
  );

create policy "student insert own session"
  on public.diagnostic_sessions for insert
  with check (student_id = public.ticket_student_id());

create policy "student update own session"
  on public.diagnostic_sessions for update
  using (student_id = public.ticket_student_id());

create policy "student read own session"
  on public.diagnostic_sessions for select
  using (student_id = public.ticket_student_id());

-- ---- diagnostic_results: teacher reads; student writes own ----
create policy "teacher read results"
  on public.diagnostic_results for select
  using (
    session_id in (
      select ds.id from public.diagnostic_sessions ds
      join public.students s on s.id = ds.student_id
      join public.classes c on c.id = s.class_id
      where c.school_id = public.teacher_school_id()
    )
  );

create policy "student insert own results"
  on public.diagnostic_results for insert
  with check (
    session_id in (
      select id from public.diagnostic_sessions
      where student_id = public.ticket_student_id()
    )
  );

create policy "student read own results"
  on public.diagnostic_results for select
  using (
    session_id in (
      select id from public.diagnostic_sessions
      where student_id = public.ticket_student_id()
    )
  );

-- ---- foerderplaene: teacher reads; edge function writes (service role) ----
create policy "teacher read foerderplaene"
  on public.foerderplaene for select
  using (
    session_id in (
      select ds.id from public.diagnostic_sessions ds
      join public.students s on s.id = ds.student_id
      join public.classes c on c.id = s.class_id
      where c.school_id = public.teacher_school_id()
    )
  );

-- ---- skills: public read ----
create policy "public read skills"
  on public.skills for select
  using (true);

-- ---- diagnostics: public read ----
create policy "public read diagnostics"
  on public.diagnostics for select
  using (true);

-- ---- diagnostic_questions: public read ----
create policy "public read diagnostic_questions"
  on public.diagnostic_questions for select
  using (true);

-- ============================================================
-- CASCADE DELETE SANITY CHECK (test via trigger)
-- On school delete: cascade to teachers, classes → students →
-- session_tickets, diagnostic_sessions → results → foerderplaene
-- All handled by FK ON DELETE CASCADE above.
-- ============================================================
