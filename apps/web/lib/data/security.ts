import type { DataAsset, PrivacyRequest, SecurityControl, SecurityEvent, SecurityFinding } from '../security-types';

export function getSecurityData() {
  const controls: SecurityControl[] = [
    { id:'ctl-1', framework:'SOC2', code:'CC6.1', title:'Logical access controls', owner:'Security Engineering', status:'effective', lastTestedAt:'2026-06-30T14:00:00Z', nextTestAt:'2026-09-30T14:00:00Z', evidenceCount:12 },
    { id:'ctl-2', framework:'SOC2', code:'CC7.2', title:'Security event monitoring', owner:'Security Operations', status:'partial', lastTestedAt:'2026-07-05T14:00:00Z', nextTestAt:'2026-08-05T14:00:00Z', evidenceCount:7 },
    { id:'ctl-3', framework:'NIST', code:'PR.DS-1', title:'Data at rest protection', owner:'Data Platform', status:'effective', lastTestedAt:'2026-07-01T14:00:00Z', nextTestAt:'2026-10-01T14:00:00Z', evidenceCount:9 },
    { id:'ctl-4', framework:'Internal', code:'SEC-14', title:'Production secret rotation', owner:'Platform Engineering', status:'ineffective', lastTestedAt:'2026-07-12T14:00:00Z', nextTestAt:'2026-07-19T14:00:00Z', evidenceCount:2 },
    { id:'ctl-5', framework:'ISO27001', code:'A.8.8', title:'Technical vulnerability management', owner:'Security Operations', status:'not_tested', lastTestedAt:null, nextTestAt:'2026-07-25T14:00:00Z', evidenceCount:0 }
  ];
  const findings: SecurityFinding[] = [
    { id:'SEC-2026-041', title:'Expired production integration credential', severity:'critical', status:'mitigating', asset:'ServiceTitan connector', owner:'Integration Operations', discoveredAt:'2026-07-18T16:20:00Z', dueAt:'2026-07-20T16:20:00Z', exploitAvailable:false, internetExposed:false },
    { id:'SEC-2026-040', title:'Webhook endpoint permits broad outbound destinations', severity:'high', status:'open', asset:'Webhook delivery service', owner:'Platform Engineering', discoveredAt:'2026-07-12T10:00:00Z', dueAt:'2026-07-26T10:00:00Z', exploitAvailable:true, internetExposed:true },
    { id:'SEC-2026-038', title:'Legacy user role exceeds current job responsibilities', severity:'medium', status:'open', asset:'Workspace authorization', owner:'Business Systems', discoveredAt:'2026-06-01T12:00:00Z', dueAt:'2026-07-16T12:00:00Z', exploitAvailable:false, internetExposed:false },
    { id:'SEC-2026-033', title:'Missing security headers on staging callback', severity:'low', status:'resolved', asset:'Staging web application', owner:'Platform Engineering', discoveredAt:'2026-05-10T12:00:00Z', dueAt:'2026-08-08T12:00:00Z', exploitAvailable:false, internetExposed:true }
  ];
  const assets: DataAsset[] = [
    { id:'data-1', name:'Customer contact and property records', system:'Primary database', classification:'restricted', owner:'Revenue Operations', personalData:true, retentionDays:2555, encryptionAtRest:true, encryptionInTransit:true },
    { id:'data-2', name:'API request telemetry', system:'Observability store', classification:'confidential', owner:'Platform Engineering', personalData:false, retentionDays:90, encryptionAtRest:true, encryptionInTransit:true },
    { id:'data-3', name:'Imported source files', system:'Object storage', classification:'restricted', owner:'Data Governance', personalData:true, retentionDays:3650, encryptionAtRest:true, encryptionInTransit:true },
    { id:'data-4', name:'Public marketing content', system:'Content repository', classification:'public', owner:'Marketing', personalData:false, retentionDays:0, encryptionAtRest:true, encryptionInTransit:true }
  ];
  const privacyRequests: PrivacyRequest[] = [
    { id:'PRIV-2026-018', type:'deletion', status:'in_progress', jurisdiction:'Florida', receivedAt:'2026-07-02T14:00:00Z', dueAt:'2026-08-16T14:00:00Z', verifiedAt:'2026-07-03T11:00:00Z', owner:'Privacy Operations' },
    { id:'PRIV-2026-017', type:'access', status:'verified', jurisdiction:'California', receivedAt:'2026-06-10T14:00:00Z', dueAt:'2026-07-25T14:00:00Z', verifiedAt:'2026-06-11T11:00:00Z', owner:'Privacy Operations' },
    { id:'PRIV-2026-016', type:'opt_out', status:'completed', jurisdiction:'California', receivedAt:'2026-06-01T14:00:00Z', dueAt:'2026-06-16T14:00:00Z', verifiedAt:'2026-06-01T16:00:00Z', owner:'Marketing Operations' }
  ];
  const events: SecurityEvent[] = [
    { id:'evt-1', category:'authentication', severity:'high', occurredAt:'2026-07-18T21:42:00Z', source:'Identity provider', disposition:'investigating', summary:'Repeated failed administrator authentication from a new network.' },
    { id:'evt-2', category:'configuration', severity:'medium', occurredAt:'2026-07-18T19:05:00Z', source:'Cloud configuration monitor', disposition:'contained', summary:'Public access policy detected and reverted on a staging storage bucket.' },
    { id:'evt-3', category:'data_access', severity:'low', occurredAt:'2026-07-18T17:14:00Z', source:'Database audit log', disposition:'benign', summary:'Bulk export matched an approved operating-review workflow.' }
  ];
  return { controls, findings, assets, privacyRequests, events };
}
