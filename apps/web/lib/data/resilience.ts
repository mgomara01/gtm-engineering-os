import type { BackupControl, ContinuityExercise, RecoveryPlan, ResilienceFinding, ThirdParty } from '../resilience-types';
export function getResilienceData(){
 const plans:RecoveryPlan[]=[
  {id:'rp-1',service:'Primary GTM application',owner:'Platform Engineering',tier:'tier_0',rtoMinutes:60,rpoMinutes:15,lastReviewedAt:'2026-06-15T14:00:00Z',nextReviewAt:'2026-09-15T14:00:00Z',runbookUrl:'/docs/recovery/app',alternateProcess:true},
  {id:'rp-2',service:'Integration processing',owner:'Integration Operations',tier:'tier_1',rtoMinutes:240,rpoMinutes:60,lastReviewedAt:'2026-05-10T14:00:00Z',nextReviewAt:'2026-08-10T14:00:00Z',runbookUrl:'/docs/recovery/integrations',alternateProcess:true},
  {id:'rp-3',service:'Management analytics',owner:'Data Platform',tier:'tier_2',rtoMinutes:1440,rpoMinutes:240,lastReviewedAt:'2026-02-01T14:00:00Z',nextReviewAt:'2026-07-01T14:00:00Z',runbookUrl:'/docs/recovery/analytics',alternateProcess:false}
 ];
 const backups:BackupControl[]=[
  {id:'bk-1',system:'Primary database',owner:'Platform Engineering',frequencyHours:1,retentionDays:35,encrypted:true,immutable:true,lastSuccessfulAt:'2026-07-18T22:30:00Z',lastRestoreTestAt:'2026-06-20T15:00:00Z',restoreTestPassed:true},
  {id:'bk-2',system:'Object storage',owner:'Data Platform',frequencyHours:24,retentionDays:90,encrypted:true,immutable:false,lastSuccessfulAt:'2026-07-18T03:00:00Z',lastRestoreTestAt:'2026-01-10T15:00:00Z',restoreTestPassed:true},
  {id:'bk-3',system:'Configuration repository',owner:'Platform Engineering',frequencyHours:24,retentionDays:365,encrypted:true,immutable:true,lastSuccessfulAt:'2026-07-17T01:00:00Z',lastRestoreTestAt:null,restoreTestPassed:false}
 ];
 const exercises:ContinuityExercise[]=[
  {id:'ex-1',name:'Regional database failover',scenario:'Primary region unavailable',owner:'Platform Engineering',scheduledAt:'2026-06-20T15:00:00Z',status:'passed',participants:8,recoveryTimeMinutes:42,findingsOpen:1},
  {id:'ex-2',name:'Integration outage tabletop',scenario:'ServiceTitan unavailable for 24 hours',owner:'Integration Operations',scheduledAt:'2026-08-12T14:00:00Z',status:'planned',participants:11,recoveryTimeMinutes:null,findingsOpen:0},
  {id:'ex-3',name:'Ransomware recovery exercise',scenario:'Restricted data store encrypted',owner:'Security Operations',scheduledAt:'2026-05-18T14:00:00Z',status:'failed',participants:13,recoveryTimeMinutes:310,findingsOpen:4}
 ];
 const vendors:ThirdParty[]=[
  {id:'v-1',name:'Supabase',service:'Database and authentication',owner:'Platform Engineering',inherentRisk:'critical',residualRisk:'medium',status:'active',dataAccess:'restricted',criticalDependency:true,contractEndsAt:'2027-04-30',lastAssessmentAt:'2026-04-01',nextAssessmentAt:'2026-10-01',socReport:true,breachNoticeHours:24},
  {id:'v-2',name:'ServiceTitan',service:'Operational system of record',owner:'Business Systems',inherentRisk:'critical',residualRisk:'high',status:'active',dataAccess:'restricted',criticalDependency:true,contractEndsAt:'2027-01-31',lastAssessmentAt:'2025-12-15',nextAssessmentAt:'2026-06-15',socReport:true,breachNoticeHours:72},
  {id:'v-3',name:'Enrichment provider',service:'Company and contact enrichment',owner:'Revenue Operations',inherentRisk:'high',residualRisk:'medium',status:'under_review',dataAccess:'confidential',criticalDependency:false,contractEndsAt:'2026-09-30',lastAssessmentAt:'2026-02-15',nextAssessmentAt:'2026-08-15',socReport:false,breachNoticeHours:null}
 ];
 const findings:ResilienceFinding[]=[
  {id:'RES-2026-014',title:'Configuration restore has not been tested',category:'backup',severity:'high',owner:'Platform Engineering',dueAt:'2026-07-25T14:00:00Z',status:'open'},
  {id:'RES-2026-013',title:'ServiceTitan assessment overdue',category:'vendor',severity:'high',owner:'Business Systems',dueAt:'2026-07-05T14:00:00Z',status:'mitigating'},
  {id:'RES-2026-011',title:'Analytics continuity plan lacks alternate process',category:'recovery',severity:'medium',owner:'Data Platform',dueAt:'2026-07-15T14:00:00Z',status:'open'}
 ];
 return {plans,backups,exercises,vendors,findings};
}
