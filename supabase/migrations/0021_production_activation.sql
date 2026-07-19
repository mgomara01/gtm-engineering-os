create schema if not exists activation;
create table if not exists activation.worker_queues (
  id uuid primary key default gen_random_uuid(), workspace_id uuid references platform.workspaces(id) on delete cascade,
  name text not null, status text not null check(status in ('healthy','degraded','stopped')) default 'stopped',
  max_attempts integer not null default 5 check(max_attempts between 1 and 20), dead_letter_enabled boolean not null default true,
  concurrency integer not null default 1 check(concurrency > 0), oldest_job_at timestamptz, last_heartbeat_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(workspace_id,name)
);
create table if not exists activation.worker_jobs (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  queue_id uuid not null references activation.worker_queues(id) on delete cascade, job_type text not null,
  status text not null check(status in ('queued','running','succeeded','retrying','dead_lettered','cancelled')) default 'queued',
  idempotency_key text not null, payload jsonb not null default '{}'::jsonb, attempts integer not null default 0,
  available_at timestamptz not null default now(), started_at timestamptz, completed_at timestamptz,
  error_code text, error_message text, correlation_id text, created_at timestamptz not null default now(),
  unique(workspace_id,idempotency_key)
);
create table if not exists activation.dead_letter_items (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  worker_job_id uuid not null unique references activation.worker_jobs(id) on delete cascade,
  replay_safe boolean not null default false, disposition text check(disposition in ('pending','replayed','discarded','resolved')) default 'pending',
  reviewed_by uuid references auth.users(id), reviewed_at timestamptz, review_note text, snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists activation.consent_records (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  subject text not null, channel text not null check(channel in ('email','sms','phone','linkedin','direct_mail')),
  state text not null check(state in ('granted','denied','unknown','expired')), source text not null,
  evidence jsonb not null default '{}'::jsonb, verified_at timestamptz, expires_at timestamptz, revoked_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists activation.suppressions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  subject text not null, channel text not null check(channel in ('email','sms','phone','linkedin','direct_mail','all')),
  reason text not null, active boolean not null default true, source text, created_by uuid references auth.users(id),
  created_at timestamptz not null default now(), lifted_at timestamptz
);
create table if not exists activation.activation_events (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id) on delete cascade,
  prior_mode text check(prior_mode in ('inactive','shadow','limited','active','paused')),
  new_mode text not null check(new_mode in ('inactive','shadow','limited','active','paused')),
  reason text not null, readiness_snapshot jsonb not null default '{}'::jsonb, approved_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists worker_jobs_queue_status_idx on activation.worker_jobs(queue_id,status,available_at);
create index if not exists consent_lookup_idx on activation.consent_records(workspace_id,subject,channel,state);
create index if not exists suppression_lookup_idx on activation.suppressions(workspace_id,subject,channel) where active;
alter table activation.worker_queues enable row level security;
alter table activation.worker_jobs enable row level security;
alter table activation.dead_letter_items enable row level security;
alter table activation.consent_records enable row level security;
alter table activation.suppressions enable row level security;
alter table activation.activation_events enable row level security;
create policy activation_queue_access on activation.worker_queues for all using (workspace_id is null or platform.user_has_workspace_access(workspace_id));
create policy activation_job_access on activation.worker_jobs for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_dlq_access on activation.dead_letter_items for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_consent_access on activation.consent_records for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_suppression_access on activation.suppressions for all using (platform.user_has_workspace_access(workspace_id));
create policy activation_event_access on activation.activation_events for select using (platform.user_has_workspace_access(workspace_id));
