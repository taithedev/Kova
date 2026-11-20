import { db } from '@/lib/db';
import { optionalViewer } from '@/lib/auth';
import { guarded,json } from '@/lib/errors';
export async function GET(req:Request){return guarded(async()=>{
 const query=new URL(req.url).searchParams.get('q')?.trim().slice(0,60)||'';
 if(query.length<2)return json({users:[],videos:[]});
 const viewerId=(await optionalViewer(req))?.id||'00000000-0000-0000-0000-000000000000';
 const term=`%${query}%`;
 const users=await db()`SELECT id,handle,display_name,avatar_url,is_verified FROM profiles p WHERE (p.handle ILIKE ${term} OR p.display_name ILIKE ${term}) AND p.disabled_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${viewerId}::uuid AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${viewerId}::uuid)) ORDER BY handle LIMIT 20`;
 const videos=await db()`SELECT v.id,v.caption,v.video_url,p.handle,p.display_name FROM videos v JOIN profiles p ON p.id=v.author_id WHERE v.caption ILIKE ${term} AND v.status='approved' AND v.visibility='public' AND p.is_private=false AND p.disabled_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${viewerId}::uuid AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${viewerId}::uuid)) ORDER BY v.created_at DESC LIMIT 20`;
 return json({users,videos});
 });}
