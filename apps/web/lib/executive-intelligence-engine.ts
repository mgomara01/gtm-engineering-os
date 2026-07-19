import type { DataQualitySignal, DecisionBrief, ExecutiveMetric, ExecutiveReport, ForecastScenario } from './executive-intelligence-types';

export function metricAttainment(metric: ExecutiveMetric){
  if(metric.target===0) return 100;
  const favorable = metric.category==='risk' ? metric.value <= metric.target : metric.value >= metric.target;
  const ratio = metric.category==='risk' ? metric.target / Math.max(metric.value,0.0001) : metric.value / metric.target;
  return Number((Math.min(favorable ? Math.max(ratio,1) : ratio,1.5)*100).toFixed(1));
}
export function portfolioAttainment(metrics: ExecutiveMetric[]){
  if(!metrics.length) return 0;
  return Number((metrics.reduce((s,m)=>s+metricAttainment(m),0)/metrics.length).toFixed(1));
}
export function forecastSpreadPct(scenarios: ForecastScenario[]){
  if(scenarios.length<2) return 0;
  const values=scenarios.map(s=>s.revenueUsd); const mid=values.reduce((a,b)=>a+b,0)/values.length;
  return Number(((Math.max(...values)-Math.min(...values))/mid*100).toFixed(1));
}
export function reportingCoverage(reports: ExecutiveReport[]){
  if(!reports.length) return 0;
  return Number((reports.filter(r=>r.status==='published'||r.status==='scheduled').length/reports.length*100).toFixed(1));
}
export function overdueDecisions(briefs: DecisionBrief[], now=new Date()){
  return briefs.filter(b=>b.status==='open'&&new Date(b.dueAt).getTime()<now.getTime());
}
export function dataTrustScore(signals: DataQualitySignal[]){
  if(!signals.length) return 0;
  const score=signals.reduce((s,d)=>s+(d.completenessPct*.55)+(d.certified?25:0)+Math.max(0,20-Math.min(d.freshnessHours,20))-Math.min(d.anomalyCount*2,15),0)/signals.length;
  return Number(Math.max(0,Math.min(score,100)).toFixed(1));
}
export function executiveReadiness(metrics:ExecutiveMetric[], reports:ExecutiveReport[], briefs:DecisionBrief[], quality:DataQualitySignal[], now=new Date()){
  const decisionScore=briefs.length?Math.max(0,100-overdueDecisions(briefs,now).length/briefs.length*100):100;
  return Number(((portfolioAttainment(metrics)+reportingCoverage(reports)+decisionScore+dataTrustScore(quality))/4).toFixed(1));
}
