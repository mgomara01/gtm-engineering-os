export type LifecycleStatus='draft'|'review'|'approved'|'active'|'retired';
export type Channel='email'|'phone'|'sms'|'linkedin'|'direct_mail'|'site_visit'|'task';
export type Offer={id:string;workspaceId:string;name:string;description:string;status:LifecycleStatus;version:number;targetIcp:string;valueProposition:string;pricing:string;eligibilityRules:string[];proofPoints:string[];objections:{objection:string;response:string}[];updatedAt:string};
export type PlaybookStep={id:string;order:number;name:string;channel:Channel;delayDays:number;ownerRole:string;template:string;completionCriteria:string;condition?:string};
export type Playbook={id:string;workspaceId:string;name:string;description:string;status:LifecycleStatus;version:number;offerId:string;targetTier:'A'|'B'|'C'|'Any';trigger:string;steps:PlaybookStep[];updatedAt:string};
export type CampaignMember={id:string;accountId:string;accountName:string;score:number;tier:'A'|'B'|'C';status:'queued'|'active'|'paused'|'completed'|'removed';currentStep:number;enrolledAt:string};
export type Campaign={id:string;workspaceId:string;name:string;description:string;status:'draft'|'active'|'paused'|'completed';playbookId:string;offerId:string;audienceRule:string;members:CampaignMember[];startedAt?:string;updatedAt:string};
export type PerformanceSummary={playbookId:string;enrolled:number;contacted:number;responses:number;meetings:number;opportunities:number;wins:number;revenue:number;taskCompletionRate:number;averageCycleDays:number};
