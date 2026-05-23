-- Remove the 24 h expiry constraint on session tickets.
-- NULL expires_at means the ticket never expires.
ALTER TABLE public.session_tickets
  ALTER COLUMN expires_at DROP NOT NULL;

-- Short 4-character code for keyboard entry (short-URL classroom flow).
-- Globally unique since it is always resolved together with a school slug.
ALTER TABLE public.session_tickets
  ADD COLUMN short_code text UNIQUE;

CREATE INDEX ON public.session_tickets (short_code);

-- School slug for short URLs: diagnose.numeris.de/s/<slug>
ALTER TABLE public.schools
  ADD COLUMN slug text UNIQUE;

CREATE INDEX ON public.schools (slug);

-- Back-fill slugs for any schools already in the database.
UPDATE public.schools
SET slug = lower(
  regexp_replace(
    regexp_replace(name, '[^a-zA-ZäöüÄÖÜß0-9\s-]', '', 'g'),
    '\s+', '-', 'g'
  )
)
WHERE slug IS NULL;
