import { viewer } from '@/lib/auth';
import { guarded, json } from '@/lib/errors';
export async function GET(req:Request) { return guarded(async()=>json(await viewer(req))); }
