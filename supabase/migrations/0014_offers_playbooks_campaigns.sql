-- Step 14: governed offers, playbooks, campaign execution, approvals, and performance
create schema if not exists gtm;

create type gtm.lifecycle_status as enum ('draft','review','approved','active','retired');
create type gtm.channel_type as enum ('email','phone','sms','linkedin','direct_mail','site_visit','task');
create type gtm.campaign_status as enum ('draft','active','paused','completed');
create type gtm.member_status as enum ('queued','active','paused','completed','removed');

create table gtm.offers (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, description text, current_version_id uuid, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create table gtm.offer_versions (
  id uuid primary key default gen_random_uuid(), offer_id uuid not null references gtm.offers(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id), version_no integer not null,
  status gtm.lifecycle_status not null default 'draft', target_icp text, value_proposition text not null,
  pricing jsonb not null default '{}'::jsonb, eligibility_rules jsonb not null default '[]'::jsonb,
  objection_handling jsonb not null default '[]'::jsonb, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), approved_at timestamptz, unique(offer_id,version_no)
);
create table gtm.proof_points (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  offer_version_id uuid not null references gtm.offer_versions(id) on delete cascade, statement text not null,
  evidence_id uuid, status text not null default 'approved', created_at timestamptz not null default now()
);
alter table gtm.offers add constraint offers_current_version_fk foreign key(current_version_id) references gtm.offer_versions(id);

create table gtm.playbooks (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, description text, current_version_id uuid, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), deleted_at timestamptz
);
create table gtm.playbook_versions (
  id uuid primary key default gen_random_uuid(), playbook_id uuid not null references gtm.playbooks(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id), offer_version_id uuid not null references gtm.offer_versions(id),
  version_no integer not null, status gtm.lifecycle_status not null default 'draft', target_tier text not null default 'Any',
  trigger_definition jsonb not null default '{}'::jsonb, completion_definition jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id), created_at timestamptz not null default now(), approved_at timestamptz,
  unique(playbook_id,version_no)
);
create table gtm.playbook_steps (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  playbook_version_id uuid not null references gtm.playbook_versions(id) on delete cascade,
  step_order integer not null check(step_order > 0), name text not null, channel gtm.channel_type not null,
  delay_days integer not null default 0 check(delay_days >= 0), owner_role text not null,
  template_body text, condition_definition jsonb not null default '{}'::jsonb, completion_criteria text not null,
  created_at timestamptz not null default now(), unique(playbook_version_id,step_order)
);
alter table gtm.playbooks add constraint playbooks_current_version_fk foreign key(current_version_id) references gtm.playbook_versions(id);

create table gtm.campaigns (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  name text not null, description text, status gtm.campaign_status not null default 'draft',
  playbook_version_id uuid not null references gtm.playbook_versions(id), audience_definition jsonb not null,
  started_at timestamptz, completed_at timestamptz, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table gtm.campaign_members (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  campaign_id uuid not null references gtm.campaigns(id) on delete cascade,
  organization_id uuid not null references entities.organizations(id), status gtm.member_status not null default 'queued',
  enrollment_score numeric(6,2), enrollment_tier text, enrollment_snapshot jsonb not null default '{}'::jsonb,
  current_step_order integer not null default 0, enrolled_at timestamptz not null default now(), completed_at timestamptz,
  unique(campaign_id,organization_id)
);
create table gtm.sequence_executions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  campaign_member_id uuid not null references gtm.campaign_members(id) on delete cascade,
  playbook_step_id uuid not null references gtm.playbook_steps(id), status text not null default 'pending',
  assigned_to uuid references auth.users(id), due_at timestamptz, completed_at timestamptz,
  outcome jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create table gtm.approval_records (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  object_type text not null check(object_type in ('offer_version','playbook_version','campaign')),
  object_id uuid not null, decision text not null check(decision in ('submitted','approved','rejected','returned')),
  reviewer_id uuid references auth.users(id), notes text, created_at timestamptz not null default now()
);
create table gtm.performance_events (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
  campaign_id uuid references gtm.campaigns(id), campaign_member_id uuid references gtm.campaign_members(id),
  playbook_version_id uuid references gtm.playbook_versions(id), event_type text not null,
  opportunity_id uuid, revenue_amount numeric(14,2), occurred_at timestamptz not null default now(), metadata jsonb not null default '{}'::jsonb
);

create index offers_workspace_idx on gtm.offers(workspace_id);
create index playbooks_workspace_idx on gtm.playbooks(workspace_id);
create index campaigns_workspace_status_idx on gtm.campaigns(workspace_id,status);
create index campaign_members_campaign_status_idx on gtm.campaign_members(campaign_id,status);
create index performance_events_playbook_idx on gtm.performance_events(workspace_id,playbook_version_id,occurred_at);

alter table gtm.offers enable row level security; alter table gtm.offer_versions enable row level security;
alter table gtm.proof_points enable row level security; alter table gtm.playbooks enable row level security;
alter table gtm.playbook_versions enable row level security; alter table gtm.playbook_steps enable row level security;
alter table gtm.campaigns enable row level security; alter table gtm.campaign_members enable row level security;
alter table gtm.sequence_executions enable row level security; alter table gtm.approval_records enable row level security;
alter table gtm.performance_events enable row level security;

do $$ declare t text; begin
  foreach t in array array['offers','offer_versions','proof_points','playbooks','playbook_versions','playbook_steps','campaigns','campaign_members','sequence_executions','approval_records','performance_events'] loop
    execute format('create policy %I on gtm.%I for all using (platform.user_has_workspace_access(workspace_id)) with check (platform.user_has_workspace_access(workspace_id))', t||'_workspace_access', t);
  end loop;
end $$;
