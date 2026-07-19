create schema if not exists developer;

create table if not exists developer.service_accounts(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id),
  name text not null,
  owner_user_id uuid,
  status text not null check(status in('active','suspended','revoked')) default 'active',
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz
);

create table if not exists developer.api_credentials(
  id uuid primary key default gen_random_uuid(),
  service_account_id uuid not null references developer.service_accounts(id) on delete cascade,
  key_prefix text not null unique,
  secret_hash text not null,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz
);

create table if not exists developer.api_scopes(
  scope_key text primary key,
  label text not null,
  risk_level text not null check(risk_level in('low','medium','high'))
);

create table if not exists developer.service_account_scopes(
  service_account_id uuid not null references developer.service_accounts(id) on delete cascade,
  scope_key text not null references developer.api_scopes(scope_key),
  approved_by uuid,
  approved_at timestamptz,
  primary key(service_account_id,scope_key)
);

create table if not exists developer.rate_limit_policies(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references platform.workspaces(id),
  service_account_id uuid references developer.service_accounts(id),
  window_seconds int not null check(window_seconds>0),
  request_limit int not null check(request_limit>0),
  burst_limit int not null check(burst_limit>=request_limit),
  created_at timestamptz not null default now(),
  check ((workspace_id is not null) or (service_account_id is not null))
);

create table if not exists developer.api_request_logs(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id),
  service_account_id uuid references developer.service_accounts(id),
  request_id text not null unique,
  method text not null,
  path text not null,
  response_code int not null,
  latency_ms int not null check(latency_ms>=0),
  idempotency_key_hash text,
  occurred_at timestamptz not null default now()
);

create table if not exists developer.webhook_endpoints(
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references platform.workspaces(id),
  name text not null,
  url text not null,
  signing_secret_hash text not null,
  status text not null check(status in('active','paused','failing')) default 'active',
  created_at timestamptz not null default now()
);

create table if not exists developer.webhook_subscriptions(
  endpoint_id uuid not null references developer.webhook_endpoints(id) on delete cascade,
  event_type text not null,
  primary key(endpoint_id,event_type)
);

create table if not exists developer.webhook_deliveries(
  id uuid primary key default gen_random_uuid(),
  endpoint_id uuid not null references developer.webhook_endpoints(id) on delete cascade,
  event_id uuid not null,
  event_type text not null,
  payload_hash text not null,
  status text not null check(status in('pending','delivered','retrying','failed')) default 'pending',
  attempt int not null default 0,
  response_code int,
  latency_ms int,
  next_attempt_at timestamptz,
  created_at timestamptz not null default now(),
  delivered_at timestamptz,
  unique(endpoint_id,event_id)
);

create table if not exists developer.idempotency_records(
  workspace_id uuid not null references platform.workspaces(id),
  service_account_id uuid not null references developer.service_accounts(id),
  key_hash text not null,
  request_hash text not null,
  response_code int,
  response_reference text,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  primary key(workspace_id,service_account_id,key_hash)
);

alter table developer.service_accounts enable row level security;
alter table developer.api_request_logs enable row level security;
alter table developer.webhook_endpoints enable row level security;
alter table developer.webhook_deliveries enable row level security;
alter table developer.idempotency_records enable row level security;
