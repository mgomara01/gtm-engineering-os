export type InferredType = 'text'|'number'|'date'|'boolean'|'email'|'phone'|'currency';
export type ImportColumn = { sourceName:string; inferredType:InferredType; targetField:string; confidence:number; samples:string[] };
export type ValidationIssue = { row:number; field:string; severity:'error'|'warning'; message:string };
export type ImportPreview = { rows:Record<string,unknown>[]; columns:ImportColumn[]; issues:ValidationIssue[]; validRows:number; invalidRows:number; duplicateRows:number };

const targetDictionary: Record<string,string[]> = {
  organization_name:['company','company name','organization','organization name','customer','customer name','account','account name'],
  property_name:['property','property name','location','location name','site','site name'],
  first_name:['first name','firstname','contact first'], last_name:['last name','lastname','contact last'],
  email:['email','email address','contact email'], phone:['phone','phone number','mobile','telephone'],
  address_line_1:['address','street','street address','address 1'], city:['city'], state_region:['state','province','region'], postal_code:['zip','zip code','postal code'],
  external_id:['id','customer id','account id','location id','external id'], annual_revenue:['revenue','annual revenue'],
  status:['status','customer status','account status']
};

export function normalizeHeader(value:string){return value.trim().toLowerCase().replace(/[_-]+/g,' ').replace(/\s+/g,' ')}
export function inferType(values:unknown[]):InferredType{
  const samples=values.filter(v=>v!==null&&v!==undefined&&String(v).trim()!=='').map(String).slice(0,30);
  if(!samples.length)return 'text';
  if(samples.every(v=>/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)))return 'email';
  if(samples.every(v=>/^\+?[\d\s().-]{7,}$/.test(v)))return 'phone';
  if(samples.every(v=>/^(true|false|yes|no|0|1)$/i.test(v)))return 'boolean';
  if(samples.every(v=>/^[$£€]?\s*-?[\d,]+(?:\.\d+)?$/.test(v))){return samples.some(v=>/[$£€]/.test(v))?'currency':'number'}
  if(samples.every(v=>!Number.isNaN(Date.parse(v)) && /[-/]|\d{4}/.test(v)))return 'date';
  return 'text';
}
export function suggestTarget(sourceName:string){
  const normalized=normalizeHeader(sourceName); let best={field:'',score:0};
  for(const [field,aliases] of Object.entries(targetDictionary)) for(const alias of aliases){
    const score=normalized===alias?1:(normalized.includes(alias)||alias.includes(normalized)?0.78:0);
    if(score>best.score)best={field,score};
  }
  return {targetField:best.field,confidence:best.score};
}
export function profileRows(rows:Record<string,unknown>[]):ImportColumn[]{
  const headers=Object.keys(rows[0]??{});
  return headers.map(sourceName=>{const values=rows.map(r=>r[sourceName]);const suggestion=suggestTarget(sourceName);return {sourceName,inferredType:inferType(values),targetField:suggestion.targetField,confidence:suggestion.confidence,samples:values.filter(Boolean).slice(0,3).map(String)}})
}
export function validateRows(rows:Record<string,unknown>[], columns:ImportColumn[]):ImportPreview{
  const issues:ValidationIssue[]=[]; const seen=new Set<string>(); let duplicates=0; const identityCols=columns.filter(c=>['external_id','email','organization_name'].includes(c.targetField));
  rows.forEach((row,index)=>{
    columns.forEach(col=>{const value=String(row[col.sourceName]??'').trim(); if(!value)return;
      if(col.inferredType==='email'&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value))issues.push({row:index+2,field:col.sourceName,severity:'error',message:'Invalid email format'});
      if(col.inferredType==='number'&&Number.isNaN(Number(value.replace(/,/g,''))))issues.push({row:index+2,field:col.sourceName,severity:'error',message:'Expected numeric value'});
    });
    const key=identityCols.map(c=>normalizeHeader(String(row[c.sourceName]??''))).filter(Boolean).join('|');
    if(key){if(seen.has(key)){duplicates++;issues.push({row:index+2,field:'record',severity:'warning',message:'Possible duplicate within file'})}seen.add(key)}
  });
  const invalid=new Set(issues.filter(i=>i.severity==='error').map(i=>i.row)).size;
  return {rows,columns,issues,validRows:rows.length-invalid,invalidRows:invalid,duplicateRows:duplicates};
}
