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
