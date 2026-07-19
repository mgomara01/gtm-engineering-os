import {describe,expect,it} from 'vitest';
import {inferType,profileRows,validateRows} from '../../apps/web/lib/import-engine';
describe('import engine',()=>{
 it('infers common types',()=>{expect(inferType(['a@b.com','c@d.com'])).toBe('email');expect(inferType(['100','200'])).toBe('number')});
 it('suggests canonical mappings',()=>{const cols=profileRows([{ 'Company Name':'ABC','Email Address':'a@b.com'}]);expect(cols[0].targetField).toBe('organization_name');expect(cols[1].targetField).toBe('email')});
 it('detects duplicate identities',()=>{const rows=[{Company:'ABC'},{Company:'ABC'}];const columns=profileRows(rows);expect(validateRows(rows,columns).duplicateRows).toBe(1)});
});
