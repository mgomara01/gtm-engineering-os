import type {ExternalSignal} from './connector-types';

export interface UsgsTimeSeries{sourceInfo:{siteName:string;siteCode:{value:string}[]};variable:{variableName:string;unit:{unitCode:string}};values:{value:{value:string;dateTime:string}[]}[];}

// USGS's JSON API embeds HTML numeric entities in text fields (e.g.
// "ft&#179;/s" for "ft³/s") instead of the actual characters -- confirmed
// live against waterservices.usgs.gov on 2026-08-07. Decode before display.
function decodeHtmlEntities(text:string):string{
  return text
    .replace(/&#(\d+);/g,(_,dec)=>String.fromCharCode(Number(dec)))
    .replace(/&#x([0-9a-fA-F]+);/g,(_,hex)=>String.fromCharCode(parseInt(hex,16)))
    .replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&#39;/g,"'");
}

// Pure, testable: turns raw USGS instantaneous-values time series into
// normalized signals -- one per monitored site, using its latest reading.
export function normalizeUsgsTimeSeries(series:UsgsTimeSeries[]):ExternalSignal[]{
  return series.map(s=>{
    const reading=s.values?.[0]?.value?.[0];
    const siteCode=s.sourceInfo.siteCode?.[0]?.value??'unknown';
    const variableName=decodeHtmlEntities(s.variable.variableName);
    return{source:'usgs_water',category:'Environmental, Weather & Water Quality',externalRef:siteCode,title:`${s.sourceInfo.siteName} — ${variableName}`,location:s.sourceInfo.siteName,severity:reading?'info':'warning',detail:{value:reading?.value??null,unit:s.variable.unit.unitCode,siteCode},observedAt:reading?.dateTime??null};
  });
}

// Live call: USGS Water Services Instantaneous Values service. Public, no
// API key required. parameterCd 00060 = discharge (streamflow), cfs.
// Verified live against waterservices.usgs.gov on 2026-08-05 (438 FL sites).
export async function fetchUsgsStreamflowSignals(stateCd:string,parameterCd='00060'):Promise<ExternalSignal[]>{
  const res=await fetch(`https://waterservices.usgs.gov/nwis/iv/?stateCd=${encodeURIComponent(stateCd)}&parameterCd=${parameterCd}&format=json&siteStatus=active`);
  if(!res.ok)throw new Error(`USGS Water Services failed: ${res.status}`);
  const json=await res.json();
  return normalizeUsgsTimeSeries(json?.value?.timeSeries??[]);
}
