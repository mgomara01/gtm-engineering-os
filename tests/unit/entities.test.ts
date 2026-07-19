import {describe,expect,it} from 'vitest';
import type {Organization} from '../../apps/web/lib/entity-types';
const account:Organization={id:'1',workspaceId:'w',name:'Test',type:'company',industry:'Service',city:'Tampa',state:'FL',lifecycle:'prospect',priority:'A',owner:'User',score:80,dataConfidence:90,propertyCount:1,contactCount:2,opportunityValue:1000,tags:[]};
describe('operational entity contract',()=>{it('keeps global identity separate from workspace context',()=>{expect(account.workspaceId).toBe('w');expect(account.lifecycle).toBe('prospect')});it('supports relationship counts and opportunity context',()=>{expect(account.propertyCount+account.contactCount).toBe(3);expect(account.opportunityValue).toBe(1000)})});
