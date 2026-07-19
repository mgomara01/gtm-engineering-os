import type {KpiDefinition,KpiResult,MetricView,TrendDirection} from './analytics-types';
export function variance(value:number,target:number){return value-target}
export function variancePercent(value:number,target:number){return target===0?null:Number((((value-target)/Math.abs(target))*100).toFixed(1))}
export function trend(value:number,priorValue?:number):TrendDirection{if(priorValue===undefined||value===priorValue)return 'flat';return value>priorValue?'up':'down'}
export function metricStatus(def:KpiDefinition,result:KpiResult):MetricView['status']{
 const higherIsBetter=!['average_sales_cycle_days','overdue_tasks','open_critical_alerts'].includes(def.key);
 const warning=def.warningThreshold ?? def.target;
 if(higherIsBetter){if(result.value>=def.target)return'on_track';if(result.value>=warning)return'watch';return'off_track'}
 if(result.value<=def.target)return'on_track';if(result.value<=warning)return'watch';return'off_track';
}
export function buildMetricView(definition:KpiDefinition,result:KpiResult):MetricView{return{definition,result,variance:variance(result.value,result.target),variancePercent:variancePercent(result.value,result.target),trend:trend(result.value,result.priorValue),status:metricStatus(definition,result)}}
export function formatMetric(value:number,format:KpiDefinition['format']){if(format==='currency')return `$${value.toLocaleString()}`;if(format==='percent')return `${value.toFixed(1)}%`;if(format==='days')return `${value.toFixed(1)} days`;return value.toLocaleString()}
export function weightedAttribution(revenue:number,weight:number){if(weight<0||weight>1)throw new Error('Attribution weight must be between 0 and 1');return Number((revenue*weight).toFixed(2))}
