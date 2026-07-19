import { cookies } from 'next/headers';
import { getAccessibleWorkspaces } from '@/lib/data/workspaces';

export async function getWorkspaceContext() {
  const workspaces = await getAccessibleWorkspaces();
  const cookieStore = await cookies();
  const requestedId = cookieStore.get('gtm_workspace_id')?.value;
  const activeWorkspace = workspaces.find((item) => item.id === requestedId) ?? workspaces[0] ?? null;
  return { workspaces, activeWorkspace };
}
