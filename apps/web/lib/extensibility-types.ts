export type TemplateStatus='draft'|'published'|'retired';
export type ProvisioningStatus='requested'|'validating'|'provisioning'|'ready'|'failed';
export interface WorkspaceTemplate{id:string;name:string;industry:string;version:number;status:TemplateStatus;description:string;modules:string[];requiredInputs:string[];sourceWorkspace?:string;updatedAt:string}
export interface ConfigurationPackage{id:string;name:string;templateId:string;version:number;checksum:string;sections:string[];exportedAt:string;compatibleSchema:string}
export interface ProvisioningRequest{id:string;workspaceName:string;templateId:string;owner:string;status:ProvisioningStatus;requestedAt:string;completedAt?:string;checks:{name:string;passed:boolean;detail:string}[]}
export interface PortabilityCheck{id:string;packageId:string;targetWorkspace:string;schemaCompatible:boolean;conflicts:number;warnings:number;status:'pass'|'review'|'blocked'}
export interface TemplateDiff{section:string;change:'added'|'changed'|'removed';summary:string;risk:'low'|'medium'|'high'}
