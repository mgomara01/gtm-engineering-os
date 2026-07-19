export type PilotGate={id:string;name:string;status:'pass'|'warning'|'fail';blocking:boolean;owner:string;evidence:string};
export type UatScenario={id:string;name:string;status:'not_started'|'in_progress'|'passed'|'failed'|'blocked';executed:number;passed:number;failed:number;blockingDefects:number};
export type PilotDefect={id:string;title:string;severity:'critical'|'high'|'medium'|'low';status:'open'|'triaged'|'in_progress'|'resolved'|'accepted'};
export type CutoverTask={id:string;name:string;status:'not_started'|'ready'|'running'|'validated'|'rolled_back';blocking:boolean};
export type PilotWorkspace={name:string;goLiveApproved:boolean};
