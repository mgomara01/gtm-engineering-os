export type ApiClientStatus = 'active' | 'suspended' | 'revoked';
export type WebhookStatus = 'active' | 'paused' | 'failing';
export type DeliveryStatus = 'pending' | 'delivered' | 'retrying' | 'failed';

export type ApiScope = {
  key: string;
  label: string;
  risk: 'low' | 'medium' | 'high';
};

export type ApiClient = {
  id: string;
  name: string;
  workspace: string;
  keyPrefix: string;
  status: ApiClientStatus;
  scopes: string[];
  requestsToday: number;
  dailyLimit: number;
  lastUsedAt: string | null;
  expiresAt: string | null;
  owner: string;
};

export type WebhookEndpoint = {
  id: string;
  workspace: string;
  name: string;
  url: string;
  status: WebhookStatus;
  events: string[];
  successRate: number;
  consecutiveFailures: number;
  lastDeliveryAt: string | null;
};

export type WebhookDelivery = {
  id: string;
  endpointId: string;
  eventType: string;
  status: DeliveryStatus;
  attempt: number;
  responseCode: number | null;
  latencyMs: number | null;
  createdAt: string;
  nextAttemptAt: string | null;
};

export type ApiRequestLog = {
  id: string;
  clientId: string;
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE';
  path: string;
  responseCode: number;
  latencyMs: number;
  occurredAt: string;
  requestId: string;
};
