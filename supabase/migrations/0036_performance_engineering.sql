-- Step 36: performance engineering, capacity planning, and scalability
create table if not exists public.performance_services (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  service_key text not null, name text not null, owner text not null, workload_tier text not null check (workload_tier in ('interactive','background','batch','analytics')),
  monthly_requests bigint not null default 0, p95_latency_ms integer not null default 0, latency_budget_ms integer not null,
  error_rate_pct numeric(8,4) not null default 0, capacity_status text not null check (capacity_status in ('healthy','watch','critical')),
  cpu_utilization_pct numeric(5,2), memory_utilization_pct numeric(5,2), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(workspace_id,service_key)
);
create table if not exists public.performance_load_tests (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  performance_service_id uuid not null references public.performance_services(id) on delete cascade, scenario text not null,
  status text not null check(status in ('planned','running','passed','failed')), target_rps integer not null, achieved_rps integer not null default 0,
  p95_latency_ms integer not null default 0, error_rate_pct numeric(8,4) not null default 0, executed_at timestamptz, release_gate boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.capacity_forecasts (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  performance_service_id uuid not null references public.performance_services(id) on delete cascade, forecast_period text not null,
  projected_requests bigint not null, projected_peak_rps integer not null, headroom_pct numeric(5,2) not null,
  confidence_pct numeric(5,2) not null, recommended_action text not null, created_at timestamptz not null default now()
);
create table if not exists public.scaling_policies (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  performance_service_id uuid not null references public.performance_services(id) on delete cascade,
  scaling_mode text not null check(scaling_mode in ('manual','scheduled','reactive','predictive')), min_instances integer not null,
  max_instances integer not null, target_cpu_pct numeric(5,2) not null, scale_out_cooldown_seconds integer not null,
  scale_in_cooldown_seconds integer not null, enabled boolean not null default true, updated_at timestamptz not null default now()
);
create table if not exists public.performance_budgets (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id) on delete cascade,
  route text not null, metric text not null check(metric in ('lcp','inp','cls','server_latency','bundle_size')),
  budget numeric(12,2) not null, current_value numeric(12,2) not null, unit text not null, blocking boolean not null default false,
  unique(workspace_id,route,metric)
);
alter table public.performance_services enable row level security;
alter table public.performance_load_tests enable row level security;
alter table public.capacity_forecasts enable row level security;
alter table public.scaling_policies enable row level security;
alter table public.performance_budgets enable row level security;
create policy "workspace performance services" on public.performance_services for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace performance tests" on public.performance_load_tests for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace capacity forecasts" on public.capacity_forecasts for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace scaling policies" on public.scaling_policies for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "workspace performance budgets" on public.performance_budgets for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
