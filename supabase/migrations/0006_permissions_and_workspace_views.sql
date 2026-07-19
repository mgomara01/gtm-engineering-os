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

