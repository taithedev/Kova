import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded,json } from '@/lib/errors';
export async function GET(req:Request){return guarded(async()=>{
 const u=await viewer(req);
 const rows=await db()`SELECT id,kind,actor_id,video_id,body,is_read,created_at FROM notifications WHERE recipient_id=${u.id} ORDER BY created_at DESC LIMIT 100`;
 return json({items:rows});
 });}
