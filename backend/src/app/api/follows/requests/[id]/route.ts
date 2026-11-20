import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded,json,ApiError } from '@/lib/errors';
import { id as identifier } from '@/lib/validation';
type Ctx={params:Promise<{id:string}>};
export async function POST(req:Request,{params}:Ctx){return guarded(async()=>{
 const u=await viewer(req);const {id}=await params;
 if(!identifier.safeParse(id).success)throw new ApiError(400,'Invalid follower ID');
 const rows=await db()`UPDATE follows SET status='accepted' WHERE follower_id=${id} AND following_id=${u.id} AND status='pending' RETURNING status`;
 if(!rows.length)throw new ApiError(404,'Follow request not found');
 return json({status:'accepted'});
});}
export async function DELETE(req:Request,{params}:Ctx){return guarded(async()=>{
 const u=await viewer(req);const {id}=await params;
 if(!identifier.safeParse(id).success)throw new ApiError(400,'Invalid follower ID');
 await db()`DELETE FROM follows WHERE follower_id=${id} AND following_id=${u.id} AND status='pending'`;
 return json({status:'declined'});
});}
