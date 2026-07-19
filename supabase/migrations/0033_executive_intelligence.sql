create table if not exists executive_metrics (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references workspaces(id) on delete cascade,
  metric_key text not null, name text not null, category text not null, value numeric not null, unit text not null,
  target numeric, prior_value numeric, owner_user_id uuid, source_system text not null, as_of timestamptz not null,
  certified boolean not null default false, created_at timestamptz not null default now(), unique(workspace_id,metric_key,as_of)
);
create table if not exists forecast_scenarios (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references workspaces(id) on delete cascade,
  name text not null, horizon_months integer not null check(horizon_months>0), confidence text not null check(confidence in ('high','medium','low')),
  revenue_usd numeric not null, gross_margin_pct numeric, pipeline_coverage numeric, churn_pct numeric,
  assumptions jsonb not null default '[]'::jsonb, model_version text, created_by uuid, updated_at timestamptz not null default now()
);
create table if not exists executive_reports (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references workspaces(id) on delete cascade,
  name text not null, cadence text not null, owner_user_id uuid, audience text not null, status text not null,
  definition jsonb not null default '{}'::jsonb, delivery_channels text[] not null default '{}', next_run_at timestamptz,
  last_published_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists decision_briefs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references workspaces(id) on delete cascade,
  title text not null, decision_owner uuid, due_at timestamptz, status text not null default 'open', recommendation text,
  confidence text, supporting_metric_keys text[] not null default '{}', risk_summary text, decided_at timestamptz, created_at timestamptz not null default now()
);
alter table executive_metrics enable row level security;
alter table forecast_scenarios enable row level security;
alter table executive_reports enable row level security;
alter table decision_briefs enable row level security;
create policy executive_metrics_workspace on executive_metrics using (workspace_id in (select workspace_id from workspace_members where user_id=auth.uid()));
create policy forecast_scenarios_workspace on forecast_scenarios using (workspace_id in (select workspace_id from workspace_members where user_id=auth.uid()));
create policy executive_reports_workspace on executive_reports using (workspace_id in (select workspace_id from workspace_members where user_id=auth.uid()));
create policy decision_briefs_workspace on decision_briefs using (workspace_id in (select workspace_id from workspace_members where user_id=auth.uid()));
