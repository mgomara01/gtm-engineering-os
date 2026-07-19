import { describe, expect, it } from 'vitest';
import { normalizeDomain, normalizePhone, normalizeText, scoreOrganizationMatch, similarity } from '../../apps/web/lib/entity-resolution';

describe('entity resolution',()=>{
 it('normalizes common company suffixes and punctuation',()=>expect(normalizeText('Harbor Hospitality Group, LLC')).toBe('harbor hospitality group'));
 it('normalizes domains and phones',()=>{expect(normalizeDomain('https://www.Example.com/path')).toBe('example.com');expect(normalizePhone('+1 (813) 555-0140')).toBe('8135550140')});
 it('auto-links exact domains and phones',()=>{const result=scoreOrganizationMatch({id:'a',name:'Harbor Hospitality',website:'harbor.example',phone:'8135551000'},{id:'b',name:'Harbor Hospitality LLC',website:'www.harbor.example',phone:'(813) 555-1000'});expect(result.decision).toBe('auto_link');expect(result.score).toBeGreaterThanOrEqual(95)});
 it('sends similar records to review rather than auto-merging',()=>{const result=scoreOrganizationMatch({id:'a',name:'Bayview Medical Properties',address:'4100 N Dale Mabry Hwy',city:'Tampa',state:'FL'},{id:'b',name:'Bayview Medical Property Management',address:'4100 North Dale Mabry Highway',city:'Tampa',state:'FL'});expect(result.score).toBeGreaterThanOrEqual(80);expect(result.decision).toBe('review')});
 it('keeps unrelated names below review threshold',()=>expect(similarity('Westshore Commerce Center','Sunrise Dental Associates')).toBeLessThan(.5));
});
