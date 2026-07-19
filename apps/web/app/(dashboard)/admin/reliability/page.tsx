import Link from 'next/link';
import { getReliabilityData } from '@/lib/data/reliability';
import { errorBudgetRemainingPercent, featureFlagRisk, incidentUpdateOverdue, sloHealth } from '@/lib/reliability-engine';

export default function Page() {
  const { services, objectives, incidents, flags, maintenance } = getReliabilityData();
  const unhealthy = services.filter((service) => service.status !== 'operational').length;
  const exhausted = objectives.filter((objective) => sloHealth(objective) === 'critical').length;
  const activeIncidents = incidents.filter((incident) => incident.status !== 'resolved');
  const riskyFlags = flags.filter((flag) => ['high', 'critical'].includes(featureFlagRisk(flag))).length;
  return <>
    <div className="hero"><div><div className="eyebrow">Step 27</div><h1>Reliability Operations</h1><p className="muted">Operate services against explicit reliability objectives, incident controls, and safe-release mechanisms.</p></div><span className={`status status-${activeIncidents.length ? 'degraded' : 'healthy'}`}>{activeIncidents.length ? 'active incident' : 'all systems operational'}</span></div>
    <div className="grid cards section">
      <div className="card"><span className="muted">Degraded services</span><div className="metric">{unhealthy}</div><small>{services.length} cataloged services</small></div>
      <div className="card"><span className="muted">SLOs at risk</span><div className="metric">{exhausted}</div><small>30-day rolling windows</small></div>
      <div className="card"><span className="muted">Open incidents</span><div className="metric">{activeIncidents.length}</div><small>{activeIncidents.filter((incident) => incidentUpdateOverdue(incident)).length} update overdue</small></div>
      <div className="card"><span className="muted">High-risk flags</span><div className="metric">{riskyFlags}</div><small>{maintenance.length} maintenance windows</small></div>
    </div>
    <div className="grid three-col section">
      <Link className="card" href="/admin/services"><h2>Service catalog & SLOs</h2><p className="muted">Ownership, dependencies, reliability targets, error budgets, and operational runbooks.</p><span className="text-link">Inspect services →</span></Link>
      <Link className="card" href="/admin/incidents"><h2>Incident command</h2><p className="muted">Severity, response deadlines, customer impact, status updates, and resolution evidence.</p><span className="text-link">Manage incidents →</span></Link>
      <Link className="card" href="/admin/feature-flags"><h2>Feature controls</h2><p className="muted">Progressive delivery, expiration, ownership, rollout exposure, and kill switches.</p><span className="text-link">Review flags →</span></Link>
    </div>
    <div className="card section"><h2>Error-budget policy</h2>{objectives.map((objective) => <div className="control-row" key={objective.id}><span>{objective.name}<small className="table-sub">{objective.targetPercent}% target · {objective.windowDays}-day window</small></span><span className={`status status-${sloHealth(objective)}`}>{errorBudgetRemainingPercent(objective)}% remaining</span></div>)}</div>
  </>;
}
