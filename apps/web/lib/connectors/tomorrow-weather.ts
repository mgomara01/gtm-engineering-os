import type {ExternalSignal} from './connector-types';

export interface TomorrowLocation{name:string;lat:number;lon:number}
export interface TomorrowRealtimeResponse{data:{time:string;values:{temperature:number;precipitationIntensity:number;precipitationType:number}}}

// Tampa Bay coverage area, one representative point per county in COUNTIES
// (apps/web/app/api/signals/sync/route.ts) -- Tomorrow.io's realtime
// endpoint is per-point, not per-region like USGS/EPA ECHO.
export const TAMPA_BAY_WEATHER_POINTS:TomorrowLocation[]=[
  {name:'Tampa, FL (Hillsborough)',lat:27.9506,lon:-82.4572},
  {name:'St. Petersburg, FL (Pinellas)',lat:27.7676,lon:-82.6403},
  {name:'New Port Richey, FL (Pasco)',lat:28.2444,lon:-82.7193},
];

const PRECIP_TYPES:Record<number,string>={0:'none',1:'rain',2:'snow',3:'freezing rain',4:'ice pellets'};

// Pure, testable: turns raw Tomorrow.io realtime readings into normalized
// signals. Freeze conditions (<=32F) drive burst-pipe/plumbing emergency
// calls; extreme heat (>=95F) drives AC-failure calls -- both are direct
// HVAC/plumbing demand triggers, unlike USGS streamflow which is passive
// regional context. See scoreExternalSignal in signal-scoring.ts.
export function normalizeTomorrowReadings(readings:{location:TomorrowLocation;response:TomorrowRealtimeResponse}[]):ExternalSignal[]{
  return readings.map(({location,response})=>{
    const v=response.data.values;
    const freeze=v.temperature<=32;
    const extremeHeat=v.temperature>=95;
    const severity:ExternalSignal['severity']=freeze?'critical':extremeHeat?'warning':'info';
    const flag=freeze?' (freeze risk)':extremeHeat?' (extreme heat)':'';
    return{source:'tomorrow_weather',category:'Environmental, Weather & Water Quality',externalRef:location.name,title:`${location.name} — ${Math.round(v.temperature)}°F${flag}`,location:location.name,severity,detail:{temperature:v.temperature,precipitationIntensity:v.precipitationIntensity,precipitationType:PRECIP_TYPES[v.precipitationType]??'unknown'},observedAt:response.data.time};
  });
}

// Live call: Tomorrow.io Realtime Weather API, imperial units (Tampa-facing
// HVAC/plumbing business -- Fahrenheit throughout). Requires TOMORROW_API_KEY
// (free/developer tier: 500 calls/day, 25/hour -- 3 points/sync is well under
// both). Returns [] gracefully if the key isn't configured yet, matching the
// mock-data-fallback convention used elsewhere in lib/data. Field paths
// (data.values.temperature, data.values.precipitationIntensity/Type) are
// corroborated from docs.tomorrow.io + third-party integrations as of
// 2026-08-08 but NOT live-curl-verified against a real key the way the other
// 3 connectors were -- confirm against the first live sync.
export async function fetchTomorrowWeatherSignals(locations:TomorrowLocation[]=TAMPA_BAY_WEATHER_POINTS):Promise<ExternalSignal[]>{
  const apiKey=process.env.TOMORROW_API_KEY;
  if(!apiKey)return[];
  const readings=await Promise.all(locations.map(async(location)=>{
    const res=await fetch(`https://api.tomorrow.io/v4/weather/realtime?location=${location.lat},${location.lon}&units=imperial&apikey=${apiKey}`);
    if(!res.ok)throw new Error(`Tomorrow.io realtime failed for ${location.name}: ${res.status}`);
    const response:TomorrowRealtimeResponse=await res.json();
    return{location,response};
  }));
  return normalizeTomorrowReadings(readings);
}
