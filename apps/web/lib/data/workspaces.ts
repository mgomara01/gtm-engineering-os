import { createClient } from '@/lib/supabase/server';
import { demoWorkspaces } from '@/lib/data/demo';
import type { WorkspaceSummary } from '@/lib/types';

export async function getAccessibleWorkspaces(): Promise<WorkspaceSummary[]> {
  const supabase = await createClient();
  if (!supabase) return demoWorkspaces;
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return [];
  const { data, error } = await supabase
    .schema('platform')
    .from('user_workspace_access')
    .select('workspace_id,name,code,status,role_code,current_stage');
  if (error) throw new Error(error.message);
  return (data ?? []).map((row) => ({
    id: row.workspace_id,
    name: row.name,
    code: row.code,
    status: row.status,
    role: row.role_code,
    currentStage: row.current_stage ?? 1,
  }));
}
