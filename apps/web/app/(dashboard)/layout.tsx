import { redirect } from 'next/navigation';
import { Sidebar } from '@/components/sidebar';
import { Topbar } from '@/components/topbar';
import { getWorkspaceContext } from '@/lib/workspace-context';

export default async function DashboardLayout({children}:{children:React.ReactNode}){
  const { workspaces, activeWorkspace } = await getWorkspaceContext();
  if (!activeWorkspace) redirect('/login');
  return <div className="shell"><Sidebar/><main className="main"><Topbar workspaces={workspaces} activeWorkspace={activeWorkspace}/>{children}</main></div>;
}
