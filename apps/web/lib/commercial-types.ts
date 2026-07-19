export type PlanStatus='draft'|'active'|'retired';
export type SubscriptionStatus='trial'|'active'|'past_due'|'suspended'|'cancelled';
export type Entitlement={key:string,label:string,limit:number|null,enabled:boolean};
export type ProductPlan={id:string,name:string,code:string,status:PlanStatus,monthlyPrice:number,annualPrice:number,entitlements:Entitlement[]};
export type TenantSubscription={id:string,workspace:string,planCode:string,status:SubscriptionStatus,billingCycle:'monthly'|'annual',renewalDate:string,seats:number,owner:string};
export type UsageMetric={key:string,label:string,used:number,limit:number|null,unit:string};
export type SupportCase={id:string,workspace:string,subject:string,severity:'low'|'medium'|'high'|'critical',status:'open'|'waiting'|'resolved',owner:string,openedAt:string,slaHours:number,ageHours:number};
export type Invoice={id:string,workspace:string,period:string,amount:number,status:'draft'|'open'|'paid'|'void',dueDate:string};
