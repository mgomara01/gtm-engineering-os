import type { MatchResult } from '@/lib/entity-resolution';
import { scoreOrganizationMatch } from '@/lib/entity-resolution';
import { createClient } from '@/lib/supabase/server';

export type ResolutionCandidate = {
  id: string;
  workspaceId: string;
  left: { id:string; name:string; website?:string; phone?:string; address?:string; city?:string; state?:string; source:string };
  right: { id:string; name:string; website?:string; phone?:string; address?:string; city?:string; state?:string; source:string };
  match: MatchResult;
  status: 'pending'|'merged'|'kept_separate'|'related'|'deferred';
  relationshipType?: string;
};

const demoPairs = [
  {
    id:'merge-001', workspaceId:'11111111-1111-1111-1111-111111111111',
    left:{id:'org-alvarez-002',name:'Harbor Hospitality Group',website:'harborhospitality.example',phone:'(727) 555-0198',address:'455 S Gulfview Blvd',city:'Clearwater',state:'FL',source:'Excel Import'},
    right:{id:'org-source-7782',name:'Harbor Hospitality Group LLC',website:'www.harborhospitality.example',phone:'727-555-0198',address:'455 South Gulfview Boulevard',city:'Clearwater',state:'FL',source:'AI Research'}, status:'pending' as const,
  },
  {
    id:'merge-002', workspaceId:'11111111-1111-1111-1111-111111111111',
    left:{id:'org-alvarez-001',name:'Bayview Medical Properties',website:'bayviewmedical.example',phone:'(813) 555-0140',address:'4100 N Dale Mabry Hwy',city:'Tampa',state:'FL',source:'ServiceTitan'},
    right:{id:'org-source-5509',name:'Bayview Medical Property Management',website:'bayviewmedicalproperties.example',phone:'813-555-0149',address:'4100 North Dale Mabry Highway',city:'Tampa',state:'FL',source:'County Records'}, status:'pending' as const,
  },
  {
    id:'merge-003', workspaceId:'11111111-1111-1111-1111-111111111111',
    left:{id:'org-alvarez-003',name:'Westshore Commerce Center',address:'500 N Westshore Blvd',city:'Tampa',state:'FL',source:'ServiceTitan'},
    right:{id:'org-source-9910',name:'Westshore Commercial Holdings',address:'500 N Westshore Blvd',city:'Tampa',state:'FL',source:'Property Appraiser'}, status:'pending' as const,
  }
];

const materialize = (row: typeof demoPairs[number]): ResolutionCandidate => ({...row,match:scoreOrganizationMatch(row.left,row.right)});

export async function getResolutionCandidates(workspaceId:string):Promise<ResolutionCandidate[]> {
  const supabase=await createClient();
  if(!supabase) return demoPairs.filter(x=>x.workspaceId===workspaceId).map(materialize);
  const {data,error}=await supabase.schema('ingestion').from('merge_candidate_directory').select('*').eq('workspace_id',workspaceId).order('match_score',{ascending:false});
  if(error) throw new Error(error.message);
  return (data??[]).map((r:any)=>({id:r.id,workspaceId:r.workspace_id,left:r.left_record,right:r.right_record,match:{score:Number(r.match_score),decision:r.recommended_action,reasons:r.match_reasons??[]},status:r.status,relationshipType:r.relationship_type??undefined}));
}

export async function getResolutionCandidate(workspaceId:string,id:string):Promise<ResolutionCandidate|null>{
  return (await getResolutionCandidates(workspaceId)).find(x=>x.id===id)??null;
}
