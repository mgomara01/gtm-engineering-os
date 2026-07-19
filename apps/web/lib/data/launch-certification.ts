import type {LaunchAuthorization,LaunchBlockerClosure,PostLaunchCheck,ProductionRelease,ReleaseArtifact} from '../launch-certification-types';
export function getLaunchCertificationData(){
const blockers:LaunchBlockerClosure[]=[
{id:'CLS-4101',source:'CERT-4006',description:'Final enablement certification',owner:'Customer Enablement',status:'verified',evidence:'Administrator guide, customer quick-start, and support escalation materials published',verifiedAt:'2026-07-19T14:00:00Z'},
{id:'CLS-4102',source:'ACC-4006',description:'Customer Success functional acceptance',owner:'Customer Success',status:'verified',evidence:'Launch support plan and adoption workflow accepted',verifiedAt:'2026-07-19T14:15:00Z'},
{id:'CLS-4103',source:'GA-4003',description:'Customer launch communications published',owner:'Product Marketing',status:'verified',evidence:'Release notes, in-app announcement, and launch email published',verifiedAt:'2026-07-19T14:30:00Z'}];
const releases:ProductionRelease[]=[{id:'REL-4101',version:'1.0.0',environment:'production',strategy:'blue_green',status:'completed',startedAt:'2026-07-19T15:00:00Z',completedAt:'2026-07-19T15:22:00Z',rollbackAvailable:true,changeTicket:'CHG-1.0.0-GA'}];
const checks:PostLaunchCheck[]=[
{id:'CHK-4101',name:'Application health',owner:'Production Operations',required:true,status:'passed',observedValue:'100% healthy',threshold:'All critical services healthy',checkedAt:'2026-07-19T15:30:00Z'},
{id:'CHK-4102',name:'Error rate',owner:'Reliability Engineering',required:true,status:'passed',observedValue:'0.08%',threshold:'< 1%',checkedAt:'2026-07-19T15:35:00Z'},
{id:'CHK-4103',name:'P95 latency',owner:'Performance Engineering',required:true,status:'passed',observedValue:'284 ms',threshold:'< 500 ms',checkedAt:'2026-07-19T15:35:00Z'},
{id:'CHK-4104',name:'Migration reconciliation',owner:'Data Operations',required:true,status:'passed',observedValue:'0 exceptions',threshold:'0 critical exceptions',checkedAt:'2026-07-19T15:40:00Z'},
{id:'CHK-4105',name:'Authentication smoke test',owner:'Quality Engineering',required:true,status:'passed',observedValue:'Passed',threshold:'Pass',checkedAt:'2026-07-19T15:42:00Z'}];
const authorizations:LaunchAuthorization[]=[
{id:'AUTH-4101',role:'Release Manager',approver:'Release Management',status:'approved',decision:'All release controls satisfied',approvedAt:'2026-07-19T14:40:00Z'},
{id:'AUTH-4102',role:'Technical Authority',approver:'Engineering Leadership',status:'approved',decision:'Production deployment authorized',approvedAt:'2026-07-19T14:45:00Z'},
{id:'AUTH-4103',role:'Executive Sponsor',approver:'Executive Sponsor',status:'approved',decision:'Version 1.0 approved for general availability',approvedAt:'2026-07-19T14:50:00Z'}];
const artifacts:ReleaseArtifact[]=[
{id:'ART-4101',name:'Version 1.0 source package',kind:'source',checksum:'sha256:step41-source-verified',status:'verified'},
{id:'ART-4102',name:'Database migrations 0001-0041',kind:'migration',checksum:'sha256:migrations-verified',status:'verified'},
{id:'ART-4103',name:'Production release runbook',kind:'runbook',checksum:'sha256:runbook-verified',status:'verified'},
{id:'ART-4104',name:'Version 1.0 release notes',kind:'release_notes',checksum:'sha256:notes-verified',status:'verified'},
{id:'ART-4105',name:'GA certification evidence',kind:'evidence',checksum:'sha256:evidence-verified',status:'verified'}];
return {blockers,releases,checks,authorizations,artifacts};}
