import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded, json, ApiError } from '@/lib/errors';
import { id as identifier } from '@/lib/validation';
type Ctx={params:Promise<{id:string}>};
async function requireVideo(id:string,userId:string){
 const rows=await db()`SELECT v.id FROM videos v JOIN profiles p ON p.id=v.author_id
 WHERE v.id=${id} AND v.status='approved' AND v.visibility='public' AND p.is_private=false
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${userId} AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${userId}))`;
 if(!rows.length) throw new ApiError(404,'Video not found');
}
export async function POST(req:Request,{params}:Ctx){return guarded(async()=>{
 const user=await viewer(req);const {id}=await params;if(!identifier.safeParse(id).success) throw new ApiError(400,'Invalid video ID');
 await requireVideo(id,user.id);await db()`INSERT INTO likes(user_id,video_id) VALUES(${user.id},${id}) ON CONFLICT DO NOTHING`;
 return json({liked:true});
 });}
export async function DELETE(req:Request,{params}:Ctx){return guarded(async()=>{
 const user=await viewer(req);const {id}=await params;if(!identifier.safeParse(id).success) throw new ApiError(400,'Invalid video ID');
 await db()`DELETE FROM likes WHERE user_id=${user.id} AND video_id=${id}`;
 return json({liked:false});
 });}
