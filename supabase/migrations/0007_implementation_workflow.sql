create table implementation.implementation_plans (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  configuration_version_id uuid references configuration.workspace_configuration_versions(id),
  name text not null,
  status text not null default 'draft' check(status in ('draft','active','complete','archived')),
  created_by uuid references platform.user_profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table implementation.implementation_stages (
  id uuid primary key default gen_random_uuid(),
  implementation_plan_id uuid not null references implementation.implementation_plans(id) on delete cascade,
  stage_number integer not null check(stage_number between 1 and 12),
  name text not null,
  objective text not null,
  status text not null default 'not_started' check(status in ('not_started','active','blocked','complete')),
  completion_percentage numeric(5,2) not null default 0 check(completion_percentage between 0 and 100),
  assigned_owner_user_id uuid references platform.user_profiles(id),
  target_date date,
  approved_by uuid references platform.user_profiles(id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(implementation_plan_id,stage_number)
);

create table implementation.stage_requirements (
  id uuid primary key default gen_random_uuid(),
  implementation_stage_id uuid not null references implementation.implementation_stages(id) on delete cascade,
  requirement_type text not null check(requirement_type in ('input','deliverable','approval','completion_rule')),
  title text not null,
  description text,
  required boolean not null default true,
  status text not null default 'not_started' check(status in ('not_started','in_progress','complete','waived')),
  completed_by uuid references platform.user_profiles(id),
  completed_at timestamptz,
  sort_order integer not null default 0
);

create table implementation.decisions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  implementation_stage_id uuid references implementation.implementation_stages(id) on delete cascade,
  title text not null,
  decision_required text not null,
  recommendation text,
  final_decision text,
  owner_user_id uuid references platform.user_profiles(id),
  due_date date,
  status text not null default 'open' check(status in ('open','approved','deferred')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table implementation.risks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  implementation_stage_id uuid references implementation.implementation_stages(id) on delete cascade,
  title text not null,
  description text not null,
  category text not null,
  probability text not null check(probability in ('low','medium','high')),
  impact text not null check(impact in ('low','medium','high')),
  mitigation text,
  owner_user_id uuid references platform.user_profiles(id),
  status text not null default 'open' check(status in ('open','monitoring','accepted','resolved')),
  target_resolution date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table implementation.readiness_assessments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  implementation_stage_id uuid not null references implementation.implementation_stages(id) on delete cascade,
  readiness_category text not null,
  score numeric(5,2) not null check(score between 0 and 100),
  status text not null,
  assessment_details jsonb not null default '{}'::jsonb,
  assessed_by uuid references platform.user_profiles(id),
  assessed_at timestamptz not null default now()
);

create or replace view implementation.stage_dashboard
with (security_invoker=true) as
select
  p.workspace_id,
  s.id,
  s.stage_number,
  s.name,
  s.objective,
  s.status,
  s.completion_percentage,
  s.target_date,
  u.display_name as owner_name,
  count(sr.id) filter (where sr.requirement_type='deliverable' and sr.status in ('complete','waived')) as deliverables_complete,
  count(sr.id) filter (where sr.requirement_type='deliverable' and sr.required=true) as deliverables_required,
  count(distinct d.id) filter (where d.status='open') as open_decisions,
  count(distinct r.id) filter (where r.status in ('open','monitoring')) as open_risks,
  coalesce(avg(ra.score),0) as readiness_score
from implementation.implementation_plans p
join implementation.implementation_stages s on s.implementation_plan_id=p.id
left join platform.user_profiles u on u.id=s.assigned_owner_user_id
left join implementation.stage_requirements sr on sr.implementation_stage_id=s.id
left join implementation.decisions d on d.implementation_stage_id=s.id
left join implementation.risks r on r.implementation_stage_id=s.id
left join implementation.readiness_assessments ra on ra.implementation_stage_id=s.id
where p.status='active'
group by p.workspace_id,s.id,u.display_name;

grant select on implementation.stage_dashboard to authenticated;

create or replace view platform.user_workspace_access
with (security_invoker=true) as
select
  uwr.user_id,
  w.id as workspace_id,
  w.name,
  w.code,
  w.status,
  r.code::text as role_code,
  coalesce(ip.current_stage, 1) as current_stage
from platform.user_workspace_roles uwr
join platform.workspaces w on w.id=uwr.workspace_id
join platform.roles r on r.id=uwr.role_id
left join lateral (
  select min(s.stage_number) filter (where s.status in ('active','blocked')) as current_stage
  from implementation.implementation_plans p
  join implementation.implementation_stages s on s.implementation_plan_id=p.id
  where p.workspace_id=w.id and p.status='active'
) ip on true
where uwr.active=true;

grant select on platform.user_workspace_access to authenticated;


alter table implementation.implementation_plans enable row level security;
alter table implementation.implementation_stages enable row level security;
alter table implementation.stage_requirements enable row level security;
alter table implementation.decisions enable row level security;
alter table implementation.risks enable row level security;
alter table implementation.readiness_assessments enable row level security;

create policy implementation_plan_access on implementation.implementation_plans for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));
create policy implementation_stage_access on implementation.implementation_stages for all using(exists(select 1 from implementation.implementation_plans p where p.id=implementation_plan_id and platform.user_has_workspace_access(p.workspace_id))) with check(exists(select 1 from implementation.implementation_plans p where p.id=implementation_plan_id and platform.user_has_workspace_access(p.workspace_id)));
create policy stage_requirement_access on implementation.stage_requirements for all using(exists(select 1 from implementation.implementation_stages s join implementation.implementation_plans p on p.id=s.implementation_plan_id where s.id=implementation_stage_id and platform.user_has_workspace_access(p.workspace_id))) with check(exists(select 1 from implementation.implementation_stages s join implementation.implementation_plans p on p.id=s.implementation_plan_id where s.id=implementation_stage_id and platform.user_has_workspace_access(p.workspace_id)));
create policy decision_access on implementation.decisions for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));
create policy risk_access on implementation.risks for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));
create policy readiness_access on implementation.readiness_assessments for all using(platform.user_has_workspace_access(workspace_id)) with check(platform.user_has_workspace_access(workspace_id));
