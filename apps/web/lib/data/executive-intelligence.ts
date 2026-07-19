import type { DataQualitySignal, DecisionBrief, ExecutiveMetric, ExecutiveReport, ForecastScenario } from '../executive-intelligence-types';
export function getExecutiveIntelligenceData(){
 const metrics:ExecutiveMetric[]=[
  {id:'KPI-01',name:'Annualized recurring revenue',category:'revenue',value:18400000,unit:'usd',target:17500000,priorValue:16800000,direction:'up',owner:'CFO',asOf:'2026-07-18',source:'Commercial Operations'},
  {id:'KPI-02',name:'Qualified pipeline coverage',category:'pipeline',value:3.4,unit:'count',target:3,priorValue:2.9,direction:'up',owner:'CRO',asOf:'2026-07-18',source:'Opportunities'},
  {id:'KPI-03',name:'Workflow success rate',category:'operations',value:92.6,unit:'percent',target:95,priorValue:89.4,direction:'up',owner:'COO',asOf:'2026-07-18',source:'Workflow Automation'},
  {id:'KPI-04',name:'Gross revenue churn',category:'customer',value:5.8,unit:'percent',target:6,priorValue:6.4,direction:'down',owner:'Chief Customer Officer',asOf:'2026-07-18',source:'Subscriptions'},
  {id:'KPI-05',name:'Open critical risk items',category:'risk',value:3,unit:'count',target:2,priorValue:5,direction:'down',owner:'CISO',asOf:'2026-07-18',source:'Security & Compliance'},
  {id:'KPI-06',name:'AI cost per successful run',category:'ai',value:1.82,unit:'usd',target:2,priorValue:2.11,direction:'down',owner:'VP AI',asOf:'2026-07-18',source:'AI Operations'}
 ];
 const scenarios:ForecastScenario[]=[
  {id:'FC-01',name:'Base plan',horizonMonths:12,confidence:'high',revenueUsd:24100000,grossMarginPct:71.5,pipelineCoverage:3.2,churnPct:5.9,assumptions:['Current hiring plan','Stable conversion','No pricing change'],updatedAt:'2026-07-18T15:00:00Z'},
  {id:'FC-02',name:'Expansion case',horizonMonths:12,confidence:'medium',revenueUsd:27400000,grossMarginPct:72.8,pipelineCoverage:3.8,churnPct:5.2,assumptions:['Partner channel acceleration','Enterprise attach improves','AI automation lowers delivery cost'],updatedAt:'2026-07-18T15:00:00Z'},
  {id:'FC-03',name:'Downside case',horizonMonths:12,confidence:'medium',revenueUsd:21100000,grossMarginPct:68.9,pipelineCoverage:2.4,churnPct:7.4,assumptions:['Longer sales cycles','Higher churn','Delayed hiring'],updatedAt:'2026-07-18T15:00:00Z'}
 ];
 const reports:ExecutiveReport[]=[
  {id:'RPT-01',name:'Weekly Executive Operating Brief',cadence:'weekly',owner:'Strategy',audience:'Executive Team',status:'scheduled',nextRunAt:'2026-07-20T11:00:00Z',lastPublishedAt:'2026-07-13T11:09:00Z',metricCount:18,sectionCount:7,deliveryChannels:['email','dashboard']},
  {id:'RPT-02',name:'Monthly Board Performance Pack',cadence:'monthly',owner:'CFO',audience:'Board of Directors',status:'published',nextRunAt:'2026-08-03T12:00:00Z',lastPublishedAt:'2026-07-03T12:04:00Z',metricCount:32,sectionCount:10,deliveryChannels:['pdf','data room']},
  {id:'RPT-03',name:'AI Value Realization Review',cadence:'monthly',owner:'VP AI',audience:'Executive Team',status:'draft',nextRunAt:null,lastPublishedAt:null,metricCount:12,sectionCount:5,deliveryChannels:['dashboard']}
 ];
 const briefs:DecisionBrief[]=[
  {id:'DEC-01',title:'Approve enterprise pricing uplift',decisionOwner:'CEO',dueAt:'2026-07-21T16:00:00Z',status:'open',recommendation:'Approve a 6% uplift for new enterprise contracts.',confidence:'high',supportingMetrics:['KPI-01','KPI-02'],riskSummary:'Potential increase in late-stage price objections.'},
  {id:'DEC-02',title:'Remediate critical vendor concentration',decisionOwner:'COO',dueAt:'2026-07-17T20:00:00Z',status:'open',recommendation:'Fund secondary provider implementation this quarter.',confidence:'medium',supportingMetrics:['KPI-05'],riskSummary:'Single-provider outage could impair customer workflows.'},
  {id:'DEC-03',title:'Expand autonomous research agent rollout',decisionOwner:'VP AI',dueAt:'2026-07-16T18:00:00Z',status:'decided',recommendation:'Expand to two additional account segments.',confidence:'high',supportingMetrics:['KPI-06'],riskSummary:'Monitor quality drift and token spend.'}
 ];
 const quality:DataQualitySignal[]=[
  {id:'DQ-01',source:'Commercial Operations',freshnessHours:2,completenessPct:99.2,anomalyCount:0,certified:true},
  {id:'DQ-02',source:'Workflow Automation',freshnessHours:1,completenessPct:98.1,anomalyCount:1,certified:true},
  {id:'DQ-03',source:'Security & Compliance',freshnessHours:8,completenessPct:94.5,anomalyCount:2,certified:false},
  {id:'DQ-04',source:'AI Operations',freshnessHours:1,completenessPct:97.7,anomalyCount:0,certified:true}
 ];
 return {metrics,scenarios,reports,briefs,quality};
}
