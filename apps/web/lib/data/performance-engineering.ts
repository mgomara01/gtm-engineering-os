import type {CapacityForecast,LoadTest,PerformanceBudget,PerformanceService,ScalingPolicy} from '../performance-engineering-types';
export function getPerformanceEngineeringData(){
const services:PerformanceService[]=[
{id:'SVC-API',name:'Public API',owner:'Platform Engineering',tier:'interactive',monthlyRequests:28400000,p95LatencyMs:218,latencyBudgetMs:300,errorRatePct:.18,capacityStatus:'healthy',cpuUtilizationPct:54,memoryUtilizationPct:61},
{id:'SVC-WRK',name:'Workflow Runtime',owner:'Automation Engineering',tier:'background',monthlyRequests:9100000,p95LatencyMs:840,latencyBudgetMs:1000,errorRatePct:.42,capacityStatus:'watch',cpuUtilizationPct:72,memoryUtilizationPct:68},
{id:'SVC-AI',name:'AI Orchestration',owner:'AI Platform',tier:'interactive',monthlyRequests:3700000,p95LatencyMs:1810,latencyBudgetMs:1600,errorRatePct:.71,capacityStatus:'critical',cpuUtilizationPct:81,memoryUtilizationPct:77},
{id:'SVC-REP',name:'Executive Reporting',owner:'Data Platform',tier:'analytics',monthlyRequests:680000,p95LatencyMs:3900,latencyBudgetMs:5000,errorRatePct:.12,capacityStatus:'healthy',cpuUtilizationPct:47,memoryUtilizationPct:58}];
const tests:LoadTest[]=[
{id:'LT-101',serviceId:'SVC-API',scenario:'2x expected peak traffic',status:'passed',targetRps:650,achievedRps:712,p95LatencyMs:244,errorRatePct:.21,executedAt:'2026-07-18T20:00:00Z',releaseGate:true},
{id:'LT-102',serviceId:'SVC-WRK',scenario:'Quarter-end workflow surge',status:'passed',targetRps:220,achievedRps:231,p95LatencyMs:903,errorRatePct:.38,executedAt:'2026-07-18T18:00:00Z',releaseGate:true},
{id:'LT-103',serviceId:'SVC-AI',scenario:'Concurrent agent execution burst',status:'failed',targetRps:95,achievedRps:83,p95LatencyMs:2040,errorRatePct:1.3,executedAt:'2026-07-18T17:00:00Z',releaseGate:true},
{id:'LT-104',serviceId:'SVC-REP',scenario:'Board report regeneration',status:'planned',targetRps:30,achievedRps:0,p95LatencyMs:0,errorRatePct:0,executedAt:null,releaseGate:false}];
const forecasts:CapacityForecast[]=[
{id:'CF-1',serviceId:'SVC-API',period:'2026-Q4',projectedRequests:42000000,projectedPeakRps:590,headroomPct:31,confidencePct:86,recommendedAction:'No action; retain current scaling envelope.'},
{id:'CF-2',serviceId:'SVC-WRK',period:'2026-Q4',projectedRequests:15100000,projectedPeakRps:205,headroomPct:18,confidencePct:78,recommendedAction:'Increase worker maximum before quarter-end.'},
{id:'CF-3',serviceId:'SVC-AI',period:'2026-Q4',projectedRequests:7200000,projectedPeakRps:91,headroomPct:7,confidencePct:72,recommendedAction:'Add queue partitioning and provider failover capacity.'}];
const policies:ScalingPolicy[]=[
{id:'SP-1',serviceId:'SVC-API',mode:'predictive',minInstances:4,maxInstances:24,targetCpuPct:62,scaleOutCooldownSec:60,scaleInCooldownSec:300,enabled:true},
{id:'SP-2',serviceId:'SVC-WRK',mode:'reactive',minInstances:3,maxInstances:18,targetCpuPct:68,scaleOutCooldownSec:45,scaleInCooldownSec:420,enabled:true},
{id:'SP-3',serviceId:'SVC-AI',mode:'scheduled',minInstances:4,maxInstances:16,targetCpuPct:65,scaleOutCooldownSec:90,scaleInCooldownSec:600,enabled:true}];
const budgets:PerformanceBudget[]=[
{id:'PB-1',route:'/executive',metric:'server_latency',budget:800,current:690,unit:'ms',blocking:true},
{id:'PB-2',route:'/admin/ai-operations',metric:'server_latency',budget:1200,current:1380,unit:'ms',blocking:true},
{id:'PB-3',route:'application-shell',metric:'bundle_size',budget:420,current:398,unit:'KB',blocking:true},
{id:'PB-4',route:'dashboard',metric:'lcp',budget:2500,current:2310,unit:'ms',blocking:false}];
return {services,tests,forecasts,policies,budgets};}
