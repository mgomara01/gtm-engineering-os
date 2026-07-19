import type { WorkflowApproval, WorkflowDefinition, WorkflowRun, WorkflowSchedule, WorkflowStep } from '../workflow-automation-types';
export function getWorkflowAutomationData(){
 const workflows:WorkflowDefinition[]=[
  {id:'WF-001',name:'Qualified Account Activation',owner:'GTM Operations',status:'active',version:4,description:'Research, score, approve, and activate qualified accounts.',trigger:'event',triggerConfig:'account.score_changed',stepCount:7,highRiskActions:1,approvalRequired:true,maxRuntimeMinutes:90,maxRunCostUsd:12,concurrencyLimit:20,lastPublishedAt:'2026-07-18T14:00:00Z'},
  {id:'WF-002',name:'Weekly Executive Operating Brief',owner:'Strategy',status:'active',version:3,description:'Assemble governed metrics and produce the weekly executive brief.',trigger:'schedule',triggerConfig:'0 7 * * MON',stepCount:5,highRiskActions:0,approvalRequired:false,maxRuntimeMinutes:30,maxRunCostUsd:4,concurrencyLimit:1,lastPublishedAt:'2026-07-17T16:00:00Z'},
  {id:'WF-003',name:'Campaign Launch Control',owner:'Revenue Operations',status:'active',version:2,description:'Validate audience, content, budget, and approvals before external launch.',trigger:'manual',triggerConfig:'operator',stepCount:8,highRiskActions:2,approvalRequired:false,maxRuntimeMinutes:120,maxRunCostUsd:20,concurrencyLimit:5,lastPublishedAt:'2026-07-16T13:00:00Z'}
 ];
 const steps:WorkflowStep[]=[
  {id:'WFS-01',workflowId:'WF-001',position:1,name:'Account qualified',kind:'trigger',handler:'events.account_score',timeoutSeconds:30,retryLimit:0,onFailure:'stop',requiresApproval:false},
  {id:'WFS-02',workflowId:'WF-001',position:2,name:'Research account',kind:'agent',handler:'AGT-001',timeoutSeconds:300,retryLimit:2,onFailure:'stop',requiresApproval:false},
  {id:'WFS-03',workflowId:'WF-001',position:3,name:'Approve activation',kind:'approval',handler:'role:gtm_manager',timeoutSeconds:3600,retryLimit:0,onFailure:'route',requiresApproval:true},
  {id:'WFS-04',workflowId:'WF-001',position:4,name:'Create opportunity',kind:'action',handler:'opportunities.create',timeoutSeconds:60,retryLimit:2,onFailure:'stop',requiresApproval:false}
 ];
 const runs:WorkflowRun[]=[
  {id:'WFR-1001',workflowId:'WF-001',status:'completed',startedAt:'2026-07-18T17:00:00Z',completedAt:'2026-07-18T17:18:00Z',currentStep:7,stepsCompleted:7,totalSteps:7,retries:0,costUsd:2.18,traceId:'wftr_1001',idempotencyKey:'acct_831_v4'},
  {id:'WFR-1002',workflowId:'WF-002',status:'completed',startedAt:'2026-07-18T11:00:00Z',completedAt:'2026-07-18T11:09:00Z',currentStep:5,stepsCompleted:5,totalSteps:5,retries:1,costUsd:1.42,traceId:'wftr_1002',idempotencyKey:'brief_2026w29'},
  {id:'WFR-1003',workflowId:'WF-003',status:'waiting',startedAt:'2026-07-18T20:00:00Z',completedAt:null,currentStep:5,stepsCompleted:4,totalSteps:8,retries:0,costUsd:3.01,traceId:'wftr_1003',idempotencyKey:'campaign_q3_04'},
  {id:'WFR-1004',workflowId:'WF-001',status:'failed',startedAt:'2026-07-18T15:00:00Z',completedAt:'2026-07-18T15:06:00Z',currentStep:2,stepsCompleted:1,totalSteps:7,retries:2,costUsd:.77,traceId:'wftr_1004',idempotencyKey:'acct_799_v4'}
 ];
 const approvals:WorkflowApproval[]=[
  {id:'WFA-01',runId:'WFR-1003',stepId:'launch-approval',reviewerRole:'Revenue Operations Director',status:'pending',requestedAt:'2026-07-18T20:12:00Z',decidedAt:null,slaMinutes:60},
  {id:'WFA-02',runId:'WFR-0998',stepId:'account-approval',reviewerRole:'GTM Manager',status:'approved',requestedAt:'2026-07-18T14:00:00Z',decidedAt:'2026-07-18T14:18:00Z',slaMinutes:60}
 ];
 const schedules:WorkflowSchedule[]=[
  {id:'SCH-01',workflowId:'WF-002',cron:'0 7 * * MON',timezone:'America/New_York',enabled:true,nextRunAt:'2026-07-20T11:00:00Z',lastRunAt:'2026-07-13T11:00:00Z',misfirePolicy:'run_once'},
  {id:'SCH-02',workflowId:'WF-001',cron:'*/15 * * * *',timezone:'UTC',enabled:false,nextRunAt:'2026-07-18T23:15:00Z',lastRunAt:'2026-07-18T22:45:00Z',misfirePolicy:'skip'}
 ];
 return {workflows,steps,runs,approvals,schedules};
}
