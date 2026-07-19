import { describe,it,expect } from 'vitest';
import { navigation } from '../../apps/web/lib/navigation';
describe('navigation',()=>{it('contains core workspace modules',()=>{expect(navigation.map(x=>x.label)).toEqual(expect.arrayContaining(['Overview','Implementation','Data Studio','Accounts','Opportunities','Administration']))})})
