-- Step 15: operational execution, approvals and opportunity control
create schema if not exists execution;
create table if not exists execution.work_items (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
 title text not null, description text, status text not null check(status in ('queued','ready','in_progress','blocked','completed','cancelled')),
 priority text not null check(priority in ('low','medium','high','critical')), owner_user_id uuid, owner_role text,
 account_id uuid, opportunity_id uuid, campaign_id uuid, playbook_step_id uuid, due_at timestamptz,
 blocked_reason text, completed_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists execution.approval_requests (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references platform.workspaces(id),
 object_type text not null, object_id uuid, object_name text not null, requested_by uuid, reviewer_role text not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected','changes_requested')),
 risk text not null default 'standard' check(risk in ('standard','elevated','high')), rationale text,
 decided_by uuid, decided_at timestamptz, decision_notes text, before_snapshot jsonb, after_snapshot jsonb,
 created_at timestamptz not null default now());
alter table gtm.opportunities add column if not exists probability numeric(5,2) default 0;
alter table gtm.opportunities add column if not exists next_action text;
alter table gtm.opportunities add column if not exists next_action_due timestamptz;
alter table gtm.opportunities add column if not exists source_type text;
alter table execution.work_items enable row level security;
alter table execution.approval_requests enable row level security;
create policy work_items_workspace_access on execution.work_items using (platform.is_workspace_member(workspace_id));
create policy approval_requests_workspace_access on execution.approval_requests using (platform.is_workspace_member(workspace_id));
create index if not exists work_items_workspace_status_idx on execution.work_items(workspace_id,status,due_at);
create index if not exists approvals_workspace_status_idx on execution.approval_requests(workspace_id,status,created_at);
