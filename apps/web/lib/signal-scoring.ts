import type {ExternalSignal} from './connectors/connector-types';

export interface SignalScore{score:number;tier:'A'|'B'|'C';}

// First-pass GTM scoring for raw external signals -- source-specific,
// because severity alone conflates "critical" (a real EPA violation) with
// things like a USGS site simply having no current reading (a data-quality
// flag, not a sales signal). Tampa GeoHub age/size drives HVAC & plumbing
// replacement likelihood (older, larger commercial buildings = higher
// probability of near-term equipment failure); EPA SDWA violations drive
// backflow/plumbing remediation likelihood, especially at community
// systems with a serious non-compliance flag; USGS streamflow is regional
// environmental context only, not an account-level lead -- scored low on
// purpose. Tomorrow.io weather is also regional (not account-level), but
// unlike streamflow it carries a direct demand trigger: freeze conditions
// drive burst-pipe emergency calls and extreme heat drives AC-failure
// calls, so those two states score meaningfully higher than routine
// weather. Entity resolution (linking a signal to a specific account or
// opportunity) remains a separate, later pass -- this is priority triage
// over the raw feed, not a finished lead.
export function scoreExternalSignal(signal:Pick<ExternalSignal,'source'|'detail'>):SignalScore{
  const d=signal.detail;
  let score=0;
  if(signal.source==='tampa_geohub'){
    const age=typeof d.ageYears==='number'?d.ageYears:0;
    const heatedArea=typeof d.heatedArea==='number'?d.heatedArea:0;
    const commercialUnits=typeof d.commercialUnits==='number'?d.commercialUnits:0;
    score=30+Math.min(40,(age/80)*40)+(heatedArea>2000?15:heatedArea>0?7:0)+(commercialUnits>1?15:0);
  }else if(signal.source==='epa_echo_sdwa'){
    const seriousViolator=d.seriousViolator===true;
    const violation=d.complianceStatus==='Violation Identified';
    const community=d.systemType==='Community water system';
    score=20+(seriousViolator?40:0)+(violation?20:0)+(community?10:0);
  }else if(signal.source==='usgs_water'){
    score=5+(d.value==null?10:0);
  }else if(signal.source==='tomorrow_weather'){
    const temp=typeof d.temperature==='number'?d.temperature:null;
    const freeze=temp!==null&&temp<=32;
    const extremeHeat=temp!==null&&temp>=95;
    score=10+(freeze?40:0)+(extremeHeat?25:0);
  }
  score=Math.max(0,Math.min(100,Math.round(score)));
  const tier=score>=70?'A':score>=40?'B':'C';
  return{score,tier};
}
