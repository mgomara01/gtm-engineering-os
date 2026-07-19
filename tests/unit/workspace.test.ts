import { describe,it,expect } from 'vitest';
import { demoWorkspaces } from '../../apps/web/lib/data/demo';
describe('workspace configuration',()=>{
  it('keeps Alvarez and Intelligent Waterflow isolated',()=>{
    expect(demoWorkspaces).toHaveLength(2);
    expect(new Set(demoWorkspaces.map(item=>item.id)).size).toBe(2);
    expect(demoWorkspaces[0].code).toBe('ALV');
    expect(demoWorkspaces[1].code).toBe('IWF');
  });
});
