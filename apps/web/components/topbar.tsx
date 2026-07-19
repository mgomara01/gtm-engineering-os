import { WorkspaceSelector } from '@/components/workspace/workspace-selector';
import { appEnvironment } from '@/lib/env';
import type { WorkspaceSummary } from '@/lib/types';

export function Topbar({ workspaces, activeWorkspace }: { workspaces: WorkspaceSummary[]; activeWorkspace: WorkspaceSummary | null }) {
  return <div className="topbar"><WorkspaceSelector workspaces={workspaces} activeId={activeWorkspace?.id}/><div className="topbar-actions"><span className="pill">{appEnvironment.toUpperCase()}</span><span>Role: {activeWorkspace?.role.replaceAll('_',' ') ?? 'none'}</span></div></div>;
}
