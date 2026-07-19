-- Step 32: Workflow automation and orchestration
create table if not exists workflow_definitions (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null, name text not null,
 owner_user_id uuid, status text not null check (status in ('draft','active','paused','retired')),
 version integer not null default 1, description text not null default '', trigger_kind text not null,
 trigger_config jsonb not null default '{}'::jsonb, max_runtime_minutes integer not null default 60,
 max_run_cost_usd numeric(12,4) not null default 0, concurrency_limit integer not null default 1,
 approval_required boolean not null default false, published_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists workflow_steps (
 id uuid primary key default gen_random_uuid(), workflow_id uuid not null references workflow_definitions(id) on delete cascade,
 position integer not null, name text not null, kind text not null, handler text not null, config jsonb not null default '{}'::jsonb,
 timeout_seconds integer not null default 60, retry_limit integer not null default 0, on_failure text not null default 'stop',
 requires_approval boolean not null default false, unique(workflow_id, position)
);
create table if not exists workflow_runs (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null, workflow_id uuid not null references workflow_definitions(id),
 workflow_version integer not null, status text not null, current_step integer not null default 0, steps_completed integer not null default 0,
 total_steps integer not null, retries integer not null default 0, cost_usd numeric(12,4) not null default 0,
 trace_id text not null unique, idempotency_key text not null, input jsonb not null default '{}'::jsonb,
 output jsonb, error jsonb, started_at timestamptz not null default now(), completed_at timestamptz,
 unique(workspace_id, workflow_id, idempotency_key)
);
create table if not exists workflow_approvals (
 id uuid primary key default gen_random_uuid(), workflow_run_id uuid not null references workflow_runs(id) on delete cascade,
 workflow_step_id uuid references workflow_steps(id), reviewer_role text not null, status text not null default 'pending',
 reason text, sla_minutes integer not null default 60, requested_at timestamptz not null default now(), decided_at timestamptz, decided_by uuid
);
create table if not exists workflow_schedules (
 id uuid primary key default gen_random_uuid(), workflow_id uuid not null references workflow_definitions(id) on delete cascade,
 cron_expression text not null, timezone text not null default 'UTC', enabled boolean not null default true,
 next_run_at timestamptz not null, last_run_at timestamptz, misfire_policy text not null default 'skip'
);
create index if not exists workflow_runs_workspace_status_idx on workflow_runs(workspace_id,status,started_at desc);
create index if not exists workflow_approvals_status_idx on workflow_approvals(status,requested_at);
alter table workflow_definitions enable row level security;
alter table workflow_runs enable row level security;
alter table workflow_approvals enable row level security;
alter table workflow_schedules enable row level security;
