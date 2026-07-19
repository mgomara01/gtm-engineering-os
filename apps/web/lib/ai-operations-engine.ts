import type { AgentDefinition, AgentRun, GuardrailPolicy, HumanReview, ModelProvider } from './ai-operations-types';

export function agentReviewOverdue(agent: AgentDefinition, now = new Date()) {
  return !['retired'].includes(agent.status) && new Date(agent.nextReviewAt).getTime() < now.getTime();
}
export function agentReadyForProduction(agent: AgentDefinition, now = new Date()) {
  return agent.status === 'active' && agent.evaluationScore >= 85 && !agentReviewOverdue(agent, now) && agent.toolScopes.length > 0;
}
export function runSuccessRate(runs: AgentRun[]) {
  if (!runs.length) return 0;
  return Number((runs.filter(r => r.status === 'completed').length / runs.length * 100).toFixed(1));
}
export function averageRunCost(runs: AgentRun[]) {
  if (!runs.length) return 0;
  return Number((runs.reduce((s, r) => s + r.costUsd, 0) / runs.length).toFixed(4));
}
export function reviewOverdue(review: HumanReview, now = new Date()) {
  if (review.decision !== 'pending') return false;
  return new Date(review.requestedAt).getTime() + review.slaMinutes * 60_000 < now.getTime();
}
export function guardrailCoverage(policies: GuardrailPolicy[]) {
  const required = ['data', 'security', 'quality', 'financial', 'action'];
  return Number((required.filter(category => policies.some(p => p.category === category && p.enabled)).length / required.length * 100).toFixed(1));
}
export function approvedModelCoverage(providers: ModelProvider[]) {
  if (!providers.length) return 0;
  return Number((providers.filter(p => p.status === 'approved').length / providers.length * 100).toFixed(1));
}
export function aiOperationalReadiness(agents: AgentDefinition[], runs: AgentRun[], policies: GuardrailPolicy[], reviews: HumanReview[], providers: ModelProvider[], now = new Date()) {
  const agentScore = agents.length ? agents.filter(a => agentReadyForProduction(a, now)).length / agents.length : 0;
  const reliabilityScore = runSuccessRate(runs) / 100;
  const guardrailScore = guardrailCoverage(policies) / 100;
  const reviewScore = reviews.length ? reviews.filter(r => !reviewOverdue(r, now)).length / reviews.length : 1;
  const providerScore = approvedModelCoverage(providers) / 100;
  return Number(((agentScore + reliabilityScore + guardrailScore + reviewScore + providerScore) / 5 * 100).toFixed(1));
}
