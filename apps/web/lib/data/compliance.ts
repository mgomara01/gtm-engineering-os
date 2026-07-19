import type { AuditEngagement, ComplianceException, ControlAttestation, EvidenceRequest, Policy, RegulatoryObligation } from '../compliance-types';
export function getComplianceData(){
 const policies:Policy[]=[
  {id:'POL-001',title:'Information Security Policy',owner:'Security Operations',status:'approved',version:'3.2',framework:'SOC 2 / ISO 27001',approvedAt:'2026-04-15',nextReviewAt:'2027-04-15',acknowledgementsRequired:112,acknowledgementsComplete:108},
  {id:'POL-002',title:'Business Continuity Policy',owner:'Enterprise Risk',status:'approved',version:'2.0',framework:'NIST / Internal',approvedAt:'2025-06-01',nextReviewAt:'2026-06-01',acknowledgementsRequired:36,acknowledgementsComplete:31},
  {id:'POL-003',title:'AI Governance Standard',owner:'AI Governance Council',status:'in_review',version:'1.1',framework:'NIST AI RMF',approvedAt:null,nextReviewAt:'2026-08-30',acknowledgementsRequired:22,acknowledgementsComplete:0}
 ];
 const obligations:RegulatoryObligation[]=[
  {id:'OBL-01',framework:'SOC 2',citation:'CC6.1',requirement:'Logical access is authorized, provisioned, reviewed, and removed.',owner:'Identity Operations',status:'compliant',controlIds:['CTRL-IAM-01','CTRL-IAM-03'],evidenceIds:['EV-101','EV-102'],dueAt:'2026-09-30',jurisdiction:'Contractual'},
  {id:'OBL-02',framework:'Florida Digital Bill of Rights',citation:'Fla. Stat. 501.701-719',requirement:'Consumer privacy requests are authenticated and completed within statutory periods.',owner:'Privacy Operations',status:'at_risk',controlIds:['CTRL-PRIV-02','CTRL-PRIV-04'],evidenceIds:['EV-201'],dueAt:'2026-08-15',jurisdiction:'Florida'},
  {id:'OBL-03',framework:'PCI DSS',citation:'12.10',requirement:'Incident response procedures are established, tested, and maintained.',owner:'Security Operations',status:'compliant',controlIds:['CTRL-IR-01'],evidenceIds:['EV-301'],dueAt:'2026-12-31',jurisdiction:'Contractual'}
 ];
 const evidence:EvidenceRequest[]=[
  {id:'EVR-1001',title:'Q2 privileged-access review',owner:'Identity Operations',requestedBy:'Baker Audit LLP',status:'accepted',dueAt:'2026-07-10',submittedAt:'2026-07-08',controlId:'CTRL-IAM-03',artifactUrl:'/evidence/q2-access-review',periodStart:'2026-04-01',periodEnd:'2026-06-30'},
  {id:'EVR-1002',title:'Restore-test results and exceptions',owner:'Platform Engineering',requestedBy:'Baker Audit LLP',status:'submitted',dueAt:'2026-07-22',submittedAt:'2026-07-18',controlId:'CTRL-BCP-04',artifactUrl:'/evidence/restore-tests',periodStart:'2026-01-01',periodEnd:'2026-06-30'},
  {id:'EVR-1003',title:'Privacy request completion sample',owner:'Privacy Operations',requestedBy:'Internal Audit',status:'overdue',dueAt:'2026-07-12',submittedAt:null,controlId:'CTRL-PRIV-02',artifactUrl:null,periodStart:'2026-04-01',periodEnd:'2026-06-30'}
 ];
 const attestations:ControlAttestation[]=[
  {id:'ATT-01',controlId:'CTRL-IAM-03',controlName:'Quarterly access certification',owner:'Identity Operations',period:'2026-Q2',attestedAt:'2026-07-09',effective:true,exceptions:1,reviewer:'Security Assurance'},
  {id:'ATT-02',controlId:'CTRL-BCP-04',controlName:'Semiannual restore testing',owner:'Platform Engineering',period:'2026-H1',attestedAt:'2026-07-18',effective:false,exceptions:2,reviewer:'Enterprise Risk'},
  {id:'ATT-03',controlId:'CTRL-PRIV-02',controlName:'Privacy request SLA monitoring',owner:'Privacy Operations',period:'2026-Q2',attestedAt:null,effective:null,exceptions:0,reviewer:'Legal'}
 ];
 const audits:AuditEngagement[]=[
  {id:'AUD-26-01',name:'SOC 2 Type II',auditor:'Baker Audit LLP',framework:'AICPA Trust Services Criteria',owner:'Security Assurance',status:'fieldwork',startAt:'2026-07-01',endAt:'2026-09-15',requestsOpen:4,findingsOpen:1,opinion:'pending'},
  {id:'AUD-26-02',name:'Privacy Operations Review',auditor:'Internal Audit',framework:'Florida privacy requirements',owner:'Privacy Operations',status:'remediation',startAt:'2026-05-01',endAt:'2026-08-31',requestsOpen:1,findingsOpen:2,opinion:'pending'}
 ];
 const exceptions:ComplianceException[]=[
  {id:'EXC-014',title:'Legacy integration cannot enforce SSO',controlId:'CTRL-IAM-01',owner:'Business Systems',status:'approved',risk:'high',compensatingControl:'IP allowlist and monthly access review',approvedBy:'CISO',expiresAt:'2026-09-30',remediationPlan:'Replace legacy connector in Q3 release.'},
  {id:'EXC-015',title:'Configuration restore test incomplete',controlId:'CTRL-BCP-04',owner:'Platform Engineering',status:'expired',risk:'medium',compensatingControl:'Immutable source repository and manual export',approvedBy:'Enterprise Risk',expiresAt:'2026-07-01',remediationPlan:'Complete automated restore exercise.'}
 ];
 return {policies,obligations,evidence,attestations,audits,exceptions};
}
