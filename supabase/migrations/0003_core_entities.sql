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
