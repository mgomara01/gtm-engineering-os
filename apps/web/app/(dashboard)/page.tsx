import { getWorkspaceContext } from '@/lib/workspace-context';
import { getImplementationStages } from '@/lib/data/implementation';
import { getMetricViews, getAlerts } from '@/lib/data/analytics';
import { formatMetric } from '@/lib/analytics-engine';
export default async function Page(){
  const {activeWorkspace}=await getWorkspaceContext();
  const [stages,scorecard,alerts]=await Promise.all([getImplementationStages(activeWorkspace!.id),getMetricViews(activeWorkspace!.id),getAlerts(activeWorkspace!.id)]);
  const current=stages.find(stage=>stage.status==='active') ?? stages[0];
  const byKey=(key:string)=>scorecard.find(m=>m.definition.key===key);
  const data=byKey('data_completeness'); const pipeline=byKey('weighted_pipeline');
  const metrics=[['Implementation stage',`${current.stageNumber} of 12`],['KPIs on track',`${scorecard.filter(m=>m.status==='on_track').length} of ${scorecard.length}`],['Weighted pipeline',pipeline?formatMetric(pipeline.result.value,pipeline.definition.format):'$0'],['Data completeness',data?formatMetric(data.result.value,data.definition.format):'Not measured'],['Open alerts',String(alerts.filter(a=>a.status==='open').length)],['Active risks',String(current.openRisks)]];
  return <><div className="hero"><div><h1>Workspace Overview</h1><p className="muted">{activeWorkspace!.name} is in {current.name}. Step 16 adds controlled management metrics, alerts, and an operating-review layer.</p></div><div className="action-row"><a className="secondary-btn" href="/implementation">Continue implementation</a><a className="btn" href="/analytics">Management dashboard</a></div></div><div className="grid cards section">{metrics.map(([a,b])=><div className="card" key={a}><div className="muted">{a}</div><div className="metric">{b}</div></div>)}</div><section className="section"><h2>Priority actions</h2><table className="table"><thead><tr><th>Action</th><th>Owner</th><th>Status</th></tr></thead><tbody><tr><td>Complete current-stage deliverables</td><td>{current.owner}</td><td><span className="pill">In progress</span></td></tr><tr><td>Resolve open stage decisions</td><td>Executive Sponsor</td><td>{current.openDecisions} open</td></tr><tr><td>Configure production data connection</td><td>Technical Administrator</td><td>Not started</td></tr></tbody></table></section></>;
}
