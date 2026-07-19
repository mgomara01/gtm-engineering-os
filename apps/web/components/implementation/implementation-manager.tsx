'use client';
import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import type { ImplementationStage } from '@/lib/types';

export function ImplementationManager({ initialStages, workspaceId }: { initialStages: ImplementationStage[]; workspaceId: string }) {
  const storageKey=`gtm-implementation-${workspaceId}`;
  const [stages,setStages]=useState(initialStages);
  useEffect(()=>{const saved=localStorage.getItem(storageKey);if(saved){try{setStages(JSON.parse(saved))}catch{localStorage.removeItem(storageKey)}}},[storageKey]);
  useEffect(()=>{localStorage.setItem(storageKey,JSON.stringify(stages))},[stages,storageKey]);
  const overall=Math.round(stages.reduce((sum,stage)=>sum+stage.completionPercentage,0)/stages.length);
  const active=useMemo(()=>stages.find(stage=>stage.status==='active'),[stages]);
  function advanceDeliverable(stageId:string){setStages(current=>current.map(stage=>stage.id===stageId?{...stage,deliverablesComplete:Math.min(stage.deliverablesRequired,stage.deliverablesComplete+1),completionPercentage:Math.min(95,stage.completionPercentage+10)}:stage));}
  return <>
    <div className="hero"><div><h1>Implementation Manager</h1><p className="muted">Controlled lifecycle with deliverables, approval gates, and readiness scoring.</p></div><div className="status-summary"><strong>{overall}%</strong><span>overall completion</span></div></div>
    {active&&<section className="section card active-stage"><div><span className="pill">Current stage {active.stageNumber}</span><h2>{active.name}</h2><p>{active.objective}</p></div><div><div className="progress"><span style={{width:`${active.completionPercentage}%`}}/></div><p className="muted">{active.deliverablesComplete} of {active.deliverablesRequired} deliverables complete · readiness {active.readinessScore}%</p><button className="secondary-btn" onClick={()=>advanceDeliverable(active.id)}>Complete next demo deliverable</button></div></section>}
    <div className="stage-list section">{stages.map(stage=><article className="card stage-row" key={stage.id}><div className="stage-number">{stage.stageNumber}</div><div className="stage-copy"><div className="row-between"><h3>{stage.name}</h3><span className={`status status-${stage.status}`}>{stage.status.replace('_',' ')}</span></div><p className="muted">{stage.objective}</p><div className="progress small"><span style={{width:`${stage.completionPercentage}%`}}/></div><div className="stage-meta"><span>{stage.completionPercentage}% complete</span><span>{stage.openDecisions} decisions</span><span>{stage.openRisks} risks</span><span>Owner: {stage.owner}</span></div></div><Link className="text-link" href={`/implementation/${stage.id}`}>Open →</Link></article>)}</div>
  </>;
}
