import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded,json,ApiError } from '@/lib/errors';
import { id as identifier } from '@/lib/validation';
type Ctx={params:Promise<{id:string}>};
export async function POST(req:Request,{params}:Ctx){return guarded(async()=>{
 const u=await viewer(req);const {id}=await params;if(!identifier.safeParse(id).success)throw new ApiError(400,'Invalid ID');
 const v=await db()`SELECT 1 FROM videos WHERE id=${id} AND status='approved' LIMIT 1`;
 if(!v.length)throw new ApiError(404,'Video unavailable');
 await db()`INSERT INTO bookmarks(user_id,video_id) VALUES(${u.id},${id}) ON CONFLICT DO NOTHING`;return json({bookmarked:true});
 });}
export async function DELETE(req:Request,{params}:Ctx){return guarded(async()=>{
 const u=await viewer(req);const {id}=await params;if(!identifier.safeParse(id).success)throw new ApiError(400,'Invalid ID');
 await db()`DELETE FROM bookmarks WHERE user_id=${u.id} AND video_id=${id}`;return json({bookmarked:false});
 });}
