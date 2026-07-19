create schema if not exists resilience;

create table if not exists resilience.recovery_plans (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  service_id uuid, service_name text not null, owner text not null,
  recovery_tier text not null check (recovery_tier in ('tier_0','tier_1','tier_2','tier_3')),
  rto_minutes integer not null check (rto_minutes > 0), rpo_minutes integer not null check (rpo_minutes >= 0),
  runbook_url text not null, alternate_process boolean not null default false,
  last_reviewed_at timestamptz, next_review_at timestamptz not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists resilience.backup_controls (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  system_name text not null, owner text not null, frequency_hours integer not null,
  retention_days integer not null, encrypted boolean not null default true,
  immutable boolean not null default false, last_successful_at timestamptz,
  last_restore_test_at timestamptz, restore_test_passed boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists resilience.continuity_exercises (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  name text not null, scenario text not null, owner text not null, scheduled_at timestamptz not null,
  status text not null check (status in ('planned','in_progress','passed','failed','cancelled')),
  participants integer not null default 0, recovery_time_minutes integer, findings_open integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists resilience.third_parties (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  name text not null, service text not null, owner text not null,
  inherent_risk text not null, residual_risk text not null, status text not null,
  data_access text not null, critical_dependency boolean not null default false,
  contract_ends_at date, last_assessment_at date, next_assessment_at date not null,
  soc_report boolean not null default false, breach_notice_hours integer,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists resilience.findings (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  title text not null, category text not null, severity text not null,
  owner text not null, due_at timestamptz not null, status text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table resilience.recovery_plans enable row level security;
alter table resilience.backup_controls enable row level security;
alter table resilience.continuity_exercises enable row level security;
alter table resilience.third_parties enable row level security;
alter table resilience.findings enable row level security;

create policy "workspace recovery plans" on resilience.recovery_plans using (platform.has_workspace_access(workspace_id));
create policy "workspace backup controls" on resilience.backup_controls using (platform.has_workspace_access(workspace_id));
create policy "workspace continuity exercises" on resilience.continuity_exercises using (platform.has_workspace_access(workspace_id));
create policy "workspace third parties" on resilience.third_parties using (platform.has_workspace_access(workspace_id));
create policy "workspace resilience findings" on resilience.findings using (platform.has_workspace_access(workspace_id));

create index if not exists recovery_plans_workspace_review_idx on resilience.recovery_plans(workspace_id,next_review_at);
create index if not exists third_parties_workspace_assessment_idx on resilience.third_parties(workspace_id,next_assessment_at);
create index if not exists resilience_findings_workspace_due_idx on resilience.findings(workspace_id,due_at);
