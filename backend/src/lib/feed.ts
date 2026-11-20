import { db } from './db';
import type { Viewer } from './auth';
export async function getFeed(user:Viewer|undefined,mode:'for-you'|'following',limit=12,cursor?:string) {
 const offset=Math.min(Math.max(Number(cursor)||0,0),1000);
 const who=user?.id||'00000000-0000-0000-0000-000000000000';
 const rows=await db()`SELECT v.id,v.caption,v.video_url,v.thumbnail_url,v.created_at,v.duration_seconds,v.music_title,
 p.id AS author_id,p.handle,p.display_name,p.avatar_url,p.is_verified,
 (SELECT count(*)::int FROM likes l WHERE l.video_id=v.id) AS likes_count,
 (SELECT count(*)::int FROM comments c WHERE c.video_id=v.id AND c.deleted_at IS NULL) AS comments_count,
 EXISTS(SELECT 1 FROM likes l WHERE l.video_id=v.id AND l.user_id=${who}::uuid) AS liked,
 EXISTS(SELECT 1 FROM bookmarks b WHERE b.video_id=v.id AND b.user_id=${who}::uuid) AS bookmarked
 FROM videos v JOIN profiles p ON p.id=v.author_id
 WHERE v.status='approved' AND v.visibility='public' AND p.is_private=false AND p.disabled_at IS NULL
   AND (${mode}='for-you' OR EXISTS(SELECT 1 FROM follows f WHERE f.follower_id=${who}::uuid AND f.following_id=p.id AND f.status='accepted'))
   AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${who}::uuid AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${who}::uuid))
 ORDER BY v.created_at DESC, v.id DESC LIMIT ${limit} OFFSET ${offset}`;
 return {items:rows, next_cursor:rows.length===limit?String(offset+limit):null};
}
