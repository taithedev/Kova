import { NextResponse } from 'next/server';
export async function GET() { return NextResponse.json({ data: { service: 'kova-api', status: 'ok', version: '0.1.0' } }); }
