-- Combined migration + seed script for alvarez_gtm_production
-- Includes RLS hardening (0043) for the 33 tables that previously had no row-level security.
-- Includes all prior fixes from rounds 1-6.
-- For a FRESH install only: run reset_before_rerun.sql FIRST.

-- ===== supabase/migrations/0001_extensions.sql =====
create extension if not exists pgcrypto;
create extension if not exists citext;
-- Both genuinely missing (not a naming issue): 0011_entity_resolution.sql uses
-- gin_trgm_ops/similarity() (needs pg_trgm) and unaccent() (needs the unaccent
-- extension), but neither extension was ever enabled anywhere in the original migrations.
create extension if not exists pg_trgm;
create extension if not exists unaccent;
create schema if not exists platform;
create schema if not exists configuration;
create schema if not exists entities;
create schema if not exists ingestion;
create schema if not exists intelligence;
create schema if not exists scoring;
create schema if not exists gtm;
create schema if not exists implementation;
create schema if not exists agents;
create schema if not exists analytics;
create schema if not exists governance;
create schema if not exists integrations;

-- ===== supabase/migrations/0002_platform.sql =====
create table platform.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code citext not null unique,
  legal_entity_name text,
  workspace_type text not null check (workspace_type in ('operating_company','concept','product_line')),
  status text not null default 'planning' check (status in ('planning','pilot','active','paused','archived')),
  timezone text not null default 'America/New_York',
  currency_code char(3) not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table platform.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email citext not null,
  display_name text not null,
  status text not null default 'active',
  default_workspace_id uuid references platform.workspaces(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table platform.roles (
  id uuid primary key default gen_random_uuid(),
  code citext not null unique,
  name text not null,
  description text
);
create table platform.user_workspace_roles (
  user_id uuid not null references platform.user_profiles(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  role_id uuid not null references platform.roles(id),
  active boolean not null default true,
  assigned_at timestamptz not null default now(),
  primary key (user_id,workspace_id,role_id)
);

-- ===== supabase/migrations/0003_core_entities.sql =====
create table entities.organizations (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null,
  normalized_name text not null,
  organization_type text not null default 'company',
  website_domain citext,
  phone text,
  status text not null default 'active',
  verified_at timestamptz,
  verification_level text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index organizations_normalized_name_idx on entities.organizations(normalized_name);
create table entities.workspace_organizations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  organization_id uuid not null references entities.organizations(id),
  relationship_status text,
  account_type text,
  lifecycle_status text,
  priority_tier text,
  assigned_owner_user_id uuid references platform.user_profiles(id),
  workspace_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,organization_id)
);
create index workspace_organizations_workspace_idx on entities.workspace_organizations(workspace_id);

-- ===== supabase/migrations/0004_configuration.sql =====
create table configuration.workspace_configuration_versions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  version_number integer not null,
  status text not null default 'draft' check(status in ('draft','review','approved','active','retired')),
  effective_at timestamptz,
  approved_by uuid references platform.user_profiles(id),
  approved_at timestamptz,
  change_summary text,
  created_at timestamptz not null default now(),
  unique(workspace_id,version_number)
);
create table configuration.business_models (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  configuration_version_id uuid not null references configuration.workspace_configuration_versions(id),
  business_summary text not null,
  strategic_objective text not null,
  primary_growth_objective text,
  business_maturity text,
  competitive_advantage text,
  current_constraints text,
  current_gtm_maturity integer check(current_gtm_maturity between 1 and 5),
  target_gtm_maturity integer check(target_gtm_maturity between 1 and 5),
  status text not null default 'draft'
);

-- ===== supabase/migrations/0005_rls.sql =====
alter table platform.workspaces enable row level security;
alter table entities.workspace_organizations enable row level security;
alter table configuration.workspace_configuration_versions enable row level security;
create or replace function platform.user_has_workspace_access(target_workspace uuid)
returns boolean language sql stable security definer set search_path=platform,public as $$
  select exists(select 1 from platform.user_workspace_roles uwr where uwr.user_id=auth.uid() and uwr.workspace_id=target_workspace and uwr.active=true)
$$;
-- Compatibility aliases: later migrations (0009-0038) called this check under three
-- different names/schemas (platform.has_workspace_access, platform.is_workspace_member,
-- public.is_workspace_member) that were never defined. Rather than rewrite every call
-- site across a dozen files, these aliases give each name a real, identical-behavior
-- implementation delegating to the one canonical function above.
create or replace function platform.has_workspace_access(target_workspace uuid)
returns boolean language sql stable security definer set search_path=platform,public as $$
  select platform.user_has_workspace_access(target_workspace)
$$;
create or replace function platform.is_workspace_member(target_workspace uuid)
returns boolean language sql stable security definer set search_path=platform,public as $$
  select platform.user_has_workspace_access(target_workspace)
$$;
create or replace function public.is_workspace_member(target_workspace uuid)
returns boolean language sql stable security definer set search_path=platform,public as $$
  select platform.user_has_workspace_access(target_workspace)
$$;
create policy workspaces_member_select on platform.workspaces for select using (platform.user_has_workspace_access(id));
create policy workspace_org_member_all on entities.workspace_organizations for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
create policy config_member_all on configuration.workspace_configuration_versions for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));

-- ===== supabase/migrations/0006_permissions_and_workspace_views.sql =====
create table if not exists platform.permissions (
  id uuid primary key default gen_random_uuid(),
  code citext not null unique,
  name text not null,
  description text
);

create table if not exists platform.role_permissions (
  role_id uuid not null references platform.roles(id) on delete cascade,
  permission_id uuid not null references platform.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

alter table platform.user_workspace_roles add column if not exists assigned_by uuid references platform.user_profiles(id);
alter table platform.workspaces add column if not exists active_configuration_version_id uuid;

-- Genuinely missing (not a naming typo): migration 0009 calls this with a permission
-- code, e.g. platform.user_has_workspace_permission(workspace_id,'data.manage'), which
-- is a finer-grained check than plain workspace membership -- true only if the user's
-- active role in that workspace has been granted the named permission.
create or replace function platform.user_has_workspace_permission(target_workspace uuid, required_permission text)
returns boolean language sql stable security definer set search_path=platform,public as $$
  select exists(
    select 1
    from platform.user_workspace_roles uwr
    join platform.role_permissions rp on rp.role_id = uwr.role_id
    join platform.permissions p on p.id = rp.permission_id
    where uwr.user_id = auth.uid()
      and uwr.workspace_id = target_workspace
      and uwr.active = true
      and p.code = required_permission
  )
$$;


-- ===== supabase/migrations/0007_implementation_workflow.sql =====
create table implementation.implementation_plans (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  configuration_version_id uuid references configuration.workspace_configuration_versions(id),
  name text not null,
  status text not null default 'draft' check(status in ('draft','active','complete','archived')),
  created_by uuid references platform.user_profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table implementation.implementation_stages (
  id uuid primary key default gen_random_uuid(),
  implementation_plan_id uuid not null references implementation.implementation_plans(id) on delete cascade,
  stage_number integer not null check(stage_number between 1 and 12),
  name text not null,
  objective text not null,
  status text not null default 'not_started' check(status in ('not_started','active','blocked','complete')),
  completion_percentage numeric(5,2) not null default 0 check(completion_percentage between 0 and 100),
  assigned_owner_user_id uuid references platform.user_profiles(id),
  target_date date,
  approved_by uuid references platform.user_profiles(id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(implementation_plan_id,stage_number)
);

create table implementation.stage_requirements (
  id uuid primary key default gen_random_uuid(),
  implementation_stage_id uuid not null references implementation.implementation_stages(id) on delete cascade,
  requirement_type text not null check(requirement_type in ('input','deliverable','approval','completion_rule')),
  title text not null,
  description text,
  required boolean not null default true,
  status text not null default 'not_started' check(status in ('not_started','in_progress','complete','waived')),
  completed_by uuid references platform.user_profiles(id),
  completed_at timestamptz,
  sort_order integer not null default 0
);

create table implementation.decisions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  implementation_stage_id uuid references implementation.implementation_stages(id) on delete cascade,
  title text not null,
  decision_required text not null,
  recommendation text,
  final_decision text,
  owner_user_id uuid references platform.user_profiles(id),
  due_date date,
  status text not null default 'open' check(status in ('open','approved','deferred')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table implementation.risks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  implementation_stage_id uuid references implementation.implementation_stages(id) on delete cascade,
  title text not null,
  description text not null,
  category text not null,
  probability text not null check(probability in ('low','medium','high')),
  impact text not null check(impact in ('low','medium','high')),
  mitigation text,
  owner_user_id uuid references platform.user_profiles(id),
  status text not null default 'open' check(status in ('open','monitoring','accepted','resolved')),
  target_resolution date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table implementation.readiness_assessments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  implementation_stage_id uuid not null references implementation.implementation_stages(id) on delete cascade,
  readiness_category text not null,
  score numeric(5,2) not null check(score between 0 and 100),
  status text not null,
  assessment_details jsonb not null default '{}'::jsonb,
  assessed_by uuid references platform.user_profiles(id),
  assessed_at timestamptz not null default now()
);

create or replace view implementation.stage_dashboard
with (security_invoker=true) as
select
  p.workspace_id,
  s.id,
  s.stage_number,
  s.name,
  s.objective,
  s.status,
  s.completion_percentage,
  s.target_date,
  u.display_name as owner_name,
  count(sr.id) filter (where sr.requirement_type='deliverable' and sr.status in ('complete','waived')) as deliverables_complete,
  count(sr.id) filter (where sr.requirement_type='deliverable' and sr.required=true) as deliverables_required,
  count(distinct d.id) filter (where d.status='open') as open_decisions,
  count(distinct r.id) filter (where r.status in ('open','monitoring')) as open_risks,
  coalesce(avg(ra.score),0) as readiness_score
from implementation.implementation_plans p
join implementation.implementation_stages s on s.implementation_plan_id=p.id
left join platform.user_profiles u on u.id=s.assigned_owner_user_id
left join implementation.stage_requirements sr on sr.implementation_stage_id=s.id
left join implementation.decisions d on d.implementation_stage_id=s.id
left join implementation.risks r on r.implementation_stage_id=s.id
left join implementation.readiness_assessments ra on ra.implementation_stage_id=s.id
where p.status='active'
group by p.workspace_id,s.id,u.display_name;

grant select on implementation.stage_dashboard to authenticated;

create or replace view platform.user_workspace_access
with (security_invoker=true) as
select
  uwr.user_id,
  w.id as workspace_id,
  w.name,
  w.code,
  w.status,
  r.code::text as role_code,
  coalesce(ip.current_stage, 1) as current_stage
from platform.user_workspace_roles uwr
join platform.workspaces w on w.id=uwr.workspace_id
join platform.roles r on r.id=uwr.role_id
left join lateral (
  select min(s.stage_number) filter (where s.status in ('active','blocked')) as current_stage
  from implementation.implementation_plans p
  join implementation.implementation_stages s on s.implementation_plan_id=p.id
  where p.workspace_id=w.id and p.status='active'
) ip on true
where uwr.active=true;

grant select on platform.user_workspace_access to authenticated;


alter table implementation.implementation_plans enable row level security;
alter table implementation.implementation_stages enable row level security;
alter table implementation.stage_requirements enable row level security;
alter table implementation.decisions enable row level security;
alter table implementation.risks enable row level security;
alter table implementation.readiness_assessments enable row level security;

create policy implementation_plan_access on implementation.implementation_plans for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));
create policy implementation_stage_access on implementation.implementation_stages for all using(exists(select 1 from implementation.implementation_plans p where p.id=implementation_plan_id and platform.user_has_workspace_access(p.workspace_id))) with check(exists(select 1 from implementation.implementation_plans p where p.id=implementation_plan_id and platform.user_has_workspace_access(p.workspace_id)));
create policy stage_requirement_access on implementation.stage_requirements for all using(exists(select 1 from implementation.implementation_stages s join implementation.implementation_plans p on p.id=s.implementation_plan_id where s.id=implementation_stage_id and platform.user_has_workspace_access(p.workspace_id))) with check(exists(select 1 from implementation.implementation_stages s join implementation.implementation_plans p on p.id=s.implementation_plan_id where s.id=implementation_stage_id and platform.user_has_workspace_access(p.workspace_id)));
create policy decision_access on implementation.decisions for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));
create policy risk_access on implementation.risks for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));
create policy readiness_access on implementation.readiness_assessments for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));

-- ===== supabase/migrations/0008_configuration_version_controls.sql =====
alter table platform.workspaces add constraint workspaces_active_configuration_fk foreign key (active_configuration_version_id) references configuration.workspace_configuration_versions(id);

create or replace function configuration.activate_workspace_configuration(target_version uuid)
returns void language plpgsql security definer set search_path=configuration,platform,public as $$
declare target_workspace uuid;
begin
  select workspace_id into target_workspace from configuration.workspace_configuration_versions where id=target_version;
  if target_workspace is null then raise exception 'Configuration version not found'; end if;
  if not platform.user_has_workspace_access(target_workspace) then raise exception 'Workspace access denied'; end if;
  update configuration.workspace_configuration_versions set status='retired' where workspace_id=target_workspace and status='active';
  update configuration.workspace_configuration_versions set status='active',effective_at=coalesce(effective_at,now()),approved_at=coalesce(approved_at,now()),approved_by=coalesce(approved_by,auth.uid()) where id=target_version and status in ('approved','active');
  if not found then raise exception 'Only approved versions can be activated'; end if;
  update platform.workspaces set active_configuration_version_id=target_version,updated_at=now() where id=target_workspace;
end $$;

-- ===== supabase/migrations/0009_data_ingestion.sql =====
create schema if not exists ingestion;

create table if not exists ingestion.data_sources (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, source_category text not null, access_method text not null default 'file',
  refresh_frequency text, reliability_rating numeric(7,4), coverage_rating numeric(7,4), restrictions text,
  status text not null default 'active', created_at timestamptz not null default now(), created_by uuid references platform.user_profiles(id)
);
create table if not exists ingestion.import_batches (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), data_source_id uuid references ingestion.data_sources(id),
  entity_type text not null, status text not null default 'uploaded', file_count integer not null default 0, row_count integer not null default 0,
  successful_row_count integer not null default 0, failed_row_count integer not null default 0, duplicate_row_count integer not null default 0,
  mapping_snapshot jsonb not null default '[]', validation_summary jsonb not null default '{}', initiated_by uuid references platform.user_profiles(id),
  started_at timestamptz not null default now(), completed_at timestamptz, rolled_back_at timestamptz, rolled_back_by uuid references platform.user_profiles(id), rollback_reason text
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
  approved_by uuid references platform.user_profiles(id), approved_at timestamptz, unique(import_batch_id,source_field_name)
);
create table if not exists ingestion.data_lineage (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), import_row_id uuid not null references ingestion.import_rows(id) on delete restrict,
  entity_type text not null, entity_id uuid, field_name text not null, source_field_name text not null, source_value text,
  accepted_value text, confidence numeric(7,4), accepted_at timestamptz, accepted_by uuid references platform.user_profiles(id), superseded_at timestamptz,
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

create policy "workspace members read sources" on ingestion.data_sources for select using (platform.user_has_workspace_access(workspace_id));
create policy "workspace engineers manage sources" on ingestion.data_sources for all using (platform.user_has_workspace_permission(workspace_id,'data.manage')) with check (platform.user_has_workspace_permission(workspace_id,'data.manage'));
create policy "workspace members read batches" on ingestion.import_batches for select using (platform.user_has_workspace_access(workspace_id));
create policy "workspace engineers manage batches" on ingestion.import_batches for all using (platform.user_has_workspace_permission(workspace_id,'data.manage')) with check (platform.user_has_workspace_permission(workspace_id,'data.manage'));
create policy "workspace members read lineage" on ingestion.data_lineage for select using (platform.user_has_workspace_access(workspace_id));
create policy "workspace engineers manage lineage" on ingestion.data_lineage for all using (platform.user_has_workspace_permission(workspace_id,'data.manage')) with check (platform.user_has_workspace_permission(workspace_id,'data.manage'));

create policy "members read import files" on ingestion.import_files for select using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_has_workspace_access(b.workspace_id)));
create policy "engineers manage import files" on ingestion.import_files for all using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_has_workspace_permission(b.workspace_id,'data.manage')));
create policy "members read import rows" on ingestion.import_rows for select using (exists(select 1 from ingestion.import_files f join ingestion.import_batches b on b.id=f.import_batch_id where f.id=import_file_id and platform.user_has_workspace_access(b.workspace_id)));
create policy "engineers manage import rows" on ingestion.import_rows for all using (exists(select 1 from ingestion.import_files f join ingestion.import_batches b on b.id=f.import_batch_id where f.id=import_file_id and platform.user_has_workspace_permission(b.workspace_id,'data.manage')));
create policy "members read mappings" on ingestion.field_mappings for select using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_has_workspace_access(b.workspace_id)));
create policy "engineers manage mappings" on ingestion.field_mappings for all using (exists(select 1 from ingestion.import_batches b where b.id=import_batch_id and platform.user_has_workspace_permission(b.workspace_id,'data.manage')));

-- ===== supabase/migrations/0010_operational_entities.sql =====
-- Step 10: operational entity layer, relationships, directories, and source-linked records.
alter table entities.organizations add column if not exists industry_name text;
alter table entities.organizations add column if not exists annual_revenue numeric(18,2);
alter table entities.organizations add column if not exists employee_count integer;

create table if not exists entities.addresses (
 id uuid primary key default gen_random_uuid(), address_line_1 text not null, address_line_2 text,
 city text, county text, state_region text, postal_code text, country_code char(2) not null default 'US',
 latitude numeric(10,7), longitude numeric(10,7), normalized_address text, validation_status text not null default 'unverified',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists entities.organization_addresses (
 organization_id uuid not null references entities.organizations(id) on delete cascade,
 address_id uuid not null references entities.addresses(id) on delete cascade,
 address_role text not null default 'primary', is_primary boolean not null default false,
 primary key(organization_id,address_id,address_role)
);
create table if not exists entities.properties (
 id uuid primary key default gen_random_uuid(), canonical_name text not null, property_type text not null default 'commercial',
 year_built integer check(year_built is null or year_built between 1700 and 2200), square_feet numeric check(square_feet is null or square_feet>=0),
 unit_count integer check(unit_count is null or unit_count>=0), status text not null default 'active',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists entities.property_addresses (
 property_id uuid primary key references entities.properties(id) on delete cascade,
 address_id uuid not null references entities.addresses(id)
);
create table if not exists entities.property_organization_relationships (
 id uuid primary key default gen_random_uuid(), property_id uuid not null references entities.properties(id) on delete cascade,
 organization_id uuid not null references entities.organizations(id) on delete cascade, relationship_type text not null,
 effective_from date, effective_to date, confidence numeric(7,4) check(confidence between 0 and 100),
 created_at timestamptz not null default now(), unique(property_id,organization_id,relationship_type,effective_from)
);
create table if not exists entities.workspace_properties (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
 property_id uuid not null references entities.properties(id) on delete cascade, assigned_owner_user_id uuid references platform.user_profiles(id),
 lifecycle_status text not null default 'prospect', priority_tier text, workspace_notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(workspace_id,property_id)
);
create table if not exists entities.people (
 id uuid primary key default gen_random_uuid(), first_name text not null, middle_name text, last_name text not null,
 display_name text generated always as (trim(first_name||' '||coalesce(middle_name||' ','')||last_name)) stored,
 status text not null default 'active', verified_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists entities.person_organization_roles (
 id uuid primary key default gen_random_uuid(), person_id uuid not null references entities.people(id) on delete cascade,
 organization_id uuid not null references entities.organizations(id) on delete cascade, title text, department text, seniority text,
 decision_role text not null default 'unknown', role_start_date date, role_end_date date, is_current boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists entities.contact_points (
 id uuid primary key default gen_random_uuid(), person_id uuid not null references entities.people(id) on delete cascade,
 contact_type text not null, contact_value citext not null, normalized_value citext not null, is_primary boolean not null default false,
 verification_status text not null default 'unverified', verified_at timestamptz, created_at timestamptz not null default now(),
 unique(contact_type,normalized_value)
);
create table if not exists entities.workspace_people (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
 person_id uuid not null references entities.people(id) on delete cascade, persona_id uuid, engagement_status text,
 assigned_owner_user_id uuid references platform.user_profiles(id), workspace_notes text, created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(), unique(workspace_id,person_id)
);
create table if not exists entities.external_identifiers (
 id uuid primary key default gen_random_uuid(), workspace_id uuid references platform.workspaces(id) on delete cascade,
 entity_type text not null, entity_id uuid not null, source_system text not null, external_id text not null,
 identifier_type text not null default 'record_id', is_active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(source_system,external_id,identifier_type,workspace_id)
);
create index if not exists property_org_relationship_org_idx on entities.property_organization_relationships(organization_id);
create index if not exists person_org_role_org_idx on entities.person_organization_roles(organization_id) where is_current;
create index if not exists external_identifiers_lookup_idx on entities.external_identifiers(source_system,external_id,workspace_id);

create table if not exists gtm.activities (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
 activity_type text not null, related_entity_type text not null, related_entity_id uuid not null, summary text not null,
 actor_type text not null default 'user', actor_id uuid, actor_name text, occurred_at timestamptz not null default now(), metadata jsonb not null default '{}'::jsonb
);
create index if not exists activities_entity_idx on gtm.activities(workspace_id,related_entity_type,related_entity_id,occurred_at desc);

create or replace view entities.workspace_organization_directory as
select wo.workspace_id,o.id organization_id,o.canonical_name,o.organization_type,o.industry_name,o.website_domain,o.phone,
 a.city,a.state_region,coalesce(wo.lifecycle_status,'prospect') lifecycle_status,coalesce(wo.priority_tier,'C') priority_tier,
 up.display_name owner_name,0::numeric current_score,0::numeric data_confidence,null::timestamptz last_activity_at,null::text next_action,
 ei.source_system,ei.external_id,
 count(distinct por.property_id) property_count,count(distinct pror.person_id) contact_count,0::numeric opportunity_value,'{}'::text[] tags
from entities.workspace_organizations wo join entities.organizations o on o.id=wo.organization_id
left join platform.user_profiles up on up.id=wo.assigned_owner_user_id
left join entities.organization_addresses oa on oa.organization_id=o.id and oa.is_primary
left join entities.addresses a on a.id=oa.address_id
left join entities.property_organization_relationships por on por.organization_id=o.id
left join entities.person_organization_roles pror on pror.organization_id=o.id and pror.is_current
left join lateral (select source_system,external_id from entities.external_identifiers e where e.workspace_id=wo.workspace_id and e.entity_type='organization' and e.entity_id=o.id and e.is_active order by e.updated_at desc limit 1) ei on true
group by wo.workspace_id,o.id,a.city,a.state_region,wo.lifecycle_status,wo.priority_tier,up.display_name,ei.source_system,ei.external_id;

create or replace view entities.property_directory as
select wp.workspace_id,p.id property_id,r.organization_id,p.canonical_name,p.property_type,p.year_built,p.square_feet,p.unit_count,
 a.address_line_1,a.city,a.state_region,a.postal_code,r.relationship_type,ei.source_system,ei.external_id
from entities.workspace_properties wp join entities.properties p on p.id=wp.property_id
left join entities.property_addresses pa on pa.property_id=p.id left join entities.addresses a on a.id=pa.address_id
left join entities.property_organization_relationships r on r.property_id=p.id
left join lateral (select source_system,external_id from entities.external_identifiers e where e.workspace_id=wp.workspace_id and e.entity_type='property' and e.entity_id=p.id and e.is_active order by e.updated_at desc limit 1) ei on true;

create or replace view entities.contact_directory as
select wp.workspace_id,pr.organization_id,p.id person_id,p.first_name,p.last_name,pr.title,pr.department,pr.decision_role,
 em.contact_value::text email,ph.contact_value::text phone,coalesce(em.verification_status,ph.verification_status,'unverified') verification_status,
 ei.source_system,ei.external_id
from entities.workspace_people wp join entities.people p on p.id=wp.person_id
join entities.person_organization_roles pr on pr.person_id=p.id and pr.is_current
left join lateral (select contact_value,verification_status from entities.contact_points c where c.person_id=p.id and c.contact_type='email' order by c.is_primary desc limit 1) em on true
left join lateral (select contact_value,verification_status from entities.contact_points c where c.person_id=p.id and c.contact_type in ('mobile_phone','office_phone') order by c.is_primary desc limit 1) ph on true
left join lateral (select source_system,external_id from entities.external_identifiers e where e.workspace_id=wp.workspace_id and e.entity_type='person' and e.entity_id=p.id and e.is_active order by e.updated_at desc limit 1) ei on true;

alter table entities.addresses enable row level security; alter table entities.properties enable row level security;
alter table entities.workspace_properties enable row level security; alter table entities.people enable row level security;
alter table entities.workspace_people enable row level security; alter table entities.external_identifiers enable row level security; alter table gtm.activities enable row level security;
create policy workspace_properties_access on entities.workspace_properties using (platform.has_workspace_access(workspace_id));
create policy workspace_people_access on entities.workspace_people using (platform.has_workspace_access(workspace_id));
create policy external_identifiers_access on entities.external_identifiers using (workspace_id is null or platform.has_workspace_access(workspace_id));
create policy activities_access on gtm.activities using (platform.has_workspace_access(workspace_id));

-- ===== supabase/migrations/0011_entity_resolution.sql =====
-- Step 11: entity normalization, duplicate review, reversible merges, and relationship classification.
create table if not exists entities.organization_aliases (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references entities.organizations(id) on delete cascade,
 alias_name text not null,
 normalized_alias text not null,
 source_record_id uuid, -- FIXME: ingestion.source_records table not yet implemented; FK dropped to keep this migration deployable
 is_primary boolean not null default false,
 created_at timestamptz not null default now(),
 unique(organization_id, normalized_alias)
);
create index if not exists organization_aliases_normalized_idx on entities.organization_aliases using gin(normalized_alias gin_trgm_ops);

create table if not exists ingestion.merge_candidates (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references platform.workspaces(id) on delete cascade,
 entity_type text not null check(entity_type in ('organization','property','person')),
 left_entity_id uuid not null,
 right_entity_id uuid not null,
 match_score numeric(7,4) not null check(match_score between 0 and 100),
 match_reasons jsonb not null default '[]'::jsonb,
 recommended_action text not null check(recommended_action in ('auto_link','review','new_record')),
 status text not null default 'pending' check(status in ('pending','merged','kept_separate','related','deferred','dismissed')),
 relationship_type text,
 reviewed_by uuid references platform.user_profiles(id),
 reviewed_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(left_entity_id <> right_entity_id)
);
create unique index if not exists merge_candidates_unique_pair_idx on ingestion.merge_candidates (
 workspace_id, entity_type, least(left_entity_id,right_entity_id), greatest(left_entity_id,right_entity_id)
) where status='pending';
create index if not exists merge_candidates_queue_idx on ingestion.merge_candidates(workspace_id,status,match_score desc);

create table if not exists ingestion.merge_actions (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references platform.workspaces(id) on delete cascade,
 candidate_id uuid references ingestion.merge_candidates(id),
 entity_type text not null,
 surviving_entity_id uuid not null,
 merged_entity_id uuid not null,
 merge_snapshot jsonb not null,
 merge_reason text not null,
 merged_by uuid references platform.user_profiles(id),
 merged_at timestamptz not null default now(),
 reversed_at timestamptz,
 reversed_by uuid references platform.user_profiles(id),
 reversal_reason text,
 check(surviving_entity_id <> merged_entity_id)
);
create index if not exists merge_actions_survivor_idx on ingestion.merge_actions(workspace_id,entity_type,surviving_entity_id);

create table if not exists entities.organization_relationships (
 id uuid primary key default gen_random_uuid(),
 source_organization_id uuid not null references entities.organizations(id) on delete cascade,
 target_organization_id uuid not null references entities.organizations(id) on delete cascade,
 relationship_type text not null check(relationship_type in ('parent','subsidiary','affiliate','owner','manager','franchisor','franchisee','partner','vendor','other')),
 confidence numeric(7,4) check(confidence between 0 and 100),
 effective_from date,
 effective_to date,
 source_record_id uuid, -- FIXME: ingestion.source_records table not yet implemented; FK dropped to keep this migration deployable
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(source_organization_id <> target_organization_id),
 unique(source_organization_id,target_organization_id,relationship_type,effective_from)
);

create or replace function entities.normalize_entity_text(input text)
returns text language sql immutable parallel safe as $$
 select trim(regexp_replace(regexp_replace(lower(unaccent(coalesce(input,''))), '\m(incorporated|inc|llc|ltd|company|co|corporation|corp)\M', '', 'g'), '[^a-z0-9]+', ' ', 'g'));
$$;

create or replace function ingestion.queue_organization_candidates(p_workspace_id uuid, p_min_similarity numeric default 0.55)
returns integer language plpgsql security definer set search_path=public,entities,ingestion,platform as $$
declare inserted_count integer;
begin
 insert into ingestion.merge_candidates(workspace_id,entity_type,left_entity_id,right_entity_id,match_score,match_reasons,recommended_action)
 select p_workspace_id,'organization',a.organization_id,b.organization_id,
   round(greatest(similarity(oa.normalized_name,ob.normalized_name)*92,
     case when oa.website_domain is not null and lower(oa.website_domain)=lower(ob.website_domain) then 98 else 0 end,
     case when regexp_replace(coalesce(oa.phone,''),'\D','','g')<>'' and regexp_replace(oa.phone,'\D','','g')=regexp_replace(ob.phone,'\D','','g') then 96 else 0 end)::numeric,4),
   jsonb_build_array(jsonb_build_object('field','name','score',round(similarity(oa.normalized_name,ob.normalized_name)*92),'detail','Normalized-name similarity')),
   case when oa.website_domain is not null and lower(oa.website_domain)=lower(ob.website_domain) then 'auto_link'
        when regexp_replace(coalesce(oa.phone,''),'\D','','g')<>'' and regexp_replace(oa.phone,'\D','','g')=regexp_replace(ob.phone,'\D','','g') then 'auto_link'
        when similarity(oa.normalized_name,ob.normalized_name)>=0.87 then 'review' else 'new_record' end
 from entities.workspace_organizations a
 join entities.workspace_organizations b on b.workspace_id=a.workspace_id and a.organization_id<b.organization_id
 join entities.organizations oa on oa.id=a.organization_id
 join entities.organizations ob on ob.id=b.organization_id
 where a.workspace_id=p_workspace_id
 and (similarity(oa.normalized_name,ob.normalized_name)>=p_min_similarity
      or (oa.website_domain is not null and lower(oa.website_domain)=lower(ob.website_domain))
      or (regexp_replace(coalesce(oa.phone,''),'\D','','g')<>'' and regexp_replace(oa.phone,'\D','','g')=regexp_replace(ob.phone,'\D','','g')))
 on conflict do nothing;
 get diagnostics inserted_count = row_count;
 return inserted_count;
end; $$;

create or replace view ingestion.merge_candidate_directory as
select mc.id,mc.workspace_id,mc.entity_type,mc.match_score,mc.match_reasons,mc.recommended_action,mc.status,mc.relationship_type,
 jsonb_build_object('id',l.id,'name',l.canonical_name,'website',l.website_domain,'phone',l.phone,'source','Global entity') left_record,
 jsonb_build_object('id',r.id,'name',r.canonical_name,'website',r.website_domain,'phone',r.phone,'source','Global entity') right_record,
 mc.created_at,mc.reviewed_at
from ingestion.merge_candidates mc
join entities.organizations l on mc.entity_type='organization' and l.id=mc.left_entity_id
join entities.organizations r on mc.entity_type='organization' and r.id=mc.right_entity_id;

alter table entities.organization_aliases enable row level security;
alter table ingestion.merge_candidates enable row level security;
alter table ingestion.merge_actions enable row level security;
alter table entities.organization_relationships enable row level security;
create policy organization_aliases_workspace_read on entities.organization_aliases for select using (
 exists(select 1 from entities.workspace_organizations wo where wo.organization_id=organization_aliases.organization_id and platform.has_workspace_access(wo.workspace_id))
);
create policy merge_candidates_workspace_access on ingestion.merge_candidates for all using (platform.has_workspace_access(workspace_id)) with check (platform.has_workspace_access(workspace_id));
create policy merge_actions_workspace_access on ingestion.merge_actions for select using (platform.has_workspace_access(workspace_id));
create policy organization_relationships_workspace_read on entities.organization_relationships for select using (
 exists(select 1 from entities.workspace_organizations wo where wo.organization_id in (organization_relationships.source_organization_id,organization_relationships.target_organization_id) and platform.has_workspace_access(wo.workspace_id))
);

-- ===== supabase/migrations/0012_enrichment_research.sql =====
create schema if not exists intelligence;
create schema if not exists agents;

create table if not exists intelligence.enrichment_providers (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id) on delete cascade,
  name text not null,
  category text not null,
  status text not null default 'test' check (status in ('active','inactive','test')),
  priority integer not null default 100,
  field_coverage jsonb not null default '[]'::jsonb,
  cost_policy jsonb not null default '{}'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  credential_reference text,
  last_success_at timestamptz,
  last_failure_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,name)
);

create table if not exists intelligence.research_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  research_type text not null,
  priority text not null default 'normal' check (priority in ('low','normal','high')),
  status text not null default 'queued' check (status in ('queued','running','review_required','complete','failed','cancelled')),
  provider_id uuid references intelligence.enrichment_providers(id),
  requested_by uuid references platform.user_profiles(id),
  confidence numeric(7,4),
  estimated_cost numeric(18,6),
  actual_cost numeric(18,6),
  started_at timestamptz,
  completed_at timestamptz,
  error_details jsonb,
  created_at timestamptz not null default now()
);

create table if not exists intelligence.evidence_items (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  research_job_id uuid references intelligence.research_jobs(id) on delete cascade,
  source_type text not null,
  source_reference text not null,
  title text,
  excerpt text,
  content_hash text,
  captured_at timestamptz not null default now(),
  reliability_rating numeric(7,4),
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists intelligence.research_findings (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  research_job_id uuid not null references intelligence.research_jobs(id) on delete cascade,
  finding_type text not null,
  field_name text,
  current_value jsonb,
  proposed_value jsonb not null,
  summary text not null,
  confidence numeric(7,4) not null,
  verification_status text not null default 'unverified' check (verification_status in ('unverified','supported','verified','conflicting')),
  review_status text not null default 'pending' check (review_status in ('pending','accepted','rejected','edited')),
  reviewed_by uuid references platform.user_profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists intelligence.finding_evidence (
  finding_id uuid not null references intelligence.research_findings(id) on delete cascade,
  evidence_id uuid not null references intelligence.evidence_items(id) on delete cascade,
  primary key(finding_id,evidence_id)
);

create table if not exists intelligence.signals (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  signal_type text not null,
  summary text not null,
  strength numeric(7,4) not null,
  confidence numeric(7,4) not null,
  detected_at timestamptz not null default now(),
  expires_at timestamptz,
  status text not null default 'active' check (status in ('active','actioned','dismissed','expired')),
  source_type text not null,
  source_reference text,
  recommended_action text,
  research_job_id uuid references intelligence.research_jobs(id),
  created_at timestamptz not null default now()
);

create table if not exists intelligence.account_briefs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  entity_type text not null default 'organization',
  entity_id uuid not null,
  version_number integer not null,
  summary text not null,
  opportunities jsonb not null default '[]'::jsonb,
  risks jsonb not null default '[]'::jsonb,
  recommended_actions jsonb not null default '[]'::jsonb,
  confidence numeric(7,4) not null,
  review_status text not null default 'pending' check (review_status in ('pending','accepted','rejected','edited')),
  generated_by_job_id uuid references intelligence.research_jobs(id),
  generated_at timestamptz not null default now(),
  reviewed_by uuid references platform.user_profiles(id),
  reviewed_at timestamptz,
  unique(workspace_id,entity_type,entity_id,version_number)
);

create index if not exists idx_research_jobs_workspace_status on intelligence.research_jobs(workspace_id,status,created_at desc);
create index if not exists idx_findings_review on intelligence.research_findings(workspace_id,review_status,created_at desc);
create index if not exists idx_signals_entity on intelligence.signals(workspace_id,entity_type,entity_id,status);
create index if not exists idx_briefs_entity on intelligence.account_briefs(workspace_id,entity_type,entity_id,version_number desc);

alter table intelligence.enrichment_providers enable row level security;
alter table intelligence.research_jobs enable row level security;
alter table intelligence.evidence_items enable row level security;
alter table intelligence.research_findings enable row level security;
alter table intelligence.signals enable row level security;
alter table intelligence.account_briefs enable row level security;

create policy enrichment_provider_workspace_access on intelligence.enrichment_providers for all using (workspace_id is null or workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy research_job_workspace_access on intelligence.research_jobs for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy evidence_workspace_access on intelligence.evidence_items for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy findings_workspace_access on intelligence.research_findings for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy signals_workspace_access on intelligence.signals for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy briefs_workspace_access on intelligence.account_briefs for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));

-- ===== supabase/migrations/0013_scoring_engine.sql =====
create schema if not exists scoring;

create table if not exists scoring.models (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  description text,
  status text not null default 'draft' check (status in ('draft','active','retired')),
  created_by uuid references platform.user_profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists scoring.model_versions (
  id uuid primary key default gen_random_uuid(), model_id uuid not null references scoring.models(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  version_number integer not null, status text not null default 'draft' check(status in ('draft','approved','active','retired')),
  priority_thresholds jsonb not null default '{"a":85,"b":70,"c":0}'::jsonb,
  change_summary text, approved_by uuid references platform.user_profiles(id), approved_at timestamptz,
  created_at timestamptz not null default now(), unique(model_id,version_number)
);
create table if not exists scoring.factors (
  id uuid primary key default gen_random_uuid(), model_version_id uuid not null references scoring.model_versions(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, description text, factor_key text not null, factor_kind text not null check(factor_kind in ('calculated','ai_assisted','manual')),
  weight numeric(7,4) not null default 0 check(weight>=0 and weight<=100), enabled boolean not null default true,
  hard_exclusion boolean not null default false, exclusion_reason text, display_order integer not null default 0,
  configuration jsonb not null default '{}'::jsonb, unique(model_version_id,factor_key)
);
create table if not exists scoring.rules (
  id uuid primary key default gen_random_uuid(), factor_id uuid not null references scoring.factors(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  rule_type text not null, operator text not null, comparison_value jsonb, score_value numeric(7,4),
  explanation_template text, evidence_requirement jsonb not null default '{}'::jsonb, display_order integer not null default 0
);
create table if not exists scoring.runs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  model_version_id uuid not null references scoring.model_versions(id), run_type text not null check(run_type in ('production','simulation','backfill')),
  status text not null default 'queued' check(status in ('queued','running','complete','failed','cancelled')),
  requested_by uuid references platform.user_profiles(id), entity_count integer not null default 0, started_at timestamptz, completed_at timestamptz,
  input_snapshot jsonb not null default '{}'::jsonb, error_details jsonb, created_at timestamptz not null default now()
);
create table if not exists scoring.account_scores (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  run_id uuid not null references scoring.runs(id) on delete cascade, model_version_id uuid not null references scoring.model_versions(id),
  entity_type text not null default 'organization', entity_id uuid not null, total_score numeric(7,4) not null,
  priority_tier text not null check(priority_tier in ('A','B','C','Excluded')), confidence numeric(7,4), excluded boolean not null default false,
  exclusion_reason text, input_hash text, scored_at timestamptz not null default now(),
  unique(run_id,entity_type,entity_id)
);
create table if not exists scoring.score_components (
  id uuid primary key default gen_random_uuid(), account_score_id uuid not null references scoring.account_scores(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade, factor_id uuid not null references scoring.factors(id),
  raw_score numeric(7,4) not null, weighted_score numeric(7,4) not null, confidence numeric(7,4), explanation text not null,
  evidence_references jsonb not null default '[]'::jsonb, input_snapshot jsonb not null default '{}'::jsonb
);
create index if not exists idx_scoring_models_workspace on scoring.models(workspace_id,status);
create index if not exists idx_account_scores_entity on scoring.account_scores(workspace_id,entity_type,entity_id,scored_at desc);
create index if not exists idx_scoring_runs_workspace on scoring.runs(workspace_id,created_at desc);

alter table scoring.models enable row level security;alter table scoring.model_versions enable row level security;alter table scoring.factors enable row level security;alter table scoring.rules enable row level security;alter table scoring.runs enable row level security;alter table scoring.account_scores enable row level security;alter table scoring.score_components enable row level security;
create policy scoring_models_workspace_access on scoring.models for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_versions_workspace_access on scoring.model_versions for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_factors_workspace_access on scoring.factors for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_rules_workspace_access on scoring.rules for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_runs_workspace_access on scoring.runs for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy account_scores_workspace_access on scoring.account_scores for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy score_components_workspace_access on scoring.score_components for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));

-- ===== supabase/migrations/0014_offers_playbooks_campaigns.sql =====
-- Step 14: governed offers, playbooks, campaign execution, approvals, and performance
create schema if not exists gtm;

create type gtm.lifecycle_status as enum ('draft','review','approved','active','retired');
create type gtm.channel_type as enum ('email','phone','sms','linkedin','direct_mail','site_visit','task');
create type gtm.campaign_status as enum ('draft','active','paused','completed');
create type gtm.member_status as enum ('queued','active','paused','completed','removed');

create table gtm.offers (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, description text, current_version_id uuid, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create table gtm.offer_versions (
  id uuid primary key default gen_random_uuid(), offer_id uuid not null references gtm.offers(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id), version_no integer not null,
  status gtm.lifecycle_status not null default 'draft', target_icp text, value_proposition text not null,
  pricing jsonb not null default '{}'::jsonb, eligibility_rules jsonb not null default '[]'::jsonb,
  objection_handling jsonb not null default '[]'::jsonb, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), approved_at timestamptz, unique(offer_id,version_no)
);
create table gtm.proof_points (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  offer_version_id uuid not null references gtm.offer_versions(id) on delete cascade, statement text not null,
  evidence_id uuid, status text not null default 'approved', created_at timestamptz not null default now()
);
alter table gtm.offers add constraint offers_current_version_fk foreign key(current_version_id) references gtm.offer_versions(id);

create table gtm.playbooks (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, description text, current_version_id uuid, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create table gtm.playbook_versions (
  id uuid primary key default gen_random_uuid(), playbook_id uuid not null references gtm.playbooks(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id), offer_version_id uuid not null references gtm.offer_versions(id),
  version_no integer not null, status gtm.lifecycle_status not null default 'draft', target_tier text not null default 'Any',
  trigger_definition jsonb not null default '{}'::jsonb, completion_definition jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id), created_at timestamptz not null default now(), approved_at timestamptz,
  unique(playbook_id,version_no)
);
create table gtm.playbook_steps (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  playbook_version_id uuid not null references gtm.playbook_versions(id) on delete cascade,
  step_order integer not null check(step_order > 0), name text not null, channel gtm.channel_type not null,
  delay_days integer not null default 0 check(delay_days >= 0), owner_role text not null,
  template_body text, condition_definition jsonb not null default '{}'::jsonb, completion_criteria text not null,
  created_at timestamptz not null default now(), unique(playbook_version_id,step_order)
);
alter table gtm.playbooks add constraint playbooks_current_version_fk foreign key(current_version_id) references gtm.playbook_versions(id);

create table gtm.campaigns (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, description text, status gtm.campaign_status not null default 'draft',
  playbook_version_id uuid not null references gtm.playbook_versions(id), audience_definition jsonb not null,
  started_at timestamptz, completed_at timestamptz, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table gtm.campaign_members (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  campaign_id uuid not null references gtm.campaigns(id) on delete cascade,
  organization_id uuid not null references entities.organizations(id), status gtm.member_status not null default 'queued',
  enrollment_score numeric(6,2), enrollment_tier text, enrollment_snapshot jsonb not null default '{}'::jsonb,
  current_step_order integer not null default 0, enrolled_at timestamptz not null default now(), completed_at timestamptz,
  unique(campaign_id,organization_id)
);
create table gtm.sequence_executions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  campaign_member_id uuid not null references gtm.campaign_members(id) on delete cascade,
  playbook_step_id uuid not null references gtm.playbook_steps(id), status text not null default 'pending',
  assigned_to uuid references auth.users(id), due_at timestamptz, completed_at timestamptz,
  outcome jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create table gtm.approval_records (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  object_type text not null check(object_type in ('offer_version','playbook_version','campaign')),
  object_id uuid not null, decision text not null check(decision in ('submitted','approved','rejected','returned')),
  reviewer_id uuid references auth.users(id), notes text, created_at timestamptz not null default now()
);
create table gtm.performance_events (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  campaign_id uuid references gtm.campaigns(id), campaign_member_id uuid references gtm.campaign_members(id),
  playbook_version_id uuid references gtm.playbook_versions(id), event_type text not null,
  opportunity_id uuid, revenue_amount numeric(14,2), occurred_at timestamptz not null default now(), metadata jsonb not null default '{}'::jsonb
);

create index offers_workspace_idx on gtm.offers(workspace_id);
create index playbooks_workspace_idx on gtm.playbooks(workspace_id);
create index campaigns_workspace_status_idx on gtm.campaigns(workspace_id,status);
create index campaign_members_campaign_status_idx on gtm.campaign_members(campaign_id,status);
create index performance_events_playbook_idx on gtm.performance_events(workspace_id,playbook_version_id,occurred_at);

alter table gtm.offers enable row level security; alter table gtm.offer_versions enable row level security;
alter table gtm.proof_points enable row level security; alter table gtm.playbooks enable row level security;
alter table gtm.playbook_versions enable row level security; alter table gtm.playbook_steps enable row level security;
alter table gtm.campaigns enable row level security; alter table gtm.campaign_members enable row level security;
alter table gtm.sequence_executions enable row level security; alter table gtm.approval_records enable row level security;
alter table gtm.performance_events enable row level security;

do $$ declare t text; begin
  foreach t in array array['offers','offer_versions','proof_points','playbooks','playbook_versions','playbook_steps','campaigns','campaign_members','sequence_executions','approval_records','performance_events'] loop
    execute format('create policy %I on gtm.%I for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id))', t||'_workspace_access', t);
  end loop;
end $$;

-- ===== supabase/migrations/0015_operational_execution.sql =====
-- Step 15: operational execution, approvals and opportunity control
create schema if not exists execution;
create table if not exists execution.work_items (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
 title text not null, description text, status text not null check(status in ('queued','ready','in_progress','blocked','completed','cancelled')),
 priority text not null check(priority in ('low','medium','high','critical')), owner_user_id uuid, owner_role text,
 account_id uuid, opportunity_id uuid, campaign_id uuid, playbook_step_id uuid, due_at timestamptz,
 blocked_reason text, completed_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists execution.approval_requests (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
 object_type text not null, object_id uuid, object_name text not null, requested_by uuid, reviewer_role text not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected','changes_requested')),
 risk text not null default 'standard' check(risk in ('standard','elevated','high')), rationale text,
 decided_by uuid, decided_at timestamptz, decision_notes text, before_snapshot jsonb, after_snapshot jsonb,
 created_at timestamptz not null default now());
-- Genuinely missing (not a naming issue): the four ALTER TABLE statements below
-- assume gtm.opportunities already exists, but no migration ever created it.
-- Shape matches the app's Opportunity TypeScript type (apps/web/lib/execution-types.ts)
-- and the mock data in apps/web/lib/data/execution.ts.
create table if not exists gtm.opportunities (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
 account_id uuid references entities.organizations(id), name text not null, offer_id uuid references gtm.offers(id),
 stage text not null default 'identified' check(stage in ('identified','qualified','discovery','proposal','negotiation','won','lost')),
 value numeric not null default 0, owner_user_id uuid references platform.user_profiles(id), lost_reason text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table gtm.opportunities add column if not exists probability numeric(5,2) default 0;
alter table gtm.opportunities add column if not exists next_action text;
alter table gtm.opportunities add column if not exists next_action_due timestamptz;
alter table gtm.opportunities add column if not exists source_type text;
alter table execution.work_items enable row level security;
alter table execution.approval_requests enable row level security;
alter table gtm.opportunities enable row level security;
create policy work_items_workspace_access on execution.work_items using (platform.is_workspace_member(workspace_id));
create policy approval_requests_workspace_access on execution.approval_requests using (platform.is_workspace_member(workspace_id));
create policy opportunities_workspace_access on gtm.opportunities using (platform.is_workspace_member(workspace_id)) with check (platform.is_workspace_member(workspace_id));
create index if not exists work_items_workspace_status_idx on execution.work_items(workspace_id,status,due_at);
create index if not exists approvals_workspace_status_idx on execution.approval_requests(workspace_id,status,created_at);
create index if not exists opportunities_workspace_stage_idx on gtm.opportunities(workspace_id,stage);

-- ===== supabase/migrations/0016_management_analytics.sql =====
-- Step 16: KPI governance, calculation runs, management alerts, attribution and operating reviews.
create schema if not exists analytics;

create table if not exists analytics.kpi_definitions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  key text not null,
  name text not null,
  description text,
  category text not null check (category in ('implementation','data','intelligence','execution','pipeline','revenue')),
  format text not null check (format in ('number','currency','percent','days')),
  target numeric not null,
  warning_threshold numeric,
  owner_role text not null,
  cadence text not null check (cadence in ('daily','weekly','monthly','quarterly')),
  calculation_version integer not null default 1,
  calculation_definition jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,key,calculation_version)
);

create table if not exists analytics.calculation_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  period_start timestamptz not null,
  period_end timestamptz not null,
  status text not null check (status in ('queued','running','completed','failed','superseded')),
  source_snapshot jsonb not null default '{}'::jsonb,
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now()
);

create table if not exists analytics.kpi_results (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  kpi_definition_id uuid not null references analytics.kpi_definitions(id),
  calculation_run_id uuid not null references analytics.calculation_runs(id),
  period_start timestamptz not null,
  period_end timestamptz not null,
  value numeric not null,
  prior_value numeric,
  target numeric not null,
  source_status text not null check (source_status in ('partial','complete')),
  evidence jsonb not null default '[]'::jsonb,
  calculated_at timestamptz not null default now(),
  unique(kpi_definition_id,calculation_run_id)
);

create table if not exists analytics.management_alerts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  kpi_definition_id uuid references analytics.kpi_definitions(id),
  title text not null,
  description text not null,
  severity text not null check (severity in ('info','warning','critical')),
  category text not null,
  status text not null default 'open' check (status in ('open','acknowledged','resolved')),
  owner_role text not null,
  recommended_action text not null,
  detected_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  acknowledged_by uuid references platform.user_profiles(id),
  resolved_at timestamptz,
  resolution_note text
);

create table if not exists analytics.attribution_records (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  opportunity_id uuid references gtm.opportunities(id),
  campaign_id uuid references gtm.campaigns(id),
  playbook_id uuid references gtm.playbooks(id),
  offer_id uuid references gtm.offers(id),
  revenue numeric not null,
  weight numeric not null check (weight between 0 and 1),
  attributed_revenue numeric generated always as (revenue * weight) stored,
  model text not null check (model in ('first_touch','last_touch','linear','manual')),
  evidence jsonb not null default '[]'::jsonb,
  occurred_at timestamptz not null
);

create table if not exists analytics.operating_reviews (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  title text not null,
  period_start date not null,
  period_end date not null,
  status text not null default 'draft' check (status in ('draft','review','approved','published','superseded')),
  calculation_run_id uuid references analytics.calculation_runs(id),
  snapshot jsonb not null default '{}'::jsonb,
  prepared_by uuid references platform.user_profiles(id),
  approved_by uuid references platform.user_profiles(id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique(workspace_id,period_start,period_end,status)
);

create index if not exists idx_kpi_results_workspace_period on analytics.kpi_results(workspace_id,period_end desc);
create index if not exists idx_management_alerts_workspace_status on analytics.management_alerts(workspace_id,status,severity);
create index if not exists idx_attribution_workspace_date on analytics.attribution_records(workspace_id,occurred_at desc);

alter table analytics.kpi_definitions enable row level security;
alter table analytics.calculation_runs enable row level security;
alter table analytics.kpi_results enable row level security;
alter table analytics.management_alerts enable row level security;
alter table analytics.attribution_records enable row level security;
alter table analytics.operating_reviews enable row level security;

create policy kpi_definitions_workspace_access on analytics.kpi_definitions for select using (platform.user_has_workspace_access(workspace_id));
create policy calculation_runs_workspace_access on analytics.calculation_runs for select using (platform.user_has_workspace_access(workspace_id));
create policy kpi_results_workspace_access on analytics.kpi_results for select using (platform.user_has_workspace_access(workspace_id));
create policy management_alerts_workspace_access on analytics.management_alerts for select using (platform.user_has_workspace_access(workspace_id));
create policy attribution_records_workspace_access on analytics.attribution_records for select using (platform.user_has_workspace_access(workspace_id));
create policy operating_reviews_workspace_access on analytics.operating_reviews for select using (platform.user_has_workspace_access(workspace_id));

-- ===== supabase/migrations/0017_agent_orchestration.sql =====
create schema if not exists agents;

create table if not exists agents.providers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  provider_type text not null,
  status text not null default 'active' check (status in ('active','test','disabled')),
  secret_reference text,
  created_at timestamptz not null default now()
);

create table if not exists agents.models (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references agents.providers(id),
  model_key text not null,
  display_name text not null,
  input_cost_per_million numeric(12,4),
  output_cost_per_million numeric(12,4),
  context_window integer,
  active boolean not null default true,
  unique(provider_id,model_key)
);

create table if not exists agents.agent_definitions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  purpose text not null,
  owner_role text not null,
  status text not null default 'draft' check(status in ('draft','active','paused','retired')),
  risk_level text not null default 'medium' check(risk_level in ('low','medium','high')),
  approval_policy text not null default 'required' check(approval_policy in ('none','sampled','required')),
  monthly_budget numeric(12,2) not null default 0,
  active_version_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists agents.agent_versions (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references agents.agent_definitions(id) on delete cascade,
  version integer not null,
  model_id uuid references agents.models(id),
  system_prompt text not null,
  input_schema jsonb not null default '{}'::jsonb,
  output_schema jsonb not null default '{}'::jsonb,
  tool_policy jsonb not null default '{}'::jsonb,
  temperature numeric(4,3) not null default 0.2,
  max_tokens integer not null default 4000,
  status text not null default 'draft' check(status in ('draft','review','approved','retired')),
  created_by uuid references platform.user_profiles(id),
  created_at timestamptz not null default now(),
  unique(agent_id,version)
);

alter table agents.agent_definitions drop constraint if exists agent_definitions_active_version_id_fkey;
alter table agents.agent_definitions add constraint agent_definitions_active_version_id_fkey foreign key(active_version_id) references agents.agent_versions(id);

create table if not exists agents.runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid not null references agents.agent_definitions(id),
  agent_version_id uuid not null references agents.agent_versions(id),
  status text not null check(status in ('queued','running','succeeded','failed','needs_review','cancelled')),
  subject_type text,
  subject_id uuid,
  input_snapshot jsonb not null default '{}'::jsonb,
  output_snapshot jsonb,
  source_references jsonb not null default '[]'::jsonb,
  confidence numeric(5,2),
  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  cost numeric(12,6) not null default 0,
  latency_ms integer,
  error_code text,
  error_message text,
  requires_review boolean not null default false,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists agents.evaluations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid not null references agents.agent_definitions(id),
  run_id uuid references agents.runs(id),
  evaluation_type text not null default 'human',
  groundedness numeric(5,2) not null,
  completeness numeric(5,2) not null,
  policy_compliance numeric(5,2) not null,
  composite_score numeric(5,2) not null,
  reviewer_id uuid references platform.user_profiles(id),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists agents.budget_events (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid references agents.agent_definitions(id),
  run_id uuid references agents.runs(id),
  amount numeric(12,6) not null,
  event_type text not null check(event_type in ('reservation','actual','release','adjustment')),
  occurred_at timestamptz not null default now()
);

create index if not exists idx_agent_runs_workspace_created on agents.runs(workspace_id,created_at desc);
create index if not exists idx_agent_runs_agent_status on agents.runs(agent_id,status);
create index if not exists idx_agent_evaluations_agent on agents.evaluations(agent_id,created_at desc);

alter table agents.agent_definitions enable row level security;
alter table agents.runs enable row level security;
alter table agents.evaluations enable row level security;
alter table agents.budget_events enable row level security;

create policy agent_definitions_workspace_access on agents.agent_definitions using (platform.user_has_workspace_access(workspace_id));
create policy agent_runs_workspace_access on agents.runs using (platform.user_has_workspace_access(workspace_id));
create policy agent_evaluations_workspace_access on agents.evaluations using (platform.user_has_workspace_access(workspace_id));
create policy agent_budget_workspace_access on agents.budget_events using (platform.user_has_workspace_access(workspace_id));

-- ===== supabase/migrations/0018_integrations_sync.sql =====
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

-- ===== supabase/migrations/0019_governance_controls.sql =====
create schema if not exists governance;

create table if not exists governance.audit_events (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), occurred_at timestamptz not null default now(), actor_id text, actor_type text not null check(actor_type in ('user','agent','integration','system')), action text not null, resource_type text not null, resource_id text not null, severity text not null default 'info' check(severity in ('info','warning','critical')), summary text not null, correlation_id text not null, ip_address inet, metadata jsonb not null default '{}'::jsonb
);
create index if not exists audit_events_workspace_time_idx on governance.audit_events(workspace_id,occurred_at desc);
create unique index if not exists audit_events_workspace_correlation_action_idx on governance.audit_events(workspace_id,correlation_id,action,resource_id);

create table if not exists governance.access_reviews (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), name text not null, scope jsonb not null default '{}'::jsonb, owner_user_id uuid, due_at timestamptz not null, status text not null check(status in ('planned','in_progress','completed','overdue')), certified_by uuid, completed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists governance.access_review_items (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), review_id uuid not null references governance.access_reviews(id) on delete cascade, principal_type text not null, principal_id text not null, role_id uuid, decision text check(decision in ('retain','remove','modify','accept_exception')), risk text not null default 'low' check(risk in ('low','medium','high')), reason text, decided_by uuid, decided_at timestamptz
);

create table if not exists governance.change_requests (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), title text not null, category text not null check(category in ('configuration','schema','integration','agent','security')), status text not null check(status in ('draft','review','approved','scheduled','deployed','rejected','rolled_back')), risk text not null check(risk in ('low','medium','high')), requested_by uuid, owner_user_id uuid, requested_at timestamptz not null default now(), scheduled_at timestamptz, approvals_required integer not null default 1 check(approvals_required>0), rollback_plan text, implementation_plan text, validation_plan text, before_snapshot jsonb, after_snapshot jsonb
);
create table if not exists governance.change_approvals (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), change_request_id uuid not null references governance.change_requests(id) on delete cascade, reviewer_id uuid not null, decision text not null check(decision in ('approved','rejected','changes_requested')), reason text, decided_at timestamptz not null default now(), unique(change_request_id,reviewer_id)
);

create table if not exists governance.retention_policies (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), data_class text not null, record_type text not null, retention_days integer not null check(retention_days>=0), disposition_action text not null check(disposition_action in ('retain','archive','anonymize','delete')), legal_hold_supported boolean not null default true, owner_role text not null, active boolean not null default true, policy_version integer not null default 1, approved_at timestamptz, unique(workspace_id,record_type,policy_version)
);
create table if not exists governance.legal_holds (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), name text not null, scope jsonb not null, reason text not null, placed_by uuid, placed_at timestamptz not null default now(), released_by uuid, released_at timestamptz
);
create table if not exists governance.disposition_runs (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), policy_id uuid not null references governance.retention_policies(id), status text not null check(status in ('planned','running','completed','failed','cancelled')), started_at timestamptz, completed_at timestamptz, records_evaluated integer not null default 0, records_disposed integer not null default 0, records_held integer not null default 0, evidence jsonb not null default '{}'::jsonb
);

create table if not exists governance.release_gates (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), release_name text not null, gate_name text not null, category text not null, status text not null check(status in ('pass','warning','fail')), blocking boolean not null default true, owner_role text not null, evidence text, evaluated_at timestamptz not null default now(), unique(workspace_id,release_name,gate_name)
);

alter table governance.audit_events enable row level security;
alter table governance.access_reviews enable row level security;
alter table governance.access_review_items enable row level security;
alter table governance.change_requests enable row level security;
alter table governance.change_approvals enable row level security;
alter table governance.retention_policies enable row level security;
alter table governance.legal_holds enable row level security;
alter table governance.disposition_runs enable row level security;
alter table governance.release_gates enable row level security;

do $$ declare t text; begin
 foreach t in array array['audit_events','access_reviews','access_review_items','change_requests','change_approvals','retention_policies','legal_holds','disposition_runs','release_gates'] loop
  execute format('drop policy if exists workspace_member_select on governance.%I',t);
  execute format('create policy workspace_member_select on governance.%I for select using (platform.is_workspace_member(workspace_id))',t);
 end loop;
end $$;

create or replace function governance.prevent_audit_mutation() returns trigger language plpgsql as $$ begin raise exception 'audit events are immutable'; end $$;
drop trigger if exists audit_events_immutable on governance.audit_events;
create trigger audit_events_immutable before update or delete on governance.audit_events for each row execute function governance.prevent_audit_mutation();

-- ===== supabase/migrations/0020_production_hardening.sql =====
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

-- ===== supabase/migrations/0021_controlled_pilot.sql =====
create schema if not exists pilot;
create table if not exists pilot.pilots(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),name text not null,status text not null check(status in('planned','preparing','active','paused','completed','failed')),target_go_live date,go_live_approved_at timestamptz,created_at timestamptz not null default now());
create table if not exists pilot.readiness_gates(id uuid primary key default gen_random_uuid(),pilot_id uuid not null references pilot.pilots(id) on delete cascade,name text not null,status text not null check(status in('pass','warning','fail')),blocking boolean not null default true,owner text,evidence jsonb not null default '{}'::jsonb);
create table if not exists pilot.uat_scenarios(id uuid primary key default gen_random_uuid(),pilot_id uuid not null references pilot.pilots(id) on delete cascade,name text not null,status text not null check(status in('not_started','in_progress','passed','failed','blocked')),executed_count integer not null default 0,passed_count integer not null default 0,failed_count integer not null default 0,blocking_defects integer not null default 0,evidence jsonb not null default '{}'::jsonb);
create table if not exists pilot.defects(id uuid primary key default gen_random_uuid(),pilot_id uuid not null references pilot.pilots(id) on delete cascade,title text not null,severity text not null check(severity in('critical','high','medium','low')),status text not null check(status in('open','triaged','in_progress','resolved','accepted')),workaround text,created_at timestamptz not null default now());
create table if not exists pilot.cutover_tasks(id uuid primary key default gen_random_uuid(),pilot_id uuid not null references pilot.pilots(id) on delete cascade,sequence integer not null,name text not null,status text not null check(status in('not_started','ready','running','validated','rolled_back')),blocking boolean not null default true,validation_procedure text,rollback_procedure text,unique(pilot_id,sequence));
alter table pilot.pilots enable row level security;alter table pilot.readiness_gates enable row level security;alter table pilot.uat_scenarios enable row level security;alter table pilot.defects enable row level security;alter table pilot.cutover_tasks enable row level security;
create policy pilots_workspace_access on pilot.pilots using(platform.user_has_workspace_access(workspace_id));
create policy pilot_gates_access on pilot.readiness_gates using(exists(select 1 from pilot.pilots p where p.id=pilot_id and platform.user_has_workspace_access(p.workspace_id)));
create policy pilot_uat_access on pilot.uat_scenarios using(exists(select 1 from pilot.pilots p where p.id=pilot_id and platform.user_has_workspace_access(p.workspace_id)));
create policy pilot_defects_access on pilot.defects using(exists(select 1 from pilot.pilots p where p.id=pilot_id and platform.user_has_workspace_access(p.workspace_id)));
create policy pilot_cutover_access on pilot.cutover_tasks using(exists(select 1 from pilot.pilots p where p.id=pilot_id and platform.user_has_workspace_access(p.workspace_id)));

-- ===== supabase/migrations/0021_production_activation.sql =====
create schema if not exists activation;
create table if not exists activation.worker_queues (
  id uuid primary key default gen_random_uuid(), workspace_id uuid references platform.workspaces(id) on delete cascade,
  name text not null, status text not null check(status in ('healthy','degraded','stopped')) default 'stopped',
  max_attempts integer not null default 5 check(max_attempts between 1 and 20), dead_letter_enabled boolean not null default true,
  concurrency integer not null default 1 check(concurrency > 0), oldest_job_at timestamptz, last_heartbeat_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(workspace_id,name)
);
create table if not exists activation.worker_jobs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  queue_id uuid not null references activation.worker_queues(id) on delete cascade, job_type text not null,
  status text not null check(status in ('queued','running','succeeded','retrying','dead_lettered','cancelled')) default 'queued',
  idempotency_key text not null, payload jsonb not null default '{}'::jsonb, attempts integer not null default 0,
  available_at timestamptz not null default now(), started_at timestamptz, completed_at timestamptz,
  error_code text, error_message text, correlation_id text, created_at timestamptz not null default now(),
  unique(workspace_id,idempotency_key)
);
create table if not exists activation.dead_letter_items (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  worker_job_id uuid not null unique references activation.worker_jobs(id) on delete cascade,
  replay_safe boolean not null default false, disposition text check(disposition in ('pending','replayed','discarded','resolved')) default 'pending',
  reviewed_by uuid references auth.users(id), reviewed_at timestamptz, review_note text, snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists activation.consent_records (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  subject text not null, channel text not null check(channel in ('email','sms','phone','linkedin','direct_mail')),
  state text not null check(state in ('granted','denied','unknown','expired')), source text not null,
  evidence jsonb not null default '{}'::jsonb, verified_at timestamptz, expires_at timestamptz, revoked_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists activation.suppressions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  subject text not null, channel text not null check(channel in ('email','sms','phone','linkedin','direct_mail','all')),
  reason text not null, active boolean not null default true, source text, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), lifted_at timestamptz
);
create table if not exists activation.activation_events (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  prior_mode text check(prior_mode in ('inactive','shadow','limited','active','paused')),
  new_mode text not null check(new_mode in ('inactive','shadow','limited','active','paused')),
  reason text not null, readiness_snapshot jsonb not null default '{}'::jsonb, approved_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists worker_jobs_queue_status_idx on activation.worker_jobs(queue_id,status,available_at);
create index if not exists consent_lookup_idx on activation.consent_records(workspace_id,subject,channel,state);
create index if not exists suppression_lookup_idx on activation.suppressions(workspace_id,subject,channel) where active;
alter table activation.worker_queues enable row level security;
alter table activation.worker_jobs enable row level security;
alter table activation.dead_letter_items enable row level security;
alter table activation.consent_records enable row level security;
alter table activation.suppressions enable row level security;
alter table activation.activation_events enable row level security;
create policy activation_queue_access on activation.worker_queues for all using (workspace_id is null or platform.user_has_workspace_access(workspace_id));
create policy activation_job_access on activation.worker_jobs for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_dlq_access on activation.dead_letter_items for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_consent_access on activation.consent_records for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_suppression_access on activation.suppressions for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_event_access on activation.activation_events for select using (platform.user_has_workspace_access(workspace_id));

-- ===== supabase/migrations/0022_rollout_stabilization.sql =====
create schema if not exists rollout;
create table if not exists rollout.cohorts(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),name text not null,status text not null check(status in('planned','onboarding','live','stabilizing','graduated','paused')),owner_user_id uuid,planned_users int not null default 0,certified_users int not null default 0,planned_accounts int not null default 0,target_live_at timestamptz,graduated_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists rollout.migration_controls(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),cohort_id uuid references rollout.cohorts(id),dataset_name text not null,source_count bigint not null default 0,target_count bigint not null default 0,exception_count bigint not null default 0,status text not null check(status in('not_started','running','reconciled','failed')),blocking boolean not null default true,source_snapshot jsonb not null default '{}'::jsonb,target_snapshot jsonb not null default '{}'::jsonb,reconciled_at timestamptz,created_at timestamptz not null default now());
create table if not exists rollout.training_certifications(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),cohort_id uuid references rollout.cohorts(id),user_id uuid not null,module_key text not null,status text not null check(status in('assigned','in_progress','passed','failed','waived')),score numeric(5,2),passing_score numeric(5,2),evidence jsonb not null default '{}'::jsonb,certified_at timestamptz,unique(workspace_id,cohort_id,user_id,module_key));
create table if not exists rollout.adoption_measurements(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),cohort_id uuid references rollout.cohorts(id),metric_key text not null,measured_at timestamptz not null,value numeric not null,target numeric,direction text check(direction in('higher','lower')),source_snapshot jsonb not null default '{}'::jsonb);
create table if not exists rollout.hypercare_issues(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),cohort_id uuid references rollout.cohorts(id),title text not null,severity text not null check(severity in('critical','high','medium','low')),status text not null check(status in('open','investigating','mitigated','resolved')),owner_user_id uuid,opened_at timestamptz not null default now(),resolved_at timestamptz,root_cause text,remediation text,audit_correlation_id uuid);
create table if not exists rollout.stabilization_gates(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),cohort_id uuid references rollout.cohorts(id),name text not null,status text not null check(status in('pass','warning','fail')),blocking boolean not null default true,evidence jsonb not null default '{}'::jsonb,approved_by uuid,approved_at timestamptz);
alter table rollout.cohorts enable row level security;alter table rollout.migration_controls enable row level security;alter table rollout.training_certifications enable row level security;alter table rollout.adoption_measurements enable row level security;alter table rollout.hypercare_issues enable row level security;alter table rollout.stabilization_gates enable row level security;
create policy cohorts_workspace on rollout.cohorts using(platform.is_workspace_member(workspace_id));create policy migration_workspace on rollout.migration_controls using(platform.is_workspace_member(workspace_id));create policy training_workspace on rollout.training_certifications using(platform.is_workspace_member(workspace_id));create policy adoption_workspace on rollout.adoption_measurements using(platform.is_workspace_member(workspace_id));create policy hypercare_workspace on rollout.hypercare_issues using(platform.is_workspace_member(workspace_id));create policy gates_workspace on rollout.stabilization_gates using(platform.is_workspace_member(workspace_id));

-- ===== supabase/migrations/0023_enterprise_intelligence.sql =====
begin;
create schema if not exists intelligence;
create table if not exists intelligence.forecast_models(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,name text not null,metric_key text not null,status text not null check(status in('draft','active','retired')),version integer not null default 1,horizon_days integer not null,confidence numeric(5,2),model_spec jsonb not null default '{}'::jsonb,created_at timestamptz not null default now(),unique(workspace_id,name,version));
create table if not exists intelligence.forecast_runs(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,forecast_model_id uuid not null references intelligence.forecast_models(id),started_at timestamptz not null default now(),completed_at timestamptz,input_snapshot jsonb not null default '{}'::jsonb,status text not null check(status in('queued','running','succeeded','failed')),error_message text);
create table if not exists intelligence.forecast_points(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,forecast_run_id uuid not null references intelligence.forecast_runs(id) on delete cascade,period_start date not null,period_end date not null,predicted_value numeric not null,lower_bound numeric,upper_bound numeric,actual_value numeric,unique(forecast_run_id,period_start));
create table if not exists intelligence.optimization_recommendations(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,type text not null,title text not null,summary text not null,impact_score numeric(5,2) not null,confidence numeric(5,2) not null,status text not null check(status in('proposed','accepted','rejected','implemented','measured')),owner_user_id uuid references platform.user_profiles(id),evidence jsonb not null default '[]'::jsonb,source_run_id uuid references agents.runs(id),expires_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists intelligence.recommendation_outcomes(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,recommendation_id uuid not null references intelligence.optimization_recommendations(id) on delete cascade,baseline_value numeric not null,expected_value numeric not null,actual_value numeric,unit text not null,measurement_window tstzrange,measured_at timestamptz,evidence jsonb not null default '[]'::jsonb,created_at timestamptz not null default now());
create table if not exists intelligence.trend_analyses(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,category text not null,title text not null,direction text not null check(direction in('positive','negative','neutral')),strength numeric(5,2) not null,summary text not null,root_causes jsonb not null default '[]'::jsonb,recommended_action text,source_snapshot jsonb not null default '{}'::jsonb,detected_at timestamptz not null default now());
create table if not exists intelligence.executive_briefs(id uuid primary key default gen_random_uuid(),workspace_id uuid references platform.workspaces(id) on delete cascade,period_start date not null,period_end date not null,status text not null check(status in('draft','approved')),content jsonb not null,source_snapshot jsonb not null,generated_by_run_id uuid references agents.runs(id),approved_by uuid references platform.user_profiles(id),approved_at timestamptz,created_at timestamptz not null default now());
create table if not exists intelligence.model_performance_metrics(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,model_type text not null,model_id uuid not null,metric_name text not null,metric_value numeric not null,period_start date not null,period_end date not null,created_at timestamptz not null default now());
create index if not exists idx_recommendations_workspace_status on intelligence.optimization_recommendations(workspace_id,status);
create index if not exists idx_forecast_runs_model on intelligence.forecast_runs(forecast_model_id,started_at desc);
alter table intelligence.forecast_models enable row level security;alter table intelligence.forecast_runs enable row level security;alter table intelligence.forecast_points enable row level security;alter table intelligence.optimization_recommendations enable row level security;alter table intelligence.recommendation_outcomes enable row level security;alter table intelligence.trend_analyses enable row level security;alter table intelligence.executive_briefs enable row level security;alter table intelligence.model_performance_metrics enable row level security;
do $$ declare t text; begin foreach t in array array['forecast_models','forecast_runs','forecast_points','optimization_recommendations','recommendation_outcomes','trend_analyses','model_performance_metrics'] loop execute format('drop policy if exists workspace_member on intelligence.%I',t);execute format('create policy workspace_member on intelligence.%I using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id))',t);end loop;end $$;
drop policy if exists brief_workspace_member on intelligence.executive_briefs;create policy brief_workspace_member on intelligence.executive_briefs using(workspace_id is null or platform.user_has_workspace_access(workspace_id)) with check(workspace_id is null or platform.user_has_workspace_access(workspace_id));
commit;

-- ===== supabase/migrations/0024_platform_extensibility.sql =====
create schema if not exists extensibility;
create table if not exists extensibility.workspace_templates(id uuid primary key default gen_random_uuid(),name text not null,industry text not null,version integer not null,status text not null check(status in('draft','published','retired')),description text,configuration jsonb not null default '{}'::jsonb,required_inputs jsonb not null default '[]'::jsonb,source_workspace_id uuid references platform.workspaces(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(name,version));
create table if not exists extensibility.configuration_packages(id uuid primary key default gen_random_uuid(),template_id uuid references extensibility.workspace_templates(id),version integer not null,checksum text not null,compatible_schema text not null,payload jsonb not null,exported_by uuid,exported_at timestamptz not null default now());
create table if not exists extensibility.provisioning_requests(id uuid primary key default gen_random_uuid(),workspace_name text not null,template_id uuid references extensibility.workspace_templates(id),requested_by uuid,owner_user_id uuid,status text not null check(status in('requested','validating','provisioning','ready','failed')),checks jsonb not null default '[]'::jsonb,target_workspace_id uuid references platform.workspaces(id),requested_at timestamptz not null default now(),completed_at timestamptz,error_message text);
create table if not exists extensibility.portability_checks(id uuid primary key default gen_random_uuid(),package_id uuid references extensibility.configuration_packages(id),target_workspace_id uuid references platform.workspaces(id),schema_compatible boolean not null,conflicts jsonb not null default '[]'::jsonb,warnings jsonb not null default '[]'::jsonb,status text not null check(status in('pass','review','blocked')),created_at timestamptz not null default now());
comment on schema extensibility is 'Reusable workspace templates, configuration packages, compatibility validation, and tenant provisioning.';

-- ===== supabase/migrations/0025_commercial_operations.sql =====
create schema if not exists commercial;
create table if not exists commercial.product_plans(id uuid primary key default gen_random_uuid(),code text unique not null,name text not null,status text not null check(status in('draft','active','retired')),monthly_price numeric(12,2) not null default 0,annual_price numeric(12,2) not null default 0,created_at timestamptz not null default now());
create table if not exists commercial.plan_entitlements(id uuid primary key default gen_random_uuid(),plan_id uuid not null references commercial.product_plans(id),entitlement_key text not null,label text not null,enabled boolean not null default true,limit_value numeric,unique(plan_id,entitlement_key));
create table if not exists commercial.subscriptions(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),plan_id uuid not null references commercial.product_plans(id),status text not null check(status in('trial','active','past_due','suspended','cancelled')),billing_cycle text not null check(billing_cycle in('monthly','annual')),renewal_date date,seats int not null default 1,created_at timestamptz not null default now());
create table if not exists commercial.usage_events(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),metric_key text not null,quantity numeric not null,event_time timestamptz not null default now(),idempotency_key text not null,source_type text,source_id text,unique(workspace_id,idempotency_key));
create table if not exists commercial.invoices(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),period_start date not null,period_end date not null,amount numeric(12,2) not null,status text not null check(status in('draft','open','paid','void')),external_invoice_id text,due_date date,created_at timestamptz not null default now());
create table if not exists commercial.support_cases(id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id),subject text not null,severity text not null check(severity in('low','medium','high','critical')),status text not null check(status in('open','waiting','resolved')),owner_user_id uuid,opened_at timestamptz not null default now(),resolved_at timestamptz,sla_due_at timestamptz);
alter table commercial.subscriptions enable row level security;alter table commercial.usage_events enable row level security;alter table commercial.invoices enable row level security;alter table commercial.support_cases enable row level security;

-- ===== supabase/migrations/0026_developer_platform.sql =====
create schema if not exists developer;

create table if not exists developer.service_accounts(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id),
  name text not null,
  owner_user_id uuid,
  status text not null check(status in('active','suspended','revoked')) default 'active',
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz
);

create table if not exists developer.api_credentials(
  id uuid primary key default gen_random_uuid(),
  service_account_id uuid not null references developer.service_accounts(id) on delete cascade,
  key_prefix text not null unique,
  secret_hash text not null,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz
);

create table if not exists developer.api_scopes(
  scope_key text primary key,
  label text not null,
  risk_level text not null check(risk_level in('low','medium','high'))
);

create table if not exists developer.service_account_scopes(
  service_account_id uuid not null references developer.service_accounts(id) on delete cascade,
  scope_key text not null references developer.api_scopes(scope_key),
  approved_by uuid,
  approved_at timestamptz,
  primary key(service_account_id,scope_key)
);

create table if not exists developer.rate_limit_policies(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id),
  service_account_id uuid references developer.service_accounts(id),
  window_seconds int not null check(window_seconds>0),
  request_limit int not null check(request_limit>0),
  burst_limit int not null check(burst_limit>=request_limit),
  created_at timestamptz not null default now(),
  check ((workspace_id is not null) or (service_account_id is not null))
);

create table if not exists developer.api_request_logs(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id),
  service_account_id uuid references developer.service_accounts(id),
  request_id text not null unique,
  method text not null,
  path text not null,
  response_code int not null,
  latency_ms int not null check(latency_ms>=0),
  idempotency_key_hash text,
  occurred_at timestamptz not null default now()
);

create table if not exists developer.webhook_endpoints(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id),
  name text not null,
  url text not null,
  signing_secret_hash text not null,
  status text not null check(status in('active','paused','failing')) default 'active',
  created_at timestamptz not null default now()
);

create table if not exists developer.webhook_subscriptions(
  endpoint_id uuid not null references developer.webhook_endpoints(id) on delete cascade,
  event_type text not null,
  primary key(endpoint_id,event_type)
);

create table if not exists developer.webhook_deliveries(
  id uuid primary key default gen_random_uuid(),
  endpoint_id uuid not null references developer.webhook_endpoints(id) on delete cascade,
  event_id uuid not null,
  event_type text not null,
  payload_hash text not null,
  status text not null check(status in('pending','delivered','retrying','failed')) default 'pending',
  attempt int not null default 0,
  response_code int,
  latency_ms int,
  next_attempt_at timestamptz,
  created_at timestamptz not null default now(),
  delivered_at timestamptz,
  unique(endpoint_id,event_id)
);

create table if not exists developer.idempotency_records(
  workspace_id uuid not null references platform.workspaces(id),
  service_account_id uuid not null references developer.service_accounts(id),
  key_hash text not null,
  request_hash text not null,
  response_code int,
  response_reference text,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  primary key(workspace_id,service_account_id,key_hash)
);

alter table developer.service_accounts enable row level security;
alter table developer.api_request_logs enable row level security;
alter table developer.webhook_endpoints enable row level security;
alter table developer.webhook_deliveries enable row level security;
alter table developer.idempotency_records enable row level security;

-- ===== supabase/migrations/0027_reliability_operations.sql =====
create schema if not exists reliability;

create table if not exists reliability.services(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id),
  service_key text not null unique,
  name text not null,
  owner_user_id uuid,
  owner_team text not null,
  tier int not null check(tier between 0 and 3),
  status text not null check(status in('operational','degraded','outage','maintenance')) default 'operational',
  runbook_url text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists reliability.service_dependencies(
  service_id uuid not null references reliability.services(id) on delete cascade,
  depends_on_service_id uuid not null references reliability.services(id) on delete cascade,
  critical boolean not null default true,
  primary key(service_id,depends_on_service_id),
  check(service_id <> depends_on_service_id)
);

create table if not exists reliability.service_level_objectives(
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references reliability.services(id) on delete cascade,
  name text not null,
  target_percent numeric(7,4) not null check(target_percent > 0 and target_percent <= 100),
  window_days int not null check(window_days > 0),
  indicator_query text not null,
  approved_by uuid,
  approved_at timestamptz,
  active boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists reliability.slo_measurements(
  id uuid primary key default gen_random_uuid(),
  objective_id uuid not null references reliability.service_level_objectives(id) on delete cascade,
  period_start timestamptz not null,
  period_end timestamptz not null,
  good_events bigint not null check(good_events >= 0),
  total_events bigint not null check(total_events >= good_events),
  source_reference text not null,
  measured_at timestamptz not null default now(),
  unique(objective_id,period_start,period_end)
);

create table if not exists reliability.incidents(
  id uuid primary key default gen_random_uuid(),
  incident_number text not null unique,
  workspace_id uuid references platform.workspaces(id),
  title text not null,
  severity text not null check(severity in('sev1','sev2','sev3','sev4')),
  status text not null check(status in('investigating','identified','monitoring','resolved')),
  commander_user_id uuid,
  customer_impact text not null,
  started_at timestamptz not null,
  identified_at timestamptz,
  resolved_at timestamptz,
  next_update_at timestamptz,
  postmortem_due_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists reliability.incident_services(
  incident_id uuid not null references reliability.incidents(id) on delete cascade,
  service_id uuid not null references reliability.services(id),
  primary key(incident_id,service_id)
);

create table if not exists reliability.incident_updates(
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references reliability.incidents(id) on delete cascade,
  status text not null,
  internal_note text not null,
  public_message text,
  author_user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists reliability.feature_flags(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id),
  flag_key text not null,
  description text not null,
  environment text not null check(environment in('staging','production')),
  status text not null check(status in('draft','active','paused','retired')) default 'draft',
  rollout_percent numeric(5,2) not null check(rollout_percent between 0 and 100) default 0,
  owner_user_id uuid,
  kill_switch boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,flag_key,environment)
);

create table if not exists reliability.maintenance_windows(
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references reliability.services(id),
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null check(status in('scheduled','in_progress','completed','cancelled')) default 'scheduled',
  customer_message text,
  approved_by uuid,
  created_at timestamptz not null default now(),
  check(ends_at > starts_at)
);

alter table reliability.services enable row level security;
alter table reliability.service_level_objectives enable row level security;
alter table reliability.incidents enable row level security;
alter table reliability.incident_updates enable row level security;
alter table reliability.feature_flags enable row level security;
alter table reliability.maintenance_windows enable row level security;

create policy services_workspace_access on reliability.services for all using (workspace_id is null or platform.is_workspace_member(workspace_id));
create policy incidents_workspace_access on reliability.incidents for all using (workspace_id is null or platform.is_workspace_member(workspace_id));
create policy feature_flags_workspace_access on reliability.feature_flags for all using (workspace_id is null or platform.is_workspace_member(workspace_id));

-- ===== supabase/migrations/0028_security_privacy_operations.sql =====
create schema if not exists security;
create table if not exists security.controls(id uuid primary key default gen_random_uuid(),workspace_id uuid references platform.workspaces(id),framework text not null,control_code text not null,title text not null,owner_user_id uuid,status text not null check(status in('effective','partial','ineffective','not_tested')),last_tested_at timestamptz,next_test_at timestamptz not null,created_at timestamptz not null default now(),unique(workspace_id,framework,control_code));
create table if not exists security.control_evidence(id uuid primary key default gen_random_uuid(),control_id uuid not null references security.controls(id) on delete cascade,evidence_type text not null,object_reference text not null,checksum text,period_start timestamptz,period_end timestamptz,collected_at timestamptz not null default now(),collected_by uuid);
create table if not exists security.findings(id uuid primary key default gen_random_uuid(),workspace_id uuid references platform.workspaces(id),finding_number text not null unique,title text not null,severity text not null check(severity in('critical','high','medium','low')),status text not null check(status in('open','mitigating','accepted','resolved')),asset_reference text not null,owner_user_id uuid,discovered_at timestamptz not null,due_at timestamptz not null,exploit_available boolean not null default false,internet_exposed boolean not null default false,accepted_by uuid,accepted_until timestamptz,resolved_at timestamptz,created_at timestamptz not null default now());
create table if not exists security.data_assets(id uuid primary key default gen_random_uuid(),workspace_id uuid references platform.workspaces(id),name text not null,system_name text not null,classification text not null check(classification in('public','internal','confidential','restricted')),owner_user_id uuid,contains_personal_data boolean not null default false,retention_days int not null check(retention_days>=0),encrypted_at_rest boolean not null,encrypted_in_transit boolean not null,created_at timestamptz not null default now());
create table if not exists security.privacy_requests(id uuid primary key default gen_random_uuid(),workspace_id uuid references platform.workspaces(id),request_number text not null unique,request_type text not null check(request_type in('access','deletion','correction','portability','opt_out')),status text not null check(status in('received','verified','in_progress','completed','denied')),jurisdiction text not null,received_at timestamptz not null,due_at timestamptz not null,verified_at timestamptz,completed_at timestamptz,owner_user_id uuid,identity_evidence_reference text,created_at timestamptz not null default now());
create table if not exists security.events(id uuid primary key default gen_random_uuid(),workspace_id uuid references platform.workspaces(id),category text not null,severity text not null,occurred_at timestamptz not null,source text not null,disposition text not null,summary text not null,correlation_id text,created_at timestamptz not null default now());
alter table security.controls enable row level security;alter table security.findings enable row level security;alter table security.data_assets enable row level security;alter table security.privacy_requests enable row level security;alter table security.events enable row level security;
create policy controls_workspace_access on security.controls for all using(workspace_id is null or platform.is_workspace_member(workspace_id));create policy findings_workspace_access on security.findings for all using(workspace_id is null or platform.is_workspace_member(workspace_id));create policy data_assets_workspace_access on security.data_assets for all using(workspace_id is null or platform.is_workspace_member(workspace_id));create policy privacy_requests_workspace_access on security.privacy_requests for all using(workspace_id is null or platform.is_workspace_member(workspace_id));create policy security_events_workspace_access on security.events for all using(workspace_id is null or platform.is_workspace_member(workspace_id));

-- ===== supabase/migrations/0029_enterprise_resilience.sql =====
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

-- ===== supabase/migrations/0030_compliance_audit.sql =====
create schema if not exists compliance;

create table if not exists compliance.policies (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  title text not null, owner text not null, status text not null check (status in ('draft','in_review','approved','retired')),
  version text not null, framework text not null, approved_at timestamptz, next_review_at timestamptz not null,
  acknowledgements_required integer not null default 0, acknowledgements_complete integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.obligations (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  framework text not null, citation text not null, requirement text not null, owner text not null,
  status text not null check (status in ('compliant','at_risk','non_compliant','not_applicable')),
  control_ids text[] not null default '{}', evidence_ids text[] not null default '{}',
  due_at timestamptz not null, jurisdiction text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.evidence_requests (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  title text not null, owner text not null, requested_by text not null,
  status text not null check (status in ('requested','submitted','accepted','rejected','overdue')),
  due_at timestamptz not null, submitted_at timestamptz, control_id text not null, artifact_url text,
  period_start date not null, period_end date not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.control_attestations (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  control_id text not null, control_name text not null, owner text not null, period text not null,
  attested_at timestamptz, effective boolean, exceptions integer not null default 0, reviewer text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.audit_engagements (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  name text not null, auditor text not null, framework text not null, owner text not null,
  status text not null check (status in ('planned','fieldwork','remediation','complete')),
  start_at date not null, end_at date not null, requests_open integer not null default 0,
  findings_open integer not null default 0, opinion text not null check (opinion in ('pending','clean','qualified','adverse')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.exceptions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  title text not null, control_id text not null, owner text not null,
  status text not null check (status in ('requested','approved','expired','closed')),
  risk text not null check (risk in ('critical','high','medium','low')),
  compensating_control text not null, approved_by text, expires_at timestamptz not null, remediation_plan text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table compliance.policies enable row level security;
alter table compliance.obligations enable row level security;
alter table compliance.evidence_requests enable row level security;
alter table compliance.control_attestations enable row level security;
alter table compliance.audit_engagements enable row level security;
alter table compliance.exceptions enable row level security;

create policy "workspace compliance policies" on compliance.policies using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance obligations" on compliance.obligations using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance evidence" on compliance.evidence_requests using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance attestations" on compliance.control_attestations using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance audits" on compliance.audit_engagements using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance exceptions" on compliance.exceptions using (platform.has_workspace_access(workspace_id));

create index if not exists compliance_policies_workspace_review_idx on compliance.policies(workspace_id,next_review_at);
create index if not exists compliance_obligations_workspace_due_idx on compliance.obligations(workspace_id,due_at);
create index if not exists compliance_evidence_workspace_due_idx on compliance.evidence_requests(workspace_id,due_at);
create index if not exists compliance_exceptions_workspace_expiry_idx on compliance.exceptions(workspace_id,expires_at);

-- ===== supabase/migrations/0031_ai_operations.sql =====
-- Step 31: governed AI operations and autonomous-agent control plane
create table if not exists public.ai_agent_definitions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, owner text not null, status text not null check (status in ('draft','evaluation','active','paused','retired')),
  risk text not null check (risk in ('low','medium','high','critical')), model text not null, version text not null,
  purpose text not null, tool_scopes text[] not null default '{}', human_approval_required boolean not null default false,
  max_cost_usd numeric(12,4) not null default 0, evaluation_score numeric(5,2) not null default 0,
  last_evaluated_at timestamptz, next_review_at timestamptz not null, created_at timestamptz not null default now()
);
create table if not exists public.ai_agent_runs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid not null references public.ai_agent_definitions(id) on delete cascade, status text not null,
  started_at timestamptz not null default now(), completed_at timestamptz, tokens_in bigint not null default 0,
  tokens_out bigint not null default 0, cost_usd numeric(12,4) not null default 0, latency_ms bigint not null default 0,
  retries integer not null default 0, guardrail_events integer not null default 0, trace_id text not null unique,
  input_digest text, output_digest text, error_code text
);
create table if not exists public.ai_guardrail_policies (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, category text not null check (category in ('data','security','quality','financial','action')),
  owner text not null, enabled boolean not null default true, enforcement text not null check (enforcement in ('monitor','block','require_approval')),
  policy_config jsonb not null default '{}', last_tested_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.ai_human_reviews (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  run_id uuid not null references public.ai_agent_runs(id) on delete cascade, reviewer_id uuid references auth.users(id),
  decision text not null default 'pending' check (decision in ('pending','approved','rejected','escalated')),
  reason text not null, requested_at timestamptz not null default now(), decided_at timestamptz, sla_minutes integer not null default 60
);
create table if not exists public.ai_model_providers (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  provider text not null, model text not null, region text not null, approved_use text[] not null default '{}',
  data_retention text not null check (data_retention in ('none','limited','standard')),
  status text not null check (status in ('approved','restricted','disabled')), unit_cost_input numeric(12,6) not null default 0,
  unit_cost_output numeric(12,6) not null default 0, availability_pct numeric(5,2), created_at timestamptz not null default now(),
  unique(workspace_id, provider, model)
);
create index if not exists idx_ai_runs_workspace_started on public.ai_agent_runs(workspace_id, started_at desc);
create index if not exists idx_ai_reviews_pending on public.ai_human_reviews(workspace_id, decision, requested_at);
alter table public.ai_agent_definitions enable row level security;
alter table public.ai_agent_runs enable row level security;
alter table public.ai_guardrail_policies enable row level security;
alter table public.ai_human_reviews enable row level security;
alter table public.ai_model_providers enable row level security;

-- ===== supabase/migrations/0032_workflow_automation.sql =====
-- Step 32: Workflow automation and orchestration
create table if not exists workflow_definitions (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null, name text not null,
 owner_user_id uuid, status text not null check (status in ('draft','active','paused','retired')),
 version integer not null default 1, description text not null default '', trigger_kind text not null,
 trigger_config jsonb not null default '{}'::jsonb, max_runtime_minutes integer not null default 60,
 max_run_cost_usd numeric(12,4) not null default 0, concurrency_limit integer not null default 1,
 approval_required boolean not null default false, published_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists workflow_steps (
 id uuid primary key default gen_random_uuid(), workflow_id uuid not null references workflow_definitions(id) on delete cascade,
 position integer not null, name text not null, kind text not null, handler text not null, config jsonb not null default '{}'::jsonb,
 timeout_seconds integer not null default 60, retry_limit integer not null default 0, on_failure text not null default 'stop',
 requires_approval boolean not null default false, unique(workflow_id, position)
);
create table if not exists workflow_runs (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null, workflow_id uuid not null references workflow_definitions(id),
 workflow_version integer not null, status text not null, current_step integer not null default 0, steps_completed integer not null default 0,
 total_steps integer not null, retries integer not null default 0, cost_usd numeric(12,4) not null default 0,
 trace_id text not null unique, idempotency_key text not null, input jsonb not null default '{}'::jsonb,
 output jsonb, error jsonb, started_at timestamptz not null default now(), completed_at timestamptz,
 unique(workspace_id, workflow_id, idempotency_key)
);
create table if not exists workflow_approvals (
 id uuid primary key default gen_random_uuid(), workflow_run_id uuid not null references workflow_runs(id) on delete cascade,
 workflow_step_id uuid references workflow_steps(id), reviewer_role text not null, status text not null default 'pending',
 reason text, sla_minutes integer not null default 60, requested_at timestamptz not null default now(), decided_at timestamptz, decided_by uuid
);
create table if not exists workflow_schedules (
 id uuid primary key default gen_random_uuid(), workflow_id uuid not null references workflow_definitions(id) on delete cascade,
 cron_expression text not null, timezone text not null default 'UTC', enabled boolean not null default true,
 next_run_at timestamptz not null, last_run_at timestamptz, misfire_policy text not null default 'skip'
);
create index if not exists workflow_runs_workspace_status_idx on workflow_runs(workspace_id,status,started_at desc);
create index if not exists workflow_approvals_status_idx on workflow_approvals(status,requested_at);
alter table workflow_definitions enable row level security;
alter table workflow_runs enable row level security;
alter table workflow_approvals enable row level security;
alter table workflow_schedules enable row level security;

-- ===== supabase/migrations/0033_executive_intelligence.sql =====
create table if not exists executive_metrics (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  metric_key text not null, name text not null, category text not null, value numeric not null, unit text not null,
  target numeric, prior_value numeric, owner_user_id uuid, source_system text not null, as_of timestamptz not null,
  certified boolean not null default false, created_at timestamptz not null default now(), unique(workspace_id,metric_key,as_of)
);
create table if not exists forecast_scenarios (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, horizon_months integer not null check(horizon_months>0), confidence text not null check(confidence in ('high','medium','low')),
  revenue_usd numeric not null, gross_margin_pct numeric, pipeline_coverage numeric, churn_pct numeric,
  assumptions jsonb not null default '[]'::jsonb, model_version text, created_by uuid, updated_at timestamptz not null default now()
);
create table if not exists executive_reports (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, cadence text not null, owner_user_id uuid, audience text not null, status text not null,
  definition jsonb not null default '{}'::jsonb, delivery_channels text[] not null default '{}', next_run_at timestamptz,
  last_published_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists decision_briefs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  title text not null, decision_owner uuid, due_at timestamptz, status text not null default 'open', recommendation text,
  confidence text, supporting_metric_keys text[] not null default '{}', risk_summary text, decided_at timestamptz, created_at timestamptz not null default now()
);
alter table executive_metrics enable row level security;
alter table forecast_scenarios enable row level security;
alter table executive_reports enable row level security;
alter table decision_briefs enable row level security;
-- Genuinely missing (not a typo): workspace_members was never created anywhere.
-- Rewritten to use the canonical membership check every other policy in this
-- codebase uses, instead of inventing a stand-in table for a raw subquery.
create policy executive_metrics_workspace on executive_metrics using (platform.user_has_workspace_access(workspace_id));
create policy forecast_scenarios_workspace on forecast_scenarios using (platform.user_has_workspace_access(workspace_id));
create policy executive_reports_workspace on executive_reports using (platform.user_has_workspace_access(workspace_id));
create policy decision_briefs_workspace on decision_briefs using (platform.user_has_workspace_access(workspace_id));

-- ===== supabase/migrations/0034_integration_marketplace.sql =====
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

-- ===== supabase/migrations/0035_platform_administration.sql =====
create table if not exists public.platform_tenants (id text primary key, name text not null, plan text not null, lifecycle text not null check (lifecycle in ('provisioning','active','suspended','offboarding')), health text not null check (health in ('healthy','warning','critical')), region text not null, owner text not null, data_residency text not null, created_at timestamptz not null default now(), last_activity_at timestamptz);
create table if not exists public.platform_environments (id text primary key, name text not null unique check (name in ('development','staging','production')), version text not null, status text not null, configuration_hash text not null, last_deployment_at timestamptz, promotion_blocked boolean not null default false);
create table if not exists public.platform_configuration_changes (id text primary key, environment text not null, category text not null, summary text not null, status text not null, risk text not null, requested_by text not null, approved_by text, scheduled_at timestamptz, created_at timestamptz not null default now());
create table if not exists public.platform_tenant_entitlements (id text primary key, tenant_id text not null references public.platform_tenants(id) on delete cascade, capability text not null, enabled boolean not null default false, limit_value integer, source text not null, expires_at timestamptz, unique(tenant_id,capability));
create table if not exists public.platform_support_access_grants (id text primary key, tenant_id text not null references public.platform_tenants(id) on delete cascade, engineer text not null, status text not null, scopes jsonb not null default '[]'::jsonb, reason text not null, requested_at timestamptz not null default now(), expires_at timestamptz not null, approved_by text);
create table if not exists public.platform_tenant_health_signals (id text primary key, tenant_id text not null references public.platform_tenants(id) on delete cascade, type text not null, severity text not null, message text not null, opened_at timestamptz not null default now(), resolved boolean not null default false);
alter table public.platform_tenants enable row level security;alter table public.platform_environments enable row level security;alter table public.platform_configuration_changes enable row level security;alter table public.platform_tenant_entitlements enable row level security;alter table public.platform_support_access_grants enable row level security;alter table public.platform_tenant_health_signals enable row level security;

-- ===== supabase/migrations/0036_performance_engineering.sql =====
-- Step 36: performance engineering, capacity planning, and scalability
create table if not exists public.performance_services (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  service_key text not null, name text not null, owner text not null, workload_tier text not null check (workload_tier in ('interactive','background','batch','analytics')),
  monthly_requests bigint not null default 0, p95_latency_ms integer not null default 0, latency_budget_ms integer not null,
  error_rate_pct numeric(8,4) not null default 0, capacity_status text not null check (capacity_status in ('healthy','watch','critical')),
  cpu_utilization_pct numeric(5,2), memory_utilization_pct numeric(5,2), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(workspace_id,service_key)
);
create table if not exists public.performance_load_tests (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  performance_service_id uuid not null references public.performance_services(id) on delete cascade, scenario text not null,
  status text not null check(status in ('planned','running','passed','failed')), target_rps integer not null, achieved_rps integer not null default 0,
  p95_latency_ms integer not null default 0, error_rate_pct numeric(8,4) not null default 0, executed_at timestamptz, release_gate boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.capacity_forecasts (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  performance_service_id uuid not null references public.performance_services(id) on delete cascade, forecast_period text not null,
  projected_requests bigint not null, projected_peak_rps integer not null, headroom_pct numeric(5,2) not null,
  confidence_pct numeric(5,2) not null, recommended_action text not null, created_at timestamptz not null default now()
);
create table if not exists public.scaling_policies (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  performance_service_id uuid not null references public.performance_services(id) on delete cascade,
  scaling_mode text not null check(scaling_mode in ('manual','scheduled','reactive','predictive')), min_instances integer not null,
  max_instances integer not null, target_cpu_pct numeric(5,2) not null, scale_out_cooldown_seconds integer not null,
  scale_in_cooldown_seconds integer not null, enabled boolean not null default true, updated_at timestamptz not null default now()
);
create table if not exists public.performance_budgets (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  route text not null, metric text not null check(metric in ('lcp','inp','cls','server_latency','bundle_size')),
  budget numeric(12,2) not null, current_value numeric(12,2) not null, unit text not null, blocking boolean not null default false,
  unique(workspace_id,route,metric)
);
alter table public.performance_services enable row level security;
alter table public.performance_load_tests enable row level security;
alter table public.capacity_forecasts enable row level security;
alter table public.scaling_policies enable row level security;
alter table public.performance_budgets enable row level security;
create policy "workspace performance services" on public.performance_services for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace performance tests" on public.performance_load_tests for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace capacity forecasts" on public.capacity_forecasts for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace scaling policies" on public.scaling_policies for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace performance budgets" on public.performance_budgets for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));

-- ===== supabase/migrations/0037_quality_engineering.sql =====
-- Step 37: End-to-end quality engineering and release hardening
create table if not exists public.quality_suites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
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
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
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
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
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
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
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
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
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

-- ===== supabase/migrations/0038_production_operations.sql =====
-- Step 38: Production deployment, observability, and operational readiness
create table if not exists public.production_deployments (id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,version text not null,environment text not null,status text not null check(status in('planned','running','succeeded','failed','rolled_back')),started_at timestamptz not null,completed_at timestamptz,strategy text not null check(strategy in('rolling','blue_green','canary')),rollback_available boolean not null default false,change_owner text not null,created_at timestamptz not null default now());
create table if not exists public.telemetry_signals (id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,service text not null,signal text not null check(signal in('logs','metrics','traces','synthetics')),coverage_pct numeric(5,2) not null check(coverage_pct between 0 and 100),retention_days integer not null check(retention_days>=0),last_ingest_at timestamptz,status text not null check(status in('healthy','degraded','missing')),unique(workspace_id,service,signal));
create table if not exists public.operational_runbooks (id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,name text not null,service text not null,owner text not null,status text not null check(status in('draft','approved','stale')),last_reviewed_at date not null,review_due_at date not null,automated_steps integer not null default 0,manual_steps integer not null default 0);
create table if not exists public.operational_alerts (id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,title text not null,service text not null,severity text not null check(severity in('critical','high','medium','low')),status text not null check(status in('open','acknowledged','resolved','suppressed')),owner text not null,opened_at timestamptz not null,acknowledged_at timestamptz,resolved_at timestamptz,runbook_id uuid references public.operational_runbooks(id) on delete set null);
create table if not exists public.on_call_rotations (id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,team text not null,primary_contact text not null,secondary_contact text not null,timezone text not null,coverage_hours integer not null check(coverage_hours between 0 and 24),handoff_at time not null,escalation_policy text not null);
create table if not exists public.go_live_controls (id uuid primary key default gen_random_uuid(),workspace_id uuid not null references platform.workspaces(id) on delete cascade,name text not null,owner text not null,required boolean not null default true,status text not null check(status in('ready','at_risk','blocked')),evidence text not null default '');
create index if not exists production_deployments_workspace_idx on public.production_deployments(workspace_id,environment,started_at desc);create index if not exists operational_alerts_workspace_idx on public.operational_alerts(workspace_id,severity,status);create index if not exists go_live_controls_workspace_idx on public.go_live_controls(workspace_id,status);
alter table public.production_deployments enable row level security;alter table public.telemetry_signals enable row level security;alter table public.operational_alerts enable row level security;alter table public.operational_runbooks enable row level security;alter table public.on_call_rotations enable row level security;alter table public.go_live_controls enable row level security;
create policy "workspace members manage production deployments" on public.production_deployments using(public.is_workspace_member(workspace_id)) with check(public.is_workspace_member(workspace_id));create policy "workspace members manage telemetry signals" on public.telemetry_signals using(public.is_workspace_member(workspace_id)) with check(public.is_workspace_member(workspace_id));create policy "workspace members manage operational alerts" on public.operational_alerts using(public.is_workspace_member(workspace_id)) with check(public.is_workspace_member(workspace_id));create policy "workspace members manage operational runbooks" on public.operational_runbooks using(public.is_workspace_member(workspace_id)) with check(public.is_workspace_member(workspace_id));create policy "workspace members manage on call rotations" on public.on_call_rotations using(public.is_workspace_member(workspace_id)) with check(public.is_workspace_member(workspace_id));create policy "workspace members manage go live controls" on public.go_live_controls using(public.is_workspace_member(workspace_id)) with check(public.is_workspace_member(workspace_id));

-- ===== supabase/migrations/0039_release_enablement.sql =====
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

-- ===== supabase/migrations/0040_ga_readiness.sql =====
-- Step 40: Version 1.0 stabilization and general availability readiness
create table if not exists public.release_certifications (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  domain text not null check (domain in ('quality','security','operations','performance','compliance','enablement')),
  owner text not null,
  status text not null check (status in ('pending','passed','failed','waived')),
  evidence text not null default '',
  required boolean not null default true,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.migration_readiness (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  owner text not null,
  status text not null check (status in ('pending','passed','failed','waived')),
  dry_run_complete boolean not null default false,
  rollback_validated boolean not null default false,
  data_reconciled boolean not null default false,
  estimated_minutes integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.residual_risks (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  title text not null,
  owner text not null,
  level text not null check (level in ('critical','high','medium','low')),
  status text not null check (status in ('open','mitigated','accepted')),
  mitigation text not null default '',
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.functional_acceptances (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  function text not null check (function in ('product','engineering','security','operations','finance','customer_success')),
  owner text not null,
  status text not null check (status in ('pending','accepted','rejected')),
  notes text not null default '',
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.ga_launch_gates (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  owner text not null,
  required boolean not null default true,
  status text not null check (status in ('ready','at_risk','blocked')),
  evidence text not null default '',
  created_at timestamptz not null default now()
);
alter table public.release_certifications enable row level security;
alter table public.migration_readiness enable row level security;
alter table public.residual_risks enable row level security;
alter table public.functional_acceptances enable row level security;
alter table public.ga_launch_gates enable row level security;

-- ===== supabase/migrations/0041_launch_certification.sql =====
-- Step 41: Production launch closure and Version 1.0 certification
create table if not exists launch_blocker_closures (
  id text primary key,
  source_reference text not null,
  description text not null,
  owner text not null,
  status text not null check (status in ('open','verified','waived')),
  evidence text not null,
  verified_at timestamptz
);
create table if not exists production_releases (
  id text primary key,
  version text not null,
  environment text not null,
  strategy text not null check (strategy in ('rolling','blue_green','canary')),
  status text not null check (status in ('planned','in_progress','completed','rolled_back')),
  started_at timestamptz,
  completed_at timestamptz,
  rollback_available boolean not null default false,
  change_ticket text not null
);
create table if not exists post_launch_checks (
  id text primary key,
  release_id text references production_releases(id),
  name text not null,
  owner text not null,
  required boolean not null default true,
  status text not null check (status in ('pending','passed','failed')),
  observed_value text not null,
  threshold text not null,
  checked_at timestamptz
);
create table if not exists launch_authorizations (
  id text primary key,
  release_id text references production_releases(id),
  role text not null,
  approver text not null,
  status text not null check (status in ('pending','approved','rejected')),
  decision text not null,
  approved_at timestamptz
);
create table if not exists release_artifacts (
  id text primary key,
  release_id text references production_releases(id),
  name text not null,
  kind text not null check (kind in ('source','migration','runbook','release_notes','evidence')),
  checksum text not null,
  status text not null check (status in ('verified','missing'))
);

-- ===== supabase/migrations/0042_post_ga_operations.sql =====
create table if not exists product_adoption_metrics (id text primary key, name text not null, owner text not null, active_users integer not null default 0, eligible_users integer not null default 0, target_percent numeric not null default 0, previous_percent numeric not null default 0, trend text not null check (trend in ('growing','stable','declining')), measured_at timestamptz not null default now());
create table if not exists customer_health_records (id text primary key, customer text not null, segment text not null, adoption_percent numeric not null default 0, support_risk numeric not null default 0, value_realization_percent numeric not null default 0, status text not null check (status in ('healthy','watch','at_risk')), owner text not null, next_action text not null);
create table if not exists customer_feedback_items (id text primary key, source text not null check (source in ('support','interview','survey','usage')), theme text not null, description text not null, impact text not null check (impact in ('low','medium','high','critical')), status text not null check (status in ('new','triaged','planned','resolved')), votes integer not null default 0, owner text not null);
create table if not exists value_outcomes (id text primary key, name text not null, baseline numeric not null, current_value numeric not null, target numeric not null, unit text not null, direction text not null check (direction in ('higher','lower')), owner text not null, verified boolean not null default false);
create table if not exists improvement_initiatives (id text primary key, title text not null, category text not null check (category in ('product','reliability','enablement','data','operations')), impact_score numeric not null, effort_score numeric not null, status text not null check (status in ('proposed','approved','in_progress','completed')), target_release text not null, owner text not null, linked_feedback jsonb not null default '[]'::jsonb);

-- ===== supabase/migrations/0043_rls_hardening.sql =====
-- Step 43: RLS hardening for the 33 tables left without row-level security.
-- Model: "just me for now" -- workspace-member-only access via the existing
-- platform.user_has_workspace_access()/is_workspace_member() functions.
-- Category A: direct workspace_id. Category B: indirect via a parent FK.
-- Category C: per-user (own row only). Category D: global reference/catalog
-- data with no workspace_id -- readable by any authenticated user.

alter table configuration.business_models enable row level security;
alter table developer.rate_limit_policies enable row level security;
alter table extensibility.workspace_templates enable row level security;
alter table extensibility.provisioning_requests enable row level security;
alter table extensibility.portability_checks enable row level security;
alter table extensibility.configuration_packages enable row level security;
alter table agents.agent_versions enable row level security;
alter table developer.api_credentials enable row level security;
alter table developer.service_account_scopes enable row level security;
alter table developer.webhook_subscriptions enable row level security;
alter table entities.organizations enable row level security;
alter table entities.organization_addresses enable row level security;
alter table entities.person_organization_roles enable row level security;
alter table entities.contact_points enable row level security;
alter table entities.property_addresses enable row level security;
alter table entities.property_organization_relationships enable row level security;
alter table intelligence.finding_evidence enable row level security;
alter table operations.recovery_tests enable row level security;
alter table reliability.incident_services enable row level security;
alter table reliability.service_dependencies enable row level security;
alter table reliability.slo_measurements enable row level security;
alter table security.control_evidence enable row level security;
alter table platform.user_profiles enable row level security;
alter table platform.user_workspace_roles enable row level security;
alter table agents.providers enable row level security;
alter table agents.models enable row level security;
alter table commercial.product_plans enable row level security;
alter table commercial.plan_entitlements enable row level security;
alter table developer.api_scopes enable row level security;
alter table platform.permissions enable row level security;
alter table platform.roles enable row level security;
alter table platform.role_permissions enable row level security;
alter table public.connector_definitions enable row level security;

-- Category A: direct workspace_id
create policy business_models_workspace on configuration.business_models using (platform.user_has_workspace_access(workspace_id));
create policy rate_limit_policies_workspace on developer.rate_limit_policies using (
  (workspace_id is not null and platform.user_has_workspace_access(workspace_id))
  or exists(select 1 from developer.service_accounts sa where sa.id = rate_limit_policies.service_account_id and platform.user_has_workspace_access(sa.workspace_id))
);
create policy workspace_templates_access on extensibility.workspace_templates using (source_workspace_id is null or platform.user_has_workspace_access(source_workspace_id));
create policy provisioning_requests_workspace on extensibility.provisioning_requests using (target_workspace_id is null or platform.user_has_workspace_access(target_workspace_id));
create policy portability_checks_workspace on extensibility.portability_checks using (target_workspace_id is null or platform.user_has_workspace_access(target_workspace_id));

-- Category B: indirect via a parent table's workspace_id
create policy configuration_packages_via_template on extensibility.configuration_packages using (
  exists(select 1 from extensibility.workspace_templates wt where wt.id = configuration_packages.template_id and (wt.source_workspace_id is null or platform.user_has_workspace_access(wt.source_workspace_id)))
);
create policy agent_versions_via_definition on agents.agent_versions using (
  exists(select 1 from agents.agent_definitions ad where ad.id = agent_versions.agent_id and platform.user_has_workspace_access(ad.workspace_id))
);
create policy api_credentials_via_service_account on developer.api_credentials using (
  exists(select 1 from developer.service_accounts sa where sa.id = api_credentials.service_account_id and platform.user_has_workspace_access(sa.workspace_id))
);
create policy service_account_scopes_via_service_account on developer.service_account_scopes using (
  exists(select 1 from developer.service_accounts sa where sa.id = service_account_scopes.service_account_id and platform.user_has_workspace_access(sa.workspace_id))
);
create policy webhook_subscriptions_via_endpoint on developer.webhook_subscriptions using (
  exists(select 1 from developer.webhook_endpoints we where we.id = webhook_subscriptions.endpoint_id and platform.user_has_workspace_access(we.workspace_id))
);
create policy organizations_via_workspace_link on entities.organizations using (
  exists(select 1 from entities.workspace_organizations wo where wo.organization_id = organizations.id and platform.user_has_workspace_access(wo.workspace_id))
);
create policy organization_addresses_via_workspace_link on entities.organization_addresses using (
  exists(select 1 from entities.workspace_organizations wo where wo.organization_id = organization_addresses.organization_id and platform.user_has_workspace_access(wo.workspace_id))
);
create policy person_org_roles_via_workspace_link on entities.person_organization_roles using (
  exists(select 1 from entities.workspace_people wp where wp.person_id = person_organization_roles.person_id and platform.user_has_workspace_access(wp.workspace_id))
);
create policy contact_points_via_workspace_link on entities.contact_points using (
  exists(select 1 from entities.workspace_people wp where wp.person_id = contact_points.person_id and platform.user_has_workspace_access(wp.workspace_id))
);
create policy property_addresses_via_workspace_link on entities.property_addresses using (
  exists(select 1 from entities.workspace_properties wp where wp.property_id = property_addresses.property_id and platform.user_has_workspace_access(wp.workspace_id))
);
create policy property_org_rel_via_workspace_link on entities.property_organization_relationships using (
  exists(select 1 from entities.workspace_properties wp where wp.property_id = property_organization_relationships.property_id and platform.user_has_workspace_access(wp.workspace_id))
);
create policy finding_evidence_via_finding on intelligence.finding_evidence using (
  exists(select 1 from intelligence.research_findings rf where rf.id = finding_evidence.finding_id and platform.user_has_workspace_access(rf.workspace_id))
);
create policy recovery_tests_via_backup_policy on operations.recovery_tests using (
  exists(select 1 from operations.backup_policies bp where bp.id = recovery_tests.backup_policy_id and (bp.workspace_id is null or platform.user_has_workspace_access(bp.workspace_id)))
);
create policy incident_services_via_incident on reliability.incident_services using (
  exists(select 1 from reliability.incidents i where i.id = incident_services.incident_id and (i.workspace_id is null or platform.user_has_workspace_access(i.workspace_id)))
);
create policy service_dependencies_via_service on reliability.service_dependencies using (
  exists(select 1 from reliability.services s where s.id = service_dependencies.service_id and (s.workspace_id is null or platform.user_has_workspace_access(s.workspace_id)))
);
create policy slo_measurements_via_objective on reliability.slo_measurements using (
  exists(select 1 from reliability.service_level_objectives slo join reliability.services s on s.id = slo.service_id where slo.id = slo_measurements.objective_id and (s.workspace_id is null or platform.user_has_workspace_access(s.workspace_id)))
);
create policy control_evidence_via_control on security.control_evidence using (
  exists(select 1 from security.controls c where c.id = control_evidence.control_id and (c.workspace_id is null or platform.is_workspace_member(c.workspace_id)))
);

-- Category C: per-user own-row access (user_workspace_roles avoids calling
-- user_has_workspace_access on itself, which would recurse into this table).
create policy user_profiles_self on platform.user_profiles using (id = auth.uid());
create policy user_workspace_roles_self on platform.user_workspace_roles using (user_id = auth.uid());

-- Category D: global reference/catalog data, no workspace_id.
-- agents.providers holds secret_reference and intentionally gets NO select
-- policy here (RLS enabled, default-deny for anon/authenticated; service
-- role still bypasses RLS for backend use), matching the entities.people/
-- entities.properties/entities.addresses pattern already in this schema.
create policy models_read on agents.models for select to authenticated using (true);
create policy product_plans_read on commercial.product_plans for select to authenticated using (true);
create policy plan_entitlements_read on commercial.plan_entitlements for select to authenticated using (true);
create policy api_scopes_read on developer.api_scopes for select to authenticated using (true);
create policy permissions_read on platform.permissions for select to authenticated using (true);
create policy roles_read on platform.roles for select to authenticated using (true);
create policy role_permissions_read on platform.role_permissions for select to authenticated using (true);
create policy connector_definitions_read on public.connector_definitions for select to authenticated using (true);

-- ===== supabase/seed/seed.sql =====
insert into platform.roles(code,name,description) values
('executive_sponsor','Executive Sponsor','Approves strategic configuration and stage gates'),
('gtm_administrator','GTM Administrator','Administers workspace configuration and implementation'),
('gtm_engineer','GTM Engineer','Builds data, scoring, research, and playbooks'),
('sales_manager','Sales Manager','Manages pipeline, assignments, and execution'),
('sales_user','Sales User','Works assigned accounts, tasks, and opportunities'),
('analyst','Analyst','Reviews analytics, quality, and performance'),
('technical_administrator','Technical Administrator','Manages integrations and production operations'),
('viewer','Viewer','Read-only workspace access')
on conflict(code) do nothing;

insert into platform.permissions(code,name) values
('workspace.view','View workspace'),('workspace.configure','Configure workspace'),('workspace.approve','Approve workspace'),
('implementation.manage','Manage implementation'),('implementation.approve','Approve implementation stages'),
('entity.edit','Edit entities'),('score.configure','Configure scoring'),('agent.execute','Execute AI agents'),
('campaign.launch','Launch campaigns'),('integration.manage','Manage integrations')
on conflict(code) do nothing;

insert into platform.workspaces(id,name,code,legal_entity_name,workspace_type,status)
values
('11111111-1111-1111-1111-111111111111','Alvarez Growth Intelligence','ALV','Alvarez Plumbing & Air Conditioning','operating_company','planning'),
('22222222-2222-2222-2222-222222222222','Intelligent Waterflow','IWF','Intelligent Waterflow','product_line','planning')
on conflict(code) do nothing;

insert into configuration.workspace_configuration_versions(id,workspace_id,version_number,status,change_summary)
values
('aaaaaaaa-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111',1,'active','Initial Alvarez workspace configuration'),
('aaaaaaaa-2222-2222-2222-222222222222','22222222-2222-2222-2222-222222222222',1,'draft','Initial Intelligent Waterflow workspace configuration')
on conflict(workspace_id,version_number) do nothing;

update platform.workspaces set active_configuration_version_id='aaaaaaaa-1111-1111-1111-111111111111' where id='11111111-1111-1111-1111-111111111111';

insert into implementation.implementation_plans(id,workspace_id,configuration_version_id,name,status)
values('bbbbbbbb-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111','aaaaaaaa-1111-1111-1111-111111111111','Alvarez GTM Implementation','active')
on conflict(id) do nothing;

with stage_data(stage_number,name,objective,status,completion) as (values
(1,'Business Definition','Define the commercial model, strategic objective, and growth hypothesis.','complete',100),
(2,'ICP Design','Approve target-account definitions, buyer personas, and exclusions.','complete',100),
(3,'Data Strategy','Specify sources, mappings, ownership, lineage, and refresh rules.','active',55),
(4,'Market Universe','Build the complete addressable account and property universe.','not_started',0),
(5,'Enrichment','Complete required firmographic, property, and contact fields.','not_started',0),
(6,'Scoring','Validate and activate explainable prioritization models.','not_started',0),
(7,'Offer Design','Approve segment-specific offers, economics, and proof points.','not_started',0),
(8,'Playbook Design','Translate strategy into controlled sequences and handoffs.','not_started',0),
(9,'Pilot','Execute a bounded pilot with explicit success and stop criteria.','not_started',0),
(10,'Measurement','Reconcile execution, pipeline, economics, and data quality.','not_started',0),
(11,'Optimization','Revise weak assumptions, rules, offers, and workflows.','not_started',0),
(12,'Scaling','Expand proven plays with governance and operating capacity.','not_started',0))
insert into implementation.implementation_stages(implementation_plan_id,stage_number,name,objective,status,completion_percentage)
select 'bbbbbbbb-1111-1111-1111-111111111111',stage_number,name,objective,status,completion from stage_data
on conflict(implementation_plan_id,stage_number) do nothing;
