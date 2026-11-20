import { optionalViewer } from '@/lib/auth';
import { getFeed } from '@/lib/feed';
import { guarded, json, ApiError } from '@/lib/errors';
export async function GET(req:Request){ return guarded(async()=>{
 const u=new URL(req.url);const mode=u.searchParams.get('mode')||'for-you';
 if(mode!=='for-you'&&mode!=='following') throw new ApiError(400,'Invalid feed mode');
 const user=await optionalViewer(req);if(mode==='following'&&!user) throw new ApiError(401,'Sign in required');
 return json(await getFeed(user,mode,12,u.searchParams.get('cursor')||undefined));
 }); }
