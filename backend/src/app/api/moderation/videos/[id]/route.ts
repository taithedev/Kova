import { z } from 'zod';
import { viewer,requireModerator } from '@/lib/auth';
import { db } from '@/lib/db';
import { body,id as identifier } from '@/lib/validation';
import { guarded,json,ApiError } from '@/lib/errors';
type Ctx={params:Promise<{id:string}>};
export async function PATCH(req:Request,{params}:Ctx){return guarded(async()=>{
 const u=await viewer(req);requireModerator(u);
 const {id}=await params;if(!identifier.safeParse(id).success)throw new ApiError(400,'Invalid video ID');
 const {status}=await body(req,z.object({status:z.enum(['approved','rejected'])}));
 const rows=await db()`UPDATE videos SET status=${status},moderated_by=${u.id},moderated_at=NOW() WHERE id=${id} AND status='pending' RETURNING id,status`;
 if(!rows.length)throw new ApiError(404,'Pending video not found');
 return json(rows[0]);
 });}
