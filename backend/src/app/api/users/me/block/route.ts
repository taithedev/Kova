import { z } from 'zod';
import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { body } from '@/lib/validation';
import { guarded,json,ApiError } from '@/lib/errors';
export async function POST(req:Request){return guarded(async()=>{
 const u=await viewer(req);const b=await body(req,z.object({user_id:z.string().uuid()}));
 if(b.user_id===u.id)throw new ApiError(400,'Cannot block yourself');
 await db()`INSERT INTO blocks(blocker_id,blocked_id) VALUES(${u.id},${b.user_id}) ON CONFLICT DO NOTHING`;
 await db()`DELETE FROM follows WHERE (follower_id=${u.id} AND following_id=${b.user_id}) OR (follower_id=${b.user_id} AND following_id=${u.id})`;
 return json({blocked:true});
 });}
