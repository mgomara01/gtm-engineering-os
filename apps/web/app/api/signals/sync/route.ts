import { getWorkspaceContext } from '@/lib/workspace-context';
import { fetchEpaEchoSdwaSignals } from '@/lib/connectors/epa-echo';
import { fetchUsgsStreamflowSignals } from '@/lib/connectors/usgs-water';
import { fetchTampaAgingCommercialBuildings } from '@/lib/connectors/tampa-geohub';
import { fetchTomorrowWeatherSignals } from '@/lib/connectors/tomorrow-weather';
import { upsertExternalSignals } from '@/lib/data/external-signals';

// Tampa Bay coverage area for the free, keyless connectors in the GTM
// Engineering API Matrix. Extend this list (or make it configurable) before
// adding paid-tier connectors that need per-workspace credentials.
const COUNTIES = ['Hillsborough', 'Pinellas', 'Pasco'];

export async function POST() {
  const { activeWorkspace } = await getWorkspaceContext();
  if (!activeWorkspace) return Response.json({ error: 'no active workspace' }, { status: 401 });
  const results = await Promise.allSettled([
    Promise.all(COUNTIES.map((c) => fetchEpaEchoSdwaSignals('FL', c))).then((r) => r.flat()),
    fetchUsgsStreamflowSignals('FL'),
    fetchTampaAgingCommercialBuildings(),
    fetchTomorrowWeatherSignals(),
  ]);
  const [epaEcho, usgs, tampa, tomorrow] = results;
  const signals = results.filter((r) => r.status === 'fulfilled').flatMap((r) => (r as PromiseFulfilledResult<Awaited<ReturnType<typeof fetchUsgsStreamflowSignals>>>).value);
  const sources = {
    epa_echo_sdwa: epaEcho.status === 'fulfilled' ? epaEcho.value.length : `error: ${(epaEcho as PromiseRejectedResult).reason}`,
    usgs_water: usgs.status === 'fulfilled' ? usgs.value.length : `error: ${(usgs as PromiseRejectedResult).reason}`,
    tampa_geohub: tampa.status === 'fulfilled' ? tampa.value.length : `error: ${(tampa as PromiseRejectedResult).reason}`,
    // 0 here (rather than an error) means TOMORROW_API_KEY isn't configured
    // in Vercel yet -- the connector no-ops by design until it is.
    tomorrow_weather: tomorrow.status === 'fulfilled' ? tomorrow.value.length : `error: ${(tomorrow as PromiseRejectedResult).reason}`,
  };
  // Writing to Supabase can fail independently of the fetches above (RLS,
  // permissions, connectivity) -- surface that instead of letting it crash
  // the route handler into an opaque, bodyless 500.
  try {
    const written = await upsertExternalSignals(activeWorkspace.id, signals);
    return Response.json({ written, sources });
  } catch (err) {
    return Response.json({ error: err instanceof Error ? err.message : String(err), sources }, { status: 500 });
  }
}
