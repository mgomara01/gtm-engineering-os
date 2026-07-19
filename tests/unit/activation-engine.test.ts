import {describe,expect,it} from 'vitest';
import {activationReadiness,canReplay,outboundAllowed,queueHealth,recommendedActivationMode} from '../../apps/web/lib/activation-engine';
const controls=[{id:'1',name:'Workers',category:'workers' as const,status:'pass' as const,blocking:true,evidence:'ok',owner:'Ops'}];
const queue={id:'q',name:'jobs',status:'healthy' as const,pending:0,running:1,failed:0,oldestAgeMinutes:2,maxAttempts:5,deadLetterEnabled:true};
describe('activation engine',()=>{
it('requires all blocking controls to pass',()=>expect(activationReadiness(controls).ready).toBe(true));
it('flags stale or failed queues',()=>expect(queueHealth({...queue,oldestAgeMinutes:20})).toBe('watch'));
it('blocks suppressed outbound activity',()=>expect(outboundAllowed('a@b.com','email',[{id:'c',subject:'a@b.com',channel:'email',state:'granted',source:'form'}],[{id:'s',subject:'a@b.com',channel:'all',reason:'optout',active:true,createdAt:'2026-01-01'}]).allowed).toBe(false));
it('permits verified, unexpired consent',()=>expect(outboundAllowed('a@b.com','email',[{id:'c',subject:'a@b.com',channel:'email',state:'granted',source:'form'}],[]).allowed).toBe(true));
it('prevents replay of policy failures',()=>expect(canReplay({id:'d',queue:'q',jobType:'send',attempts:1,failedAt:'2026-01-01',errorCode:'invalid_consent',errorMessage:'no',replaySafe:true})).toBe(false));
it('recommends active mode only with healthy queues',()=>expect(recommendedActivationMode(controls,[queue])).toBe('active'));
});
