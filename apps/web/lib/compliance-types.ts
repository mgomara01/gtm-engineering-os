export type PolicyStatus = 'draft' | 'in_review' | 'approved' | 'retired';
export type ObligationStatus = 'compliant' | 'at_risk' | 'non_compliant' | 'not_applicable';
export type EvidenceStatus = 'requested' | 'submitted' | 'accepted' | 'rejected' | 'overdue';
export type AuditStatus = 'planned' | 'fieldwork' | 'remediation' | 'complete';
export type ExceptionStatus = 'requested' | 'approved' | 'expired' | 'closed';

export type Policy = {
  id: string; title: string; owner: string; status: PolicyStatus; version: string;
  framework: string; approvedAt: string | null; nextReviewAt: string;
  acknowledgementsRequired: number; acknowledgementsComplete: number;
};
export type RegulatoryObligation = {
  id: string; framework: string; citation: string; requirement: string; owner: string;
  status: ObligationStatus; controlIds: string[]; evidenceIds: string[];
  dueAt: string; jurisdiction: string;
};
export type EvidenceRequest = {
  id: string; title: string; owner: string; requestedBy: string; status: EvidenceStatus;
  dueAt: string; submittedAt: string | null; controlId: string; artifactUrl: string | null;
  periodStart: string; periodEnd: string;
};
export type ControlAttestation = {
  id: string; controlId: string; controlName: string; owner: string; period: string;
  attestedAt: string | null; effective: boolean | null; exceptions: number; reviewer: string;
};
export type AuditEngagement = {
  id: string; name: string; auditor: string; framework: string; owner: string;
  status: AuditStatus; startAt: string; endAt: string; requestsOpen: number;
  findingsOpen: number; opinion: 'pending' | 'clean' | 'qualified' | 'adverse';
};
export type ComplianceException = {
  id: string; title: string; controlId: string; owner: string; status: ExceptionStatus;
  risk: 'critical' | 'high' | 'medium' | 'low'; compensatingControl: string;
  approvedBy: string | null; expiresAt: string; remediationPlan: string;
};
