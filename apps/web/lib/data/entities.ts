import { createClient } from '@/lib/supabase/server';
import type { AccountDetail, Contact, Organization, Property } from '@/lib/entity-types';

const demoOrganizations: Organization[] = [
 {id:'org-alvarez-001',workspaceId:'11111111-1111-1111-1111-111111111111',name:'Bayview Medical Properties',type:'property_manager',industry:'Healthcare Real Estate',website:'bayviewmedical.example',phone:'(813) 555-0140',city:'Tampa',state:'FL',lifecycle:'customer',priority:'A',owner:'Santiago Rodriguez',score:91,dataConfidence:94,lastActivity:'2026-07-15',nextAction:'Review HVAC maintenance expansion',externalId:'ST-20481',sourceSystem:'ServiceTitan',propertyCount:4,contactCount:3,opportunityValue:185000,tags:['Healthcare','Multi-location','Plumbing customer']},
 {id:'org-alvarez-002',workspaceId:'11111111-1111-1111-1111-111111111111',name:'Harbor Hospitality Group',type:'company',industry:'Hotels & Resorts',website:'harborhospitality.example',phone:'(727) 555-0198',city:'Clearwater',state:'FL',lifecycle:'prospect',priority:'A',owner:'Mike O’Mara',score:87,dataConfidence:81,lastActivity:'2026-07-11',nextAction:'Identify facilities decision-maker',externalId:'IMP-7782',sourceSystem:'Excel Import',propertyCount:6,contactCount:1,opportunityValue:240000,tags:['Hotel','Smart Valve fit','High water use']},
 {id:'org-alvarez-003',workspaceId:'11111111-1111-1111-1111-111111111111',name:'Westshore Commerce Center',type:'property_owner',industry:'Commercial Real Estate',city:'Tampa',state:'FL',lifecycle:'customer',priority:'B',owner:'James Taylor',score:74,dataConfidence:89,lastActivity:'2026-06-29',nextAction:'Confirm backflow renewal date',externalId:'ST-19007',sourceSystem:'ServiceTitan',propertyCount:2,contactCount:2,opportunityValue:42000,tags:['Office','Backflow','HVAC']},
];
const properties: Property[] = [
 {id:'prop-001',organizationId:'org-alvarez-001',name:'Bayview Medical Plaza North',type:'medical_office',address:'4100 N Dale Mabry Hwy',city:'Tampa',state:'FL',postalCode:'33607',yearBuilt:2007,squareFeet:88000,relationship:'managed_by',sourceSystem:'ServiceTitan',externalId:'LOC-1101'},
 {id:'prop-002',organizationId:'org-alvarez-001',name:'Bayview Outpatient Center',type:'healthcare',address:'12800 Bruce B Downs Blvd',city:'Tampa',state:'FL',postalCode:'33612',yearBuilt:2014,squareFeet:62000,relationship:'managed_by',sourceSystem:'ServiceTitan',externalId:'LOC-1102'},
 {id:'prop-003',organizationId:'org-alvarez-002',name:'Harbor Suites Clearwater',type:'hotel',address:'455 S Gulfview Blvd',city:'Clearwater',state:'FL',postalCode:'33767',yearBuilt:1999,unitCount:214,relationship:'owned_by',sourceSystem:'Excel Import',externalId:'PROP-7782-A'},
];
const contacts: Contact[] = [
 {id:'contact-001',organizationId:'org-alvarez-001',firstName:'Dana',lastName:'Morris',title:'Regional Facilities Director',department:'Facilities',decisionRole:'decision_maker',email:'dana.morris@example.com',phone:'(813) 555-0185',verification:'verified',sourceSystem:'ServiceTitan',externalId:'CON-5501'},
 {id:'contact-002',organizationId:'org-alvarez-001',firstName:'Chris',lastName:'Patel',title:'Property Manager',department:'Operations',decisionRole:'champion',email:'chris.patel@example.com',verification:'verified',sourceSystem:'Manual',externalId:'MAN-1002'},
 {id:'contact-003',organizationId:'org-alvarez-002',firstName:'Morgan',lastName:'Lee',title:'Vice President of Operations',department:'Operations',decisionRole:'unknown',email:'morgan.lee@example.com',verification:'unverified',sourceSystem:'AI Research',externalId:'AI-901'},
];

export async function getOrganizations(workspaceId:string):Promise<Organization[]> {
 const supabase=await createClient(); if(!supabase) return demoOrganizations.filter(x=>x.workspaceId===workspaceId);
 const {data,error}=await supabase.schema('entities').from('workspace_organization_directory').select('*').eq('workspace_id',workspaceId).order('canonical_name');
 if(error) throw new Error(error.message);
 return (data??[]).map((r:any)=>({id:r.organization_id,workspaceId:r.workspace_id,name:r.canonical_name,type:r.organization_type,industry:r.industry_name??'Unclassified',website:r.website_domain??undefined,phone:r.phone??undefined,city:r.city??'',state:r.state_region??'',lifecycle:r.lifecycle_status,priority:r.priority_tier??'C',owner:r.owner_name??'Unassigned',score:Number(r.current_score??0),dataConfidence:Number(r.data_confidence??0),lastActivity:r.last_activity_at??undefined,nextAction:r.next_action??undefined,externalId:r.external_id??undefined,sourceSystem:r.source_system??undefined,propertyCount:Number(r.property_count??0),contactCount:Number(r.contact_count??0),opportunityValue:Number(r.opportunity_value??0),tags:r.tags??[]}));
}
export async function getAccountDetail(workspaceId:string,id:string):Promise<AccountDetail|null>{
 const org=(await getOrganizations(workspaceId)).find(x=>x.id===id); if(!org)return null;
 const supabase=await createClient();
 if(!supabase) return {...org,properties:properties.filter(x=>x.organizationId===id),contacts:contacts.filter(x=>x.organizationId===id),activities:[{id:'a1',type:'system',summary:'Account record synchronized from source system',occurredAt:'2026-07-15T14:30:00Z',actor:'ServiceTitan integration'},{id:'a2',type:'note',summary:'Commercial cross-sell review requested',occurredAt:'2026-07-16T15:00:00Z',actor:'Mike O’Mara'}],sourceLinks:org.externalId?[{system:org.sourceSystem??'Unknown',externalId:org.externalId,lastSynced:'2026-07-18T12:00:00Z'}]:[]};
 const [{data:p},{data:c},{data:s},{data:a}]=await Promise.all([
  supabase.schema('entities').from('property_directory').select('*').eq('workspace_id',workspaceId).eq('organization_id',id),
  supabase.schema('entities').from('contact_directory').select('*').eq('workspace_id',workspaceId).eq('organization_id',id),
  supabase.schema('entities').from('external_identifiers').select('source_system,external_id,updated_at').eq('workspace_id',workspaceId).eq('entity_id',id),
  supabase.schema('gtm').from('activities').select('*').eq('workspace_id',workspaceId).eq('related_entity_id',id).order('occurred_at',{ascending:false}).limit(25)
 ]);
 return {...org,properties:(p??[]).map((r:any)=>({id:r.property_id,organizationId:id,name:r.canonical_name,type:r.property_type,address:r.address_line_1??'',city:r.city??'',state:r.state_region??'',postalCode:r.postal_code??'',yearBuilt:r.year_built??undefined,squareFeet:r.square_feet?Number(r.square_feet):undefined,unitCount:r.unit_count??undefined,relationship:r.relationship_type??'related',sourceSystem:r.source_system??undefined,externalId:r.external_id??undefined})),contacts:(c??[]).map((r:any)=>({id:r.person_id,organizationId:id,firstName:r.first_name,lastName:r.last_name,title:r.title??'',department:r.department??undefined,decisionRole:r.decision_role??'unknown',email:r.email??undefined,phone:r.phone??undefined,verification:r.verification_status??'unverified',sourceSystem:r.source_system??undefined,externalId:r.external_id??undefined})),activities:(a??[]).map((r:any)=>({id:r.id,type:r.activity_type,summary:r.summary,occurredAt:r.occurred_at,actor:r.actor_name??'System'})),sourceLinks:(s??[]).map((r:any)=>({system:r.source_system,externalId:r.external_id,lastSynced:r.updated_at}))};
}
