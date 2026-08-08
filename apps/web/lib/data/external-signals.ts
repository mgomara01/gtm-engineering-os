import { createClient } from '@/lib/supabase/server';
import type { ExternalSignal } from '@/lib/connectors/connector-types';
import { scoreExternalSignal } from '@/lib/signal-scoring';

export interface ExternalSignalRow{id:string;source:string;category:string;externalRef:string;title:string;location:string|null;severity:string;detail:Record<string,unknown>;observedAt:string|null;fetchedAt:string;opportunityScore:number|null;priorityTier:string|null;}

export async function getExternalSignals(workspaceId:string):Promise<ExternalSignalRow[]>{
  const supabase = await createClient();
  if (!supabase) return [];
  const { data, error } = await supabase
    .schema('ingestion')
    .from('external_signals')
    .select('id,source,category,external_ref,title,location,severity,detail,observed_at,fetched_at,opportunity_score,priority_tier')
    .eq('workspace_id', workspaceId)
    .order('opportunity_score', { ascending: false, nullsFirst: false })
    .order('fetched_at', { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []).map((row) => ({
    id: row.id, source: row.source, category: row.category, externalRef: row.external_ref,
    title: row.title, location: row.location, severity: row.severity, detail: row.detail,
    observedAt: row.observed_at, fetchedAt: row.fetched_at,
    opportunityScore: row.opportunity_score, priorityTier: row.priority_tier,
  }));
}

export async function upsertExternalSignals(workspaceId:string,signals:ExternalSignal[]):Promise<number>{
  const supabase = await createClient();
  if (!supabase || !signals.length) return 0;
  const rows = signals.map((s) => {
    const { score, tier } = scoreExternalSignal(s);
    return {
      workspace_id: workspaceId, source: s.source, category: s.category, external_ref: s.externalRef,
      title: s.title, location: s.location, severity: s.severity, detail: s.detail, observed_at: s.observedAt,
      fetched_at: new Date().toISOString(), opportunity_score: score, priority_tier: tier,
    };
  });
  const { error } = await supabase.schema('ingestion').from('external_signals').upsert(rows, { onConflict: 'workspace_id,source,external_ref' });
  if (error) throw new Error(error.message);
  return rows.length;
}
