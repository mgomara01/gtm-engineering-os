import type { BackupControl, ContinuityExercise, RecoveryPlan, ResilienceFinding, ThirdParty, VendorRisk } from './resilience-types';

export function recoveryPlanOverdue(plan: RecoveryPlan, now = new Date()) {
  return new Date(plan.nextReviewAt).getTime() < now.getTime();
}
export function backupStale(control: BackupControl, now = new Date()) {
  if (!control.lastSuccessfulAt) return true;
  return now.getTime() - new Date(control.lastSuccessfulAt).getTime() > control.frequencyHours * 3600000 * 1.5;
}
export function backupAssuranceScore(control: BackupControl, now = new Date()) {
  let score = 100;
  if (backupStale(control, now)) score -= 35;
  if (!control.encrypted) score -= 20;
  if (!control.immutable) score -= 15;
  if (!control.restoreTestPassed) score -= 25;
  if (!control.lastRestoreTestAt || now.getTime() - new Date(control.lastRestoreTestAt).getTime() > 180 * 86400000) score -= 10;
  return Math.max(0, score);
}
export function exerciseMeetsRto(exercise: ContinuityExercise, plan: RecoveryPlan) {
  return exercise.recoveryTimeMinutes !== null && exercise.recoveryTimeMinutes <= plan.rtoMinutes;
}
const riskPoints: Record<VendorRisk, number> = { critical: 100, high: 75, medium: 45, low: 20 };
export function vendorRiskScore(vendor: ThirdParty) {
  let score = riskPoints[vendor.residualRisk];
  if (vendor.criticalDependency) score += 10;
  if (vendor.dataAccess === 'restricted') score += 10;
  if (!vendor.socReport) score += 8;
  if (vendor.breachNoticeHours === null || vendor.breachNoticeHours > 72) score += 7;
  return Math.min(100, score);
}
export function vendorAssessmentOverdue(vendor: ThirdParty, now = new Date()) {
  return vendor.status !== 'offboarded' && new Date(vendor.nextAssessmentAt).getTime() < now.getTime();
}
export function findingOverdue(finding: ResilienceFinding, now = new Date()) {
  return finding.status !== 'resolved' && new Date(finding.dueAt).getTime() < now.getTime();
}
export function resilienceReadiness(plans: RecoveryPlan[], backups: BackupControl[], vendors: ThirdParty[], now = new Date()) {
  const planScore = plans.length ? plans.filter(p => !recoveryPlanOverdue(p, now) && p.runbookUrl && p.alternateProcess).length / plans.length : 0;
  const backupScore = backups.length ? backups.reduce((s,b)=>s+backupAssuranceScore(b,now),0)/(backups.length*100) : 0;
  const vendorScore = vendors.length ? vendors.filter(v=>!vendorAssessmentOverdue(v,now) && vendorRiskScore(v)<80).length/vendors.length : 0;
  return Number((((planScore + backupScore + vendorScore) / 3) * 100).toFixed(1));
}
