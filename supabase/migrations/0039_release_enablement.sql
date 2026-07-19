-- Step 39: Documentation, onboarding, training, release communications, and launch readiness.
create table if not exists public.documentation_assets (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  title text not null, category text not null check (category in ('product','implementation','administration','api','runbook')),
  audience text not null check (audience in ('customer','administrator','operator','developer','executive')), owner text not null,
  status text not null check (status in ('draft','approved','stale')), version text not null, content_url text,
  coverage_pct numeric(5,2) not null default 0 check (coverage_pct between 0 and 100), last_reviewed_at timestamptz, review_due_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.onboarding_programs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, audience text not null, owner text not null, status text not null check (status in ('not_started','in_progress','completed','blocked')),
  participants integer not null default 0, completed_participants integer not null default 0, target_days integer not null, actual_days integer, blocker text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.training_modules (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  title text not null, audience text not null, owner text not null, status text not null check (status in ('draft','published','retired')),
  required boolean not null default false, completion_pct numeric(5,2) not null default 0, assessment_pass_pct numeric(5,2) not null default 0,
  expires_after_days integer, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.release_communications (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  version text not null, channel text not null check (channel in ('release_notes','email','in_app','webinar')), audience text not null,
  owner text not null, status text not null check (status in ('planned','published')), scheduled_at timestamptz not null, published_at timestamptz,
  created_at timestamptz not null default now());
create table if not exists public.launch_controls (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, owner text not null, required boolean not null default true, status text not null check (status in ('ready','at_risk','blocked')),
  evidence text not null default '', updated_at timestamptz not null default now());
alter table public.documentation_assets enable row level security; alter table public.onboarding_programs enable row level security;
alter table public.training_modules enable row level security; alter table public.release_communications enable row level security; alter table public.launch_controls enable row level security;
