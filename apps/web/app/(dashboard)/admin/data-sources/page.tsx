import {getWorkspaceContext} from '@/lib/workspace-context';
import {getExternalSignals} from '@/lib/data/external-signals';
import {SyncSignalsButton} from '@/components/data/sync-signals-button';

export default async function Page(){
  const {activeWorkspace}=await getWorkspaceContext();
  if(!activeWorkspace)return null;
  const signals=await getExternalSignals(activeWorkspace.id);
  return <>
    <div className="hero">
      <div>
        <p className="eyebrow">GTM Engineering API Matrix</p>
        <h1>Data sources</h1>
        <p className="muted">Live external signals from the free, keyless connectors: EPA ECHO (drinking water compliance), USGS Water Services (streamflow), and Tampa GeoHub (aging commercial buildings). Paid-tier sources (permits, property, contact enrichment) join this feed once credentials are provisioned.</p>
      </div>
      <div className="action-row"><SyncSignalsButton/></div>
    </div>
    {signals.length===0?
      <div className="card empty"><h2>No signals yet</h2><p className="muted">Click &quot;Sync live sources&quot; to pull real data from EPA ECHO, USGS, and Tampa GeoHub.</p></div>
    :<>
      <div className="grid cards section">
        <div className="card"><span className="muted">Total signals</span><div className="metric">{signals.length}</div></div>
        <div className="card"><span className="muted">A-priority signals</span><div className="metric">{signals.filter(s=>s.priorityTier==='A').length}</div></div>
        <div className="card"><span className="muted">Average score</span><div className="metric">{Math.round(signals.reduce((a,b)=>a+(b.opportunityScore??0),0)/Math.max(signals.length,1))}</div></div>
      </div>
      <section className="section"><table className="table"><thead><tr><th>Signal</th><th>Source</th><th>Location</th><th>Score</th><th>Severity</th><th>Fetched</th></tr></thead><tbody>
        {signals.map(s=><tr key={s.id}><td><strong>{s.title}</strong><small className="table-sub">{s.category}</small></td><td>{s.source}</td><td>{s.location??'—'}</td><td><span className="score-number">{s.opportunityScore??'—'}</span> <span className={`tier tier-${(s.priorityTier??'c').toLowerCase()}`}>{s.priorityTier??'—'}</span></td><td><span className={`status alert-${s.severity}`}>{s.severity}</span></td><td>{new Date(s.fetchedAt).toLocaleString()}</td></tr>)}
      </tbody></table></section>
    </>}
  </>;
}
