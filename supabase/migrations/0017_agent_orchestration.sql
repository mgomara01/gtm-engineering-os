create schema if not exists agents;

create table if not exists agents.providers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  provider_type text not null,
  status text not null default 'active' check (status in ('active','test','disabled')),
  secret_reference text,
  created_at timestamptz not null default now()
);

create table if not exists agents.models (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references agents.providers(id),
  model_key text not null,
  display_name text not null,
  input_cost_per_million numeric(12,4),
  output_cost_per_million numeric(12,4),
  context_window integer,
  active boolean not null default true,
  unique(provider_id,model_key)
);

create table if not exists agents.agent_definitions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  purpose text not null,
  owner_role text not null,
  status text not null default 'draft' check(status in ('draft','active','paused','retired')),
  risk_level text not null default 'medium' check(risk_level in ('low','medium','high')),
  approval_policy text not null default 'required' check(approval_policy in ('none','sampled','required')),
  monthly_budget numeric(12,2) not null default 0,
  active_version_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists agents.agent_versions (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references agents.agent_definitions(id) on delete cascade,
  version integer not null,
  model_id uuid references agents.models(id),
  system_prompt text not null,
  input_schema jsonb not null default '{}'::jsonb,
  output_schema jsonb not null default '{}'::jsonb,
  tool_policy jsonb not null default '{}'::jsonb,
  temperature numeric(4,3) not null default 0.2,
  max_tokens integer not null default 4000,
  status text not null default 'draft' check(status in ('draft','review','approved','retired')),
  created_by uuid references platform.user_profiles(id),
  created_at timestamptz not null default now(),
  unique(agent_id,version)
);

alter table agents.agent_definitions drop constraint if exists agent_definitions_active_version_id_fkey;
alter table agents.agent_definitions add constraint agent_definitions_active_version_id_fkey foreign key(active_version_id) references agents.agent_versions(id);

create table if not exists agents.runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid not null references agents.agent_definitions(id),
  agent_version_id uuid not null references agents.agent_versions(id),
  status text not null check(status in ('queued','running','succeeded','failed','needs_review','cancelled')),
  subject_type text,
  subject_id uuid,
  input_snapshot jsonb not null default '{}'::jsonb,
  output_snapshot jsonb,
  source_references jsonb not null default '[]'::jsonb,
  confidence numeric(5,2),
  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  cost numeric(12,6) not null default 0,
  latency_ms integer,
  error_code text,
  error_message text,
  requires_review boolean not null default false,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists agents.evaluations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid not null references agents.agent_definitions(id),
  run_id uuid references agents.runs(id),
  evaluation_type text not null default 'human',
  groundedness numeric(5,2) not null,
  completeness numeric(5,2) not null,
  policy_compliance numeric(5,2) not null,
  composite_score numeric(5,2) not null,
  reviewer_id uuid references platform.user_profiles(id),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists agents.budget_events (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid references agents.agent_definitions(id),
  run_id uuid references agents.runs(id),
  amount numeric(12,6) not null,
  event_type text not null check(event_type in ('reservation','actual','release','adjustment')),
  occurred_at timestamptz not null default now()
);

create index if not exists idx_agent_runs_workspace_created on agents.runs(workspace_id,created_at desc);
create index if not exists idx_agent_runs_agent_status on agents.runs(agent_id,status);
create index if not exists idx_agent_evaluations_agent on agents.evaluations(agent_id,created_at desc);

alter table agents.agent_definitions enable row level security;
alter table agents.runs enable row level security;
alter table agents.evaluations enable row level security;
alter table agents.budget_events enable row level security;

create policy agent_definitions_workspace_access on agents.agent_definitions using (platform.user_has_workspace_access(workspace_id));
create policy agent_runs_workspace_access on agents.runs using (platform.user_has_workspace_access(workspace_id));
create policy agent_evaluations_workspace_access on agents.evaluations using (platform.user_has_workspace_access(workspace_id));
create policy agent_budget_workspace_access on agents.budget_events using (platform.user_has_workspace_access(workspace_id));
