export type WorkflowStatus = 'draft' | 'active' | 'paused' | 'retired';
export type WorkflowRunStatus = 'queued' | 'running' | 'waiting' | 'completed' | 'failed' | 'cancelled';
export type StepKind = 'trigger' | 'condition' | 'action' | 'agent' | 'approval' | 'delay' | 'webhook';
export type TriggerKind = 'manual' | 'schedule' | 'event' | 'webhook';

export type WorkflowDefinition = {
  id: string; name: string; owner: string; status: WorkflowStatus; version: number;
  description: string; trigger: TriggerKind; triggerConfig: string; stepCount: number;
  highRiskActions: number; approvalRequired: boolean; maxRuntimeMinutes: number;
  maxRunCostUsd: number; concurrencyLimit: number; lastPublishedAt: string | null;
};
export type WorkflowStep = {
  id: string; workflowId: string; position: number; name: string; kind: StepKind;
  handler: string; timeoutSeconds: number; retryLimit: number; onFailure: 'stop' | 'continue' | 'route';
  requiresApproval: boolean;
};
export type WorkflowRun = {
  id: string; workflowId: string; status: WorkflowRunStatus; startedAt: string;
  completedAt: string | null; currentStep: number; stepsCompleted: number; totalSteps: number;
  retries: number; costUsd: number; traceId: string; idempotencyKey: string;
};
export type WorkflowApproval = {
  id: string; runId: string; stepId: string; reviewerRole: string;
  status: 'pending' | 'approved' | 'rejected' | 'expired'; requestedAt: string;
  decidedAt: string | null; slaMinutes: number;
};
export type WorkflowSchedule = {
  id: string; workflowId: string; cron: string; timezone: string; enabled: boolean;
  nextRunAt: string; lastRunAt: string | null; misfirePolicy: 'skip' | 'run_once' | 'catch_up';
};
