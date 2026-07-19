import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getWorkspaceContext } from '@/lib/workspace-context';
import { getResolutionCandidate } from '@/lib/data/entity-resolution';

const fields=['name','website','phone','address','city','state'] as const;
export default async function Page({params}:{params:Promise<{candidateId:string}>}){
 const {candidateId}=await params; const {activeWorkspace}=await getWorkspaceContext(); const row=await getResolutionCandidate(activeWorkspace!.id,candidateId); if(!row)notFound();
 return <>
  <div className="hero"><div><div className="eyebrow">Duplicate review</div><h1>{row.left.name}</h1><p className="muted">Confidence {row.match.score}/100 · Recommended action: {row.match.decision.replace('_',' ')}</p></div><Link className="secondary-btn" href="/entity-resolution">Back to queue</Link></div>
  <div className="grid two-col section">
   <div className="card"><div className="eyebrow">Record A · {row.left.source}</div>{fields.map(f=><div className="control-row" key={f}><span className="muted">{f}</span><strong>{row.left[f]||'—'}</strong></div>)}</div>
   <div className="card"><div className="eyebrow">Record B · {row.right.source}</div>{fields.map(f=><div className="control-row" key={f}><span className="muted">{f}</span><strong>{row.right[f]||'—'}</strong></div>)}</div>
  </div>
  <div className="grid two-col section">
   <div className="card"><h2>Match evidence</h2>{row.match.reasons.map(r=><div className="control-row" key={r.field}><span><strong>{r.field}</strong><small className="table-sub">{r.detail}</small></span><strong>{r.score}</strong></div>)}</div>
   <div className="card"><h2>Resolution controls</h2><p className="muted">Production actions use a transactional merge function, preserve a complete snapshot, move relationships to the surviving record, and support reversal.</p><div className="resolution-actions"><button className="btn button-reset">Merge records</button><button className="secondary-btn">Keep separate</button><button className="secondary-btn">Classify relationship</button><button className="secondary-btn">Defer</button></div><label className="muted">Relationship type</label><select className="input"><option>Parent / subsidiary</option><option>Owner / manager</option><option>Affiliate</option><option>Franchisor / franchisee</option><option>Unrelated</option></select></div>
  </div>
 </>
}
