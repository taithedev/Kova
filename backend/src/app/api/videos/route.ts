import { z } from 'zod';
import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { validatedUpload } from '@/lib/media';
import { body, caption } from '@/lib/validation';
import { guarded, json, ApiError } from '@/lib/errors';
export async function POST(req:Request){return guarded(async()=>{
 const user=await viewer(req);
 const b=await body(req,z.object({key:z.string().min(10).max(500),caption,duration_seconds:z.number().min(1).max(600),visibility:z.enum(['public','followers','private']).default('public'),music_title:z.string().max(140).default('Original audio')}));
 if(!b.key.startsWith(`videos/${user.id}/`)||!/\.(mp4|mov)$/.test(b.key)) throw new ApiError(403,'Invalid video key');
 const url=await validatedUpload(b.key);
 const rows=await db()`INSERT INTO videos(author_id,video_key,video_url,caption,duration_seconds,visibility,music_title,status)
 VALUES(${user.id},${b.key},${url},${b.caption},${b.duration_seconds},${b.visibility},${b.music_title},'pending') RETURNING id,status,created_at`;
 return json({ ...rows[0], message:'Video submitted for moderation before appearing in feeds.' },201);
 });}
