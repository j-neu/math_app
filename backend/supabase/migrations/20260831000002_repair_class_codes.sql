-- 20260831000002_repair_class_codes.sql
-- Repair the class-code backfill: 20260830000000 filled class_code from
-- UUID hex (upper(substr(replace(gen_random_uuid()::text,'-',''),1,4))),
-- which can emit 0/O/1/I/L — characters deliberately excluded from the
-- confusables-free alphabet CODE_ALPHABET (ABCDEFGHJKMNPQRSTUVWXYZ23456789)
-- used by rotate_class_code() and validated by student-auth's
-- isValidCodeShape(). A code like "703F" passes the unique constraint but
-- is rejected by the roster endpoint, silently locking a class out of
-- child login.
--
-- Re-rotate every code that is null, malformed, or duplicated, using the
-- same alphabet and uniqueness loop as rotate_class_code(). Idempotent;
-- re-running changes nothing.
do $$
declare
  r record;
  candidate text;
  i int;
begin
  for r in
    select c.id
    from public.classes c
    where c.class_code is null
       or c.class_code !~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}$'
       or exists (
         select 1 from public.classes c2
         where c2.class_code = c.class_code and c2.id <> c.id
       )
  loop
    candidate := null;
    for i in 1..50 loop
      candidate := '';
      for j in 1..4 loop
        candidate := candidate ||
          substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789',
                 1 + floor(random() * 32)::int, 1);
      end loop;
      exit when not exists (
        select 1 from public.classes where class_code = candidate
      );
    end loop;
    if candidate is null then
      raise exception 'Could not allocate a unique class code for class %', r.id;
    end if;
    update public.classes
      set class_code = candidate, code_rotated_at = now()
      where id = r.id;
  end loop;
end $$;
