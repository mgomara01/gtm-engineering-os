export type RecoveryTier = 'tier_0' | 'tier_1' | 'tier_2' | 'tier_3';
export type ExerciseStatus = 'planned' | 'in_progress' | 'passed' | 'failed' | 'cancelled';
export type VendorRisk = 'critical' | 'high' | 'medium' | 'low';
export type VendorStatus = 'active' | 'under_review' | 'restricted' | 'offboarded';

export type RecoveryPlan = {
  id: string; service: string; owner: string; tier: RecoveryTier;
  rtoMinutes: number; rpoMinutes: number; lastReviewedAt: string;
  nextReviewAt: string; runbookUrl: string; alternateProcess: boolean;
};
export type BackupControl = {
  id: string; system: string; owner: string; frequencyHours: number;
  retentionDays: number; encrypted: boolean; immutable: boolean;
  lastSuccessfulAt: string | null; lastRestoreTestAt: string | null;
  restoreTestPassed: boolean;
};
export type ContinuityExercise = {
  id: string; name: string; scenario: string; owner: string;
  scheduledAt: string; status: ExerciseStatus; participants: number;
  recoveryTimeMinutes: number | null; findingsOpen: number;
};
export type ThirdParty = {
  id: string; name: string; service: string; owner: string;
  inherentRisk: VendorRisk; residualRisk: VendorRisk; status: VendorStatus;
  dataAccess: 'none' | 'internal' | 'confidential' | 'restricted';
  criticalDependency: boolean; contractEndsAt: string; lastAssessmentAt: string;
  nextAssessmentAt: string; socReport: boolean; breachNoticeHours: number | null;
};
export type ResilienceFinding = {
  id: string; title: string; category: 'recovery' | 'backup' | 'exercise' | 'vendor';
  severity: VendorRisk; owner: string; dueAt: string; status: 'open' | 'mitigating' | 'accepted' | 'resolved';
};
