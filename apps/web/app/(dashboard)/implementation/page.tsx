import { ImplementationManager } from '@/components/implementation/implementation-manager';
import { getImplementationStages } from '@/lib/data/implementation';
import { getWorkspaceContext } from '@/lib/workspace-context';

export default async function Page(){
  const { activeWorkspace }=await getWorkspaceContext();
  const stages=await getImplementationStages(activeWorkspace!.id);
  return <ImplementationManager initialStages={stages} workspaceId={activeWorkspace!.id}/>;
}
