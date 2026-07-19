export type FactorKind='calculated'|'ai_assisted'|'manual';
export type Factor={id:string,name:string,description:string,kind:FactorKind,weight:number,enabled:boolean,hardExclusion?:boolean,exclusionReason?:string};
export type ScoringModel={id:string,workspaceId:string,name:string,description:string,status:'draft'|'active'|'retired',version:number,maxScore:number,priorityThresholds:{a:number,b:number,c:number},factors:Factor[],updatedAt:string};
export type FactorResult={factorId:string,factorName:string,rawScore:number,weightedScore:number,weight:number,explanation:string,evidence:string[],kind:FactorKind};
export type AccountScore={id:string,workspaceId:string,modelId:string,modelVersion:number,entityId:string,entityName:string,totalScore:number,priorityTier:'A'|'B'|'C'|'Excluded',excluded:boolean,exclusionReason?:string,confidence:number,runAt:string,factors:FactorResult[]};
export type SimulationInput={factors:Record<string,number>,excluded?:boolean,exclusionReason?:string};
