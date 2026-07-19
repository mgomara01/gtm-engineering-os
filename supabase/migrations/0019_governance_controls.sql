create schema if not exists governance;

create table if not exists governance.audit_events (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), occurred_at timestamptz not null default now(), actor_id text, actor_type text not null check(actor_type in ('user','agent','integration','system')), action text not null, resource_type text not null, resource_id text not null, severity text not null default 'info' check(severity in ('info','warning','critical')), summary text not null, correlation_id text not null, ip_address inet, metadata jsonb not null default '{}'::jsonb
);
create index if not exists audit_events_workspace_time_idx on governance.audit_events(workspace_id,occurred_at desc);
create unique index if not exists audit_events_workspace_correlation_action_idx on governance.audit_events(workspace_id,correlation_id,action,resource_id);

create table if not exists governance.access_reviews (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), name text not null, scope jsonb not null default '{}'::jsonb, owner_user_id uuid, due_at timestamptz not null, status text not null check(status in ('planned','in_progress','completed','overdue')), certified_by uuid, completed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists governance.access_review_items (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), review_id uuid not null references governance.access_reviews(id) on delete cascade, principal_type text not null, principal_id text not null, role_id uuid, decision text check(decision in ('retain','remove','modify','accept_exception')), risk text not null default 'low' check(risk in ('low','medium','high')), reason text, decided_by uuid, decided_at timestamptz
);

create table if not exists governance.change_requests (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), title text not null, category text not null check(category in ('configuration','schema','integration','agent','security')), status text not null check(status in ('draft','review','approved','scheduled','deployed','rejected','rolled_back')), risk text not null check(risk in ('low','medium','high')), requested_by uuid, owner_user_id uuid, requested_at timestamptz not null default now(), scheduled_at timestamptz, approvals_required integer not null default 1 check(approvals_required>0), rollback_plan text, implementation_plan text, validation_plan text, before_snapshot jsonb, after_snapshot jsonb
);
create table if not exists governance.change_approvals (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), change_request_id uuid not null references governance.change_requests(id) on delete cascade, reviewer_id uuid not null, decision text not null check(decision in ('approved','rejected','changes_requested')), reason text, decided_at timestamptz not null default now(), unique(change_request_id,reviewer_id)
);

create table if not exists governance.retention_policies (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), data_class text not null, record_type text not null, retention_days integer not null check(retention_days>=0), disposition_action text not null check(disposition_action in ('retain','archive','anonymize','delete')), legal_hold_supported boolean not null default true, owner_role text not null, active boolean not null default true, policy_version integer not null default 1, approved_at timestamptz, unique(workspace_id,record_type,policy_version)
);
create table if not exists governance.legal_holds (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), name text not null, scope jsonb not null, reason text not null, placed_by uuid, placed_at timestamptz not null default now(), released_by uuid, released_at timestamptz
);
create table if not exists governance.disposition_runs (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), policy_id uuid not null references governance.retention_policies(id), status text not null check(status in ('planned','running','completed','failed','cancelled')), started_at timestamptz, completed_at timestamptz, records_evaluated integer not null default 0, records_disposed integer not null default 0, records_held integer not null default 0, evidence jsonb not null default '{}'::jsonb
);

create table if not exists governance.release_gates (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id), release_name text not null, gate_name text not null, category text not null, status text not null check(status in ('pass','warning','fail')), blocking boolean not null default true, owner_role text not null, evidence text, evaluated_at timestamptz not null default now(), unique(workspace_id,release_name,gate_name)
);

alter table governance.audit_events enable row level security;
alter table governance.access_reviews enable row level security;
alter table governance.access_review_items enable row level security;
alter table governance.change_requests enable row level security;
alter table governance.change_approvals enable row level security;
alter table governance.retention_policies enable row level security;
alter table governance.legal_holds enable row level security;
alter table governance.disposition_runs enable row level security;
alter table governance.release_gates enable row level security;

do $$ declare t text; begin
 foreach t in array array['audit_events','access_reviews','access_review_items','change_requests','change_approvals','retention_policies','legal_holds','disposition_runs','release_gates'] loop
  execute format('drop policy if exists workspace_member_select on governance.%I',t);
  execute format('create policy workspace_member_select on governance.%I for select using (platform.is_workspace_member(workspace_id))',t);
 end loop;
end $$;

create or replace function governance.prevent_audit_mutation() returns trigger language plpgsql as $$ begin raise exception 'audit events are immutable'; end $$;
drop trigger if exists audit_events_immutable on governance.audit_events;
create trigger audit_events_immutable before update or delete on governance.audit_events for each row execute function governance.prevent_audit_mutation();
