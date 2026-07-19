-- Step 37: End-to-end quality engineering and release hardening
create table if not exists public.quality_suites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  layer text not null check (layer in ('unit','integration','contract','e2e','security','performance','uat')),
  owner text not null,
  automated boolean not null default false,
  required_for_release boolean not null default false,
  total_cases integer not null default 0 check (total_cases >= 0),
  passed_cases integer not null default 0 check (passed_cases >= 0),
  failed_cases integer not null default 0 check (failed_cases >= 0),
  coverage_pct numeric(5,2) not null default 0 check (coverage_pct between 0 and 100),
  last_run_at timestamptz,
  status text not null check (status in ('planned','running','passed','failed','blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.quality_defects (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  external_key text not null,
  title text not null,
  severity text not null check (severity in ('critical','high','medium','low')),
  status text not null check (status in ('open','triaged','in_progress','resolved','accepted')),
  owner text not null,
  release_candidate_id uuid,
  opened_at timestamptz not null default now(),
  target_resolution_at timestamptz not null,
  customer_impact boolean not null default false,
  root_cause text,
  accepted_risk_reason text,
  unique(workspace_id, external_key)
);
create table if not exists public.environment_certifications (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  environment text not null,
  version text not null,
  status text not null check (status in ('pending','certified','expired','failed')),
  certified_at timestamptz,
  expires_at timestamptz,
  data_refresh_at timestamptz,
  configuration_fingerprint text not null,
  open_blockers integer not null default 0 check (open_blockers >= 0),
  certification_evidence jsonb not null default '{}'::jsonb,
  unique(workspace_id, environment, version)
);
create table if not exists public.release_candidates (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  version text not null,
  status text not null check (status in ('draft','testing','candidate','approved','rejected','released')),
  created_at timestamptz not null default now(),
  target_release_at timestamptz not null,
  change_count integer not null default 0,
  blocking_defects integer not null default 0,
  required_suites_passed integer not null default 0,
  required_suites_total integer not null default 0,
  uat_approved boolean not null default false,
  rollback_validated boolean not null default false,
  security_approved boolean not null default false,
  performance_approved boolean not null default false,
  release_owner text not null,
  release_notes text,
  unique(workspace_id, version)
);
alter table public.quality_defects add constraint quality_defects_release_candidate_fk foreign key (release_candidate_id) references public.release_candidates(id) on delete set null;
create table if not exists public.uat_signoffs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  release_candidate_id uuid not null references public.release_candidates(id) on delete cascade,
  business_area text not null,
  approver text not null,
  status text not null check (status in ('pending','approved','rejected')),
  signed_at timestamptz,
  notes text not null default '',
  unique(release_candidate_id, business_area)
);
create index if not exists quality_suites_workspace_status_idx on public.quality_suites(workspace_id,status);
create index if not exists quality_defects_workspace_severity_idx on public.quality_defects(workspace_id,severity,status);
create index if not exists release_candidates_workspace_status_idx on public.release_candidates(workspace_id,status,target_release_at);
create index if not exists uat_signoffs_release_idx on public.uat_signoffs(release_candidate_id,status);
alter table public.quality_suites enable row level security;
alter table public.quality_defects enable row level security;
alter table public.environment_certifications enable row level security;
alter table public.release_candidates enable row level security;
alter table public.uat_signoffs enable row level security;
create policy "workspace members manage quality suites" on public.quality_suites using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace members manage quality defects" on public.quality_defects using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace members manage environment certifications" on public.environment_certifications using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace members manage release candidates" on public.release_candidates using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace members manage uat signoffs" on public.uat_signoffs using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
