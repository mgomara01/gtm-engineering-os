import type {ExternalSignal} from './connector-types';

export interface TampaBuildingFeature{attributes:{OBJECTID:number;FULLADDRESS:string|null;YEAR_BUILT:number|null;HEAT_AREA:number|null;GROSS_AREA:number|null;COM_UNITS:number|null;};}

// Pure, testable: turns raw Tampa GeoHub building-footprint features into
// aging-commercial-infrastructure signals (older buildings = higher HVAC/
// plumbing replacement likelihood -- the matrix's targeting rationale).
export function normalizeTampaBuildings(features:TampaBuildingFeature[],nowYear=new Date().getFullYear()):ExternalSignal[]{
  return features.map(f=>{
    const a=f.attributes;
    const age=a.YEAR_BUILT?nowYear-a.YEAR_BUILT:null;
    const severity:ExternalSignal['severity']=a.YEAR_BUILT&&a.YEAR_BUILT<1980?'warning':'info';
    return{source:'tampa_geohub',category:'Property & Infrastructure Data',externalRef:String(a.OBJECTID),title:`${a.FULLADDRESS??'Unknown address'} — built ${a.YEAR_BUILT??'unknown'}`,location:a.FULLADDRESS,severity,detail:{yearBuilt:a.YEAR_BUILT,ageYears:age,heatedArea:a.HEAT_AREA,grossArea:a.GROSS_AREA,commercialUnits:a.COM_UNITS},observedAt:null};
  });
}

// Live call: City of Tampa GeoHub ArcGIS REST MapServer, Building Footprint
// layer (layer 0). Public, no API key required. Filters to commercial
// buildings older than `builtBefore` -- the aging-infrastructure targeting
// criterion. Verified live against arcgis.tampagov.net on 2026-08-05.
export async function fetchTampaAgingCommercialBuildings(builtBefore=2000,limit=50):Promise<ExternalSignal[]>{
  const where=encodeURIComponent(`COM_UNITS>0 AND YEAR_BUILT<${builtBefore} AND YEAR_BUILT>0`);
  const outFields='OBJECTID,FULLADDRESS,YEAR_BUILT,HEAT_AREA,GROSS_AREA,COM_UNITS';
  const res=await fetch(`https://arcgis.tampagov.net/arcgis/rest/services/OpenData/Location/MapServer/0/query?where=${where}&outFields=${outFields}&f=json&resultRecordCount=${limit}&returnGeometry=false`);
  if(!res.ok)throw new Error(`Tampa GeoHub query failed: ${res.status}`);
  const json=await res.json();
  return normalizeTampaBuildings(json?.features??[]);
}
