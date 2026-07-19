alter table platform.workspaces enable row level security;
alter table entities.workspace_organizations enable row level security;
alter table configuration.workspace_configuration_versions enable row level security;
create or replace function platform.user_has_workspace_access(target_workspace uuid)
returns boolean language sql stable security definer set search_path=platform,public as $$
  select exists(select 1 from platform.user_workspace_roles uwr where uwr.user_id=auth.uid() and uwr.workspace_id=target_workspace and uwr.active=true)
$$;
create policy workspaces_member_select on platform.workspaces for select using (platform.user_has_workspace_access(id));
create policy workspace_org_member_all on entities.workspace_organizations for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
create policy config_member_all on configuration.workspace_configuration_versions for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id));
