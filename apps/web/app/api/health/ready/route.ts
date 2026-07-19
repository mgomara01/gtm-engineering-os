import {environmentReadiness} from '@/lib/launch-engine';import {getLaunchData} from '@/lib/data/launch';
export async function GET(){const result=environmentReadiness(getLaunchData().checks);return Response.json({status:result.ready?'ready':'not_ready',configured:result.configured,total:result.total,missing:result.missing.map(x=>x.name)},{status:result.ready?200:503});}
