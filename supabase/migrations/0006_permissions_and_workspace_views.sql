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

