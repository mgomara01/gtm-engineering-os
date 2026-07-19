import type { ApiClient, ApiRequestLog, ApiScope, WebhookDelivery, WebhookEndpoint } from '../developer-types';

export function getDeveloperPlatformData() {
  const scopes: ApiScope[] = [
    { key: 'accounts:read', label: 'Read accounts', risk: 'low' },
    { key: 'signals:read', label: 'Read signals', risk: 'low' },
    { key: 'campaigns:write', label: 'Create and update campaigns', risk: 'medium' },
    { key: 'work:write', label: 'Create operational work', risk: 'medium' },
    { key: 'exports:run', label: 'Run governed exports', risk: 'high' },
    { key: 'admin:write', label: 'Manage workspace configuration', risk: 'high' }
  ];

  const clients: ApiClient[] = [
    { id: 'cli_01', name: 'ServiceTitan Sync Worker', workspace: 'Alvarez Plumbing & Air Conditioning', keyPrefix: 'gtm_live_a7f2', status: 'active', scopes: ['accounts:read', 'signals:read', 'work:write'], requestsToday: 18420, dailyLimit: 50000, lastUsedAt: '2026-07-18T20:42:00Z', expiresAt: null, owner: 'Integration Operations' },
    { id: 'cli_02', name: 'Executive Data Export', workspace: 'Alvarez Plumbing & Air Conditioning', keyPrefix: 'gtm_live_d91c', status: 'active', scopes: ['accounts:read', 'signals:read', 'exports:run'], requestsToday: 4380, dailyLimit: 5000, lastUsedAt: '2026-07-18T19:58:00Z', expiresAt: '2026-12-31T23:59:59Z', owner: 'Data Governance' },
    { id: 'cli_03', name: 'IWF Prototype', workspace: 'Intelligent Waterflow', keyPrefix: 'gtm_test_41be', status: 'suspended', scopes: ['accounts:read'], requestsToday: 0, dailyLimit: 1000, lastUsedAt: '2026-07-12T14:11:00Z', expiresAt: null, owner: 'Workspace Owner' }
  ];

  const endpoints: WebhookEndpoint[] = [
    { id: 'wh_01', workspace: 'Alvarez Plumbing & Air Conditioning', name: 'Operations event bus', url: 'https://integrations.alvarez.example/gtm/events', status: 'active', events: ['signal.created', 'work.completed', 'integration.failed'], successRate: 99.7, consecutiveFailures: 0, lastDeliveryAt: '2026-07-18T20:41:22Z' },
    { id: 'wh_02', workspace: 'Intelligent Waterflow', name: 'Prototype CRM listener', url: 'https://iwf.example/webhooks/gtm', status: 'failing', events: ['account.updated', 'opportunity.created'], successRate: 84.2, consecutiveFailures: 7, lastDeliveryAt: '2026-07-18T18:12:10Z' }
  ];

  const deliveries: WebhookDelivery[] = [
    { id: 'del_1004', endpointId: 'wh_01', eventType: 'signal.created', status: 'delivered', attempt: 1, responseCode: 202, latencyMs: 184, createdAt: '2026-07-18T20:41:22Z', nextAttemptAt: null },
    { id: 'del_1003', endpointId: 'wh_02', eventType: 'account.updated', status: 'retrying', attempt: 4, responseCode: 503, latencyMs: 1032, createdAt: '2026-07-18T18:12:10Z', nextAttemptAt: '2026-07-18T18:16:10Z' },
    { id: 'del_1002', endpointId: 'wh_01', eventType: 'work.completed', status: 'delivered', attempt: 1, responseCode: 200, latencyMs: 221, createdAt: '2026-07-18T17:35:02Z', nextAttemptAt: null }
  ];

  const requests: ApiRequestLog[] = [
    { id: 'req_001', clientId: 'cli_01', method: 'POST', path: '/api/v1/work-items', responseCode: 201, latencyMs: 142, occurredAt: '2026-07-18T20:42:00Z', requestId: 'rq_9d122f' },
    { id: 'req_002', clientId: 'cli_02', method: 'POST', path: '/api/v1/exports', responseCode: 429, latencyMs: 18, occurredAt: '2026-07-18T19:58:00Z', requestId: 'rq_a70c31' },
    { id: 'req_003', clientId: 'cli_01', method: 'GET', path: '/api/v1/accounts?updated_since=...', responseCode: 200, latencyMs: 89, occurredAt: '2026-07-18T19:55:40Z', requestId: 'rq_54bf28' }
  ];

  return { scopes, clients, endpoints, deliveries, requests };
}
