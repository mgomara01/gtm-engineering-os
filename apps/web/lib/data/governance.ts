import type {AccessException,AccessReview,AuditEvent,ChangeRequest,ReleaseGate,RetentionPolicy} from '../governance-types';
const W='11111111-1111-1111-1111-111111111111';
export const auditEvents:AuditEvent[]=[
{id:'aud-1',workspaceId:W,occurredAt:'2026-07-18T19:16:00Z',actor:'ServiceTitan Sync Worker',actorType:'integration',action:'sync.completed',resourceType:'sync_job',resourceId:'sync-101',severity:'info',summary:'Customer and location synchronization completed with 14 rejected rows.',correlationId:'corr-st-101',immutable:true},
{id:'aud-2',workspaceId:W,occurredAt:'2026-07-18T18:40:00Z',actor:'GTM Administrator',actorType:'user',action:'playbook.version.approved',resourceType:'playbook_version',resourceId:'pbv-2',severity:'info',summary:'Commercial PM outreach playbook version 2 approved.',correlationId:'corr-pbv-2',immutable:true},
{id:'aud-3',workspaceId:W,occurredAt:'2026-07-18T17:55:00Z',actor:'Research Agent',actorType:'agent',action:'finding.proposed',resourceType:'research_finding',resourceId:'rf-18',severity:'warning',summary:'Agent proposed an ownership update with medium confidence; human review required.',correlationId:'corr-rf-18',immutable:true},
{id:'aud-4',workspaceId:W,occurredAt:'2026-07-18T16:12:00Z',actor:'System',actorType:'system',action:'access.policy.denied',resourceType:'workspace',resourceId:W,severity:'critical',summary:'Cross-workspace record access was denied by row-level security.',correlationId:'corr-rls-7',ipAddress:'10.0.0.18',immutable:true}
];
export const accessReviews:AccessReview[]=[
{id:'ar-1',workspaceId:W,name:'Quarterly privileged-access certification',scope:'Administrators, integration owners, agent publishers',owner:'Security Administrator',dueAt:'2026-07-25T21:00:00Z',status:'in_progress',membersReviewed:14,exceptions:2},
{id:'ar-2',workspaceId:W,name:'Sales workspace role review',scope:'Sales managers and sales users',owner:'Revenue Operations',dueAt:'2026-07-15T21:00:00Z',status:'overdue',membersReviewed:31,exceptions:1},
{id:'ar-3',workspaceId:W,name:'Service account certification',scope:'Workers and connector service identities',owner:'Technical Administrator',dueAt:'2026-06-30T21:00:00Z',status:'completed',membersReviewed:8,exceptions:0,certifiedBy:'Technical Administrator',completedAt:'2026-06-29T16:00:00Z'}
];
export const accessExceptions:AccessException[]=[
{id:'axe-1',workspaceId:W,reviewId:'ar-1',principal:'Legacy Integration Operator',role:'Integration Administrator',reason:'Role exceeds current operational duties.',risk:'high',status:'open',owner:'Technical Administrator',dueAt:'2026-07-22T21:00:00Z'},
{id:'axe-2',workspaceId:W,reviewId:'ar-1',principal:'Campaign Analyst',role:'Agent Publisher',reason:'Temporary pilot access requires expiration.',risk:'medium',status:'accepted',owner:'GTM Administrator',dueAt:'2026-08-01T21:00:00Z'}
];
export const changes:ChangeRequest[]=[
{id:'chg-1',workspaceId:W,title:'Publish commercial scoring model v3',category:'configuration',status:'approved',risk:'medium',requestedBy:'Revenue Operations',owner:'GTM Administrator',requestedAt:'2026-07-17T14:00:00Z',scheduledAt:'2026-07-21T13:00:00Z',approvalsRequired:2,approvalsReceived:2,rollbackPlan:true,summary:'Promotes calibrated territory and revenue-potential weights.'},
{id:'chg-2',workspaceId:W,title:'Enable Microsoft Graph outbound email',category:'integration',status:'review',risk:'high',requestedBy:'Marketing',owner:'Technical Administrator',requestedAt:'2026-07-18T15:30:00Z',approvalsRequired:3,approvalsReceived:1,rollbackPlan:false,summary:'Activates governed campaign email delivery after consent validation.'},
{id:'chg-3',workspaceId:W,title:'Deploy retention worker',category:'schema',status:'scheduled',risk:'high',requestedBy:'Data Governance',owner:'Technical Administrator',requestedAt:'2026-07-16T11:00:00Z',scheduledAt:'2026-07-20T11:00:00Z',approvalsRequired:3,approvalsReceived:3,rollbackPlan:true,summary:'Enables archive and anonymization jobs for expired records.'}
];
export const retentionPolicies:RetentionPolicy[]=[
{id:'ret-1',workspaceId:W,dataClass:'Operational',recordType:'Integration request snapshots',retentionDays:365,action:'archive',legalHold:false,owner:'Data Governance',lastEvaluatedAt:'2026-07-17T04:00:00Z',nextEvaluationAt:'2026-07-19T04:00:00Z',eligibleRecords:1284},
{id:'ret-2',workspaceId:W,dataClass:'Personal',recordType:'Rejected prospect contact data',retentionDays:90,action:'delete',legalHold:false,owner:'Privacy Officer',lastEvaluatedAt:'2026-07-18T04:00:00Z',nextEvaluationAt:'2026-07-19T04:00:00Z',eligibleRecords:73},
{id:'ret-3',workspaceId:W,dataClass:'Audit',recordType:'Security and approval events',retentionDays:2555,action:'archive',legalHold:true,owner:'Security Administrator',lastEvaluatedAt:'2026-07-01T04:00:00Z',nextEvaluationAt:'2026-08-01T04:00:00Z',eligibleRecords:0}
];
export const releaseGates:ReleaseGate[]=[
{id:'rg-1',workspaceId:W,name:'TypeScript and unit tests',category:'Engineering',status:'pass',owner:'Engineering',evidence:'47 tests and strict typecheck passed in Step 18.',blocking:true},
{id:'rg-2',workspaceId:W,name:'RLS cross-workspace tests',category:'Security',status:'pass',owner:'Security Administrator',evidence:'Denied-access audit event and policy validation recorded.',blocking:true},
{id:'rg-3',workspaceId:W,name:'Production secret manager',category:'Infrastructure',status:'warning',owner:'Technical Administrator',evidence:'Required before production connector credentials are activated.',blocking:false},
{id:'rg-4',workspaceId:W,name:'Outbound consent enforcement',category:'Compliance',status:'fail',owner:'GTM Administrator',evidence:'Suppression and consent server actions are not yet connected.',blocking:true}
];
export async function getGovernance(workspaceId:string){return{auditEvents:auditEvents.filter(x=>x.workspaceId===workspaceId),accessReviews:accessReviews.filter(x=>x.workspaceId===workspaceId),accessExceptions:accessExceptions.filter(x=>x.workspaceId===workspaceId),changes:changes.filter(x=>x.workspaceId===workspaceId),retentionPolicies:retentionPolicies.filter(x=>x.workspaceId===workspaceId),releaseGates:releaseGates.filter(x=>x.workspaceId===workspaceId)}}
