import { describe, expect, it } from 'vitest';
import { backupAssuranceScore, backupStale, exerciseMeetsRto, findingOverdue, recoveryPlanOverdue, resilienceReadiness, vendorAssessmentOverdue, vendorRiskScore } from '../../apps/web/lib/resilience-engine';
import { getResilienceData } from '../../apps/web/lib/data/resilience';
const now=new Date('2026-07-18T23:00:00Z');
describe('resilience engine',()=>{
 const d=getResilienceData();
 it('detects overdue recovery plans',()=>expect(recoveryPlanOverdue(d.plans[2],now)).toBe(true));
 it('detects stale backups',()=>expect(backupStale(d.backups[2],now)).toBe(true));
 it('scores strong backup controls highly',()=>expect(backupAssuranceScore(d.backups[0],now)).toBe(100));
 it('checks exercise recovery against RTO',()=>expect(exerciseMeetsRto(d.exercises[0],d.plans[0])).toBe(true));
 it('raises vendor score for critical restricted dependencies',()=>expect(vendorRiskScore(d.vendors[0])).toBeGreaterThan(45));
 it('detects overdue vendor assessments',()=>expect(vendorAssessmentOverdue(d.vendors[1],now)).toBe(true));
 it('detects overdue findings',()=>expect(findingOverdue(d.findings[1],now)).toBe(true));
 it('calculates bounded readiness',()=>expect(resilienceReadiness(d.plans,d.backups,d.vendors,now)).toBeGreaterThanOrEqual(0));
});
