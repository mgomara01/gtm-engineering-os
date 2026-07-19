import type {AccessReview,AuditEvent,ChangeRequest,ReleaseGate,RetentionPolicy} from './governance-types';
export function auditIntegrity(events:AuditEvent[]){const immutable=events.filter(e=>e.immutable).length;return events.length?Math.round(immutable/events.length*1000)/10:100}
export function overdueReviews(reviews:AccessReview[],now=new Date()){return reviews.filter(r=>r.status!=='completed'&&new Date(r.dueAt)<now)}
export function changeReady(change:ChangeRequest){if(change.status!=='approved'&&change.status!=='scheduled')return false;if(change.approvalsReceived<change.approvalsRequired)return false;if(change.risk==='high'&&!change.rollbackPlan)return false;return true}
export function retentionDue(policy:RetentionPolicy,now=new Date()){return !policy.legalHold&&policy.eligibleRecords>0&&new Date(policy.nextEvaluationAt)<=now}
export function releaseReadiness(gates:ReleaseGate[]){const blockingFailures=gates.filter(g=>g.blocking&&g.status==='fail').length;const passed=gates.filter(g=>g.status==='pass').length;const score=gates.length?Math.round(passed/gates.length*100):100;return{score,blockingFailures,ready:blockingFailures===0}}
