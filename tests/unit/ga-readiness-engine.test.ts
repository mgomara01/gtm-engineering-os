import {describe,expect,it} from 'vitest';
import {acceptanceCoverage,blockingRisks,canCertifyGA,certificationCoverage,gaBlockers,gaReadinessScore,migrationReadinessScore} from '../../apps/web/lib/ga-readiness-engine';
import {getGAReadinessData} from '../../apps/web/lib/data/ga-readiness';
const d=getGAReadinessData();
describe('ga readiness engine',()=>{
it('calculates certification coverage',()=>expect(certificationCoverage(d.certifications)).toBe(83.3));
it('calculates migration readiness',()=>expect(migrationReadinessScore(d.migrations)).toBe(100));
it('identifies no blocking residual risks',()=>expect(blockingRisks(d.risks)).toHaveLength(0));
it('calculates functional acceptance',()=>expect(acceptanceCoverage(d.acceptances)).toBe(83.3));
it('finds mandatory launch blockers',()=>expect(gaBlockers(d.gates)).toHaveLength(1));
it('calculates overall ga readiness',()=>expect(gaReadinessScore(d.certifications,d.migrations,d.risks,d.acceptances,d.gates)).toBe(88.3));
it('prevents premature ga certification',()=>expect(canCertifyGA(d.certifications,d.migrations,d.risks,d.acceptances,d.gates)).toBe(false));
it('returns perfect scores for empty portfolios',()=>{expect(certificationCoverage([])).toBe(100);expect(migrationReadinessScore([])).toBe(100);expect(acceptanceCoverage([])).toBe(100);});
});
