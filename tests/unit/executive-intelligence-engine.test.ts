import { describe, expect, it } from 'vitest';
import { dataTrustScore, executiveReadiness, forecastSpreadPct, metricAttainment, overdueDecisions, portfolioAttainment, reportingCoverage } from '../../apps/web/lib/executive-intelligence-engine';
import { getExecutiveIntelligenceData } from '../../apps/web/lib/data/executive-intelligence';
const d=getExecutiveIntelligenceData();
describe('executive intelligence engine',()=>{
 it('calculates metric and portfolio attainment',()=>{expect(metricAttainment(d.metrics[0])).toBeGreaterThan(100);expect(portfolioAttainment(d.metrics)).toBeGreaterThan(80)});
 it('calculates forecast spread',()=>expect(forecastSpreadPct(d.scenarios)).toBeGreaterThan(20));
 it('measures report coverage',()=>expect(reportingCoverage(d.reports)).toBeCloseTo(66.7,1));
 it('detects overdue decisions',()=>expect(overdueDecisions(d.briefs,new Date('2026-07-18T23:00:00Z'))).toHaveLength(1));
 it('scores data trust',()=>expect(dataTrustScore(d.quality)).toBeGreaterThan(80));
 it('produces executive readiness',()=>expect(executiveReadiness(d.metrics,d.reports,d.briefs,d.quality,new Date('2026-07-18T23:00:00Z'))).toBeGreaterThan(70));
});
