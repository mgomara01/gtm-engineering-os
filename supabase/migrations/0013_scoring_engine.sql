create schema if not exists scoring;

create table if not exists scoring.models (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  description text,
  status text not null default 'draft' check (status in ('draft','active','retired')),
  created_by uuid references platform.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists scoring.model_versions (
  id uuid primary key default gen_random_uuid(), model_id uuid not null references scoring.models(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  version_number integer not null, status text not null default 'draft' check(status in ('draft','approved','active','retired')),
  priority_thresholds jsonb not null default '{"a":85,"b":70,"c":0}'::jsonb,
  change_summary text, approved_by uuid references platform.users(id), approved_at timestamptz,
  created_at timestamptz not null default now(), unique(model_id,version_number)
);
create table if not exists scoring.factors (
  id uuid primary key default gen_random_uuid(), model_version_id uuid not null references scoring.model_versions(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, description text, factor_key text not null, factor_kind text not null check(factor_kind in ('calculated','ai_assisted','manual')),
  weight numeric(7,4) not null default 0 check(weight>=0 and weight<=100), enabled boolean not null default true,
  hard_exclusion boolean not null default false, exclusion_reason text, display_order integer not null default 0,
  configuration jsonb not null default '{}'::jsonb, unique(model_version_id,factor_key)
);
create table if not exists scoring.rules (
  id uuid primary key default gen_random_uuid(), factor_id uuid not null references scoring.factors(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  rule_type text not null, operator text not null, comparison_value jsonb, score_value numeric(7,4),
  explanation_template text, evidence_requirement jsonb not null default '{}'::jsonb, display_order integer not null default 0
);
create table if not exists scoring.runs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  model_version_id uuid not null references scoring.model_versions(id), run_type text not null check(run_type in ('production','simulation','backfill')),
  status text not null default 'queued' check(status in ('queued','running','complete','failed','cancelled')),
  requested_by uuid references platform.users(id), entity_count integer not null default 0, started_at timestamptz, completed_at timestamptz,
  input_snapshot jsonb not null default '{}'::jsonb, error_details jsonb, created_at timestamptz not null default now()
);
create table if not exists scoring.account_scores (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  run_id uuid not null references scoring.runs(id) on delete cascade, model_version_id uuid not null references scoring.model_versions(id),
  entity_type text not null default 'organization', entity_id uuid not null, total_score numeric(7,4) not null,
  priority_tier text not null check(priority_tier in ('A','B','C','Excluded')), confidence numeric(7,4), excluded boolean not null default false,
  exclusion_reason text, input_hash text, scored_at timestamptz not null default now(),
  unique(run_id,entity_type,entity_id)
);
create table if not exists scoring.score_components (
  id uuid primary key default gen_random_uuid(), account_score_id uuid not null references scoring.account_scores(id) on delete cascade,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade, factor_id uuid not null references scoring.factors(id),
  raw_score numeric(7,4) not null, weighted_score numeric(7,4) not null, confidence numeric(7,4), explanation text not null,
  evidence_references jsonb not null default '[]'::jsonb, input_snapshot jsonb not null default '{}'::jsonb
);
create index if not exists idx_scoring_models_workspace on scoring.models(workspace_id,status);
create index if not exists idx_account_scores_entity on scoring.account_scores(workspace_id,entity_type,entity_id,scored_at desc);
create index if not exists idx_scoring_runs_workspace on scoring.runs(workspace_id,created_at desc);

alter table scoring.models enable row level security;alter table scoring.model_versions enable row level security;alter table scoring.factors enable row level security;alter table scoring.rules enable row level security;alter table scoring.runs enable row level security;alter table scoring.account_scores enable row level security;alter table scoring.score_components enable row level security;
create policy scoring_models_workspace_access on scoring.models for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_versions_workspace_access on scoring.model_versions for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_factors_workspace_access on scoring.factors for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_rules_workspace_access on scoring.rules for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy scoring_runs_workspace_access on scoring.runs for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy account_scores_workspace_access on scoring.account_scores for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
create policy score_components_workspace_access on scoring.score_components for all using (workspace_id in(select workspace_id from platform.user_workspace_roles where user_id=auth.uid() and active=true));
