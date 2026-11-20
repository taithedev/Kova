import { z } from 'zod';
import { db } from '@/lib/db';
import { body, handle } from '@/lib/validation';
import { guarded, json, ApiError } from '@/lib/errors';
import { verifyPassword, createToken, tokenHash } from '@/lib/crypto';
import { rateLimit } from '@/lib/rateLimit';
export async function POST(req:Request) { return guarded(async()=>{
 await rateLimit(req,'login',12,15);
 const b=await body(req,z.object({handle,password:z.string()}));
 const rows=await db()`SELECT id,handle,display_name,password_hash,age_band,is_private,allow_messages FROM profiles WHERE handle=${b.handle} AND disabled_at IS NULL LIMIT 1`;
 const u=rows[0];
 if(!u||!(await verifyPassword(b.password,String(u.password_hash)))) throw new ApiError(401,'Invalid username or password');
 const token=createToken();
 await db()`INSERT INTO sessions(user_id,token_hash,expires_at) VALUES(${u.id},${tokenHash(token)},NOW()+INTERVAL '30 days')`;
 const {password_hash:_secret,...user}=u; void _secret;
 return json({user,token});
 }); }
