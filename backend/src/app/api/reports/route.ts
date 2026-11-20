import { z } from 'zod';
import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { body } from '@/lib/validation';
import { guarded,json } from '@/lib/errors';
import { rateLimit } from '@/lib/rateLimit';
const schema=z.object({target_type:z.enum(['video','comment','user']),target_id:z.string().uuid(),reason:z.enum(['bullying','sexual_content','violence','hate','spam','privacy','other']),detail:z.string().max(500).default('')});
export async function POST(req:Request){return guarded(async()=>{
 const u=await viewer(req);await rateLimit(req,'report',25,60);
 const b=await body(req,schema);
 const r=await db()`INSERT INTO reports(reporter_id,target_type,target_id,reason,detail) VALUES(${u.id},${b.target_type},${b.target_id},${b.reason},${b.detail}) RETURNING id,status`;
 return json(r[0],201);
 });}
