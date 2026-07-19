-- Step 16: KPI governance, calculation runs, management alerts, attribution and operating reviews.
create schema if not exists analytics;

create table if not exists analytics.kpi_definitions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  key text not null,
  name text not null,
  description text,
  category text not null check (category in ('implementation','data','intelligence','execution','pipeline','revenue')),
  format text not null check (format in ('number','currency','percent','days')),
  target numeric not null,
  warning_threshold numeric,
  owner_role text not null,
  cadence text not null check (cadence in ('daily','weekly','monthly','quarterly')),
  calculation_version integer not null default 1,
  calculation_definition jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,key,calculation_version)
);

create table if not exists analytics.calculation_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  period_start timestamptz not null,
  period_end timestamptz not null,
  status text not null check (status in ('queued','running','completed','failed','superseded')),
  source_snapshot jsonb not null default '{}'::jsonb,
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now()
);

create table if not exists analytics.kpi_results (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  kpi_definition_id uuid not null references analytics.kpi_definitions(id),
  calculation_run_id uuid not null references analytics.calculation_runs(id),
  period_start timestamptz not null,
  period_end timestamptz not null,
  value numeric not null,
  prior_value numeric,
  target numeric not null,
  source_status text not null check (source_status in ('partial','complete')),
  evidence jsonb not null default '[]'::jsonb,
  calculated_at timestamptz not null default now(),
  unique(kpi_definition_id,calculation_run_id)
);

create table if not exists analytics.management_alerts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  kpi_definition_id uuid references analytics.kpi_definitions(id),
  title text not null,
  description text not null,
  severity text not null check (severity in ('info','warning','critical')),
  category text not null,
  status text not null default 'open' check (status in ('open','acknowledged','resolved')),
  owner_role text not null,
  recommended_action text not null,
  detected_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  acknowledged_by uuid references platform.user_profiles(id),
  resolved_at timestamptz,
  resolution_note text
);

create table if not exists analytics.attribution_records (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  opportunity_id uuid references gtm.opportunities(id),
  campaign_id uuid references gtm.campaigns(id),
  playbook_id uuid references gtm.playbooks(id),
  offer_id uuid references gtm.offers(id),
  revenue numeric not null,
  weight numeric not null check (weight between 0 and 1),
  attributed_revenue numeric generated always as (revenue * weight) stored,
  model text not null check (model in ('first_touch','last_touch','linear','manual')),
  evidence jsonb not null default '[]'::jsonb,
  occurred_at timestamptz not null
);

create table if not exists analytics.operating_reviews (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  title text not null,
  period_start date not null,
  period_end date not null,
  status text not null default 'draft' check (status in ('draft','review','approved','published','superseded')),
  calculation_run_id uuid references analytics.calculation_runs(id),
  snapshot jsonb not null default '{}'::jsonb,
  prepared_by uuid references platform.user_profiles(id),
  approved_by uuid references platform.user_profiles(id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique(workspace_id,period_start,period_end,status)
);

create index if not exists idx_kpi_results_workspace_period on analytics.kpi_results(workspace_id,period_end desc);
create index if not exists idx_management_alerts_workspace_status on analytics.management_alerts(workspace_id,status,severity);
create index if not exists idx_attribution_workspace_date on analytics.attribution_records(workspace_id,occurred_at desc);

alter table analytics.kpi_definitions enable row level security;
alter table analytics.calculation_runs enable row level security;
alter table analytics.kpi_results enable row level security;
alter table analytics.management_alerts enable row level security;
alter table analytics.attribution_records enable row level security;
alter table analytics.operating_reviews enable row level security;

create policy kpi_definitions_workspace_access on analytics.kpi_definitions for select using (platform.user_has_workspace_access(workspace_id));
create policy calculation_runs_workspace_access on analytics.calculation_runs for select using (platform.user_has_workspace_access(workspace_id));
create policy kpi_results_workspace_access on analytics.kpi_results for select using (platform.user_has_workspace_access(workspace_id));
create policy management_alerts_workspace_access on analytics.management_alerts for select using (platform.user_has_workspace_access(workspace_id));
create policy attribution_records_workspace_access on analytics.attribution_records for select using (platform.user_has_workspace_access(workspace_id));
create policy operating_reviews_workspace_access on analytics.operating_reviews for select using (platform.user_has_workspace_access(workspace_id));
