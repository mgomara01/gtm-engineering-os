import { createClient } from '@/lib/supabase/server';
import { demoStages } from '@/lib/data/demo';
import type { ImplementationStage } from '@/lib/types';

export async function getImplementationStages(workspaceId: string): Promise<ImplementationStage[]> {
  const supabase = await createClient();
  if (!supabase) return demoStages;
  const { data, error } = await supabase
    .schema('implementation')
    .from('stage_dashboard')
    .select('*')
    .eq('workspace_id', workspaceId)
    .order('stage_number');
  if (error) throw new Error(error.message);
  return (data ?? []).map((row) => ({
    id: row.id,
    stageNumber: row.stage_number,
    name: row.name,
    objective: row.objective,
    status: row.status,
    completionPercentage: Number(row.completion_percentage),
    targetDate: row.target_date ?? undefined,
    owner: row.owner_name ?? 'Unassigned',
    deliverablesComplete: Number(row.deliverables_complete),
    deliverablesRequired: Number(row.deliverables_required),
    openDecisions: Number(row.open_decisions),
    openRisks: Number(row.open_risks),
    readinessScore: Number(row.readiness_score),
  }));
}
