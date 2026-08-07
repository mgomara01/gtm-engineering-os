-- Step 45: real external GTM signal ingestion (EPA ECHO, USGS Water Services,
-- Tampa GeoHub, and future sources from the GTM Engineering API Matrix).
-- Raw, pre-entity-resolution records land here; scoring/entity-resolution is
-- a separate, later pass -- this table is intentionally just the ingest layer.
create table if not exists ingestion.external_signals (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  source text not null, category text not null, external_ref text not null,
  title text not null, location text, severity text not null default 'info',
  detail jsonb not null default '{}', observed_at timestamptz, fetched_at timestamptz not null default now(),
  unique(workspace_id,source,external_ref)
);
create index if not exists idx_external_signals_workspace_source on ingestion.external_signals(workspace_id,source,fetched_at desc);

alter table ingestion.external_signals enable row level security;
create policy "workspace members read external signals" on ingestion.external_signals for select using (platform.user_has_workspace_access(workspace_id));
create policy "workspace engineers manage external signals" on ingestion.external_signals for all using (platform.user_has_workspace_permission(workspace_id,'data.manage')) with check (platform.user_has_workspace_permission(workspace_id,'data.manage'));
grant select,insert,update,delete on ingestion.external_signals to authenticated,service_role;
