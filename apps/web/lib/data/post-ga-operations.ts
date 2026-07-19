import type {CustomerFeedbackItem,CustomerHealthRecord,ImprovementInitiative,ProductAdoptionMetric,ValueOutcome} from '../post-ga-operations-types';
export function getPostGAOperationsData(){
const adoption:ProductAdoptionMetric[]=[
{id:'ADM-4201',name:'Weekly active operators',owner:'Product Operations',activeUsers:86,eligibleUsers:100,targetPercent:80,previousPercent:72,trend:'growing',measuredAt:'2026-07-25T12:00:00Z'},
{id:'ADM-4202',name:'Executive intelligence usage',owner:'Executive Products',activeUsers:18,eligibleUsers:20,targetPercent:75,previousPercent:70,trend:'growing',measuredAt:'2026-07-25T12:00:00Z'},
{id:'ADM-4203',name:'Automated workflow adoption',owner:'Automation Operations',activeUsers:61,eligibleUsers:80,targetPercent:70,previousPercent:68,trend:'growing',measuredAt:'2026-07-25T12:00:00Z'},
{id:'ADM-4204',name:'Governed API client adoption',owner:'Developer Platform',activeUsers:21,eligibleUsers:30,targetPercent:65,previousPercent:63,trend:'stable',measuredAt:'2026-07-25T12:00:00Z'}];
const health:CustomerHealthRecord[]=[
{id:'HLT-4201',customer:'Alvarez Revenue Operations',segment:'enterprise',adoptionPercent:88,supportRisk:12,valueRealizationPercent:92,status:'healthy',owner:'Customer Success',nextAction:'Expand executive reporting cadence'},
{id:'HLT-4202',customer:'Commercial Growth Team',segment:'business unit',adoptionPercent:81,supportRisk:18,valueRealizationPercent:85,status:'healthy',owner:'Customer Success',nextAction:'Activate workflow templates'},
{id:'HLT-4203',customer:'Service Operations',segment:'business unit',adoptionPercent:74,supportRisk:31,valueRealizationPercent:78,status:'watch',owner:'Customer Success',nextAction:'Complete supervisor enablement'}];
const feedback:CustomerFeedbackItem[]=[
{id:'FDB-4201',source:'interview',theme:'Executive reporting',description:'Add scheduled PDF distribution for board packets',impact:'high',status:'planned',votes:12,owner:'Product Management'},
{id:'FDB-4202',source:'usage',theme:'Workflow authoring',description:'Reduce configuration steps for common approvals',impact:'high',status:'triaged',votes:19,owner:'Automation Product'},
{id:'FDB-4203',source:'support',theme:'Data onboarding',description:'Expose import reconciliation guidance in context',impact:'medium',status:'planned',votes:8,owner:'Data Platform'},
{id:'FDB-4204',source:'survey',theme:'Mobile experience',description:'Improve responsive tables for field leaders',impact:'medium',status:'triaged',votes:15,owner:'Experience Design'}];
const outcomes:ValueOutcome[]=[
{id:'VAL-4201',name:'Manual reporting hours per month',baseline:84,current:28,target:35,unit:'hours',direction:'lower',owner:'Business Operations',verified:true},
{id:'VAL-4202',name:'Campaign decision cycle',baseline:10,current:4,target:5,unit:'days',direction:'lower',owner:'Revenue Operations',verified:true},
{id:'VAL-4203',name:'Governed automation rate',baseline:22,current:71,target:65,unit:'percent',direction:'higher',owner:'Automation Operations',verified:true}];
const initiatives:ImprovementInitiative[]=[
{id:'IMP-4201',title:'Scheduled executive report distribution',category:'product',impactScore:9,effortScore:4,status:'approved',targetRelease:'1.1.0',owner:'Executive Products',linkedFeedback:['FDB-4201']},
{id:'IMP-4202',title:'Workflow quick-start templates',category:'enablement',impactScore:9,effortScore:3,status:'in_progress',targetRelease:'1.1.0',owner:'Automation Product',linkedFeedback:['FDB-4202']},
{id:'IMP-4203',title:'Contextual import reconciliation assistant',category:'data',impactScore:7,effortScore:4,status:'approved',targetRelease:'1.1.0',owner:'Data Platform',linkedFeedback:['FDB-4203']},
{id:'IMP-4204',title:'Responsive operations tables',category:'product',impactScore:6,effortScore:5,status:'proposed',targetRelease:'1.2.0',owner:'Experience Design',linkedFeedback:['FDB-4204']}];
return {adoption,health,feedback,outcomes,initiatives};}
