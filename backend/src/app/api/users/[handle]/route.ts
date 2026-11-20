import { db } from '@/lib/db';
import { optionalViewer } from '@/lib/auth';
import { guarded,json,ApiError } from '@/lib/errors';
type Ctx={params:Promise<{handle:string}>};
export async function GET(req:Request,{params}:Ctx){return guarded(async()=>{
 const {handle}=await params;const user=await optionalViewer(req);
 const who=user?.id||'00000000-0000-0000-0000-000000000000';
 const p=await db()`SELECT p.id,p.handle,p.display_name,p.bio,p.avatar_url,p.is_verified,p.is_private,
 (SELECT count(*)::int FROM follows f WHERE f.following_id=p.id AND f.status='accepted') AS followers_count,
 (SELECT count(*)::int FROM follows f WHERE f.follower_id=p.id AND f.status='accepted') AS following_count,
 EXISTS(SELECT 1 FROM follows f WHERE f.following_id=p.id AND f.follower_id=${who}::uuid AND f.status='accepted') AS is_following
 FROM profiles p WHERE p.handle=${handle.toLowerCase()} AND p.disabled_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${who}::uuid AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${who}::uuid)) LIMIT 1`;
 if(!p.length)throw new ApiError(404,'User not found');
 const profile=p[0];
 const canView=!profile.is_private || profile.id===user?.id || profile.is_following;
 const videos=canView?await db()`SELECT id,caption,video_url,thumbnail_url,created_at FROM videos WHERE author_id=${profile.id} AND status='approved' AND (visibility='public' OR author_id=${who}::uuid OR (visibility='followers' AND ${Boolean(profile.is_following)})) ORDER BY created_at DESC LIMIT 60`:[];
 return json({profile,videos});
 });}
