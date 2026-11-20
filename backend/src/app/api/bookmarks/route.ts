import { viewer } from '@/lib/auth';
import { db } from '@/lib/db';
import { signedRead } from '@/lib/media';
import { guarded, json } from '@/lib/errors';
export async function GET(req:Request){return guarded(async()=>{
 const u=await viewer(req);
 const items=await db()`SELECT v.id,v.caption,v.video_key,v.thumbnail_url,v.created_at,v.duration_seconds,v.music_title,
 p.id AS author_id,p.handle,p.display_name,p.avatar_url,p.is_verified,
 (SELECT count(*)::int FROM likes l WHERE l.video_id=v.id) AS likes_count,
 (SELECT count(*)::int FROM comments c WHERE c.video_id=v.id AND c.deleted_at IS NULL) AS comments_count,
 EXISTS(SELECT 1 FROM likes l WHERE l.video_id=v.id AND l.user_id=${u.id}) AS liked,
 true AS bookmarked FROM bookmarks b JOIN videos v ON v.id=b.video_id JOIN profiles p ON p.id=v.author_id
 WHERE b.user_id=${u.id} AND v.status='approved' AND p.disabled_at IS NULL
 AND (v.author_id=${u.id} OR (v.visibility='public' AND p.is_private=false) OR (v.visibility='followers' AND EXISTS(SELECT 1 FROM follows f WHERE f.following_id=p.id AND f.follower_id=${u.id} AND f.status='accepted')))
 AND NOT EXISTS(SELECT 1 FROM blocks bl WHERE (bl.blocker_id=${u.id} AND bl.blocked_id=p.id) OR (bl.blocker_id=p.id AND bl.blocked_id=${u.id}))
 ORDER BY b.created_at DESC LIMIT 100`;
 const safeItems=await Promise.all(items.map(async row=>{const {video_key,...video}=row;return {...video,video_url:await signedRead(String(video_key))};}));
 return json({items:safeItems,next_cursor:null});
});}
