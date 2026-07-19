import type{ConfigurationPackage,PortabilityCheck,ProvisioningRequest,TemplateDiff,WorkspaceTemplate}from'./extensibility-types';
export function templateCompleteness(t:WorkspaceTemplate){const moduleScore=Math.min(60,t.modules.length*8),inputScore=Math.min(40,t.requiredInputs.length*5);return Math.min(100,moduleScore+inputScore)}
export function canPublishTemplate(t:WorkspaceTemplate){return t.name.trim().length>2&&t.modules.length>=4&&t.requiredInputs.length>=3&&templateCompleteness(t)>=60}
export function provisioningProgress(r:ProvisioningRequest){if(!r.checks.length)return 0;return Math.round(r.checks.filter(c=>c.passed).length/r.checks.length*100)}
export function canActivateWorkspace(r:ProvisioningRequest){return r.status==='ready'&&r.checks.length>0&&r.checks.every(c=>c.passed)}
export function portabilityStatus(p:PortabilityCheck){if(!p.schemaCompatible||p.conflicts>0)return'blocked';if(p.warnings>0)return'review';return'pass'}
export function packageFingerprint(p:Pick<ConfigurationPackage,'name'|'version'|'sections'|'compatibleSchema'>){return `${p.name.toLowerCase().replace(/[^a-z0-9]+/g,'-')}:v${p.version}:${p.compatibleSchema}:${[...p.sections].sort().join(',')}`}
export function diffRiskSummary(diffs:TemplateDiff[]){return{high:diffs.filter(d=>d.risk==='high').length,medium:diffs.filter(d=>d.risk==='medium').length,low:diffs.filter(d=>d.risk==='low').length}}
