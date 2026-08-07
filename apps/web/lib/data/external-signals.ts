import { createClient } from '@/lib/supabase/server';
import type { ExternalSignal } from '@/lib/connectors/connector-types';

export interface ExternalSignalRow{id:string;source:string;category:string;externalRef:string;title:string;location:string|null;severity:string;detail:Record<string,unknown>;observedAt:string|null;fetchedAt:string;}

export async function getExternalSignals(workspaceId:string):Promise<ExternalSignalRow[]>{
  const supabase = await createClient();
  if (!supabase) return [];
  const { data, error } = await supabase
    .schema('ingestion')
    .from('external_signals')
    .select('id,source,category,external_ref,title,location,severity,detail,observed_at,fetched_at')
    .eq('workspace_id', workspaceId)
    .order('fetched_at', { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []).map((row) => ({
    id: row.id, source: row.source, category: row.category, externalRef: row.external_ref,
    title: row.title, location: row.location, severity: row.severity, detail: row.detail,
    observedAt: row.observed_at, fetchedAt: row.fetched_at,
  }));
}

export async function upsertExternalSignals(workspaceId:string,signals:ExternalSignal[]):Promise<number>{
  const supabase = await createClient();
  if (!supabase || !signals.length) return 0;
  const rows = signals.map((s) => ({
    workspace_id: workspaceId, source: s.source, category: s.category, external_ref: s.externalRef,
    title: s.title, location: s.location, severity: s.severity, detail: s.detail, observed_at: s.observedAt,
    fetched_at: new Date().toISOString(),
  }));
  const { error } = await supabase.schema('ingestion').from('external_signals').upsert(rows, { onConflict: 'workspace_id,source,external_ref' });
  if (error) throw new Error(error.message);
  return rows.length;
}
