export type CohortStatus='planned'|'onboarding'|'live'|'stabilizing'|'graduated'|'paused';
export type RolloutCohort={id:string;name:string;workspace:string;users:number;certified:number;accounts:number;status:CohortStatus;owner:string;targetDate:string};
export type AdoptionMetric={id:string;name:string;actual:number;target:number;unit:'percent'|'count'|'days';direction:'higher'|'lower'};
export type MigrationControl={id:string;name:string;sourceCount:number;targetCount:number;exceptions:number;status:'not_started'|'running'|'reconciled'|'failed';blocking:boolean};
export type TrainingModule={id:string;name:string;assigned:number;completed:number;passingScore:number;averageScore:number;blocking:boolean};
export type HypercareIssue={id:string;title:string;severity:'critical'|'high'|'medium'|'low';status:'open'|'investigating'|'mitigated'|'resolved';owner:string;ageHours:number};
export type StabilizationGate={id:string;name:string;status:'pass'|'warning'|'fail';blocking:boolean;evidence:string};
