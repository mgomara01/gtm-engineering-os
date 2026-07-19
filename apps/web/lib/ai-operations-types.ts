export type AgentRisk = 'low' | 'medium' | 'high' | 'critical';
export type AgentStatus = 'draft' | 'evaluation' | 'active' | 'paused' | 'retired';
export type RunStatus = 'queued' | 'running' | 'completed' | 'failed' | 'blocked';
export type ReviewDecision = 'pending' | 'approved' | 'rejected' | 'escalated';

export type AgentDefinition = {
  id: string; name: string; owner: string; status: AgentStatus; risk: AgentRisk;
  model: string; version: string; purpose: string; toolScopes: string[];
  humanApprovalRequired: boolean; maxCostUsd: number; evaluationScore: number;
  lastEvaluatedAt: string; nextReviewAt: string;
};
export type AgentRun = {
  id: string; agentId: string; workspaceId: string; status: RunStatus; startedAt: string;
  completedAt: string | null; tokensIn: number; tokensOut: number; costUsd: number;
  latencyMs: number; retries: number; guardrailEvents: number; traceId: string;
};
export type GuardrailPolicy = {
  id: string; name: string; category: 'data' | 'security' | 'quality' | 'financial' | 'action';
  owner: string; enabled: boolean; enforcement: 'monitor' | 'block' | 'require_approval';
  triggeredRuns: number; falsePositiveRate: number; lastTestedAt: string;
};
export type HumanReview = {
  id: string; runId: string; reviewer: string; decision: ReviewDecision; reason: string;
  requestedAt: string; decidedAt: string | null; slaMinutes: number;
};
export type ModelProvider = {
  id: string; provider: string; model: string; region: string; approvedUse: string[];
  dataRetention: 'none' | 'limited' | 'standard'; status: 'approved' | 'restricted' | 'disabled';
  unitCostInput: number; unitCostOutput: number; availabilityPct: number;
};
