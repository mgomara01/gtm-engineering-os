export type ClosureStatus = 'open' | 'verified' | 'waived';
export type DeploymentStatus = 'planned' | 'in_progress' | 'completed' | 'rolled_back';
export type VerificationStatus = 'pending' | 'passed' | 'failed';
export type LaunchBlockerClosure = {id:string;source:string;description:string;owner:string;status:ClosureStatus;evidence:string;verifiedAt:string|null;};
export type ProductionRelease = {id:string;version:string;environment:string;strategy:'rolling'|'blue_green'|'canary';status:DeploymentStatus;startedAt:string|null;completedAt:string|null;rollbackAvailable:boolean;changeTicket:string;};
export type PostLaunchCheck = {id:string;name:string;owner:string;required:boolean;status:VerificationStatus;observedValue:string;threshold:string;checkedAt:string|null;};
export type LaunchAuthorization = {id:string;role:string;approver:string;status:'pending'|'approved'|'rejected';decision:string;approvedAt:string|null;};
export type ReleaseArtifact = {id:string;name:string;kind:'source'|'migration'|'runbook'|'release_notes'|'evidence';checksum:string;status:'verified'|'missing';};
