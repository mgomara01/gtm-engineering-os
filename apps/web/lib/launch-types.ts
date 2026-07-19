export type GateStatus='pass'|'warning'|'fail';
export type LaunchGate={id:string;category:'environment'|'security'|'data'|'operations'|'recovery'|'testing';name:string;status:GateStatus;blocking:boolean;evidence:string;owner:string};
export type RecoveryControl={id:string;name:string;rpoHours:number;rtoHours:number;lastTested?:string;status:GateStatus;evidence:string};
export type EnvironmentCheck={name:string;required:boolean;configured:boolean;scope:'server'|'public';description:string};
