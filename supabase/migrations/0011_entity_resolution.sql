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
