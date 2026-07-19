import type{Entitlement,ProductPlan,SupportCase,TenantSubscription,UsageMetric}from'./commercial-types';
export function entitlementAllowed(entitlements:Entitlement[],key:string,requested=1){const e=entitlements.find(x=>x.key===key);if(!e||!e.enabled)return false;return e.limit===null||requested<=e.limit}
export function usagePercent(metric:UsageMetric){if(metric.limit===null||metric.limit<=0)return 0;return Math.min(100,Math.round(metric.used/metric.limit*100))}
export function usageStatus(metric:UsageMetric){const p=usagePercent(metric);return p>=100?'blocked':p>=85?'warning':'healthy'}
export function subscriptionOperational(s:TenantSubscription){return s.status==='active'||s.status==='trial'}
export function planPublishable(plan:ProductPlan){return plan.name.trim().length>2&&plan.code.trim().length>1&&plan.monthlyPrice>=0&&plan.annualPrice>=0&&plan.entitlements.length>=3&&plan.entitlements.every(e=>e.key&&e.label)}
export function supportSlaStatus(c:SupportCase){if(c.status==='resolved')return'met';const ratio=c.ageHours/c.slaHours;return ratio>=1?'breached':ratio>=.75?'at-risk':'on-track'}
export function annualSavings(plan:ProductPlan){return Math.max(0,plan.monthlyPrice*12-plan.annualPrice)}
export function projectedMrr(subscriptions:TenantSubscription[],plans:ProductPlan[]){return subscriptions.filter(subscriptionOperational).reduce((sum,s)=>{const p=plans.find(x=>x.code===s.planCode);if(!p)return sum;return sum+(s.billingCycle==='annual'?p.annualPrice/12:p.monthlyPrice)},0)}
