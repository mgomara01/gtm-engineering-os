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
