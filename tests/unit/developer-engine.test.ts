import { describe, expect, it } from 'vitest';
import { clientOperational, clientRequiresApproval, deliveryTerminal, normalizeIdempotencyKey, quotaPercent, quotaStatus, retryDelaySeconds, scopeAllowed, signWebhookPayload, verifyWebhookSignature, webhookHealth } from '../../apps/web/lib/developer-engine';
import type { ApiClient, ApiScope } from '../../apps/web/lib/developer-types';
const client:ApiClient={id:'1',name:'Worker',workspace:'w',keyPrefix:'gtm_live_x',status:'active',scopes:['accounts:read','exports:run'],requestsToday:90,dailyLimit:100,lastUsedAt:null,expiresAt:null,owner:'Ops'};
const catalog:ApiScope[]=[{key:'accounts:read',label:'Read',risk:'low'},{key:'exports:run',label:'Export',risk:'high'}];
describe('developer platform engine',()=>{
  it('enforces status and scopes',()=>{expect(scopeAllowed(client,'accounts:read')).toBe(true);expect(scopeAllowed({...client,status:'suspended'},'accounts:read')).toBe(false)});
  it('classifies quota consumption',()=>{expect(quotaPercent(client)).toBe(90);expect(quotaStatus(client)).toBe('warning')});
  it('checks expiration',()=>{expect(clientOperational(client,new Date('2026-01-01'))).toBe(true);expect(clientOperational({...client,expiresAt:'2025-01-01'},new Date('2026-01-01'))).toBe(false)});
  it('flags privileged scopes',()=>expect(clientRequiresApproval(client,catalog)).toBe(true));
  it('signs and verifies webhooks',()=>{const signature=signWebhookPayload('{"id":1}','secret','100');expect(verifyWebhookSignature('{"id":1}','secret','100',signature)).toBe(true);expect(verifyWebhookSignature('{"id":2}','secret','100',signature)).toBe(false)});
  it('bounds retry delays and terminal state',()=>{expect(retryDelaySeconds(1)).toBe(30);expect(retryDelaySeconds(20)).toBe(3600);expect(deliveryTerminal({id:'d',endpointId:'e',eventType:'x',status:'retrying',attempt:6,responseCode:500,latencyMs:1,createdAt:'x',nextAttemptAt:'x'})).toBe(true)});
  it('classifies endpoint health',()=>expect(webhookHealth({id:'e',workspace:'w',name:'x',url:'x',status:'active',events:[],successRate:96,consecutiveFailures:2,lastDeliveryAt:null})).toBe('warning'));
  it('validates idempotency keys',()=>{expect(normalizeIdempotencyKey('  request-123 ')).toBe('request-123');expect(normalizeIdempotencyKey('tiny')).toBeNull()});
});
