import type {Defect,EnvironmentCertification,QualitySuite,ReleaseCandidate,UatSignoff} from '../quality-engineering-types';
export function getQualityEngineeringData(){
const suites:QualitySuite[]=[
{id:'QS-UNIT',name:'Domain and engine unit tests',layer:'unit',owner:'Platform Engineering',automated:true,requiredForRelease:true,totalCases:178,passedCases:178,failedCases:0,coveragePct:91,lastRunAt:'2026-07-19T00:05:00Z',status:'passed'},
{id:'QS-CONTRACT',name:'API and connector contracts',layer:'contract',owner:'Developer Platform',automated:true,requiredForRelease:true,totalCases:64,passedCases:64,failedCases:0,coveragePct:84,lastRunAt:'2026-07-18T23:40:00Z',status:'passed'},
{id:'QS-E2E',name:'Critical tenant journeys',layer:'e2e',owner:'Quality Engineering',automated:true,requiredForRelease:true,totalCases:42,passedCases:40,failedCases:2,coveragePct:78,lastRunAt:'2026-07-18T23:10:00Z',status:'failed'},
{id:'QS-SEC',name:'Security regression suite',layer:'security',owner:'Security Engineering',automated:true,requiredForRelease:true,totalCases:31,passedCases:31,failedCases:0,coveragePct:82,lastRunAt:'2026-07-18T22:50:00Z',status:'passed'},
{id:'QS-UAT',name:'Business acceptance scenarios',layer:'uat',owner:'Product Operations',automated:false,requiredForRelease:true,totalCases:18,passedCases:15,failedCases:0,coveragePct:100,lastRunAt:'2026-07-18T21:00:00Z',status:'running'}];
const defects:Defect[]=[
{id:'DEF-1042',title:'Connector retry may duplicate a completed outbound action',severity:'high',status:'in_progress',owner:'Integration Engineering',releaseId:'RC-037',openedAt:'2026-07-18T18:20:00Z',targetResolutionAt:'2026-07-19T15:00:00Z',customerImpact:true,rootCause:'Idempotency token not persisted before provider timeout.'},
{id:'DEF-1043',title:'Executive report export truncates long recommendation text',severity:'medium',status:'triaged',owner:'Data Platform',releaseId:'RC-037',openedAt:'2026-07-18T19:10:00Z',targetResolutionAt:'2026-07-21T17:00:00Z',customerImpact:false,rootCause:null},
{id:'DEF-1038',title:'Support access expiration not reflected until refresh',severity:'low',status:'resolved',owner:'Platform Administration',releaseId:'RC-037',openedAt:'2026-07-17T14:00:00Z',targetResolutionAt:'2026-07-18T20:00:00Z',customerImpact:false,rootCause:'Cached tenant access summary.'}];
const environments:EnvironmentCertification[]=[
{id:'ENV-DEV',environment:'Development',version:'0.37.0-rc.2',status:'certified',certifiedAt:'2026-07-18T20:00:00Z',expiresAt:'2026-07-25T20:00:00Z',dataRefreshAt:'2026-07-18T08:00:00Z',configurationFingerprint:'dev-a8e31c',openBlockers:0},
{id:'ENV-STG',environment:'Staging',version:'0.37.0-rc.2',status:'failed',certifiedAt:null,expiresAt:null,dataRefreshAt:'2026-07-18T08:15:00Z',configurationFingerprint:'stg-c910bf',openBlockers:1},
{id:'ENV-PRD',environment:'Production',version:'0.36.0',status:'certified',certifiedAt:'2026-07-18T16:00:00Z',expiresAt:'2026-07-25T16:00:00Z',dataRefreshAt:null,configurationFingerprint:'prd-238f1d',openBlockers:0}];
const release:ReleaseCandidate={id:'RC-037',version:'0.37.0-rc.2',status:'testing',createdAt:'2026-07-18T17:00:00Z',targetReleaseAt:'2026-07-20T02:00:00Z',changeCount:47,blockingDefects:1,requiredSuitesPassed:3,requiredSuitesTotal:5,uatApproved:false,rollbackValidated:true,securityApproved:true,performanceApproved:true,releaseOwner:'Release Engineering'};
const signoffs:UatSignoff[]=[
{id:'UAT-1',releaseId:'RC-037',businessArea:'Revenue Operations',approver:'VP Revenue Operations',status:'approved',signedAt:'2026-07-18T22:00:00Z',notes:'Core opportunity and campaign journeys accepted.'},
{id:'UAT-2',releaseId:'RC-037',businessArea:'Customer Success',approver:'Director Customer Success',status:'pending',signedAt:null,notes:'Awaiting connector retry validation.'},
{id:'UAT-3',releaseId:'RC-037',businessArea:'Finance & Compliance',approver:'Controller',status:'approved',signedAt:'2026-07-18T22:20:00Z',notes:'Billing, evidence, and audit exports accepted.'}];
return {suites,defects,environments,release,signoffs};}
