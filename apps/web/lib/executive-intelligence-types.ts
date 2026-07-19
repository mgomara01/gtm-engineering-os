export type MetricDirection = 'up' | 'down' | 'flat';
export type ForecastConfidence = 'high' | 'medium' | 'low';
export type ReportStatus = 'draft' | 'scheduled' | 'published' | 'archived';

export type ExecutiveMetric = {
  id:string; name:string; category:'revenue'|'pipeline'|'operations'|'customer'|'risk'|'ai';
  value:number; unit:'usd'|'percent'|'count'|'days'|'hours'; target:number; priorValue:number;
  direction:MetricDirection; owner:string; asOf:string; source:string;
};
export type ForecastScenario = {
  id:string; name:string; horizonMonths:number; confidence:ForecastConfidence;
  revenueUsd:number; grossMarginPct:number; pipelineCoverage:number; churnPct:number;
  assumptions:string[]; updatedAt:string;
};
export type ExecutiveReport = {
  id:string; name:string; cadence:'weekly'|'monthly'|'quarterly'|'ad_hoc'; owner:string;
  audience:string; status:ReportStatus; nextRunAt:string|null; lastPublishedAt:string|null;
  metricCount:number; sectionCount:number; deliveryChannels:string[];
};
export type DecisionBrief = {
  id:string; title:string; decisionOwner:string; dueAt:string; status:'open'|'decided'|'deferred';
  recommendation:string; confidence:ForecastConfidence; supportingMetrics:string[]; riskSummary:string;
};
export type DataQualitySignal = {
  id:string; source:string; freshnessHours:number; completenessPct:number; anomalyCount:number; certified:boolean;
};
