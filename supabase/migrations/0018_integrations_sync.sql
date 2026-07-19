create schema if not exists integrations;

create table if not exists integrations.connections (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  provider text not null,
  category text not null,
  direction text not null check (direction in ('inbound','outbound','bidirectional')),
  auth_type text not null check (auth_type in ('oauth2','api_key','service_account','webhook')),
  status text not null default 'pending' check (status in ('healthy','degraded','disconnected','pending')),
  secret_reference text,
  owner_role text not null,
  scopes jsonb not null default '[]'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  last_checked_at timestamptz,
  last_successful_sync_at timestamptz,
  failure_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,name)
);
comment on column integrations.connections.secret_reference is 'Reference to external secret manager. Never store connector credentials in this table.';

create table if not exists integrations.sync_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  connection_id uuid not null references integrations.connections(id) on delete cascade,
  object_type text not null,
  direction text not null check (direction in ('inbound','outbound')),
  status text not null check (status in ('queued','running','succeeded','partial','failed','cancelled')),
  idempotency_key text not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  records_read integer not null default 0,
  records_written integer not null default 0,
  records_rejected integer not null default 0,
  retry_count integer not null default 0,
  cursor_before jsonb,
  cursor_after jsonb,
  request_snapshot jsonb not null default '{}'::jsonb,
  result_snapshot jsonb not null default '{}'::jsonb,
  error_code text,
  error_message text,
  unique(connection_id,idempotency_key)
);

create table if not exists integrations.sync_record_results (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  sync_job_id uuid not null references integrations.sync_jobs(id) on delete cascade,
  external_id text not null,
  internal_entity_type text,
  internal_entity_id uuid,
  status text not null check (status in ('created','updated','unchanged','rejected','deferred')),
  source_hash text,
  error_code text,
  error_message text,
  payload_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists integrations.webhook_endpoints (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  connection_id uuid not null references integrations.connections(id) on delete cascade,
  event_type text not null,
  endpoint_key text not null unique,
  status text not null default 'active' check (status in ('active','paused')),
  signature_required boolean not null default true,
  secret_reference text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists integrations.webhook_deliveries (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  endpoint_id uuid not null references integrations.webhook_endpoints(id) on delete cascade,
  provider_event_id text not null,
  received_at timestamptz not null default now(),
  signature_valid boolean not null,
  replay_key text not null,
  status text not null check (status in ('accepted','processed','rejected','failed')),
  payload_hash text not null,
  payload_snapshot jsonb not null default '{}'::jsonb,
  error_message text,
  unique(endpoint_id,provider_event_id),
  unique(endpoint_id,replay_key)
);

create table if not exists integrations.reconciliation_issues (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  connection_id uuid not null references integrations.connections(id) on delete cascade,
  sync_job_id uuid references integrations.sync_jobs(id) on delete set null,
  object_type text not null,
  external_id text not null,
  internal_entity_id uuid,
  issue_type text not null check (issue_type in ('missing_internal','missing_external','field_mismatch','duplicate','stale')),
  severity text not null check (severity in ('critical','warning','info')),
  status text not null default 'open' check (status in ('open','acknowledged','resolved')),
  summary text not null,
  source_value jsonb,
  internal_value jsonb,
  resolution jsonb,
  owner_role text not null,
  detected_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists idx_connections_workspace on integrations.connections(workspace_id,status);
create index if not exists idx_sync_jobs_workspace_started on integrations.sync_jobs(workspace_id,started_at desc);
create index if not exists idx_sync_jobs_connection_status on integrations.sync_jobs(connection_id,status);
create index if not exists idx_sync_record_results_job on integrations.sync_record_results(sync_job_id,status);
create index if not exists idx_reconciliation_workspace_status on integrations.reconciliation_issues(workspace_id,status,severity);
create index if not exists idx_webhook_deliveries_endpoint_received on integrations.webhook_deliveries(endpoint_id,received_at desc);

alter table integrations.connections enable row level security;
alter table integrations.sync_jobs enable row level security;
alter table integrations.sync_record_results enable row level security;
alter table integrations.webhook_endpoints enable row level security;
alter table integrations.webhook_deliveries enable row level security;
alter table integrations.reconciliation_issues enable row level security;

create policy connections_workspace_access on integrations.connections for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
create policy sync_jobs_workspace_access on integrations.sync_jobs for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
create policy sync_record_results_workspace_access on integrations.sync_record_results for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
create policy webhook_endpoints_workspace_access on integrations.webhook_endpoints for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
create policy webhook_deliveries_workspace_access on integrations.webhook_deliveries for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
create policy reconciliation_workspace_access on integrations.reconciliation_issues for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
