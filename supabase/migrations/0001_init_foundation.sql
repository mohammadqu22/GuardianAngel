-- Guardian Angel — Supabase foundation (Phase 1)
--
-- These tables mirror the on-device SQLite model (see
-- lib/services/database_service.dart) so the LOCAL database stays the
-- offline-first source of truth and Supabase is an optional cloud copy used
-- only when the user is signed in and online.
--
-- Every user table is protected by Row-Level Security: a row is only ever
-- visible to its owner. Login is never required for emergency usage.

-- ── Tables ───────────────────────────────────────────────────────────────────

-- One row per authenticated user.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Mirrors the SharedPreferences flags + User_Settings table.
create table if not exists public.user_settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  language text,
  tts_enabled boolean,
  ai_detection_enabled boolean,
  theme_mode text,
  updated_at timestamptz not null default now()
);

-- Mirrors Emergency_Contact.
create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  phone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists emergency_contacts_user_id_idx
  on public.emergency_contacts (user_id);

-- Mirrors Incident_Log (timed protocol sessions).
create table if not exists public.incident_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  protocol_id text not null,
  started_at timestamptz,
  completed boolean not null default false,
  steps_completed integer,
  total_steps integer,
  total_elapsed_ms integer,
  step_durations jsonb,
  created_at timestamptz not null default now()
);
create index if not exists incident_logs_user_id_idx
  on public.incident_logs (user_id);

-- Per-protocol learn-mode completion.
create table if not exists public.learning_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  protocol_id text not null,
  is_completed boolean not null default false,
  last_step integer,
  updated_at timestamptz not null default now(),
  primary key (user_id, protocol_id)
);

-- Per-protocol quiz scores.
create table if not exists public.quiz_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  protocol_id text not null,
  best_score integer,
  attempts integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, protocol_id)
);

-- Minimal, privacy-preserving analytics for the AI triage proxy.
-- Written ONLY by the Edge Function via the service-role key (bypasses RLS).
-- Raw user text is NOT stored by default: input_text stays null unless the
-- function is run with LOG_TRIAGE_INPUT = "true". user_id is null for
-- anonymous (logged-out) triage.
create table if not exists public.ai_triage_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  matched_id text,
  had_local_match boolean,
  query_length integer,
  lang text,
  model text,
  latency_ms integer,
  input_text text,
  created_at timestamptz not null default now()
);
create index if not exists ai_triage_logs_created_at_idx
  on public.ai_triage_logs (created_at);

-- ── Row-Level Security ───────────────────────────────────────────────────────

alter table public.profiles           enable row level security;
alter table public.user_settings      enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.incident_logs      enable row level security;
alter table public.learning_progress  enable row level security;
alter table public.quiz_progress      enable row level security;
alter table public.ai_triage_logs     enable row level security;

-- profiles: the owner is the row id itself.
create policy "profiles_select_own" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_delete_own" on public.profiles
  for delete to authenticated using (id = auth.uid());

-- user_settings
create policy "user_settings_select_own" on public.user_settings
  for select to authenticated using (user_id = auth.uid());
create policy "user_settings_insert_own" on public.user_settings
  for insert to authenticated with check (user_id = auth.uid());
create policy "user_settings_update_own" on public.user_settings
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_settings_delete_own" on public.user_settings
  for delete to authenticated using (user_id = auth.uid());

-- emergency_contacts
create policy "emergency_contacts_select_own" on public.emergency_contacts
  for select to authenticated using (user_id = auth.uid());
create policy "emergency_contacts_insert_own" on public.emergency_contacts
  for insert to authenticated with check (user_id = auth.uid());
create policy "emergency_contacts_update_own" on public.emergency_contacts
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "emergency_contacts_delete_own" on public.emergency_contacts
  for delete to authenticated using (user_id = auth.uid());

-- incident_logs
create policy "incident_logs_select_own" on public.incident_logs
  for select to authenticated using (user_id = auth.uid());
create policy "incident_logs_insert_own" on public.incident_logs
  for insert to authenticated with check (user_id = auth.uid());
create policy "incident_logs_update_own" on public.incident_logs
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "incident_logs_delete_own" on public.incident_logs
  for delete to authenticated using (user_id = auth.uid());

-- learning_progress
create policy "learning_progress_select_own" on public.learning_progress
  for select to authenticated using (user_id = auth.uid());
create policy "learning_progress_insert_own" on public.learning_progress
  for insert to authenticated with check (user_id = auth.uid());
create policy "learning_progress_update_own" on public.learning_progress
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "learning_progress_delete_own" on public.learning_progress
  for delete to authenticated using (user_id = auth.uid());

-- quiz_progress
create policy "quiz_progress_select_own" on public.quiz_progress
  for select to authenticated using (user_id = auth.uid());
create policy "quiz_progress_insert_own" on public.quiz_progress
  for insert to authenticated with check (user_id = auth.uid());
create policy "quiz_progress_update_own" on public.quiz_progress
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "quiz_progress_delete_own" on public.quiz_progress
  for delete to authenticated using (user_id = auth.uid());

-- ai_triage_logs: a user may read their OWN rows; there is intentionally NO
-- insert/update/delete policy, so clients can never write. Only the Edge
-- Function's service-role key (which bypasses RLS) inserts rows.
create policy "ai_triage_logs_select_own" on public.ai_triage_logs
  for select to authenticated using (user_id = auth.uid());
