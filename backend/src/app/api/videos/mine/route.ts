import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded, json } from '@/lib/errors';
export async function GET(req:Request){return guarded(async()=>{
 const user=await viewer(req);
 const rows=await db()`SELECT id,caption,video_url,status,visibility,created_at FROM videos WHERE author_id=${user.id} ORDER BY created_at DESC LIMIT 100`;
 return json({items:rows});
 });}
