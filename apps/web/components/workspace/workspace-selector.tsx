'use client';
import { useRouter } from 'next/navigation';
import type { WorkspaceSummary } from '@/lib/types';

export function WorkspaceSelector({ workspaces, activeId }: { workspaces: WorkspaceSummary[]; activeId?: string }) {
  const router = useRouter();
  function changeWorkspace(id: string) {
    document.cookie = `gtm_workspace_id=${id}; path=/; max-age=31536000; samesite=lax`;
    router.refresh();
  }
  return <label className="workspace-select"><span className="sr-only">Active workspace</span><select value={activeId} onChange={(event)=>changeWorkspace(event.target.value)}>{workspaces.map((workspace)=><option key={workspace.id} value={workspace.id}>{workspace.name}</option>)}</select></label>;
}
