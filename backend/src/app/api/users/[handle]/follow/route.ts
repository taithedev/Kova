import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded,json,ApiError } from '@/lib/errors';
type Ctx={params:Promise<{handle:string}>};
export async function POST(req:Request,{params}:Ctx){return guarded(async()=>{
 const u=await viewer(req);const {handle}=await params;
 const rows=await db()`SELECT id,is_private FROM profiles WHERE handle=${handle.toLowerCase()} AND disabled_at IS NULL LIMIT 1`;
 const p=rows[0];if(!p)throw new ApiError(404,'User not found');if(p.id===u.id)throw new ApiError(400,'You cannot follow yourself');
 const bans=await db()`SELECT 1 FROM blocks WHERE (blocker_id=${u.id} AND blocked_id=${p.id}) OR (blocker_id=${p.id} AND blocked_id=${u.id}) LIMIT 1`;
 if(bans.length)throw new ApiError(403,'Not allowed');
 const status=p.is_private?'pending':'accepted';
 await db()`INSERT INTO follows(follower_id,following_id,status) VALUES(${u.id},${p.id},${status}) ON CONFLICT(follower_id,following_id) DO UPDATE SET status=EXCLUDED.status`;
 return json({status});
 });}
export async function DELETE(req:Request,{params}:Ctx){return guarded(async()=>{
 const u=await viewer(req);const {handle}=await params;
 await db()`DELETE FROM follows WHERE follower_id=${u.id} AND following_id=(SELECT id FROM profiles WHERE handle=${handle.toLowerCase()})`;
 return json({following:false});
 });}
