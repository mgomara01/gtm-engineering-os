import type {ExternalSignal} from './connector-types';

export interface EchoFacilityRow{FacName:string;FacCity:string|null;FacState:string;FacCounty:string;RegistryID:string;SDWAIDs:string|null;SDWASystemTypes:string|null;SDWAComplianceStatus:string|null;SDWASNCFlag:string|null;}

// Pure, testable: turns raw ECHO facility rows into normalized signals.
// Only rows with an SDWAIDs value are actual drinking water systems -- the
// underlying ECHO facility search spans every EPA program (air, water, RCRA).
export function normalizeEpaEchoFacilities(rows:EchoFacilityRow[]):ExternalSignal[]{
  return rows.filter(r=>r.SDWAIDs).map(r=>{
    const status=r.SDWAComplianceStatus??'Unknown';
    const seriousViolator=r.SDWASNCFlag==='Y';
    const severity:ExternalSignal['severity']=seriousViolator?'critical':status==='Violation Identified'?'warning':'info';
    return{source:'epa_echo_sdwa',category:'Environmental, Weather & Water Quality',externalRef:r.SDWAIDs as string,title:`${r.FacName} — ${status}`,location:[r.FacCity,r.FacCounty,r.FacState].filter(Boolean).join(', ')||null,severity,detail:{registryId:r.RegistryID,systemType:r.SDWASystemTypes,complianceStatus:status,seriousViolator},observedAt:null};
  });
}

// Live call: EPA ECHO's Detailed Facility Search REST service. Two-step --
// get_facilities returns a QueryID, get_qid returns the actual rows.
// p_med=S restricts the multi-program search to SDWA (drinking water).
// Verified live against echodata.epa.gov on 2026-08-05 (no API key required).
export async function fetchEpaEchoSdwaSignals(state:string,county:string):Promise<ExternalSignal[]>{
  const facRes=await fetch(`https://echodata.epa.gov/echo/echo_rest_services.get_facilities?output=JSON&p_st=${encodeURIComponent(state)}&p_act=Y&p_co=${encodeURIComponent(county)}&p_med=S`);
  if(!facRes.ok)throw new Error(`EPA ECHO get_facilities failed: ${facRes.status}`);
  const facJson=await facRes.json();
  const qid=facJson?.Results?.QueryID;
  if(!qid)return[];
  const rowsRes=await fetch(`https://echodata.epa.gov/echo/echo_rest_services.get_qid?output=JSON&qid=${qid}&qcolumns=1,3,4,7,25,33,40,130`);
  if(!rowsRes.ok)throw new Error(`EPA ECHO get_qid failed: ${rowsRes.status}`);
  const rowsJson=await rowsRes.json();
  return normalizeEpaEchoFacilities(rowsJson?.Results?.Facilities??[]);
}
