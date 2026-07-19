import Link from 'next/link';
import { getDeveloperPlatformData } from '@/lib/data/developer';
import { clientOperational, clientRequiresApproval, quotaStatus, webhookHealth } from '@/lib/developer-engine';

export default function Page() {
  const { clients, endpoints, scopes } = getDeveloperPlatformData();
  const activeClients = clients.filter((client) => clientOperational(client)).length;
  const atRiskClients = clients.filter((client) => quotaStatus(client) !== 'healthy').length;
  const unhealthyHooks = endpoints.filter((endpoint) => !['healthy', 'paused'].includes(webhookHealth(endpoint))).length;
  const approvalClients = clients.filter((client) => clientRequiresApproval(client, scopes)).length;

  return <>
    <div className="hero"><div><div className="eyebrow">Step 26</div><h1>Developer Platform</h1><p className="muted">Govern API clients, scopes, quotas, webhook delivery, and machine-to-machine access.</p></div><span className="pill">API v1</span></div>
    <div className="grid cards section">
      <div className="card"><span className="muted">Operational clients</span><div className="metric">{activeClients}</div></div>
      <div className="card"><span className="muted">Quota watch</span><div className="metric">{atRiskClients}</div></div>
      <div className="card"><span className="muted">Webhook incidents</span><div className="metric">{unhealthyHooks}</div></div>
      <div className="card"><span className="muted">Privileged clients</span><div className="metric">{approvalClients}</div></div>
    </div>
    <div className="grid three-col section">
      <Link className="card" href="/admin/api-clients"><h2>API clients</h2><p className="muted">Service accounts, key lifecycle, scope approvals, expiration, and quotas.</p><span className="text-link">Manage clients →</span></Link>
      <Link className="card" href="/admin/webhooks"><h2>Webhooks</h2><p className="muted">Signed event delivery, retry state, failure isolation, and endpoint health.</p><span className="text-link">Inspect delivery →</span></Link>
      <Link className="card" href="/admin/api-activity"><h2>API activity</h2><p className="muted">Request IDs, response codes, latency, rate limiting, and audit lineage.</p><span className="text-link">Review traffic →</span></Link>
    </div>
    <div className="card section"><h2>Control boundary</h2><p className="muted">API authentication never replaces workspace authorization. Every request must pass client status, expiration, workspace membership, scope, entitlement, quota, and idempotency controls before business logic executes.</p></div>
  </>;
}
