export type FindingSeverity = 'critical' | 'high' | 'medium' | 'low';
export type FindingStatus = 'open' | 'mitigating' | 'accepted' | 'resolved';
export type DataClassification = 'public' | 'internal' | 'confidential' | 'restricted';
export type PrivacyRequestStatus = 'received' | 'verified' | 'in_progress' | 'completed' | 'denied';

export type SecurityControl = {
  id: string;
  framework: 'SOC2' | 'NIST' | 'ISO27001' | 'Internal';
  code: string;
  title: string;
  owner: string;
  status: 'effective' | 'partial' | 'ineffective' | 'not_tested';
  lastTestedAt: string | null;
  nextTestAt: string;
  evidenceCount: number;
};

export type SecurityFinding = {
  id: string;
  title: string;
  severity: FindingSeverity;
  status: FindingStatus;
  asset: string;
  owner: string;
  discoveredAt: string;
  dueAt: string;
  exploitAvailable: boolean;
  internetExposed: boolean;
};

export type DataAsset = {
  id: string;
  name: string;
  system: string;
  classification: DataClassification;
  owner: string;
  personalData: boolean;
  retentionDays: number;
  encryptionAtRest: boolean;
  encryptionInTransit: boolean;
};

export type PrivacyRequest = {
  id: string;
  type: 'access' | 'deletion' | 'correction' | 'portability' | 'opt_out';
  status: PrivacyRequestStatus;
  jurisdiction: string;
  receivedAt: string;
  dueAt: string;
  verifiedAt: string | null;
  owner: string;
};

export type SecurityEvent = {
  id: string;
  category: 'authentication' | 'authorization' | 'data_access' | 'malware' | 'configuration';
  severity: FindingSeverity;
  occurredAt: string;
  source: string;
  disposition: 'investigating' | 'benign' | 'contained' | 'escalated';
  summary: string;
};
