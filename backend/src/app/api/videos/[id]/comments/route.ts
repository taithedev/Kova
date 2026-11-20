import { z } from 'zod';
import { viewer, optionalViewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { body, id as identifier } from '@/lib/validation';
import { guarded,json,ApiError } from '@/lib/errors';
import { rateLimit } from '@/lib/rateLimit';
type Ctx={params:Promise<{id:string}>};
export async function GET(req:Request,{params}:Ctx){return guarded(async()=>{
 const {id}=await params;if(!identifier.safeParse(id).success)throw new ApiError(400,'Invalid ID');
 const user=await optionalViewer(req);const who=user?.id||'00000000-0000-0000-0000-000000000000';
 const rows=await db()`SELECT c.id,c.body,c.created_at,p.handle,p.display_name,p.avatar_url FROM comments c JOIN profiles p ON p.id=c.user_id JOIN videos v ON v.id=c.video_id JOIN profiles author ON author.id=v.author_id
 WHERE c.video_id=${id} AND c.deleted_at IS NULL AND v.status='approved' AND v.visibility='public' AND author.is_private=false
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${who}::uuid AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${who}::uuid))
 ORDER BY c.created_at DESC LIMIT 100`;
 return json({items:rows});
 });}
export async function POST(req:Request,{params}:Ctx){return guarded(async()=>{
 const user=await viewer(req);await rateLimit(req,'comment',30,10);
 const {id}=await params;if(!identifier.safeParse(id).success)throw new ApiError(400,'Invalid ID');
 const b=await body(req,z.object({body:z.string().trim().min(1).max(500)}));
 const v=await db()`SELECT v.author_id FROM videos v JOIN profiles p ON p.id=v.author_id WHERE v.id=${id} AND v.status='approved' AND v.visibility='public' AND p.is_private=false AND NOT EXISTS(SELECT 1 FROM blocks bl WHERE (bl.blocker_id=${user.id} AND bl.blocked_id=p.id) OR (bl.blocker_id=p.id AND bl.blocked_id=${user.id}))`;
 if(!v.length)throw new ApiError(404,'Video unavailable');
 const r=await db()`INSERT INTO comments(video_id,user_id,body) VALUES(${id},${user.id},${b.body}) RETURNING id,body,created_at`;
 return json(r[0],201);
 });}
