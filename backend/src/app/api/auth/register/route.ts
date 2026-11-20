import { z } from 'zod';
import { db } from '@/lib/db';
import { body, handle } from '@/lib/validation';
import { guarded, json, ApiError } from '@/lib/errors';
import { ageBand, ageFromISO } from '@/lib/age';
import { hashPassword, createToken, tokenHash } from '@/lib/crypto';
import { rateLimit } from '@/lib/rateLimit';
const schema=z.object({handle,display_name:z.string().trim().min(1).max(50),password:z.string().min(10).max(128),birth_date:z.string()});
export async function POST(req:Request) { return guarded(async()=>{
 await rateLimit(req,'register',5,60);
 const b=await body(req,schema); const band=ageBand(ageFromISO(b.birth_date));
 const hashed=await hashPassword(b.password);
 const exists=await db()`SELECT 1 FROM profiles WHERE handle=${b.handle} LIMIT 1`;
 if(exists.length) throw new ApiError(409,'Username already taken');
 const created=await db()`INSERT INTO profiles(handle,display_name,password_hash,age_band,is_private,allow_messages)
 VALUES(${b.handle},${b.display_name},${hashed},${band},true,false)
 ON CONFLICT (handle) DO NOTHING RETURNING id,handle,display_name,age_band,is_private,allow_messages`;
 if(!created.length) throw new ApiError(409,'Username already taken');
 const token=createToken(); const user=created[0];
 await db()`INSERT INTO sessions(user_id,token_hash,expires_at) VALUES(${user.id},${tokenHash(token)},NOW()+INTERVAL '30 days')`;
 return json({user,token},201);
 }); }
