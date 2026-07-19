import type {ActivationControl,ConsentRecord,DeadLetterItem,SuppressionRecord,WorkerQueue} from '../activation-types';
export function getActivationData(){const controls:ActivationControl[]=[
{id:'a1',name:'Queue workers deployed',category:'workers',status:'pass',blocking:true,evidence:'Research, enrichment, scoring, campaign, and integration worker contracts are registered.',owner:'Infrastructure'},
{id:'a2',name:'Dead-letter handling',category:'workers',status:'pass',blocking:true,evidence:'Bounded retries and replay-safe dead-letter review are configured.',owner:'Engineering'},
{id:'a3',name:'Consent verification',category:'consent',status:'pass',blocking:true,evidence:'Every outbound channel requires an active, source-backed consent record.',owner:'Compliance'},
{id:'a4',name:'Suppression enforcement',category:'consent',status:'pass',blocking:true,evidence:'Workspace and global suppressions are evaluated before provider dispatch.',owner:'Compliance'},
{id:'a5',name:'Provider credentials',category:'providers',status:'warning',blocking:true,evidence:'Secret references exist; live credentials must be injected in the target environment.',owner:'Infrastructure'},
{id:'a6',name:'Restore-test evidence',category:'recovery',status:'warning',blocking:true,evidence:'Evidence model and runbook are complete; a live production-like restore remains required.',owner:'Infrastructure'},
{id:'a7',name:'Worker monitoring and alerts',category:'monitoring',status:'pass',blocking:true,evidence:'Queue depth, oldest job age, failure rate, and dead-letter growth have thresholds.',owner:'Operations'},
];
const queues:WorkerQueue[]=[
{id:'q1',name:'research',status:'healthy',pending:4,running:2,failed:0,oldestAgeMinutes:3,maxAttempts:5,deadLetterEnabled:true},
{id:'q2',name:'enrichment',status:'healthy',pending:8,running:3,failed:0,oldestAgeMinutes:5,maxAttempts:5,deadLetterEnabled:true},
{id:'q3',name:'campaign-dispatch',status:'degraded',pending:12,running:1,failed:2,oldestAgeMinutes:18,maxAttempts:4,deadLetterEnabled:true},
{id:'q4',name:'integration-sync',status:'healthy',pending:2,running:1,failed:0,oldestAgeMinutes:2,maxAttempts:6,deadLetterEnabled:true},
];
const consents:ConsentRecord[]=[
{id:'c1',subject:'facilities@example.com',channel:'email',state:'granted',source:'website_form',verifiedAt:'2026-07-17T15:00:00Z'},
{id:'c2',subject:'+18135550199',channel:'sms',state:'unknown',source:'legacy_import'},
{id:'c3',subject:'operations@example.com',channel:'email',state:'expired',source:'event_registration',verifiedAt:'2025-01-10T10:00:00Z',expiresAt:'2026-01-10T10:00:00Z'},
];
const suppressions:SuppressionRecord[]=[{id:'s1',subject:'do-not-contact@example.com',channel:'all',reason:'Customer opt-out',active:true,createdAt:'2026-07-12T12:00:00Z'}];
const deadLetters:DeadLetterItem[]=[
{id:'d1',queue:'campaign-dispatch',jobType:'send_email',attempts:4,failedAt:'2026-07-18T17:25:00Z',errorCode:'provider_timeout',errorMessage:'Provider did not acknowledge before timeout.',replaySafe:true},
{id:'d2',queue:'campaign-dispatch',jobType:'send_sms',attempts:1,failedAt:'2026-07-18T17:40:00Z',errorCode:'invalid_consent',errorMessage:'No active SMS consent was present.',replaySafe:false},
];return{controls,queues,consents,suppressions,deadLetters};}
