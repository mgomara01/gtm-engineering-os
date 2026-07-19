import type {EnvironmentCheck,LaunchGate,RecoveryControl} from '../launch-types';
export function getLaunchData(){const gates:LaunchGate[]=[
{id:'g1',category:'environment',name:'Production environment variables',status:'warning',blocking:true,evidence:'Required secret references are documented; production values are not present in this source package.',owner:'Infrastructure'},
{id:'g2',category:'security',name:'RLS and permission tests',status:'pass',blocking:true,evidence:'Workspace RLS policies and permission contracts exist through migration 0019.',owner:'Engineering'},
{id:'g3',category:'data',name:'Demo and production data separation',status:'pass',blocking:true,evidence:'Demo workspaces are explicit and production seed mode is independently controlled.',owner:'Data'},
{id:'g4',category:'operations',name:'Worker and queue deployment',status:'fail',blocking:true,evidence:'Production queue workers, retry policies, and dead-letter queues still require deployment.',owner:'Infrastructure'},
{id:'g5',category:'recovery',name:'Backup restore drill',status:'warning',blocking:true,evidence:'Runbook and verification queries are included; a live restore drill is not evidenced.',owner:'Infrastructure'},
{id:'g6',category:'testing',name:'Automated release suite',status:'pass',blocking:true,evidence:'TypeScript, unit, build, and browser smoke-test contracts are configured.',owner:'Engineering'},
{id:'g7',category:'security',name:'Outbound consent enforcement',status:'fail',blocking:true,evidence:'Suppression and consent controls are not connected to production providers.',owner:'Compliance'},
];
const checks:EnvironmentCheck[]=[
{name:'NEXT_PUBLIC_SUPABASE_URL',required:true,configured:Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL),scope:'public',description:'Supabase project URL'},
{name:'NEXT_PUBLIC_SUPABASE_ANON_KEY',required:true,configured:Boolean(process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY),scope:'public',description:'Supabase anonymous key'},
{name:'SUPABASE_SERVICE_ROLE_KEY',required:true,configured:Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),scope:'server',description:'Server-only administrative key'},
{name:'SENTRY_DSN',required:false,configured:Boolean(process.env.SENTRY_DSN),scope:'server',description:'Error monitoring'},
{name:'POSTHOG_KEY',required:false,configured:Boolean(process.env.POSTHOG_KEY),scope:'server',description:'Product analytics'},
];
const recovery:RecoveryControl[]=[
{id:'r1',name:'PostgreSQL point-in-time recovery',rpoHours:1,rtoHours:4,status:'warning',evidence:'Target defined; live restore test pending.'},
{id:'r2',name:'Storage object recovery',rpoHours:24,rtoHours:8,status:'warning',evidence:'Versioning and export procedure documented; test pending.'},
{id:'r3',name:'Configuration repository recovery',rpoHours:0,rtoHours:1,lastTested:'2026-07-18',status:'pass',evidence:'Git source archive and migrations are reproducible.'},
];return{gates,checks,recovery};}
