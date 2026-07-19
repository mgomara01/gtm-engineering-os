import type { AgentDefinition, AgentRun, GuardrailPolicy, HumanReview, ModelProvider } from '../ai-operations-types';
export function getAiOperationsData(){
 const agents:AgentDefinition[]=[
  {id:'AGT-001',name:'Account Research Agent',owner:'Revenue Intelligence',status:'active',risk:'medium',model:'gpt-5.6',version:'4.2',purpose:'Research and summarize target accounts.',toolScopes:['research.read','accounts.write'],humanApprovalRequired:false,maxCostUsd:2.5,evaluationScore:94,lastEvaluatedAt:'2026-07-10',nextReviewAt:'2026-10-10'},
  {id:'AGT-002',name:'Campaign Launch Agent',owner:'GTM Operations',status:'evaluation',risk:'high',model:'gpt-5.6',version:'1.8',purpose:'Prepare and launch governed campaign workflows.',toolScopes:['campaigns.write','contacts.read'],humanApprovalRequired:true,maxCostUsd:8,evaluationScore:82,lastEvaluatedAt:'2026-07-15',nextReviewAt:'2026-08-15'},
  {id:'AGT-003',name:'Executive Briefing Agent',owner:'Strategy',status:'active',risk:'low',model:'gpt-5.6',version:'3.0',purpose:'Generate weekly operating briefs from approved metrics.',toolScopes:['analytics.read'],humanApprovalRequired:false,maxCostUsd:1.5,evaluationScore:91,lastEvaluatedAt:'2026-06-30',nextReviewAt:'2026-06-30'}
 ];
 const runs:AgentRun[]=[
  {id:'RUN-1001',agentId:'AGT-001',workspaceId:'WS-ALV',status:'completed',startedAt:'2026-07-18T18:00:00Z',completedAt:'2026-07-18T18:00:28Z',tokensIn:12000,tokensOut:2300,costUsd:.82,latencyMs:28000,retries:0,guardrailEvents:0,traceId:'tr_1001'},
  {id:'RUN-1002',agentId:'AGT-002',workspaceId:'WS-ALV',status:'blocked',startedAt:'2026-07-18T19:10:00Z',completedAt:'2026-07-18T19:10:06Z',tokensIn:5600,tokensOut:400,costUsd:.31,latencyMs:6000,retries:0,guardrailEvents:1,traceId:'tr_1002'},
  {id:'RUN-1003',agentId:'AGT-003',workspaceId:'WS-ALV',status:'completed',startedAt:'2026-07-18T20:00:00Z',completedAt:'2026-07-18T20:00:18Z',tokensIn:8900,tokensOut:1800,costUsd:.64,latencyMs:18000,retries:1,guardrailEvents:0,traceId:'tr_1003'},
  {id:'RUN-1004',agentId:'AGT-001',workspaceId:'WS-ALV',status:'failed',startedAt:'2026-07-18T21:00:00Z',completedAt:'2026-07-18T21:00:42Z',tokensIn:15000,tokensOut:900,costUsd:.91,latencyMs:42000,retries:2,guardrailEvents:0,traceId:'tr_1004'}
 ];
 const policies:GuardrailPolicy[]=[
  {id:'GRD-01',name:'Restricted data egress',category:'data',owner:'Privacy Operations',enabled:true,enforcement:'block',triggeredRuns:2,falsePositiveRate:0,lastTestedAt:'2026-07-12'},
  {id:'GRD-02',name:'Privileged action approval',category:'action',owner:'Security Operations',enabled:true,enforcement:'require_approval',triggeredRuns:7,falsePositiveRate:.03,lastTestedAt:'2026-07-14'},
  {id:'GRD-03',name:'Grounded output quality',category:'quality',owner:'AI Assurance',enabled:true,enforcement:'require_approval',triggeredRuns:11,falsePositiveRate:.08,lastTestedAt:'2026-07-15'},
  {id:'GRD-04',name:'Per-run cost ceiling',category:'financial',owner:'FinOps',enabled:true,enforcement:'block',triggeredRuns:1,falsePositiveRate:0,lastTestedAt:'2026-07-16'},
  {id:'GRD-05',name:'Prompt injection defense',category:'security',owner:'Security Operations',enabled:true,enforcement:'block',triggeredRuns:4,falsePositiveRate:.02,lastTestedAt:'2026-07-17'}
 ];
 const reviews:HumanReview[]=[
  {id:'REV-01',runId:'RUN-1002',reviewer:'GTM Operations Lead',decision:'pending',reason:'Campaign launch includes external send action.',requestedAt:'2026-07-18T19:10:06Z',decidedAt:null,slaMinutes:60},
  {id:'REV-02',runId:'RUN-0998',reviewer:'Privacy Operations',decision:'approved',reason:'No restricted data found after review.',requestedAt:'2026-07-18T16:00:00Z',decidedAt:'2026-07-18T16:22:00Z',slaMinutes:60}
 ];
 const providers:ModelProvider[]=[
  {id:'MDL-01',provider:'OpenAI',model:'gpt-5.6',region:'US',approvedUse:['research','analysis','orchestration'],dataRetention:'none',status:'approved',unitCostInput:1.25,unitCostOutput:10,availabilityPct:99.95},
  {id:'MDL-02',provider:'Anthropic',model:'Claude Enterprise',region:'US',approvedUse:['analysis','document review'],dataRetention:'limited',status:'restricted',unitCostInput:3,unitCostOutput:15,availabilityPct:99.9}
 ];
 return {agents,runs,policies,reviews,providers};
}
