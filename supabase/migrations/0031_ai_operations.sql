-- Step 31: governed AI operations and autonomous-agent control plane
create table if not exists public.ai_agent_definitions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, owner text not null, status text not null check (status in ('draft','evaluation','active','paused','retired')),
  risk text not null check (risk in ('low','medium','high','critical')), model text not null, version text not null,
  purpose text not null, tool_scopes text[] not null default '{}', human_approval_required boolean not null default false,
  max_cost_usd numeric(12,4) not null default 0, evaluation_score numeric(5,2) not null default 0,
  last_evaluated_at timestamptz, next_review_at timestamptz not null, created_at timestamptz not null default now()
);
create table if not exists public.ai_agent_runs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  agent_id uuid not null references public.ai_agent_definitions(id) on delete cascade, status text not null,
  started_at timestamptz not null default now(), completed_at timestamptz, tokens_in bigint not null default 0,
  tokens_out bigint not null default 0, cost_usd numeric(12,4) not null default 0, latency_ms bigint not null default 0,
  retries integer not null default 0, guardrail_events integer not null default 0, trace_id text not null unique,
  input_digest text, output_digest text, error_code text
);
create table if not exists public.ai_guardrail_policies (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null, category text not null check (category in ('data','security','quality','financial','action')),
  owner text not null, enabled boolean not null default true, enforcement text not null check (enforcement in ('monitor','block','require_approval')),
  policy_config jsonb not null default '{}', last_tested_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.ai_human_reviews (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  run_id uuid not null references public.ai_agent_runs(id) on delete cascade, reviewer_id uuid references auth.users(id),
  decision text not null default 'pending' check (decision in ('pending','approved','rejected','escalated')),
  reason text not null, requested_at timestamptz not null default now(), decided_at timestamptz, sla_minutes integer not null default 60
);
create table if not exists public.ai_model_providers (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  provider text not null, model text not null, region text not null, approved_use text[] not null default '{}',
  data_retention text not null check (data_retention in ('none','limited','standard')),
  status text not null check (status in ('approved','restricted','disabled')), unit_cost_input numeric(12,6) not null default 0,
  unit_cost_output numeric(12,6) not null default 0, availability_pct numeric(5,2), created_at timestamptz not null default now(),
  unique(workspace_id, provider, model)
);
create index if not exists idx_ai_runs_workspace_started on public.ai_agent_runs(workspace_id, started_at desc);
create index if not exists idx_ai_reviews_pending on public.ai_human_reviews(workspace_id, decision, requested_at);
alter table public.ai_agent_definitions enable row level security;
alter table public.ai_agent_runs enable row level security;
alter table public.ai_guardrail_policies enable row level security;
alter table public.ai_human_reviews enable row level security;
alter table public.ai_model_providers enable row level security;
