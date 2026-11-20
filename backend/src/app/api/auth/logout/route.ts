import { db } from '@/lib/db';
import { viewer } from '@/lib/auth';
import { tokenHash } from '@/lib/crypto';
import { guarded, json } from '@/lib/errors';
export async function POST(req:Request) { return guarded(async()=>{
 await viewer(req);
 const token=req.headers.get('authorization')!.slice(7).trim();
 await db()`DELETE FROM sessions WHERE token_hash=${tokenHash(token)}`;
 return json({ok:true});
 }); }
