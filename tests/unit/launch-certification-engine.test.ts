import {describe,expect,it} from 'vitest';
import {artifactCoverage,authorizationCoverage,blockerClosureCoverage,canDeclareGA,completedProductionRelease,launchCertificationScore,postLaunchCoverage} from '../../apps/web/lib/launch-certification-engine';
import {getLaunchCertificationData} from '../../apps/web/lib/data/launch-certification';

describe('launch certification engine',()=>{
 const d=getLaunchCertificationData();
 it('calculates complete blocker closure',()=>expect(blockerClosureCoverage(d.blockers)).toBe(100));
 it('calculates required post-launch coverage',()=>expect(postLaunchCoverage(d.checks)).toBe(100));
 it('calculates authorization coverage',()=>expect(authorizationCoverage(d.authorizations)).toBe(100));
 it('calculates artifact integrity coverage',()=>expect(artifactCoverage(d.artifacts)).toBe(100));
 it('finds the completed rollback-capable production release',()=>expect(completedProductionRelease(d.releases)?.version).toBe('1.0.0'));
 it('produces a perfect certification score',()=>expect(launchCertificationScore(d.blockers,d.releases,d.checks,d.authorizations,d.artifacts)).toBe(100));
 it('declares GA only after every control passes',()=>expect(canDeclareGA(d.blockers,d.releases,d.checks,d.authorizations,d.artifacts)).toBe(true));
 it('blocks GA when a required check fails',()=>{const checks=d.checks.map((x,i)=>i===0?{...x,status:'failed' as const}:x);expect(canDeclareGA(d.blockers,d.releases,checks,d.authorizations,d.artifacts)).toBe(false);});
});
