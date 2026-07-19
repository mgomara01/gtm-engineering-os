import type { AuditEngagement, ComplianceException, ControlAttestation, EvidenceRequest, Policy, RegulatoryObligation } from './compliance-types';

export function policyReviewOverdue(policy: Policy, now = new Date()) {
  return policy.status === 'approved' && new Date(policy.nextReviewAt).getTime() < now.getTime();
}
export function policyAcknowledgementRate(policy: Policy) {
  if (!policy.acknowledgementsRequired) return 100;
  return Number(((policy.acknowledgementsComplete / policy.acknowledgementsRequired) * 100).toFixed(1));
}
export function evidenceRequestOverdue(request: EvidenceRequest, now = new Date()) {
  return !['accepted'].includes(request.status) && new Date(request.dueAt).getTime() < now.getTime();
}
export function obligationCoverage(obligation: RegulatoryObligation) {
  if (!obligation.controlIds.length) return 0;
  const evidenceFactor = Math.min(1, obligation.evidenceIds.length / obligation.controlIds.length);
  const statusFactor = obligation.status === 'compliant' ? 1 : obligation.status === 'at_risk' ? 0.6 : obligation.status === 'not_applicable' ? 1 : 0.2;
  return Number((evidenceFactor * statusFactor * 100).toFixed(1));
}
export function attestationCompletion(attestations: ControlAttestation[]) {
  if (!attestations.length) return 0;
  return Number((attestations.filter(a => a.attestedAt && a.effective !== null).length / attestations.length * 100).toFixed(1));
}
export function exceptionExpired(exception: ComplianceException, now = new Date()) {
  return !['closed'].includes(exception.status) && new Date(exception.expiresAt).getTime() < now.getTime();
}
export function auditReadiness(audit: AuditEngagement, requests: EvidenceRequest[]) {
  const auditRequests = requests.filter(r => r.requestedBy === audit.auditor);
  const accepted = auditRequests.filter(r => r.status === 'accepted').length;
  const evidenceScore = auditRequests.length ? accepted / auditRequests.length : 1;
  const findingPenalty = Math.min(0.5, audit.findingsOpen * 0.05);
  return Math.max(0, Number(((evidenceScore - findingPenalty) * 100).toFixed(1)));
}
export function complianceReadiness(policies: Policy[], obligations: RegulatoryObligation[], evidence: EvidenceRequest[], attestations: ControlAttestation[], exceptions: ComplianceException[], now = new Date()) {
  const policyScore = policies.length ? policies.filter(p => p.status === 'approved' && !policyReviewOverdue(p, now) && policyAcknowledgementRate(p) >= 90).length / policies.length : 0;
  const obligationScore = obligations.length ? obligations.reduce((s, o) => s + obligationCoverage(o), 0) / (obligations.length * 100) : 0;
  const evidenceScore = evidence.length ? evidence.filter(e => e.status === 'accepted' && !evidenceRequestOverdue(e, now)).length / evidence.length : 0;
  const attestationScore = attestationCompletion(attestations) / 100;
  const exceptionPenalty = exceptions.filter(e => exceptionExpired(e, now) || e.risk === 'critical').length * 0.04;
  return Math.max(0, Number((((policyScore + obligationScore + evidenceScore + attestationScore) / 4 - exceptionPenalty) * 100).toFixed(1)));
}
