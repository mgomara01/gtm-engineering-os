-- Step 34: Integration Marketplace and Connector Operations
create table if not exists public.connector_definitions (
  id uuid primary key default gen_random_uuid(), slug text unique not null, name text not null,
  category text not null, publisher text not null, version text not null, lifecycle_status text not null,
  certified boolean not null default false, scopes jsonb not null default '[]', capabilities jsonb not null default '{}',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.connector_installations (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null, connector_id uuid not null references public.connector_definitions(id),
  environment text not null, status text not null, credential_type text not null, credential_secret_ref text not null,
  credential_expires_at timestamptz, owner_user_id uuid, last_health_check_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.connector_field_mappings (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null, installation_id uuid not null references public.connector_installations(id) on delete cascade,
  source_object text not null, source_field text not null, target_object text not null, target_field text not null,
  transform_expression text, required boolean not null default false, active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.connector_sync_jobs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null, installation_id uuid not null references public.connector_installations(id) on delete cascade,
  object_type text not null, direction text not null, status text not null, cursor text, started_at timestamptz not null,
  completed_at timestamptz, records_read bigint not null default 0, records_written bigint not null default 0,
  records_failed bigint not null default 0, retry_count integer not null default 0, error_summary text
);
create table if not exists public.connector_alerts (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null, installation_id uuid not null references public.connector_installations(id) on delete cascade,
  severity text not null, alert_type text not null, message text not null, acknowledged_at timestamptz,
  opened_at timestamptz not null default now(), resolved_at timestamptz
);
create index if not exists connector_installations_workspace_idx on public.connector_installations(workspace_id,status);
create index if not exists connector_sync_jobs_workspace_started_idx on public.connector_sync_jobs(workspace_id,started_at desc);
create index if not exists connector_alerts_workspace_open_idx on public.connector_alerts(workspace_id,resolved_at);
alter table public.connector_installations enable row level security;
alter table public.connector_field_mappings enable row level security;
alter table public.connector_sync_jobs enable row level security;
alter table public.connector_alerts enable row level security;
-- Production deployment must attach the standard workspace membership RLS policies and store only vault references, never raw credentials.
