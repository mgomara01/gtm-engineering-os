import type { FeatureFlag, Incident, IncidentSeverity, MaintenanceWindow, ServiceObjective } from './reliability-types';

export function availabilityPercent(objective: ServiceObjective) {
  if (objective.totalEvents <= 0) return 100;
  return Number(((objective.goodEvents / objective.totalEvents) * 100).toFixed(3));
}

export function allowedBadEvents(objective: ServiceObjective) {
  return Math.max(0, Math.floor(objective.totalEvents * (1 - objective.targetPercent / 100)));
}

export function consumedBadEvents(objective: ServiceObjective) {
  return Math.max(0, objective.totalEvents - objective.goodEvents);
}

export function errorBudgetRemainingPercent(objective: ServiceObjective) {
  const allowed = allowedBadEvents(objective);
  if (allowed === 0) return consumedBadEvents(objective) === 0 ? 100 : 0;
  return Math.max(0, Math.min(100, Number((((allowed - consumedBadEvents(objective)) / allowed) * 100).toFixed(1))));
}

export function sloHealth(objective: ServiceObjective) {
  const remaining = errorBudgetRemainingPercent(objective);
  const actual = availabilityPercent(objective);
  if (actual < objective.targetPercent || remaining <= 10) return 'critical';
  if (remaining <= 35) return 'warning';
  return 'healthy';
}

export function burnRate(objective: ServiceObjective, elapsedWindowFraction = 1) {
  const allowed = allowedBadEvents(objective);
  if (allowed === 0) return consumedBadEvents(objective) > 0 ? Number.POSITIVE_INFINITY : 0;
  const normalizedFraction = Math.max(0.001, Math.min(1, elapsedWindowFraction));
  return Number((consumedBadEvents(objective) / (allowed * normalizedFraction)).toFixed(2));
}

export function severityResponseMinutes(severity: IncidentSeverity) {
  return ({ sev1: 5, sev2: 15, sev3: 60, sev4: 240 })[severity];
}

export function incidentDurationMinutes(incident: Incident, now = new Date()) {
  const end = incident.resolvedAt ? new Date(incident.resolvedAt) : now;
  return Math.max(0, Math.round((end.getTime() - new Date(incident.startedAt).getTime()) / 60000));
}

export function incidentUpdateOverdue(incident: Incident, now = new Date()) {
  return incident.status !== 'resolved' && !!incident.nextUpdateAt && new Date(incident.nextUpdateAt).getTime() < now.getTime();
}

export function featureFlagRisk(flag: FeatureFlag, now = new Date()) {
  if (flag.status !== 'active') return 'low';
  if (flag.expiresAt && new Date(flag.expiresAt).getTime() < now.getTime()) return 'critical';
  if (flag.environment === 'production' && flag.rolloutPercent === 100 && !flag.killSwitch) return 'high';
  if (flag.environment === 'production' && flag.rolloutPercent >= 50) return 'medium';
  return 'low';
}

export function validRolloutPercent(percent: number) {
  return Number.isFinite(percent) && percent >= 0 && percent <= 100;
}

export function maintenanceWindowsOverlap(a: MaintenanceWindow, b: MaintenanceWindow) {
  if (a.serviceId !== b.serviceId || a.status === 'cancelled' || b.status === 'cancelled') return false;
  return new Date(a.startsAt).getTime() < new Date(b.endsAt).getTime() && new Date(b.startsAt).getTime() < new Date(a.endsAt).getTime();
}
