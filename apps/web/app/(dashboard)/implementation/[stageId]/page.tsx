import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getImplementationStages } from '@/lib/data/implementation';
import { getWorkspaceContext } from '@/lib/workspace-context';

export default async function StagePage({params}:{params:Promise<{stageId:string}>}){
  const {stageId}=await params;
  const {activeWorkspace}=await getWorkspaceContext();
  const stages=await getImplementationStages(activeWorkspace!.id);
  const stage=stages.find(item=>item.id===stageId);
  if(!stage) notFound();
  return <><Link className="text-link" href="/implementation">← Implementation Manager</Link><div className="hero section"><div><span className="pill">Stage {stage.stageNumber}</span><h1>{stage.name}</h1><p className="muted">{stage.objective}</p></div><span className={`status status-${stage.status}`}>{stage.status.replace('_',' ')}</span></div><div className="grid two-col section"><section className="card"><h2>Completion controls</h2><div className="metric">{stage.completionPercentage}%</div><div className="progress"><span style={{width:`${stage.completionPercentage}%`}}/></div><dl className="detail-list"><div><dt>Deliverables</dt><dd>{stage.deliverablesComplete} / {stage.deliverablesRequired}</dd></div><div><dt>Readiness</dt><dd>{stage.readinessScore}%</dd></div><div><dt>Owner</dt><dd>{stage.owner}</dd></div><div><dt>Target date</dt><dd>{stage.targetDate ?? 'Not assigned'}</dd></div></dl></section><section className="card"><h2>Open controls</h2><div className="control-row"><span>Decisions requiring closure</span><strong>{stage.openDecisions}</strong></div><div className="control-row"><span>Active risks</span><strong>{stage.openRisks}</strong></div><div className="control-row"><span>Approval gate</span><strong>{stage.status==='complete'?'Approved':'Pending'}</strong></div><p className="notice">Stage completion is blocked until required deliverables, decisions, risks, readiness, and approvals satisfy policy.</p></section></div><section className="card section"><h2>Required deliverables</h2><table className="table embedded"><thead><tr><th>Deliverable</th><th>Owner</th><th>Status</th></tr></thead><tbody>{['Approved stage definition','Documented operating assumptions','Evidence package','Executive approval'].map((item,index)=><tr key={item}><td>{item}</td><td>{index===3?'Executive Sponsor':'GTM Administrator'}</td><td><span className="pill">{index<stage.deliverablesComplete?'Complete':'Required'}</span></td></tr>)}</tbody></table></section></>;
}
