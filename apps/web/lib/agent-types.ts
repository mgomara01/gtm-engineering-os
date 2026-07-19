export type AgentStatus='draft'|'active'|'paused'|'retired';
export type RunStatus='queued'|'running'|'succeeded'|'failed'|'needs_review'|'cancelled';
export type RiskLevel='low'|'medium'|'high';
export interface AgentDefinition{id:string;workspaceId:string;name:string;purpose:string;status:AgentStatus;ownerRole:string;provider:string;model:string;activeVersion:number;approvalPolicy:'none'|'sampled'|'required';riskLevel:RiskLevel;monthlyBudget:number;monthToDateCost:number;successRate:number;}
export interface AgentVersion{id:string;agentId:string;version:number;systemPrompt:string;inputSchema:Record<string,string>;outputSchema:Record<string,string>;temperature:number;maxTokens:number;createdAt:string;createdBy:string;status:'draft'|'approved'|'retired';}
export interface AgentRun{id:string;workspaceId:string;agentId:string;agentName:string;version:number;status:RunStatus;startedAt:string;completedAt?:string;entityName?:string;inputTokens:number;outputTokens:number;cost:number;latencyMs:number;confidence:number;requiresReview:boolean;error?:string;}
export interface Evaluation{id:string;agentId:string;runId:string;score:number;groundedness:number;completeness:number;policyCompliance:number;reviewer:string;reviewedAt:string;notes:string;}
export interface AgentBudgetSummary{budget:number;spent:number;remaining:number;utilization:number;projected:number;status:'on_track'|'watch'|'exceeded';}
