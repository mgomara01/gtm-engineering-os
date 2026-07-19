create schema if not exists intelligence;
create schema if not exists agents;

create table if not exists intelligence.enrichment_providers (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id) on delete cascade,
  name text not null,
  category text not null,
  status text not null default 'test' check (status in ('active','inactive','test')),
  priority integer not null default 100,
  field_coverage jsonb not null default '[]'::jsonb,
  cost_policy jsonb not null default '{}'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  credential_reference text,
  last_success_at timestamptz,
  last_failure_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,name)
);

create table if not exists intelligence.research_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  research_type text not null,
  priority text not null default 'normal' check (priority in ('low','normal','high')),
  status text not null default 'queued' check (status in ('queued','running','review_required','complete','failed','cancelled')),
  provider_id uuid references intelligence.enrichment_providers(id),
  requested_by uuid references platform.users(id),
  confidence numeric(7,4),
  estimated_cost numeric(18,6),
  actual_cost numeric(18,6),
  started_at timestamptz,
  completed_at timestamptz,
  error_details jsonb,
  created_at timestamptz not null default now()
);

create table if not exists intelligence.evidence_items (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  research_job_id uuid references intelligence.research_jobs(id) on delete cascade,
  source_type text not null,
  source_reference text not null,
  title text,
  excerpt text,
  content_hash text,
  captured_at timestamptz not null default now(),
  reliability_rating numeric(7,4),
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists intelligence.research_findings (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  research_job_id uuid not null references intelligence.research_jobs(id) on delete cascade,
  finding_type text not null,
  field_name text,
  current_value jsonb,
  proposed_value jsonb not null,
  summary text not null,
  confidence numeric(7,4) not null,
  verification_status text not null default 'unverified' check (verification_status in ('unverified','supported','verified','conflicting')),
  review_status text not null default 'pending' check (review_status in ('pending','accepted','rejected','edited')),
  reviewed_by uuid references platform.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists intelligence.finding_evidence (
  finding_id uuid not null references intelligence.research_findings(id) on delete cascade,
  evidence_id uuid not null references intelligence.evidence_items(id) on delete cascade,
  primary key(finding_id,evidence_id)
);

create table if not exists intelligence.signals (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  signal_type text not null,
  summary text not null,
  strength numeric(7,4) not null,
  confidence numeric(7,4) not null,
  detected_at timestamptz not null default now(),
  expires_at timestamptz,
  status text not null default 'active' check (status in ('active','actioned','dismissed','expired')),
  source_type text not null,
  source_reference text,
  recommended_action text,
  research_job_id uuid references intelligence.research_jobs(id),
  created_at timestamptz not null default now()
);

create table if not exists intelligence.account_briefs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  entity_type text not null default 'organization',
  entity_id uuid not null,
  version_number integer not null,
  summary text not null,
  opportunities jsonb not null default '[]'::jsonb,
  risks jsonb not null default '[]'::jsonb,
  recommended_actions jsonb not null default '[]'::jsonb,
  confidence numeric(7,4) not null,
  review_status text not null default 'pending' check (review_status in ('pending','accepted','rejected','edited')),
  generated_by_job_id uuid references intelligence.research_jobs(id),
  generated_at timestamptz not null default now(),
  reviewed_by uuid references platform.users(id),
  reviewed_at timestamptz,
  unique(workspace_id,entity_type,entity_id,version_number)
);

create index if not exists idx_research_jobs_workspace_status on intelligence.research_jobs(workspace_id,status,created_at desc);
create index if not exists idx_findings_review on intelligence.research_findings(workspace_id,review_status,created_at desc);
create index if not exists idx_signals_entity on intelligence.signals(workspace_id,entity_type,entity_id,status);
create index if not exists idx_briefs_entity on intelligence.account_briefs(workspace_id,entity_type,entity_id,version_number desc);

alter table intelligence.enrichment_providers enable row level security;
alter table intelligence.research_jobs enable row level security;
alter table intelligence.evidence_items enable row level security;
alter table intelligence.research_findings enable row level security;
alter table intelligence.signals enable row level security;
alter table intelligence.account_briefs enable row level security;

create policy enrichment_provider_workspace_access on intelligence.enrichment_providers for all using (workspace_id is null or workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy research_job_workspace_access on intelligence.research_jobs for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy evidence_workspace_access on intelligence.evidence_items for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy findings_workspace_access on intelligence.research_findings for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy signals_workspace_access on intelligence.signals for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy briefs_workspace_access on intelligence.account_briefs for all using (workspace_id in (select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
