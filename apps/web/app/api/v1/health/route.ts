import { NextResponse } from 'next/server';
export async function GET(){return NextResponse.json({service:'gtm-engineering-os-api',version:'v1',status:'operational',timestamp:new Date().toISOString()},{headers:{'Cache-Control':'no-store','X-API-Version':'1'}})}
