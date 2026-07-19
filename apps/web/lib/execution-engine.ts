import type {Opportunity,WorkItem} from './execution-types';
export function weightedPipeline(opportunities:Opportunity[]){return opportunities.filter(x=>!['won','lost'].includes(x.stage)).reduce((sum,x)=>sum+x.value*(x.probability/100),0)}
export function pipelineValue(opportunities:Opportunity[]){return opportunities.filter(x=>!['won','lost'].includes(x.stage)).reduce((sum,x)=>sum+x.value,0)}
export function isOverdue(item:WorkItem,now=new Date()){return Boolean(item.dueAt&&item.status!=='completed'&&new Date(item.dueAt)<now)}
export function canAdvanceOpportunity(opportunity:Opportunity,openTasks:WorkItem[]){if(opportunity.stage==='won'||opportunity.stage==='lost')return false;return !openTasks.some(x=>x.opportunityId===opportunity.id&&['blocked','in_progress','ready'].includes(x.status)&&x.priority==='critical')}
export function nextStage(stage:Opportunity['stage']):Opportunity['stage']|null{const stages:Opportunity['stage'][]=['identified','qualified','discovery','proposal','negotiation','won'];const i=stages.indexOf(stage);return i>=0&&i<stages.length-1?stages[i+1]:null}
