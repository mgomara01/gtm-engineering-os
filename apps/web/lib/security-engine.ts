import type { DataAsset, FindingSeverity, PrivacyRequest, SecurityControl, SecurityFinding } from './security-types';

export function remediationTargetDays(severity: FindingSeverity) {
  return ({ critical: 2, high: 14, medium: 45, low: 90 })[severity];
}

export function findingOverdue(finding: SecurityFinding, now = new Date()) {
  return finding.status !== 'resolved' && new Date(finding.dueAt).getTime() < now.getTime();
}

export function findingRiskScore(finding: SecurityFinding) {
  const base = ({ critical: 80, high: 60, medium: 35, low: 15 })[finding.severity];
  return Math.min(100, base + (finding.exploitAvailable ? 12 : 0) + (finding.internetExposed ? 8 : 0));
}

export function controlCoveragePercent(controls: SecurityControl[]) {
  if (!controls.length) return 0;
  const points = controls.reduce((sum, control) => sum + ({ effective: 1, partial: 0.5, ineffective: 0, not_tested: 0 })[control.status], 0);
  return Number(((points / controls.length) * 100).toFixed(1));
}

export function controlTestOverdue(control: SecurityControl, now = new Date()) {
  return new Date(control.nextTestAt).getTime() < now.getTime();
}

export function dataAssetRisk(asset: DataAsset) {
  let score = ({ public: 0, internal: 15, confidential: 35, restricted: 55 })[asset.classification];
  if (asset.personalData) score += 15;
  if (!asset.encryptionAtRest) score += 15;
  if (!asset.encryptionInTransit) score += 15;
  if (asset.retentionDays > 2555) score += 5;
  return Math.min(100, score);
}

export function privacyRequestOverdue(request: PrivacyRequest, now = new Date()) {
  return !['completed', 'denied'].includes(request.status) && new Date(request.dueAt).getTime() < now.getTime();
}

export function privacyDaysRemaining(request: PrivacyRequest, now = new Date()) {
  return Math.ceil((new Date(request.dueAt).getTime() - now.getTime()) / 86400000);
}
