import { z } from 'zod';
import { randomUUID } from 'node:crypto';
import { viewer } from '@/lib/auth';
import { signedUpload } from '@/lib/media';
import { body } from '@/lib/validation';
import { guarded, json } from '@/lib/errors';
import { rateLimit } from '@/lib/rateLimit';
export async function POST(req:Request){return guarded(async()=>{
 const user=await viewer(req);await rateLimit(req,'upload',20,60);
 const {mime}=await body(req,z.object({mime:z.enum(['video/mp4','video/quicktime'])}));
 const key=`videos/${user.id}/${randomUUID()}.${mime==='video/mp4'?'mp4':'mov'}`;
 return json({key,...await signedUpload(key,mime)});
 });}
