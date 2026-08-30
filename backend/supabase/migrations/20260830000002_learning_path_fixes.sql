-- ============================================================
-- P1 — Lernpfad: fix round 1 (review findings C2, I8, I5).
-- ============================================================

-- ------------------------------------------------------------
-- I5: student_pins — column-level secret, not row-level.
--
-- students.pin_hash (added in 20260830000000_learning_path.sql) sits behind
-- the pre-existing "teacher select students" policy, which is row-level:
-- any teacher in the school can read it with `select *`. A 4-symbol picture
-- PIN drawn from 8 glyphs is ~4096 combinations, so a readable hash is
-- effectively plaintext. Move it to its own table with RLS enabled and NO
-- policies at all — service-role only, exactly like login_attempts.
-- ------------------------------------------------------------
create table public.student_pins (
  student_id uuid primary key references public.students on delete cascade,
  pin_hash   text not null,
  updated_at timestamptz not null default now()
);

alter table public.student_pins enable row level security;
-- Deliberately no policies: only the service role (which bypasses RLS)
-- can read or write this table. Same intended design as login_attempts.

-- Defensive copy, even though pin_hash was added hours ago and nothing has
-- ever written to it (verified: no deployed code sets it). Costs nothing
-- and protects against exactly this assumption being wrong.
insert into public.student_pins (student_id, pin_hash)
select id, pin_hash from public.students where pin_hash is not null;

alter table public.students drop column pin_hash;

-- ------------------------------------------------------------
-- I8: reorder_path_items — one transaction, not one autocommit UPDATE
-- per skill.
--
-- The PATCH "reorder" action previously issued one autocommit UPDATE per
-- skill, never checked the returned error, and returned {ok:true}
-- regardless. A genuine A<->B swap trips the (path_id, position) unique
-- constraint on the first UPDATE; `deferrable initially deferred` only
-- helps inside a single transaction. Doing the renumbering inside one
-- plpgsql function call means every UPDATE in the loop runs in the same
-- transaction, so the deferred constraint is checked only once, at the end.
-- ------------------------------------------------------------
create or replace function public.reorder_path_items(
  p_path_id uuid,
  p_skill_ids text[]
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  expected_count int;
  given_count    int;
  i              int;
begin
  if p_path_id is null or p_skill_ids is null or array_length(p_skill_ids, 1) is null then
    raise exception 'Reihenfolge fehlt';
  end if;

  select count(*) into expected_count from public.path_items where path_id = p_path_id;
  given_count := array_length(p_skill_ids, 1);

  if expected_count = 0 then
    raise exception 'Pfad nicht gefunden';
  end if;

  if given_count <> expected_count then
    raise exception
      'Reihenfolge unvollständig: % Einträge im Pfad, % angegeben',
      expected_count, given_count;
  end if;

  for i in 1..given_count loop
    update public.path_items
    set position = i - 1, updated_at = now()
    where path_id = p_path_id and skill_id = p_skill_ids[i];

    if not found then
      raise exception 'Skill % nicht in diesem Pfad gefunden', p_skill_ids[i];
    end if;
  end loop;
end;
$$;

revoke all on function public.reorder_path_items(uuid, text[]) from public;
grant execute on function public.reorder_path_items(uuid, text[]) to service_role;
