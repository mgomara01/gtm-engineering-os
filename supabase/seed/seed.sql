insert into platform.roles(code,name,description) values
('executive_sponsor','Executive Sponsor','Approves strategic configuration and stage gates'),
('gtm_administrator','GTM Administrator','Administers workspace configuration and implementation'),
('gtm_engineer','GTM Engineer','Builds data, scoring, research, and playbooks'),
('sales_manager','Sales Manager','Manages pipeline, assignments, and execution'),
('sales_user','Sales User','Works assigned accounts, tasks, and opportunities'),
('analyst','Analyst','Reviews analytics, quality, and performance'),
('technical_administrator','Technical Administrator','Manages integrations and production operations'),
('viewer','Viewer','Read-only workspace access')
on conflict(code) do nothing;

insert into platform.permissions(code,name) values
('workspace.view','View workspace'),('workspace.configure','Configure workspace'),('workspace.approve','Approve workspace'),
('implementation.manage','Manage implementation'),('implementation.approve','Approve implementation stages'),
('entity.edit','Edit entities'),('score.configure','Configure scoring'),('agent.execute','Execute AI agents'),
('campaign.launch','Launch campaigns'),('integration.manage','Manage integrations')
on conflict(code) do nothing;

insert into platform.workspaces(id,name,code,legal_entity_name,workspace_type,status)
values
('11111111-1111-1111-1111-111111111111','Alvarez Growth Intelligence','ALV','Alvarez Plumbing & Air Conditioning','operating_company','planning'),
('22222222-2222-2222-2222-222222222222','Intelligent Waterflow','IWF','Intelligent Waterflow','product_line','planning')
on conflict(code) do nothing;

insert into configuration.workspace_configuration_versions(id,workspace_id,version_number,status,change_summary)
values
('aaaaaaaa-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111',1,'active','Initial Alvarez workspace configuration'),
('aaaaaaaa-2222-2222-2222-222222222222','22222222-2222-2222-2222-222222222222',1,'draft','Initial Intelligent Waterflow workspace configuration')
on conflict(workspace_id,version_number) do nothing;

update platform.workspaces set active_configuration_version_id='aaaaaaaa-1111-1111-1111-111111111111' where id='11111111-1111-1111-1111-111111111111';

insert into implementation.implementation_plans(id,workspace_id,configuration_version_id,name,status)
values('bbbbbbbb-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111','aaaaaaaa-1111-1111-1111-111111111111','Alvarez GTM Implementation','active')
on conflict(id) do nothing;

with stage_data(stage_number,name,objective,status,completion) as (values
(1,'Business Definition','Define the commercial model, strategic objective, and growth hypothesis.','complete',100),
(2,'ICP Design','Approve target-account definitions, buyer personas, and exclusions.','complete',100),
(3,'Data Strategy','Specify sources, mappings, ownership, lineage, and refresh rules.','active',55),
(4,'Market Universe','Build the complete addressable account and property universe.','not_started',0),
(5,'Enrichment','Complete required firmographic, property, and contact fields.','not_started',0),
(6,'Scoring','Validate and activate explainable prioritization models.','not_started',0),
(7,'Offer Design','Approve segment-specific offers, economics, and proof points.','not_started',0),
(8,'Playbook Design','Translate strategy into controlled sequences and handoffs.','not_started',0),
(9,'Pilot','Execute a bounded pilot with explicit success and stop criteria.','not_started',0),
(10,'Measurement','Reconcile execution, pipeline, economics, and data quality.','not_started',0),
(11,'Optimization','Revise weak assumptions, rules, offers, and workflows.','not_started',0),
(12,'Scaling','Expand proven plays with governance and operating capacity.','not_started',0))
insert into implementation.implementation_stages(implementation_plan_id,stage_number,name,objective,status,completion_percentage)
select 'bbbbbbbb-1111-1111-1111-111111111111',stage_number,name,objective,status,completion from stage_data
on conflict(implementation_plan_id,stage_number) do nothing;
