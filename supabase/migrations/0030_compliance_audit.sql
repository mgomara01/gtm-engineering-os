create schema if not exists compliance;

create table if not exists compliance.policies (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  title text not null, owner text not null, status text not null check (status in ('draft','in_review','approved','retired')),
  version text not null, framework text not null, approved_at timestamptz, next_review_at timestamptz not null,
  acknowledgements_required integer not null default 0, acknowledgements_complete integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.obligations (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  framework text not null, citation text not null, requirement text not null, owner text not null,
  status text not null check (status in ('compliant','at_risk','non_compliant','not_applicable')),
  control_ids text[] not null default '{}', evidence_ids text[] not null default '{}',
  due_at timestamptz not null, jurisdiction text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.evidence_requests (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  title text not null, owner text not null, requested_by text not null,
  status text not null check (status in ('requested','submitted','accepted','rejected','overdue')),
  due_at timestamptz not null, submitted_at timestamptz, control_id text not null, artifact_url text,
  period_start date not null, period_end date not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.control_attestations (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  control_id text not null, control_name text not null, owner text not null, period text not null,
  attested_at timestamptz, effective boolean, exceptions integer not null default 0, reviewer text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.audit_engagements (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  name text not null, auditor text not null, framework text not null, owner text not null,
  status text not null check (status in ('planned','fieldwork','remediation','complete')),
  start_at date not null, end_at date not null, requests_open integer not null default 0,
  findings_open integer not null default 0, opinion text not null check (opinion in ('pending','clean','qualified','adverse')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists compliance.exceptions (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null,
  title text not null, control_id text not null, owner text not null,
  status text not null check (status in ('requested','approved','expired','closed')),
  risk text not null check (risk in ('critical','high','medium','low')),
  compensating_control text not null, approved_by text, expires_at timestamptz not null, remediation_plan text not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table compliance.policies enable row level security;
alter table compliance.obligations enable row level security;
alter table compliance.evidence_requests enable row level security;
alter table compliance.control_attestations enable row level security;
alter table compliance.audit_engagements enable row level security;
alter table compliance.exceptions enable row level security;

create policy "workspace compliance policies" on compliance.policies using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance obligations" on compliance.obligations using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance evidence" on compliance.evidence_requests using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance attestations" on compliance.control_attestations using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance audits" on compliance.audit_engagements using (platform.has_workspace_access(workspace_id));
create policy "workspace compliance exceptions" on compliance.exceptions using (platform.has_workspace_access(workspace_id));

create index if not exists compliance_policies_workspace_review_idx on compliance.policies(workspace_id,next_review_at);
create index if not exists compliance_obligations_workspace_due_idx on compliance.obligations(workspace_id,due_at);
create index if not exists compliance_evidence_workspace_due_idx on compliance.evidence_requests(workspace_id,due_at);
create index if not exists compliance_exceptions_workspace_expiry_idx on compliance.exceptions(workspace_id,expires_at);
