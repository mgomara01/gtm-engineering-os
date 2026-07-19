import { createHmac, timingSafeEqual } from 'node:crypto';
import type { ApiClient, ApiScope, WebhookDelivery, WebhookEndpoint } from './developer-types';

export function scopeAllowed(client: ApiClient, requiredScope: string) {
  return client.status === 'active' && client.scopes.includes(requiredScope);
}

export function quotaPercent(client: ApiClient) {
  if (client.dailyLimit <= 0) return 100;
  return Math.min(100, Math.round((client.requestsToday / client.dailyLimit) * 100));
}

export function quotaStatus(client: ApiClient) {
  const percent = quotaPercent(client);
  return percent >= 100 ? 'blocked' : percent >= 85 ? 'warning' : 'healthy';
}

export function clientOperational(client: ApiClient, now = new Date()) {
  if (client.status !== 'active') return false;
  if (!client.expiresAt) return true;
  return new Date(client.expiresAt).getTime() > now.getTime();
}

export function highRiskScopes(client: ApiClient, catalog: ApiScope[]) {
  const highRisk = new Set(catalog.filter((scope) => scope.risk === 'high').map((scope) => scope.key));
  return client.scopes.filter((scope) => highRisk.has(scope));
}

export function clientRequiresApproval(client: ApiClient, catalog: ApiScope[]) {
  return highRiskScopes(client, catalog).length > 0;
}

export function signWebhookPayload(payload: string, secret: string, timestamp: string) {
  return createHmac('sha256', secret).update(`${timestamp}.${payload}`).digest('hex');
}

export function verifyWebhookSignature(payload: string, secret: string, timestamp: string, signature: string) {
  const expected = signWebhookPayload(payload, secret, timestamp);
  if (signature.length !== expected.length) return false;
  return timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
}

export function retryDelaySeconds(attempt: number) {
  const normalizedAttempt = Math.max(1, attempt);
  return Math.min(3600, 30 * 2 ** (normalizedAttempt - 1));
}

export function deliveryTerminal(delivery: WebhookDelivery, maxAttempts = 6) {
  return delivery.status === 'delivered' || delivery.status === 'failed' || delivery.attempt >= maxAttempts;
}

export function webhookHealth(endpoint: WebhookEndpoint) {
  if (endpoint.status === 'paused') return 'paused';
  if (endpoint.status === 'failing' || endpoint.consecutiveFailures >= 5 || endpoint.successRate < 90) return 'critical';
  if (endpoint.consecutiveFailures >= 2 || endpoint.successRate < 98) return 'warning';
  return 'healthy';
}

export function normalizeIdempotencyKey(value: string) {
  const normalized = value.trim();
  if (normalized.length < 8 || normalized.length > 128) return null;
  return normalized;
}
