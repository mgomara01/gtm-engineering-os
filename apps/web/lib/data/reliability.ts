import type { FeatureFlag, Incident, MaintenanceWindow, PlatformService, ServiceObjective } from '../reliability-types';

export function getReliabilityData() {
  const services: PlatformService[] = [
    { id: 'svc_web', name: 'Web application', owner: 'Platform Engineering', tier: 1, status: 'operational', dependencies: ['svc_auth', 'svc_db'], runbookUrl: '/docs/runbooks/web-application', lastDeployAt: '2026-07-18T21:36:00Z' },
    { id: 'svc_api', name: 'Public API', owner: 'Platform Engineering', tier: 1, status: 'degraded', dependencies: ['svc_auth', 'svc_db', 'svc_queue'], runbookUrl: '/docs/runbooks/public-api', lastDeployAt: '2026-07-18T21:36:00Z' },
    { id: 'svc_queue', name: 'Worker queues', owner: 'Integration Operations', tier: 1, status: 'operational', dependencies: ['svc_db'], runbookUrl: '/docs/runbooks/worker-queues', lastDeployAt: '2026-07-17T18:20:00Z' },
    { id: 'svc_auth', name: 'Authentication', owner: 'Security Engineering', tier: 0, status: 'operational', dependencies: ['svc_db'], runbookUrl: '/docs/runbooks/authentication', lastDeployAt: '2026-07-16T16:05:00Z' },
    { id: 'svc_db', name: 'Primary database', owner: 'Data Platform', tier: 0, status: 'operational', dependencies: [], runbookUrl: '/docs/runbooks/database', lastDeployAt: '2026-07-15T03:00:00Z' }
  ];

  const objectives: ServiceObjective[] = [
    { id: 'slo_api_availability', serviceId: 'svc_api', name: 'Successful API requests', targetPercent: 99.9, windowDays: 30, goodEvents: 998640, totalEvents: 1000000 },
    { id: 'slo_web_availability', serviceId: 'svc_web', name: 'Successful page loads', targetPercent: 99.9, windowDays: 30, goodEvents: 1999000, totalEvents: 2000000 },
    { id: 'slo_queue_completion', serviceId: 'svc_queue', name: 'Jobs completed within SLA', targetPercent: 99.5, windowDays: 30, goodEvents: 497900, totalEvents: 500000 },
    { id: 'slo_auth_availability', serviceId: 'svc_auth', name: 'Successful authentication', targetPercent: 99.99, windowDays: 30, goodEvents: 499970, totalEvents: 500000 }
  ];

  const incidents: Incident[] = [
    { id: 'INC-2026-014', title: 'Elevated API latency and intermittent 503 responses', severity: 'sev2', status: 'monitoring', serviceIds: ['svc_api', 'svc_queue'], commander: 'Raj Butta', startedAt: '2026-07-18T20:42:00Z', resolvedAt: null, nextUpdateAt: '2026-07-18T22:45:00Z', customerImpact: 'Some API clients experienced delayed responses and retries.' },
    { id: 'INC-2026-013', title: 'Webhook delivery backlog', severity: 'sev3', status: 'resolved', serviceIds: ['svc_queue'], commander: 'Integration Operations', startedAt: '2026-07-17T13:05:00Z', resolvedAt: '2026-07-17T14:22:00Z', nextUpdateAt: null, customerImpact: 'Outbound webhook events were delayed by up to 24 minutes.' },
    { id: 'INC-2026-012', title: 'Staging authentication callback failure', severity: 'sev4', status: 'resolved', serviceIds: ['svc_auth'], commander: 'Security Engineering', startedAt: '2026-07-16T15:12:00Z', resolvedAt: '2026-07-16T15:39:00Z', nextUpdateAt: null, customerImpact: 'Staging only; no production customer impact.' }
  ];

  const flags: FeatureFlag[] = [
    { id: 'flag_01', key: 'api_v1_exports', description: 'Enable governed exports through API v1', status: 'active', environment: 'production', rolloutPercent: 25, owner: 'Data Governance', expiresAt: '2026-09-30T23:59:59Z', killSwitch: true },
    { id: 'flag_02', key: 'agent_auto_write', description: 'Permit approved agents to write operational records', status: 'paused', environment: 'production', rolloutPercent: 0, owner: 'AI Governance', expiresAt: null, killSwitch: true },
    { id: 'flag_03', key: 'new_scoring_simulator', description: 'Next-generation scoring simulator', status: 'active', environment: 'staging', rolloutPercent: 100, owner: 'Revenue Operations', expiresAt: '2026-08-31T23:59:59Z', killSwitch: true },
    { id: 'flag_04', key: 'legacy_import_parser', description: 'Fallback browser import parser', status: 'active', environment: 'production', rolloutPercent: 100, owner: 'Data Platform', expiresAt: '2026-07-01T23:59:59Z', killSwitch: false }
  ];

  const maintenance: MaintenanceWindow[] = [
    { id: 'mw_01', serviceId: 'svc_db', title: 'Database index maintenance', startsAt: '2026-07-20T06:00:00Z', endsAt: '2026-07-20T06:45:00Z', status: 'scheduled' },
    { id: 'mw_02', serviceId: 'svc_api', title: 'API gateway policy rollout', startsAt: '2026-07-21T02:00:00Z', endsAt: '2026-07-21T02:30:00Z', status: 'scheduled' }
  ];

  return { services, objectives, incidents, flags, maintenance };
}
