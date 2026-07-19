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
