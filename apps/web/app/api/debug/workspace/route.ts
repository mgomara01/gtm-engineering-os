import { createClient } from '@/lib/supabase/server';

// TEMPORARY diagnostic route -- returns the real error messages from the
// dashboard's data queries instead of the swallowed production digest.
// Remove after the crash on '/' is diagnosed.
export async function GET() {
  const supabase = await createClient();
  if (!supabase) return Response.json({ step: 'client', error: 'no supabase config' }, { status: 500 });

  const { data: auth, error: authError } = await supabase.auth.getUser();
  if (authError || !auth.user) {
    return Response.json({ step: 'auth', authError: authError?.message ?? null, user: auth.user ?? null });
  }

  const workspaces = await supabase
    .schema('platform')
    .from('user_workspace_access')
    .select('workspace_id,name,code,status,role_code,current_stage');

  const firstWorkspaceId = workspaces.data?.[0]?.workspace_id;

  const stages = firstWorkspaceId
    ? await supabase.schema('implementation').from('stage_dashboard').select('*').eq('workspace_id', firstWorkspaceId).order('stage_number')
    : { data: null, error: { message: 'no workspace resolved, skipped' } };

  return Response.json({
    userId: auth.user.id,
    userEmail: auth.user.email,
    workspaces: { data: workspaces.data, error: workspaces.error?.message ?? null },
    stages: { data: stages.data, error: stages.error?.message ?? null },
  });
}
