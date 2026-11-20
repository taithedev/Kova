import { z } from 'zod';
import { db } from '@/lib/db';
import { viewer } from '@/lib/auth';
import { body } from '@/lib/validation';
import { guarded,json } from '@/lib/errors';
export async function PATCH(req:Request){return guarded(async()=>{
 const u=await viewer(req);
 const b=await body(req,z.object({display_name:z.string().trim().min(1).max(50),bio:z.string().max(160),is_private:z.boolean() }));
 const p=await db()`UPDATE profiles SET display_name=${b.display_name},bio=${b.bio},is_private=${b.is_private},updated_at=NOW() WHERE id=${u.id}
 RETURNING id,handle,display_name,bio,is_private,age_band,role,allow_messages`;
 return json(p[0]);
 });}
