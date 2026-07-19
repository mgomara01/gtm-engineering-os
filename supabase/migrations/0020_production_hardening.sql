create schema if not exists operations;
create table if not exists operations.backup_policies (
  id uuid primary key default gen_random_uuid(), workspace_id uuid references platform.workspaces(id) on delete cascade,
  resource_type text not null, rpo_hours integer not null check (rpo_hours >= 0), rto_hours integer not null check (rto_hours >= 0),
  schedule text not null, retention_days integer not null check (retention_days > 0), is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists operations.recovery_tests (
  id uuid primary key default gen_random_uuid(), backup_policy_id uuid not null references operations.backup_policies(id) on delete cascade,
  started_at timestamptz not null, completed_at timestamptz, status text not null check(status in ('planned','running','passed','failed')),
  restored_to text, evidence jsonb not null default '{}'::jsonb, failure_reason text, performed_by uuid references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists operations.release_deployments (
  id uuid primary key default gen_random_uuid(), workspace_id uuid references platform.workspaces(id) on delete cascade,
  environment text not null check(environment in ('development','staging','production')), git_sha text not null,
  release_version text not null, status text not null check(status in ('planned','running','succeeded','failed','rolled_back')),
  started_at timestamptz, completed_at timestamptz, initiated_by uuid references auth.users(id),
  readiness_snapshot jsonb not null default '{}'::jsonb, rollback_release_id uuid references operations.release_deployments(id), created_at timestamptz not null default now()
);
create table if not exists operations.runtime_incidents (
  id uuid primary key default gen_random_uuid(), workspace_id uuid references platform.workspaces(id) on delete cascade,
  severity text not null check(severity in ('sev1','sev2','sev3','sev4')), title text not null, status text not null check(status in ('open','mitigated','resolved')),
  detected_at timestamptz not null default now(), resolved_at timestamptz, correlation_id text, summary text, root_cause text, remediation text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table operations.backup_policies enable row level security;
alter table operations.release_deployments enable row level security;
alter table operations.runtime_incidents enable row level security;
create policy backup_workspace_access on operations.backup_policies for all using (workspace_id is null or platform.user_has_workspace_access(workspace_id));
create policy deployment_workspace_access on operations.release_deployments for select using (workspace_id is null or platform.user_has_workspace_access(workspace_id));
create policy incident_workspace_access on operations.runtime_incidents for all using (workspace_id is null or platform.user_has_workspace_access(workspace_id));
