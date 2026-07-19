create schema if not exists ingestion;

create table if not exists ingestion.data_sources (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, source_category text not null, access_method text not null default 'file',
  refresh_frequency text, reliability_rating numeric(7,4), coverage_rating numeric(7,4), restrictions text,
  status text not null default 'active', created_at timestamptz not null default now(), created_by uuid references platform.users(id)
);
create table if not exists ingestion.import_batches (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), data_source_id uuid references ingestion.data_sources(id),
  entity_type text not null, status text not null default 'uploaded', file_count integer not null default 0, row_count integer not null default 0,
  successful_row_count integer not null default 0, failed_row_count integer not null default 0, duplicate_row_count integer not null default 0,
  mapping_snapshot jsonb not null default '[]', validation_summary jsonb not null default '{}', initiated_by uuid references platform.users(id),
  started_at timestamptz not null default now(), completed_at timestamptz, rolled_back_at timestamptz, rolled_back_by uuid references platform.users(id), rollback_reason text
);
create table if not exists ingestion.import_files (
  id uuid primary key default gen_random_uuid(), import_batch_id uuid not null references ingestion.import_batches(id) on delete restrict,
  storage_path text, original_filename text not null, mime_type text, file_hash text, sheet_name text, header_row_number integer default 1, created_at timestamptz not null default now()
);
create table if not exists ingestion.import_rows (
  id uuid primary key default gen_random_uuid(), import_file_id uuid not null references ingestion.import_files(id) on delete restrict,
  row_number integer not null, raw_values jsonb not null, normalized_values jsonb not null default '{}', status text not null default 'pending',
  error_details jsonb not null default '[]', result_entity_type text, result_entity_id uuid, created_at timestamptz not null default now(),
  unique(import_file_id,row_number)
);
create table if not exists ingestion.field_mappings (
  id uuid primary key default gen_random_uuid(), import_batch_id uuid not null references ingestion.import_batches(id) on delete restrict,
  source_field_name text not null, inferred_type text, target_entity_type text not null, target_field_name text,
  confidence numeric(7,4), transformation_definition jsonb not null default '{}', required boolean not null default false,
  approved_by uuid references platform.users(id), approved_at timestamptz, unique(import_batch_id,source_field_name)
);
create table if not exists ingestion.data_lineage (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), import_row_id uuid not null references ingestion.import_rows(id) on delete restrict,
  entity_type text not null, entity_id uuid, field_name text not null, source_field_name text not null, source_value text,
  accepted_value text, confidence numeric(7,4), accepted_at timestamptz, accepted_by uuid references platform.users(id), superseded_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_import_batches_workspace_created on ingestion.import_batches(workspace_id,started_at desc);
create index if not exists idx_import_rows_file_status on ingestion.import_rows(import_file_id,status);
create index if not exists idx_lineage_entity on ingestion.data_lineage(workspace_id,entity_type,entity_id,field_name);

alter table ingestion.data_sources enable row level security;
alter table ingestion.import_batches enable row level security;
alter table ingestion.import_files enable row level security;
alter table ingestion.import_rows enable row level security;
alter table ingestion.field_mappings enable row level security;
alter table ingestion.data_lineage enable row level security;

create policy "workspace members read sources" on ingestion.data_sources for select using (platform.user_can_access_workspace(workspace_id));
create policy "workspace engineers manage sources" on ingestion.data_sources for all using (platform.user_has_workspace_permission(workspace_id,'data.manage')) with check (platform.user_has_workspace_permission(workspace_id,'data.manage'));
create policy "workspace members read batches" on ingestion.import_batches for select using (platform.user_can_access_workspace(workspace_id));
create policy "workspace engineers manage batches" on ingestion.import_batches for all using (platform.user_has_workspace_permission(workspace_id,'data.manage')) with check (platform.user_has_workspace_permission(workspace_id,'data.manage'));
create policy "workspace members read lineage" on ingestion.data_lineage for select using (platform.user_can_access_workspace(workspace_id));
create policy "workspace engineers manage lineage" on ingestion.data_lineage for all using (platform.user_has_workspace_permission(workspace_id,'data.manage')) with check (platform.user_has_workspace_permission(workspace_id,'data.manage'));

create policy "members read import files" on ingestion.import_files for select using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_can_access_workspace(b.workspace_id)));
create policy "engineers manage import files" on ingestion.import_files for all using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_has_workspace_permission(b.workspace_id,'data.manage')));
create policy "members read import rows" on ingestion.import_rows for select using (exists(select 1 from ingestion.import_files f join ingestion.import_batches b on b.id=f.import_batch_id where f.id=import_file_id and platform.user_can_access_workspace(b.workspace_id)));
create policy "engineers manage import rows" on ingestion.import_rows for all using (exists(select 1 from ingestion.import_files f join ingestion.import_batches b on b.id=f.import_batch_id where f.id=import_file_id and platform.user_has_workspace_permission(b.workspace_id,'data.manage')));
create policy "members read mappings" on ingestion.field_mappings for select using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_can_access_workspace(b.workspace_id)));
create policy "engineers manage mappings" on ingestion.field_mappings for all using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_has_workspace_permission(b.workspace_id,'data.manage')));
