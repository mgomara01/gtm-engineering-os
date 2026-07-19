import Link from 'next/link';
import { getWorkspaceContext } from '@/lib/workspace-context';
import { getResolutionCandidates } from '@/lib/data/entity-resolution';

export default async function Page(){
 const {activeWorkspace}=await getWorkspaceContext(); const rows=await getResolutionCandidates(activeWorkspace!.id);
 return <>
  <div className="hero"><div><h1>Entity Resolution</h1><p className="muted">Review potential duplicates, relationship candidates, and deterministic matches before changing the global entity layer.</p></div></div>
  <div className="grid cards section">
   <div className="card"><span className="muted">Pending review</span><div className="metric">{rows.filter(x=>x.status==='pending').length}</div></div>
   <div className="card"><span className="muted">Auto-link threshold</span><div className="metric">95+</div></div>
   <div className="card"><span className="muted">Human-review band</span><div className="metric">80–94</div></div>
   <div className="card"><span className="muted">Reversible merges</span><div className="metric">100%</div></div>
  </div>
  <div className="notice section">Exact external identifiers, domains, and normalized phones take precedence. Fuzzy name and address similarity only recommend review; they do not silently merge records.</div>
  <div className="table-scroll section"><table className="table"><thead><tr><th>Candidate pair</th><th>Sources</th><th>Match score</th><th>Recommendation</th><th>Status</th><th></th></tr></thead><tbody>{rows.map(r=><tr key={r.id}><td><strong>{r.left.name}</strong><small className="table-sub">vs. {r.right.name}</small></td><td>{r.left.source}<small className="table-sub">{r.right.source}</small></td><td><strong>{r.match.score}</strong><small className="table-sub">{r.match.reasons[0]?.detail}</small></td><td><span className={`status status-${r.match.decision==='auto_link'?'complete':r.match.decision==='review'?'active':'not_started'}`}>{r.match.decision.replace('_',' ')}</span></td><td><span className="pill">{r.status.replace('_',' ')}</span></td><td><Link className="text-link" href={`/entity-resolution/${r.id}`}>Review</Link></td></tr>)}</tbody></table></div>
 </>
}
