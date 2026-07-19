create schema if not exists reliability;

create table if not exists reliability.services(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id),
  service_key text not null unique,
  name text not null,
  owner_user_id uuid,
  owner_team text not null,
  tier int not null check(tier between 0 and 3),
  status text not null check(status in('operational','degraded','outage','maintenance')) default 'operational',
  runbook_url text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists reliability.service_dependencies(
  service_id uuid not null references reliability.services(id) on delete cascade,
  depends_on_service_id uuid not null references reliability.services(id) on delete cascade,
  critical boolean not null default true,
  primary key(service_id,depends_on_service_id),
  check(service_id <> depends_on_service_id)
);

create table if not exists reliability.service_level_objectives(
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references reliability.services(id) on delete cascade,
  name text not null,
  target_percent numeric(7,4) not null check(target_percent > 0 and target_percent <= 100),
  window_days int not null check(window_days > 0),
  indicator_query text not null,
  approved_by uuid,
  approved_at timestamptz,
  active boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists reliability.slo_measurements(
  id uuid primary key default gen_random_uuid(),
  objective_id uuid not null references reliability.service_level_objectives(id) on delete cascade,
  period_start timestamptz not null,
  period_end timestamptz not null,
  good_events bigint not null check(good_events >= 0),
  total_events bigint not null check(total_events >= good_events),
  source_reference text not null,
  measured_at timestamptz not null default now(),
  unique(objective_id,period_start,period_end)
);

create table if not exists reliability.incidents(
  id uuid primary key default gen_random_uuid(),
  incident_number text not null unique,
  workspace_id uuid references platform.workspaces(id),
  title text not null,
  severity text not null check(severity in('sev1','sev2','sev3','sev4')),
  status text not null check(status in('investigating','identified','monitoring','resolved')),
  commander_user_id uuid,
  customer_impact text not null,
  started_at timestamptz not null,
  identified_at timestamptz,
  resolved_at timestamptz,
  next_update_at timestamptz,
  postmortem_due_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists reliability.incident_services(
  incident_id uuid not null references reliability.incidents(id) on delete cascade,
  service_id uuid not null references reliability.services(id),
  primary key(incident_id,service_id)
);

create table if not exists reliability.incident_updates(
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references reliability.incidents(id) on delete cascade,
  status text not null,
  internal_note text not null,
  public_message text,
  author_user_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists reliability.feature_flags(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id),
  flag_key text not null,
  description text not null,
  environment text not null check(environment in('staging','production')),
  status text not null check(status in('draft','active','paused','retired')) default 'draft',
  rollout_percent numeric(5,2) not null check(rollout_percent between 0 and 100) default 0,
  owner_user_id uuid,
  kill_switch boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,flag_key,environment)
);

create table if not exists reliability.maintenance_windows(
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references reliability.services(id),
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null check(status in('scheduled','in_progress','completed','cancelled')) default 'scheduled',
  customer_message text,
  approved_by uuid,
  created_at timestamptz not null default now(),
  check(ends_at > starts_at)
);

alter table reliability.services enable row level security;
alter table reliability.service_level_objectives enable row level security;
alter table reliability.incidents enable row level security;
alter table reliability.incident_updates enable row level security;
alter table reliability.feature_flags enable row level security;
alter table reliability.maintenance_windows enable row level security;

create policy services_workspace_access on reliability.services for all using (workspace_id is null or platform.is_workspace_member(workspace_id));
create policy incidents_workspace_access on reliability.incidents for all using (workspace_id is null or platform.is_workspace_member(workspace_id));
create policy feature_flags_workspace_access on reliability.feature_flags for all using (workspace_id is null or platform.is_workspace_member(workspace_id));
