import { describe,it,expect } from 'vitest';
import { demoStages } from '../../apps/web/lib/data/demo';
describe('implementation lifecycle',()=>{
  it('contains the approved twelve ordered stages',()=>{
    expect(demoStages).toHaveLength(12);
    expect(demoStages.map(stage=>stage.stageNumber)).toEqual([1,2,3,4,5,6,7,8,9,10,11,12]);
    expect(demoStages.filter(stage=>stage.status==='active')).toHaveLength(1);
  });
});
