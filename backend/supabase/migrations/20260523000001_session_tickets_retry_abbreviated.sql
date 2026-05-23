-- Phase 1.1: Add retry mode and abbreviated (verkürzte) mode to session_tickets.

alter table public.session_tickets
  add column if not exists retry_mode boolean not null default false,
  add column if not exists retry_session_id uuid references public.diagnostic_sessions(id) on delete set null,
  add column if not exists abbreviated_mode boolean not null default false;
