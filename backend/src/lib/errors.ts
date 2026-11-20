import { NextResponse } from 'next/server';
export class ApiError extends Error {
  constructor(public status: number, message: string) { super(message); this.name = 'ApiError'; }
}
export function json(data: unknown, status = 200) { return NextResponse.json({ data }, { status, headers: { 'Cache-Control': 'no-store' } }); }
export function fail(error: unknown) {
  if (error instanceof ApiError) return NextResponse.json({ error: error.message }, {status:error.status});
  console.error('[kova api]', error);
  return NextResponse.json({ error: 'Internal server error' }, {status:500});
}
export function guarded<T>(handler: () => Promise<T>): Promise<T | NextResponse> {
  return handler().catch(fail);
}
