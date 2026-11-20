import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { guarded, json } from '@/lib/errors';
export async function GET(req:Request){return guarded(async()=>{
 const u=await viewer(req);
 const items=await db()`SELECT p.id,p.handle,p.display_name,f.created_at FROM follows f JOIN profiles p ON p.id=f.follower_id WHERE f.following_id=${u.id} AND f.status='pending' AND p.disabled_at IS NULL ORDER BY f.created_at ASC LIMIT 50`;
 return json({items});
});}
