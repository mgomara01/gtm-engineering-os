import { describe, expect, it } from 'vitest';
import { allowedBadEvents, availabilityPercent, burnRate, errorBudgetRemainingPercent, featureFlagRisk, incidentDurationMinutes, incidentUpdateOverdue, maintenanceWindowsOverlap, severityResponseMinutes, sloHealth, validRolloutPercent } from '../../apps/web/lib/reliability-engine';
import type { FeatureFlag, Incident, MaintenanceWindow, ServiceObjective } from '../../apps/web/lib/reliability-types';

const objective: ServiceObjective = { id:'slo', serviceId:'svc', name:'Availability', targetPercent:99.9, windowDays:30, goodEvents:9995, totalEvents:10000 };
const incident: Incident = { id:'INC-1', title:'API degraded', severity:'sev2', status:'monitoring', serviceIds:['svc'], commander:'Raj', startedAt:'2026-07-18T20:00:00Z', resolvedAt:null, nextUpdateAt:'2026-07-18T20:30:00Z', customerImpact:'Delayed requests' };
const flag: FeatureFlag = { id:'f', key:'flag', description:'x', status:'active', environment:'production', rolloutPercent:100, owner:'Ops', expiresAt:null, killSwitch:false };

describe('reliability engine',()=>{
  it('calculates availability and allowed failures',()=>{expect(availabilityPercent(objective)).toBe(99.95);expect(allowedBadEvents(objective)).toBe(9)});
  it('tracks remaining error budget',()=>expect(errorBudgetRemainingPercent(objective)).toBe(44.4));
  it('classifies SLO health',()=>{expect(sloHealth(objective)).toBe('healthy');expect(sloHealth({...objective,goodEvents:9980})).toBe('critical')});
  it('calculates normalized burn rate',()=>expect(burnRate(objective,0.5)).toBe(1.11));
  it('maps incident response targets',()=>{expect(severityResponseMinutes('sev1')).toBe(5);expect(severityResponseMinutes('sev4')).toBe(240)});
  it('calculates incident duration and overdue updates',()=>{const now=new Date('2026-07-18T21:00:00Z');expect(incidentDurationMinutes(incident,now)).toBe(60);expect(incidentUpdateOverdue(incident,now)).toBe(true)});
  it('detects unsafe feature flags',()=>{expect(featureFlagRisk(flag)).toBe('high');expect(featureFlagRisk({...flag,expiresAt:'2026-01-01'},new Date('2026-07-18'))).toBe('critical')});
  it('validates rollout percentages',()=>{expect(validRolloutPercent(25)).toBe(true);expect(validRolloutPercent(101)).toBe(false)});
  it('detects overlapping maintenance',()=>{const a:MaintenanceWindow={id:'a',serviceId:'s',title:'a',startsAt:'2026-07-20T01:00:00Z',endsAt:'2026-07-20T02:00:00Z',status:'scheduled'};const b={...a,id:'b',startsAt:'2026-07-20T01:30:00Z',endsAt:'2026-07-20T03:00:00Z'};expect(maintenanceWindowsOverlap(a,b)).toBe(true);expect(maintenanceWindowsOverlap(a,{...b,serviceId:'other'})).toBe(false)});
});
