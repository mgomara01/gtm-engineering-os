import {describe,expect,it} from 'vitest';import {auditIntegrity,changeReady,overdueReviews,releaseReadiness,retentionDue} from '../../apps/web/lib/governance-engine';
import type {AccessReview,AuditEvent,ChangeRequest,ReleaseGate,RetentionPolicy} from '../../apps/web/lib/governance-types';
describe('governance engine',()=>{
it('calculates immutable audit integrity',()=>{expect(auditIntegrity([{immutable:true},{immutable:false}] as AuditEvent[])).toBe(50)});
it('identifies overdue access reviews',()=>{const r=[{status:'in_progress',dueAt:'2026-01-01'}] as AccessReview[];expect(overdueReviews(r,new Date('2026-02-01'))).toHaveLength(1)});
it('blocks high-risk change without rollback plan',()=>{const c={status:'approved',risk:'high',approvalsReceived:2,approvalsRequired:2,rollbackPlan:false} as ChangeRequest;expect(changeReady(c)).toBe(false)});
it('holds records from disposition',()=>{const p={legalHold:true,eligibleRecords:10,nextEvaluationAt:'2026-01-01'} as RetentionPolicy;expect(retentionDue(p,new Date('2026-02-01'))).toBe(false)});
it('fails readiness on a blocking failed gate',()=>{const g=[{status:'pass',blocking:true},{status:'fail',blocking:true}] as ReleaseGate[];expect(releaseReadiness(g)).toEqual({score:50,blockingFailures:1,ready:false})});
});
