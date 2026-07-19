import type {AttributionRecord,KpiDefinition,KpiResult,ManagementAlert,OperatingReviewSection} from '@/lib/analytics-types';
import {buildMetricView,weightedAttribution} from '@/lib/analytics-engine';
const workspace='11111111-1111-1111-1111-111111111111';
export const kpiDefinitions:KpiDefinition[]=[
{id:'kpi-1',workspaceId:workspace,key:'implementation_completion',name:'Implementation completion',description:'Completed lifecycle requirements as a percent of total.',category:'implementation',format:'percent',target:75,warningThreshold:60,ownerRole:'GTM Administrator',cadence:'weekly',active:true},
{id:'kpi-2',workspaceId:workspace,key:'data_completeness',name:'Data completeness',description:'Required account fields populated and verified.',category:'data',format:'percent',target:90,warningThreshold:80,ownerRole:'Data Steward',cadence:'weekly',active:true},
{id:'kpi-3',workspaceId:workspace,key:'research_acceptance_rate',name:'Research acceptance rate',description:'AI findings accepted without material correction.',category:'intelligence',format:'percent',target:80,warningThreshold:65,ownerRole:'GTM Analyst',cadence:'monthly',active:true},
{id:'kpi-4',workspaceId:workspace,key:'task_completion_rate',name:'Task completion rate',description:'Due workflow tasks completed on time.',category:'execution',format:'percent',target:90,warningThreshold:80,ownerRole:'Sales Manager',cadence:'weekly',active:true},
{id:'kpi-5',workspaceId:workspace,key:'weighted_pipeline',name:'Weighted pipeline',description:'Open opportunity value weighted by stage probability.',category:'pipeline',format:'currency',target:50000,warningThreshold:35000,ownerRole:'Sales Manager',cadence:'weekly',active:true},
{id:'kpi-6',workspaceId:workspace,key:'average_sales_cycle_days',name:'Average sales cycle',description:'Average days from identified opportunity to close.',category:'pipeline',format:'days',target:45,warningThreshold:60,ownerRole:'Sales Manager',cadence:'monthly',active:true},
{id:'kpi-7',workspaceId:workspace,key:'attributed_revenue',name:'Attributed revenue',description:'Closed revenue attributed to GTM campaigns and playbooks.',category:'revenue',format:'currency',target:75000,warningThreshold:50000,ownerRole:'Executive',cadence:'monthly',active:true},
{id:'kpi-8',workspaceId:workspace,key:'open_critical_alerts',name:'Open critical alerts',description:'Unresolved critical management exceptions.',category:'execution',format:'number',target:0,warningThreshold:1,ownerRole:'GTM Administrator',cadence:'daily',active:true}
];
export const kpiResults:KpiResult[]=[
{id:'r1',workspaceId:workspace,kpiId:'kpi-1',periodStart:'2026-07-13',periodEnd:'2026-07-19',value:71,priorValue:64,target:75,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'},
{id:'r2',workspaceId:workspace,kpiId:'kpi-2',periodStart:'2026-07-13',periodEnd:'2026-07-19',value:86,priorValue:81,target:90,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'},
{id:'r3',workspaceId:workspace,kpiId:'kpi-3',periodStart:'2026-07-01',periodEnd:'2026-07-31',value:78,priorValue:74,target:80,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'},
{id:'r4',workspaceId:workspace,kpiId:'kpi-4',periodStart:'2026-07-13',periodEnd:'2026-07-19',value:82,priorValue:88,target:90,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'},
{id:'r5',workspaceId:workspace,kpiId:'kpi-5',periodStart:'2026-07-13',periodEnd:'2026-07-19',value:34725,priorValue:28100,target:50000,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'},
{id:'r6',workspaceId:workspace,kpiId:'kpi-6',periodStart:'2026-07-01',periodEnd:'2026-07-31',value:52,priorValue:49,target:45,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'},
{id:'r7',workspaceId:workspace,kpiId:'kpi-7',periodStart:'2026-07-01',periodEnd:'2026-07-31',value:42000,priorValue:18000,target:75000,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'},
{id:'r8',workspaceId:workspace,kpiId:'kpi-8',periodStart:'2026-07-18',periodEnd:'2026-07-18',value:1,priorValue:0,target:0,calculatedAt:'2026-07-18T18:00:00Z',sourceStatus:'demo'}
];
export const alerts:ManagementAlert[]=[
{id:'alert-1',workspaceId:workspace,title:'Critical workflow task is overdue',description:'Decision-maker verification is blocking an opportunity and campaign progression.',severity:'critical',category:'execution',metricKey:'open_critical_alerts',detectedAt:'2026-07-18T18:00:00Z',status:'open',ownerRole:'Sales Manager',recommendedAction:'Assign a verified contact-research owner and resolve before the next campaign step.'},
{id:'alert-2',workspaceId:workspace,title:'Task completion is below target',description:'Weekly on-time task completion fell to 82% against a 90% target.',severity:'warning',category:'execution',metricKey:'task_completion_rate',detectedAt:'2026-07-18T18:00:00Z',status:'open',ownerRole:'Sales Manager',recommendedAction:'Review overdue tasks by owner and remove repeat blockers.'},
{id:'alert-3',workspaceId:workspace,title:'Data completeness is improving',description:'Required-field completeness increased five points week over week.',severity:'info',category:'data',metricKey:'data_completeness',detectedAt:'2026-07-18T18:00:00Z',status:'acknowledged',ownerRole:'Data Steward',recommendedAction:'Continue enrichment on missing decision-maker and property fields.'}
];
export const attribution:AttributionRecord[]=[
{id:'att-1',workspaceId:workspace,opportunityId:'opp-won-1',accountName:'Harbor Hospitality Group',campaignName:'Existing Customer Expansion',playbookName:'Portfolio Cross-Sell',offerName:'Existing Customer Cross-Sell Review',revenue:42000,weight:1,attributedRevenue:weightedAttribution(42000,1),model:'last_touch',occurredAt:'2026-07-14T17:00:00Z'},
{id:'att-2',workspaceId:workspace,opportunityId:'opp-won-2',accountName:'Bayview Medical Properties',campaignName:'Commercial IAQ Pilot',playbookName:'IAQ Discovery',offerName:'Commercial IAQ Assessment',revenue:28500,weight:.6,attributedRevenue:weightedAttribution(28500,.6),model:'linear',occurredAt:'2026-07-11T17:00:00Z'}
];
export const operatingReview:OperatingReviewSection[]=[
{title:'Implementation and governance',status:'yellow',summary:'Core platform capabilities are built; production write controls and external integrations remain gated.',metrics:['71% implementation completion','2 pending approvals'],decisions:['Approve transactional server-action pattern'],actions:['Complete production permission matrix','Run RLS integration tests']},
{title:'Data and intelligence',status:'yellow',summary:'Data quality is improving, but decision-maker coverage remains the principal constraint.',metrics:['86% data completeness','78% research acceptance'],decisions:['Set minimum contact-verification threshold'],actions:['Enrich priority A accounts','Resolve duplicate-review backlog']},
{title:'Execution and pipeline',status:'red',summary:'Task execution is below target and one critical blocker is delaying pipeline advancement.',metrics:['82% task completion','$34,725 weighted pipeline','52-day average cycle'],decisions:['Reassign blocked research work'],actions:['Resolve critical overdue task','Review next actions on all open opportunities']},
{title:'Revenue and optimization',status:'yellow',summary:'Attributed revenue is growing but remains below the current monthly target.',metrics:['$59,100 attributed revenue','$75,000 target'],decisions:['Select next playbook optimization test'],actions:['Compare response by channel','Retire low-performing sequence steps']}
];
export async function getMetricViews(workspaceId:string){return kpiDefinitions.filter(d=>d.workspaceId===workspaceId).map(d=>buildMetricView(d,kpiResults.find(r=>r.kpiId===d.id)!))}
export async function getAlerts(workspaceId:string){return alerts.filter(a=>a.workspaceId===workspaceId)}
export async function getAttribution(workspaceId:string){return attribution.filter(a=>a.workspaceId===workspaceId)}
export async function getOperatingReview(workspaceId:string){return workspaceId===workspace?operatingReview:[]}
