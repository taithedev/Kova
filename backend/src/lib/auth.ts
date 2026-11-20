import { db } from './db';
import { ApiError } from './errors';
import { tokenHash } from './crypto';
export type Viewer = { id:string; handle:string; display_name:string; age_band:string; role:string; is_private:boolean; allow_messages:boolean };
export async function viewer(req:Request): Promise<Viewer> {
 const value=req.headers.get('authorization');
 if(!value?.startsWith('Bearer ')) throw new ApiError(401,'Sign in required');
 const token=value.slice(7).trim();
 if(token.length<20||token.length>256) throw new ApiError(401,'Invalid session');
 const rows=await db()`SELECT p.id, p.handle, p.display_name, p.age_band, p.role, p.is_private, p.allow_messages
                       FROM sessions s JOIN profiles p ON p.id=s.user_id
                       WHERE s.token_hash=${tokenHash(token)} AND s.expires_at > NOW() AND p.disabled_at IS NULL LIMIT 1`;
 const user=rows[0] as Viewer|undefined;
 if(!user) throw new ApiError(401,'Session expired. Sign in again.');
 return user;
}
export async function optionalViewer(req:Request):Promise<Viewer|undefined> {
 if(!req.headers.has('authorization')) return undefined;
 return viewer(req);
}
export function requireModerator(user:Viewer) { if(user.role!=='moderator'&&user.role!=='admin') throw new ApiError(403,'Moderator access required'); }
