import type {ConnectorAlert,ConnectorDefinition,ConnectorInstallation,FieldMapping,SyncJob} from '../integration-marketplace-types';
export function getIntegrationMarketplaceData(){
const connectors:ConnectorDefinition[]=[
{id:'CON-01',name:'Salesforce',category:'crm',status:'available',publisher:'GTM OS',version:'3.2.0',certified:true,scopes:['accounts:read','opportunities:write'],supportsWebhooks:true,supportsIncrementalSync:true},
{id:'CON-02',name:'HubSpot',category:'marketing',status:'available',publisher:'GTM OS',version:'2.8.1',certified:true,scopes:['contacts:read','campaigns:read'],supportsWebhooks:true,supportsIncrementalSync:true},
{id:'CON-03',name:'Snowflake',category:'data',status:'available',publisher:'GTM OS',version:'1.9.0',certified:true,scopes:['warehouse:read'],supportsWebhooks:false,supportsIncrementalSync:true},
{id:'CON-04',name:'Microsoft Teams',category:'communications',status:'beta',publisher:'GTM OS Labs',version:'0.9.4',certified:false,scopes:['messages:write'],supportsWebhooks:true,supportsIncrementalSync:false}
];
const installations:ConnectorInstallation[]=[
{id:'INS-01',connectorId:'CON-01',workspaceId:'WS-001',status:'healthy',credentialType:'oauth2',credentialExpiresAt:'2026-10-01T00:00:00Z',lastHealthCheckAt:'2026-07-18T22:55:00Z',owner:'Revenue Operations',environment:'production'},
{id:'INS-02',connectorId:'CON-02',workspaceId:'WS-001',status:'degraded',credentialType:'api_key',credentialExpiresAt:'2026-08-02T00:00:00Z',lastHealthCheckAt:'2026-07-18T22:52:00Z',owner:'Growth',environment:'production'},
{id:'INS-03',connectorId:'CON-03',workspaceId:'WS-001',status:'healthy',credentialType:'service_account',credentialExpiresAt:null,lastHealthCheckAt:'2026-07-18T22:58:00Z',owner:'Data Platform',environment:'production'}
];
const jobs:SyncJob[]=[
{id:'SYNC-01',installationId:'INS-01',objectType:'opportunities',direction:'bidirectional',status:'succeeded',startedAt:'2026-07-18T22:00:00Z',completedAt:'2026-07-18T22:03:00Z',recordsRead:1230,recordsWritten:1188,recordsFailed:0,retryCount:0,cursor:'sf-1922'},
{id:'SYNC-02',installationId:'INS-02',objectType:'contacts',direction:'inbound',status:'partial',startedAt:'2026-07-18T21:30:00Z',completedAt:'2026-07-18T21:39:00Z',recordsRead:8420,recordsWritten:8177,recordsFailed:243,retryCount:2,cursor:'hs-8831'},
{id:'SYNC-03',installationId:'INS-03',objectType:'executive_metrics',direction:'outbound',status:'succeeded',startedAt:'2026-07-18T22:15:00Z',completedAt:'2026-07-18T22:16:00Z',recordsRead:92,recordsWritten:92,recordsFailed:0,retryCount:0,cursor:'sw-123'}
];
const mappings:FieldMapping[]=[
{id:'MAP-01',installationId:'INS-01',sourceObject:'Opportunity',sourceField:'Amount',targetObject:'opportunity',targetField:'amountUsd',transform:'currency_normalize',required:true,active:true},
{id:'MAP-02',installationId:'INS-01',sourceObject:'Account',sourceField:'Website',targetObject:'account',targetField:'domain',transform:'domain_normalize',required:true,active:true},
{id:'MAP-03',installationId:'INS-02',sourceObject:'Contact',sourceField:'LifecycleStage',targetObject:'person',targetField:'lifecycleStage',transform:null,required:true,active:false}
];
const alerts:ConnectorAlert[]=[{id:'ALT-01',installationId:'INS-02',severity:'high',type:'auth',message:'API credential expires within 15 days.',openedAt:'2026-07-18T18:00:00Z',acknowledged:false},{id:'ALT-02',installationId:'INS-02',severity:'medium',type:'schema',message:'Lifecycle stage values require remapping.',openedAt:'2026-07-18T21:39:00Z',acknowledged:false}];
return {connectors,installations,jobs,mappings,alerts};}
