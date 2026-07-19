-- Step 41: Production launch closure and Version 1.0 certification
create table if not exists launch_blocker_closures (
  id text primary key,
  source_reference text not null,
  description text not null,
  owner text not null,
  status text not null check (status in ('open','verified','waived')),
  evidence text not null,
  verified_at timestamptz
);
create table if not exists production_releases (
  id text primary key,
  version text not null,
  environment text not null,
  strategy text not null check (strategy in ('rolling','blue_green','canary')),
  status text not null check (status in ('planned','in_progress','completed','rolled_back')),
  started_at timestamptz,
  completed_at timestamptz,
  rollback_available boolean not null default false,
  change_ticket text not null
);
create table if not exists post_launch_checks (
  id text primary key,
  release_id text references production_releases(id),
  name text not null,
  owner text not null,
  required boolean not null default true,
  status text not null check (status in ('pending','passed','failed')),
  observed_value text not null,
  threshold text not null,
  checked_at timestamptz
);
create table if not exists launch_authorizations (
  id text primary key,
  release_id text references production_releases(id),
  role text not null,
  approver text not null,
  status text not null check (status in ('pending','approved','rejected')),
  decision text not null,
  approved_at timestamptz
);
create table if not exists release_artifacts (
  id text primary key,
  release_id text references production_releases(id),
  name text not null,
  kind text not null check (kind in ('source','migration','runbook','release_notes','evidence')),
  checksum text not null,
  status text not null check (status in ('verified','missing'))
);
