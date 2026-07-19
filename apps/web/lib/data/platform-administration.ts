import type {ConfigurationChange,EnvironmentRecord,SupportAccessGrant,TenantEntitlement,TenantHealthSignal,TenantRecord} from '../platform-administration-types';
export function getPlatformAdministrationData(){
const tenants:TenantRecord[]=[
{id:'TEN-001',name:'Alvarez Plumbing & Air',plan:'Enterprise',lifecycle:'active',health:'healthy',region:'us-east-1',owner:'Customer Success',createdAt:'2026-05-01T00:00:00Z',lastActivityAt:'2026-07-18T22:58:00Z',dataResidency:'United States'},
{id:'TEN-002',name:'Northstar Industrial',plan:'Growth',lifecycle:'active',health:'warning',region:'us-east-1',owner:'Customer Success',createdAt:'2026-06-10T00:00:00Z',lastActivityAt:'2026-07-18T21:14:00Z',dataResidency:'United States'},
{id:'TEN-003',name:'Pilot Workspace',plan:'Pilot',lifecycle:'provisioning',health:'healthy',region:'us-west-2',owner:'Implementation',createdAt:'2026-07-17T00:00:00Z',lastActivityAt:'2026-07-18T19:00:00Z',dataResidency:'United States'}];
const environments:EnvironmentRecord[]=[
{id:'ENV-DEV',name:'development',version:'0.35.0-rc.2',status:'healthy',configurationHash:'cfg-dev-811',lastDeploymentAt:'2026-07-18T20:00:00Z',promotionBlocked:false},
{id:'ENV-STG',name:'staging',version:'0.35.0-rc.1',status:'healthy',configurationHash:'cfg-stg-722',lastDeploymentAt:'2026-07-18T18:00:00Z',promotionBlocked:false},
{id:'ENV-PRD',name:'production',version:'0.34.0',status:'healthy',configurationHash:'cfg-prd-698',lastDeploymentAt:'2026-07-17T23:00:00Z',promotionBlocked:false}];
const changes:ConfigurationChange[]=[
{id:'CHG-101',environment:'production',category:'feature',summary:'Enable workflow approval analytics',status:'approved',risk:'medium',requestedBy:'Product Ops',approvedBy:'Platform Owner',scheduledAt:'2026-07-19T02:00:00Z'},
{id:'CHG-102',environment:'production',category:'security',summary:'Rotate connector encryption key',status:'scheduled',risk:'high',requestedBy:'Security',approvedBy:'Security Officer',scheduledAt:'2026-07-20T01:00:00Z'},
{id:'CHG-103',environment:'staging',category:'runtime',summary:'Increase background worker concurrency',status:'deployed',risk:'low',requestedBy:'SRE',approvedBy:'Platform Owner',scheduledAt:'2026-07-18T18:00:00Z'}];
const entitlements:TenantEntitlement[]=[
{id:'ENT-01',tenantId:'TEN-001',capability:'autonomous_agents',enabled:true,limit:25,source:'plan',expiresAt:null},
{id:'ENT-02',tenantId:'TEN-002',capability:'advanced_forecasting',enabled:true,limit:5,source:'override',expiresAt:'2026-08-01T00:00:00Z'},
{id:'ENT-03',tenantId:'TEN-003',capability:'connector_marketplace',enabled:true,limit:3,source:'trial',expiresAt:'2026-08-18T00:00:00Z'}];
const grants:SupportAccessGrant[]=[
{id:'SAG-01',tenantId:'TEN-002',engineer:'Raj Butta',status:'active',scope:['configuration:read','sync:retry'],reason:'Investigate failed CRM synchronization',requestedAt:'2026-07-18T20:00:00Z',expiresAt:'2026-07-19T02:00:00Z',approvedBy:'Tenant Admin'},
{id:'SAG-02',tenantId:'TEN-001',engineer:'Platform Support',status:'expired',scope:['logs:read'],reason:'Prior incident review',requestedAt:'2026-07-10T18:00:00Z',expiresAt:'2026-07-10T22:00:00Z',approvedBy:'Tenant Admin'}];
const signals:TenantHealthSignal[]=[
{id:'SIG-01',tenantId:'TEN-002',type:'sync',severity:'high',message:'CRM synchronization failure rate exceeds 5%.',openedAt:'2026-07-18T21:30:00Z',resolved:false},
{id:'SIG-02',tenantId:'TEN-001',type:'usage',severity:'low',message:'Workflow volume increased 18% week over week.',openedAt:'2026-07-18T17:00:00Z',resolved:false}];
return {tenants,environments,changes,entitlements,grants,signals};}
