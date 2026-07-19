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
