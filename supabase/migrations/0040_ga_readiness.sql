-- Step 40: Version 1.0 stabilization and general availability readiness
create table if not exists public.release_certifications (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  domain text not null check (domain in ('quality','security','operations','performance','compliance','enablement')),
  owner text not null,
  status text not null check (status in ('pending','passed','failed','waived')),
  evidence text not null default '',
  required boolean not null default true,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.migration_readiness (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  owner text not null,
  status text not null check (status in ('pending','passed','failed','waived')),
  dry_run_complete boolean not null default false,
  rollback_validated boolean not null default false,
  data_reconciled boolean not null default false,
  estimated_minutes integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.residual_risks (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  title text not null,
  owner text not null,
  level text not null check (level in ('critical','high','medium','low')),
  status text not null check (status in ('open','mitigated','accepted')),
  mitigation text not null default '',
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.functional_acceptances (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  function text not null check (function in ('product','engineering','security','operations','finance','customer_success')),
  owner text not null,
  status text not null check (status in ('pending','accepted','rejected')),
  notes text not null default '',
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.ga_launch_gates (
  id text primary key,
  workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  name text not null,
  owner text not null,
  required boolean not null default true,
  status text not null check (status in ('ready','at_risk','blocked')),
  evidence text not null default '',
  created_at timestamptz not null default now()
);
alter table public.release_certifications enable row level security;
alter table public.migration_readiness enable row level security;
alter table public.residual_risks enable row level security;
alter table public.functional_acceptances enable row level security;
alter table public.ga_launch_gates enable row level security;
