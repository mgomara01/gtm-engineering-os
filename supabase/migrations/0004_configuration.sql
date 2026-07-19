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
