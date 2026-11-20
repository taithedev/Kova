import { viewer,requireModerator } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded,json } from '@/lib/errors';
export async function GET(req:Request){return guarded(async()=>{
 const u=await viewer(req);requireModerator(u);
 const videos=await db()`SELECT v.id,v.caption,v.video_url,v.created_at,p.handle FROM videos v JOIN profiles p ON p.id=v.author_id WHERE v.status='pending' ORDER BY v.created_at ASC LIMIT 50`;
 const reports=await db()`SELECT id,reporter_id,target_type,target_id,reason,detail,status,created_at FROM reports WHERE status='open' ORDER BY created_at ASC LIMIT 50`;
 return json({videos,reports});
 });}
