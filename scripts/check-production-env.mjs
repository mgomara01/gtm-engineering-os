const required=['NEXT_PUBLIC_SUPABASE_URL','NEXT_PUBLIC_SUPABASE_ANON_KEY','SUPABASE_SERVICE_ROLE_KEY','APP_ENCRYPTION_KEY'];
const missing=required.filter(k=>!process.env[k]);
if(missing.length){console.error(`Missing production variables: ${missing.join(', ')}`);process.exit(1);} 
for(const key of ['ENABLE_OUTBOUND_COMMUNICATIONS','ENABLE_AUTOMATED_AGENT_WRITES','ENABLE_PRODUCTION_IMPORTS']){if(process.env[key]!=='false')console.warn(`${key} is not false; confirm the corresponding release gate.`)}
console.log('Production environment contract satisfied.');
