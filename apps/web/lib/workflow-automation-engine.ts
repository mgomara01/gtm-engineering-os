import type { WorkflowApproval, WorkflowDefinition, WorkflowRun, WorkflowSchedule } from './workflow-automation-types';

export function workflowReadyForActivation(workflow: WorkflowDefinition) {
  return workflow.status === 'active' && workflow.stepCount > 1 && workflow.maxRuntimeMinutes > 0 && workflow.concurrencyLimit > 0 && workflow.maxRunCostUsd >= 0 && (!workflow.highRiskActions || workflow.approvalRequired);
}
export function workflowSuccessRate(runs: WorkflowRun[]) {
  if (!runs.length) return 0;
  return Number((runs.filter(run => run.status === 'completed').length / runs.length * 100).toFixed(1));
}
export function averageWorkflowDurationMinutes(runs: WorkflowRun[]) {
  const completed = runs.filter(run => run.completedAt);
  if (!completed.length) return 0;
  return Number((completed.reduce((sum, run) => sum + (new Date(run.completedAt!).getTime() - new Date(run.startedAt).getTime()) / 60000, 0) / completed.length).toFixed(1));
}
export function approvalOverdue(approval: WorkflowApproval, now = new Date()) {
  return approval.status === 'pending' && new Date(approval.requestedAt).getTime() + approval.slaMinutes * 60000 < now.getTime();
}
export function scheduleHealthy(schedule: WorkflowSchedule, now = new Date()) {
  if (!schedule.enabled) return true;
  return new Date(schedule.nextRunAt).getTime() > now.getTime() && (!schedule.lastRunAt || new Date(schedule.lastRunAt).getTime() <= now.getTime());
}
export function automationReadiness(workflows: WorkflowDefinition[], runs: WorkflowRun[], approvals: WorkflowApproval[], schedules: WorkflowSchedule[], now = new Date()) {
  const definitionScore = workflows.length ? workflows.filter(workflowReadyForActivation).length / workflows.length : 0;
  const executionScore = workflowSuccessRate(runs) / 100;
  const approvalScore = approvals.length ? approvals.filter(a => !approvalOverdue(a, now)).length / approvals.length : 1;
  const scheduleScore = schedules.length ? schedules.filter(s => scheduleHealthy(s, now)).length / schedules.length : 1;
  return Number(((definitionScore + executionScore + approvalScore + scheduleScore) / 4 * 100).toFixed(1));
}
export function activeConcurrency(runs: WorkflowRun[]) {
  return runs.filter(run => ['queued','running','waiting'].includes(run.status)).length;
}
