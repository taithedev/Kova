import { neon } from '@neondatabase/serverless';
import { randomBytes, randomUUID, createHash, createHmac, createCipheriv, createDecipheriv } from 'node:crypto';

class AppError extends Error {
 constructor(status, message){super(message);this.status=status;}
}
let query;
const db=()=>{if(!query){if(!process.env.DATABASE_URL)throw new AppError(503,'Kova database is not connected');query=neon(process.env.DATABASE_URL);}return query;};
const digest=(s)=>createHash('sha256').update(s).digest('hex');
const json=(data,status=200)=>Response.json({data},{status,headers:{'cache-control':'no-store','x-content-type-options':'nosniff'}});
const problem=(message,status)=>Response.json({error:message},{status,headers:{'cache-control':'no-store'}});
const safeError=(err)=>{
 if(err instanceof AppError)return problem(err.message,err.status);
 console.error('Kova backend error',err?.name || 'unknown');
 return problem('Kova could not complete this request. Please try again.',500);
};
const cleanHandle=(text)=>String(text||'').trim().toLowerCase();
const validHandle=(value)=>/^[a-z0-9_]{3,25}$/.test(value);
const validUUID=(s)=>/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
async function parseBody(req){
 const length=Number(req.headers.get('content-length')||0);
 if(length>10000)throw new AppError(413,'Request too large');
 let body;
 try {body=await req.json();}catch{throw new AppError(400,'Invalid request');}
 if(!body||typeof body!=='object'||Array.isArray(body))throw new AppError(400,'Invalid request');
 return body;
}
function ageBand(date){
 if(!/^\d{4}-\d{2}-\d{2}$/.test(date||''))throw new AppError(400,'Enter a valid date of birth');
 const d=new Date(date+'T00:00:00.000Z');
 if(Number.isNaN(d.valueOf())||d.toISOString().slice(0,10)!==date)throw new AppError(400,'Invalid date of birth');
 const today=new Date();
 const age=today.getUTCFullYear()-d.getUTCFullYear()-(today.getUTCMonth()<d.getUTCMonth()||(today.getUTCMonth()===d.getUTCMonth()&&today.getUTCDate()<d.getUTCDate())?1:0);
 if(age<13)throw new AppError(403,'Kova social accounts currently require age 13 or older.');
 if(age>120)throw new AppError(400,'Invalid date of birth');
 return age<16?'13_15':age<18?'16_17':'18_plus';
}
async function throttle(req,action,limit=10,minutes=15){
 const ip=(req.headers.get('x-real-ip')||req.headers.get('cf-connecting-ip')||req.headers.get('x-forwarded-for')?.split(',')[0]||'unknown').slice(0,120);
 const key=digest('kova:'+action+':'+ip);
 const r=await db()`SELECT count(*)::int AS n FROM rate_events WHERE key=${key} AND at>now()-(${minutes}::integer*interval '1 minute')`;
 if(Number(r[0]?.n||0)>=limit)throw new AppError(429,'Too many attempts. Try again later.');
 await db()`INSERT INTO rate_events(key) VALUES(${key})`;
}
async function viewer(req,required=true){
 const header=req.headers.get('authorization')||'';
 const token=header.startsWith('Bearer ')?header.slice(7).trim():'';
 if(!token){if(required)throw new AppError(401,'Please sign in');return null;}
 if(token.length<20||token.length>256)throw new AppError(401,'Session expired');
 const hashed=digest(token);
 const rows=await db()`SELECT p.id,p.handle,p.display_name,p.bio,p.avatar_url,p.avatar_key,p.is_verified,p.age_band,p.age_restricted,COALESCE(pr.role,p.role) AS role,p.is_private,p.allow_messages,p.banner_style,p.pronouns,p.avatar_key,p.banner_key,p.banner_animated,
 s.id AS session_id,s.created_at AS session_created_at,
 (SELECT count(*)::int FROM follows f WHERE f.following_id=p.id AND f.status='accepted') AS followers_count,
 (SELECT count(*)::int FROM follows f WHERE f.follower_id=p.id AND f.status='accepted') AS following_count
 FROM sessions s JOIN profiles p ON p.id=s.user_id LEFT JOIN profile_staff_roles pr ON pr.profile_id=p.id
 WHERE s.token_hash=${hashed} AND s.expires_at>now() AND p.disabled_at IS NULL LIMIT 1`;
 if(!rows.length)throw new AppError(401,'Session expired. Sign in again.');
 return rows[0];
}
const publicUser=({session_id,session_created_at,neon_auth_id,internal_auth_email,password_hash,avatar_key,banner_key,...profile})=>profile;
async function mediaProfile(row){
 const profile=publicUser(row);
 if(row.avatar_key)profile.avatar_url=await presignS3('GET',row.avatar_key,900);
 if(row.banner_key)profile.banner_url=await presignS3('GET',row.banner_key,900);
 return profile;
}
async function beginSession(user){
 const token=randomBytes(32).toString('base64url');
 await db()`INSERT INTO sessions(user_id,token_hash,expires_at) VALUES(${user.id},${digest(token)},now()+interval '30 days')`;
 return {user:await mediaProfile(user),token};
}
async function betterAuth(action,payload){
 const base=process.env.NEON_AUTH_BASE_URL?.replace(/\/+$/,'');
 if(!base||!base.startsWith('https://'))throw new AppError(503,'Kova account service is not configured');
 let res;
 try{res=await fetch(base+'/'+action,{method:'POST',headers:{'content-type':'application/json','accept':'application/json','origin':'https://br-autumn-water-bc3ti0gm-kovaapi.compute.c-16.us-east-1.aws.neon.tech'},body:JSON.stringify({...payload,callbackURL:'https://br-autumn-water-bc3ti0gm-kovaapi.compute.c-16.us-east-1.aws.neon.tech/api/health'}),signal:AbortSignal.timeout(12000)});}
 catch{throw new AppError(503,'Account service unavailable. Please try again.');}
 let result;
 try{result=await res.json();}catch{result={};}
 if(!res.ok){
  console.error('Neon auth request rejected: '+JSON.stringify({action,status:res.status,code:String(result?.code||'unknown').slice(0,60),message:String(result?.message||'').replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/g,'[redacted]').slice(0,140)}));
  if(action==='sign-in/email')throw new AppError(401,'Incorrect username or password');
  if(res.status===429)throw new AppError(429,'Please try again in a few minutes');
  throw new AppError(503,'Could not create your account right now. Please try again.');
 }
 return result;
}
async function register(req){
 await throttle(req,'register',6,60);
 const b=await parseBody(req);
 const handle=cleanHandle(b.handle);
 if(!validHandle(handle))throw new AppError(400,'Username must be 3–25 letters, numbers or underscores.');
 const password=String(b.password||'');
 if(password.length<10||password.length>128)throw new AppError(400,'Password must be 10–128 characters.');
 const displayName=String(b.display_name||handle).trim().slice(0,50);
 if(!displayName)throw new AppError(400,'Enter a display name.');
 const band=ageBand(String(b.birth_date||''));
 const found=await db()`SELECT 1 FROM profiles WHERE handle=${handle} LIMIT 1`;
 if(found.length)throw new AppError(409,'This username is already taken.');
 // Managed Better Auth requires email identities. A random reserved address is internal
 // and never presented as a real contact/recovery email. No email is collected.
 const internal='kova-'+randomUUID().replace(/-/g,'')+'@example.com';
 const signed=await betterAuth('sign-up/email',{email:internal,name:displayName,password});
 const authId=String(signed?.user?.id||'');
 if(!authId)throw new AppError(503,'Account service did not confirm registration');
 const rows=await db()`INSERT INTO profiles(handle,display_name,password_hash,age_band,is_private,allow_messages,neon_auth_id,internal_auth_email)
 VALUES(${handle},${displayName},'neon-managed-better-auth',${band},true,false,${authId},${internal})
 ON CONFLICT(handle) DO NOTHING
 RETURNING id,handle,display_name,bio,avatar_url,is_verified,age_band,role,is_private,allow_messages,banner_style,pronouns`;
 if(!rows.length)throw new AppError(409,'This username is already taken.');
 return json(await beginSession(rows[0]),201);
}
async function login(req){
 await throttle(req,'login',12,15);
 const b=await parseBody(req);
 const handle=cleanHandle(b.handle);
 const password=String(b.password||'');
 if(!validHandle(handle)||!password)throw new AppError(401,'Incorrect username or password');
 const rows=await db()`SELECT p.id,p.handle,p.display_name,p.bio,p.avatar_url,p.avatar_key,p.is_verified,p.age_band,COALESCE(pr.role,p.role) AS role,p.is_private,p.allow_messages,p.banner_style,p.pronouns,p.avatar_key,p.banner_key,p.banner_animated,p.internal_auth_email
 FROM profiles p LEFT JOIN profile_staff_roles pr ON pr.profile_id=p.id WHERE p.handle=${handle} AND p.disabled_at IS NULL LIMIT 1`;
 if(!rows.length || !rows[0].internal_auth_email)throw new AppError(401,'Incorrect username or password');
 await betterAuth('sign-in/email',{email:rows[0].internal_auth_email,password});
 return json(await beginSession(rows[0]));
}
async function logout(req){
 const who=await viewer(req);
 await db()`DELETE FROM sessions WHERE id=${who.session_id}`;
 return json({ok:true});
}
// Pure Node.js SigV4 signing avoids loading AWS SDK's Node HTTP transports
// inside the Neon Function ESM worker.
function getStorage(){
 const access=process.env.AWS_ACCESS_KEY_ID||process.env.S3_ACCESS_KEY_ID;
 const secret=process.env.AWS_SECRET_ACCESS_KEY||process.env.S3_SECRET_ACCESS_KEY;
 const endpoint=process.env.AWS_ENDPOINT_URL_S3||process.env.S3_ENDPOINT;
 const region=process.env.AWS_REGION||process.env.S3_REGION||'us-east-1';
 if(!access||!secret||!endpoint)throw new AppError(503,'Video storage is not configured yet.');
 let uri;
 try {uri=new URL(endpoint);}catch{throw new AppError(503,'Video storage URL is invalid');}
 if(uri.protocol!=='https:')throw new AppError(503,'Video storage requires HTTPS');
 return {access,secret,uri,region,bucket:'kova-videos'};
}
const uriEncode=s=>encodeURIComponent(s).replace(/[!'()*]/g,ch=>'%'+ch.charCodeAt(0).toString(16).toUpperCase());
const hmac=(key,data)=>createHmac('sha256',key).update(data).digest();
async function presignS3(method,key,seconds=600){
 const cfg=getStorage();
 const now=new Date().toISOString().replace(/[:-]|\.\d{3}/g,'');
 const day=now.slice(0,8);
 const scope=day+'/'+cfg.region+'/s3/aws4_request';
 const path=cfg.uri.pathname.replace(/\/$/,'')+'/'+cfg.bucket+'/'+key.split('/').map(uriEncode).join('/');
 const params=[
 ['X-Amz-Algorithm','AWS4-HMAC-SHA256'],
 ['X-Amz-Credential',cfg.access+'/'+scope],
 ['X-Amz-Date',now],
 ['X-Amz-Expires',String(seconds)],
 ['X-Amz-SignedHeaders','host']
 ];
 const sessionToken=process.env.AWS_SESSION_TOKEN;
 if(sessionToken)params.push(['X-Amz-Security-Token',sessionToken]);
 const canonicalQuery=params.map(([k,v])=>uriEncode(k)+'='+uriEncode(v)).sort().join('&');
 const canonical=method+'\n'+path+'\n'+canonicalQuery+'\nhost:'+cfg.uri.host.toLowerCase()+'\n\nhost\nUNSIGNED-PAYLOAD';
 const hash=createHash('sha256').update(canonical).digest('hex');
 const text='AWS4-HMAC-SHA256\n'+now+'\n'+scope+'\n'+hash;
 const kDate=hmac('AWS4'+cfg.secret,day);
 const kRegion=hmac(kDate,cfg.region);
 const kService=hmac(kRegion,'s3');
 const signingKey=hmac(kService,'aws4_request');
 const signature=createHmac('sha256',signingKey).update(text).digest('hex');
 return cfg.uri.origin+path+'?'+canonicalQuery+'&X-Amz-Signature='+signature;
}
async function readVideo(key){return presignS3('GET',key,900);}
async function signVideoRows(rows){
 return Promise.all(rows.map(async ({video_key,avatar_key,...item})=>({
 ...item,
 video_url:await readVideo(String(video_key)),
 ...(avatar_key ? {avatar_url:await presignS3('GET',avatar_key,900)} : {})
 })));
}
// Transparent, bounded ranking: recency + capped engagement, with small
// follow signals and fairer exposure for newer creators. No watch-time or
// sensitive-trait profiling. Members can hide posts via "Not interested".
async function trending(req){
 const topics=await db()`SELECT lower(tags.parts[1]) AS tag,count(*)::int AS videos
 FROM videos v JOIN profiles p ON p.id=v.author_id
 CROSS JOIN LATERAL (
  SELECT regexp_matches(v.caption,'#([A-Za-z0-9_]{2,24})','g') AS parts
 ) tags
 WHERE v.status='approved' AND v.visibility='public' AND p.is_private=false
 AND p.disabled_at IS NULL AND v.created_at>now()-interval '30 days'
 GROUP BY lower(tags.parts[1])
 ORDER BY count(*) DESC,lower(tags.parts[1]) ASC LIMIT 15`;
 return json({topics});
}
async function feedPreferences(req){
 const me=await viewer(req);
 if(req.method==='DELETE'){
  const removed=await db()`DELETE FROM video_not_interested WHERE user_id=${me.id} RETURNING video_id`;
  return json({reset:true,cleared:removed.length});
 }
 const rows=await db()`SELECT count(*)::int AS hidden_count FROM video_not_interested WHERE user_id=${me.id}`;
 return json(rows[0]);
}
async function feed(req){
 const u=new URL(req.url);
 const mode=u.searchParams.get('mode')||'for-you';
 if(!['for-you','following'].includes(mode))throw new AppError(400,'Invalid feed mode');
 const person=await viewer(req,false);
 if(mode==='following'&&!person)throw new AppError(401,'Sign in for your Following feed');
 const id=person?.id||'00000000-0000-0000-0000-000000000000';
 const offset=Math.min(Math.max(parseInt(u.searchParams.get('cursor')||'0',10)||0,0),1000);
 const rows=await db()`WITH candidates AS (
  SELECT v.id,v.caption,v.video_key,v.thumbnail_url,v.created_at,v.duration_seconds,v.music_title,
   p.id AS author_id,p.handle,p.display_name,p.avatar_url,p.avatar_key,p.is_verified,
   (SELECT count(*)::int FROM likes l WHERE l.video_id=v.id) AS likes_count,
   (SELECT count(*)::int FROM comments co WHERE co.video_id=v.id AND co.deleted_at IS NULL) AS comments_count,
   (SELECT count(*)::int FROM video_reposts rr WHERE rr.video_id=v.id) AS reposts_count,
   EXISTS(SELECT 1 FROM likes l WHERE l.video_id=v.id AND l.user_id=${id}::uuid) AS liked,
   EXISTS(SELECT 1 FROM bookmarks b WHERE b.video_id=v.id AND b.user_id=${id}::uuid) AS bookmarked,
   EXISTS(SELECT 1 FROM video_reposts rr WHERE rr.video_id=v.id AND rr.user_id=${id}::uuid) AS reposted,
   EXISTS(SELECT 1 FROM follows f WHERE f.follower_id=${id}::uuid
     AND f.following_id=p.id AND f.status='accepted') AS already_following,
   row_number() OVER(PARTITION BY p.id ORDER BY v.created_at DESC) AS author_slot
  FROM videos v JOIN profiles p ON p.id=v.author_id
  WHERE v.status='approved' AND p.disabled_at IS NULL
   AND (
     (${mode}='for-you' AND v.visibility='public' AND p.is_private=false)
     OR (${mode}='following'
       AND (v.visibility='public' AND p.is_private=false
         OR v.visibility IN ('public','followers') AND EXISTS (
           SELECT 1 FROM follows f WHERE f.follower_id=${id}::uuid
           AND f.following_id=p.id AND f.status='accepted'
         ))
       AND (
        EXISTS (SELECT 1 FROM follows f WHERE f.follower_id=${id}::uuid
         AND f.following_id=p.id AND f.status='accepted')
        OR EXISTS (SELECT 1 FROM video_reposts rr
          JOIN follows f ON f.following_id=rr.user_id
          WHERE rr.video_id=v.id AND f.follower_id=${id}::uuid AND f.status='accepted'
          AND v.visibility='public' AND p.is_private=false)
       ))
   )
   AND NOT EXISTS (SELECT 1 FROM video_not_interested hide
     WHERE hide.user_id=${id}::uuid AND hide.video_id=v.id)
   AND NOT EXISTS(SELECT 1 FROM blocks b
     WHERE (b.blocker_id=${id}::uuid AND b.blocked_id=p.id)
     OR (b.blocker_id=p.id AND b.blocked_id=${id}::uuid))
 )
 SELECT * FROM candidates c
 WHERE (${mode}='following' OR author_slot<=3)
 ORDER BY
 CASE WHEN ${mode}='following' THEN c.created_at END DESC,
 CASE WHEN ${mode}='for-you' THEN
  (7.5 / (1 + GREATEST(EXTRACT(EPOCH FROM now()-c.created_at),0)/86400/3))
  + LEAST(4.0,ln(1+c.likes_count)*0.8)
  + LEAST(3.5,ln(1+c.comments_count)*1.15)
  + LEAST(2.5,ln(1+c.reposts_count)*0.65)
  + CASE WHEN c.already_following THEN 1.25 ELSE 0 END
  - greatest(c.author_slot-1,0)*0.45
 END DESC,
 c.created_at DESC,md5(c.id::text || current_date::text)
 LIMIT 12 OFFSET ${offset}`;
 return json({items:await signVideoRows(rows),next_cursor:rows.length===12?String(offset+12):null,
  ranking:mode==='for-you'?'freshness-community-diversity':'following-and-reposts'});
}

async function search(req){
 const u=new URL(req.url);
 const q=(u.searchParams.get('q')||'').trim().slice(0,60);
 if(q.length<2)return json({users:[],videos:[]});
 const person=await viewer(req,false);
 const id=person?.id||'00000000-0000-0000-0000-000000000000';
 const term='%'+q+'%';
 const users=await db()`SELECT p.id,p.handle,p.display_name,p.avatar_url,p.avatar_key,p.is_verified,COALESCE(pr.role,p.role) AS role FROM profiles p LEFT JOIN profile_staff_roles pr ON pr.profile_id=p.id
 WHERE (p.handle ILIKE ${term} OR p.display_name ILIKE ${term}) AND p.disabled_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${id}::uuid AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${id}::uuid))
 ORDER BY handle LIMIT 20`;
 const rows=await db()`SELECT v.id,v.caption,v.video_key,p.handle,p.display_name FROM videos v JOIN profiles p ON p.id=v.author_id
 WHERE v.caption ILIKE ${term} AND v.status='approved' AND v.visibility='public' AND p.is_private=false AND p.disabled_at IS NULL
 ORDER BY v.created_at DESC LIMIT 20`;
 return json({users:await Promise.all(users.map(mediaProfile)),videos:await signVideoRows(rows)});
}
async function accountStats(req){
 const me=await viewer(req);
 const r=await db()`SELECT
 (SELECT count(*)::int FROM videos WHERE author_id=${me.id} AND status='approved') AS published_videos,
 (SELECT count(*)::int FROM videos WHERE author_id=${me.id} AND status='pending') AS pending_videos,
 (SELECT count(*)::int FROM bookmarks WHERE user_id=${me.id}) AS saved_videos,
 (SELECT count(*)::int FROM comments WHERE user_id=${me.id} AND deleted_at IS NULL) AS comments,
 (SELECT count(*)::int FROM notifications WHERE recipient_id=${me.id} AND is_read=false) AS unread_notifications`;
 return json(r[0]);
}
async function userMe(req){
 const me=await viewer(req);
 if(req.method==='GET')return json(await mediaProfile(me));
 const b=await parseBody(req);
 const name=String(b.display_name||'').trim();
 const bio=String(b.bio||'').trim();
 if(name.length<1||name.length>50||bio.length>160||typeof b.is_private!=='boolean')throw new AppError(400,'Invalid profile');
 const styles=['ink','glacier','orchid','coral','mint','sunset'];
 const banner=String(b.banner_style ?? me.banner_style ?? 'ink');
 if(!styles.includes(banner))throw new AppError(400,'Select a valid banner style');
 const pronouns=String(b.pronouns ?? me.pronouns ?? '').trim();
 if(pronouns.length>32)throw new AppError(400,'Pronouns must be 32 characters or shorter');
 const input=b.avatar_url===undefined?me.avatar_url:b.avatar_url;
 let avatar=null;
 if(input!==null && String(input).trim()){
  const raw=String(input).trim();
  if(raw.length>512)throw new AppError(400,'Avatar URL is too long');
  if(/^kova-avatar:(violet|ocean|sunset|moss|rose|mono)$/.test(raw)){avatar=raw;}
  else{
   try{const u=new URL(raw);if(u.protocol!=='https:'||u.username||u.password||!u.hostname.includes('.')||u.port)throw Error('Invalid');avatar=u.toString();}
   catch{throw new AppError(400,'Profile photo must use a Kova avatar or HTTPS image link');}
  }
 }
 const result=await db()`UPDATE profiles SET display_name=${name},bio=${bio},is_private=${b.is_private},
 avatar_url=${avatar},avatar_key=CASE WHEN ${b.avatar_url!==undefined} THEN NULL ELSE avatar_key END,
 banner_key=CASE WHEN ${b.reset_banner===true} THEN NULL ELSE banner_key END,
 banner_animated=CASE WHEN ${b.reset_banner===true} THEN false ELSE banner_animated END,
 banner_style=${banner},pronouns=${pronouns},updated_at=now()
 WHERE id=${me.id}
 RETURNING id,handle,display_name,bio,avatar_url,is_verified,age_band,role,is_private,allow_messages,banner_style,pronouns`;
 return json(await mediaProfile({...result[0],role:me.role,
 avatar_key:b.avatar_url!==undefined ? null : me.avatar_key,
 banner_key:b.reset_banner===true ? null : me.banner_key,
 banner_animated:b.reset_banner===true ? false : me.banner_animated}));
}
// Kova messages: opt-in, mutual follows, age-band matching, blocks and reports.
// Restrict 13–15 and 16–17 accounts from messaging 18+ users. No unsolicited DMs.
async function messageEligibility(me,targetID){
 if(!validUUID(String(targetID||''))||targetID===me.id)
  throw new AppError(400,'Choose another account');
 const rows=await db()`SELECT p.id,p.handle,p.display_name,p.avatar_url,p.age_band,p.allow_messages,p.age_restricted
 FROM profiles p WHERE p.id=${targetID} AND p.disabled_at IS NULL LIMIT 1`;
 if(!rows.length)throw new AppError(404,'Account not found');
 const them=rows[0];
 if(me.age_restricted||them.age_restricted)throw new AppError(403,'Messaging is restricted on this account');
 if(!me.allow_messages||!them.allow_messages)throw new AppError(403,'Both users must enable private messaging');
 if(me.age_band!==them.age_band)throw new AppError(403,'Messaging is limited to mutual followers in the same age group');
 const following=await db()`SELECT count(*)::int AS n FROM follows
 WHERE status='accepted' AND
 ((follower_id=${me.id} AND following_id=${targetID})
 OR (follower_id=${targetID} AND following_id=${me.id}))`;
 if(Number(following[0]?.n)!==2)throw new AppError(403,'Messaging requires a mutual follow');
 const blocks=await db()`SELECT 1 FROM blocks
 WHERE (blocker_id=${me.id} AND blocked_id=${targetID})
 OR (blocker_id=${targetID} AND blocked_id=${me.id}) LIMIT 1`;
 if(blocks.length)throw new AppError(403,'Messaging unavailable');
 return them;
}
async function messageOptions(req){
 const me=await viewer(req);
 if(req.method==='GET')return json({
  allow_messages:me.allow_messages && !me.age_restricted,age_restricted:me.age_restricted,
  restrictions:'Mutual accepted followers in the same age group. Both opt in.'
 });
 const body=await parseBody(req);
 if(typeof body.allow_messages!=='boolean')throw new AppError(400,'Invalid message setting');
 const allowed=Boolean(body.allow_messages&&!me.age_restricted);
 const rows=await db()`UPDATE profiles SET allow_messages=${allowed},updated_at=now()
 WHERE id=${me.id} RETURNING allow_messages,age_restricted`;
 return json(rows[0]);
}
async function dmInbox(req){
 const me=await viewer(req);
 if(me.age_restricted||!me.allow_messages)return json({items:[]});
 const rows=await db()`SELECT DISTINCT ON (partner.id)
 partner.id,partner.handle,partner.display_name,partner.avatar_url,
 dm.body AS last_message,dm.created_at AS last_message_at,dm.sender_id=${me.id} AS sent_by_me
 FROM direct_messages dm JOIN profiles partner ON partner.id=
 CASE WHEN dm.sender_id=${me.id} THEN dm.recipient_id ELSE dm.sender_id END
 WHERE (dm.sender_id=${me.id} OR dm.recipient_id=${me.id})
 AND dm.deleted_at IS NULL AND partner.disabled_at IS NULL
 AND partner.allow_messages=true AND partner.age_restricted=false AND partner.age_band=${me.age_band}
 AND EXISTS (SELECT 1 FROM follows f WHERE f.follower_id=${me.id} AND f.following_id=partner.id AND f.status='accepted')
 AND EXISTS (SELECT 1 FROM follows f WHERE f.follower_id=partner.id AND f.following_id=${me.id} AND f.status='accepted')
 AND NOT EXISTS (SELECT 1 FROM blocks b WHERE
 (b.blocker_id=${me.id} AND b.blocked_id=partner.id)
 OR (b.blocker_id=partner.id AND b.blocked_id=${me.id}))
 ORDER BY partner.id,dm.created_at DESC LIMIT 80`;
 rows.sort((a,b)=>new Date(b.last_message_at)-new Date(a.last_message_at));
 return json({items:rows});
}
async function dmConversation(req,handle){
 const me=await viewer(req);
 const users=await db()`SELECT id FROM profiles WHERE handle=${handle} AND disabled_at IS NULL LIMIT 1`;
 if(!users.length)throw new AppError(404,'Account not found');
 const them=await messageEligibility(me,users[0].id);
 if(req.method==='GET'){
  const rows=await db()`SELECT id,sender_id,recipient_id,body,created_at FROM direct_messages
  WHERE deleted_at IS NULL
  AND ((sender_id=${me.id} AND recipient_id=${them.id}) OR
  (sender_id=${them.id} AND recipient_id=${me.id}))
  ORDER BY created_at DESC LIMIT 100`;
  return json({user:{id:them.id,handle:them.handle,display_name:them.display_name,
    avatar_url:them.avatar_url},messages:rows.reverse()});
 }
 await throttle(req,'dm_send',18,5);
 const b=await parseBody(req);
 const body=String(b.body||'').trim();
 if(body.length<1||body.length>1000)throw new AppError(400,'Message must be 1–1000 characters');
 // Reduce personal-information sharing and spam in teen chat.
 if(/(?:https?:\/\/|www\.)/i.test(body)||/(?:\+?\d[\s().-]*){9,}/.test(body))
 throw new AppError(400,'Links and phone numbers cannot be shared in Kova messages');
 const rows=await db()`INSERT INTO direct_messages(sender_id,recipient_id,body)
 VALUES(${me.id},${them.id},${body})
 RETURNING id,sender_id,recipient_id,body,created_at`;
 await db()`INSERT INTO notifications(recipient_id,actor_id,kind,body)
 VALUES(${them.id},${me.id},'message','New message from @' || ${me.handle})`;
 return json(rows[0],201);
}
async function dmReport(req,id){
 const me=await viewer(req);
 if(!validUUID(id))throw new AppError(400,'Invalid message');
 const messages=await db()`SELECT id,sender_id,recipient_id FROM direct_messages WHERE id=${id}
 AND (sender_id=${me.id} OR recipient_id=${me.id}) LIMIT 1`;
 if(!messages.length)throw new AppError(404,'Message not found');
 const b=await parseBody(req);
 if(!['bullying','sexual_content','violence','hate','spam','privacy','other'].includes(b.reason))
 throw new AppError(400,'Invalid report reason');
 const detail=String(b.detail||'').slice(0,500);
 // Staff report queues use the same report IDs but never reveal the private DM text.
 const rows=await db()`INSERT INTO reports(reporter_id,target_type,target_id,reason,detail)
 VALUES(${me.id},'message',${id},${b.reason},${detail}) RETURNING id,status`;
 return json(rows[0],201);
}
async function ageSafety(req,handle){
 const me=await viewer(req);
 if(!['owner','admin','moderator'].includes(me.role))
 throw new AppError(403,'Staff access required');
 const target=await db()`SELECT p.id,p.handle,p.age_restricted,COALESCE(r.role,p.role) AS role
 FROM profiles p LEFT JOIN profile_staff_roles r ON r.profile_id=p.id
 WHERE p.handle=${handle} AND p.disabled_at IS NULL LIMIT 1`;
 if(!target.length)throw new AppError(404,'Account not found');
 const person=target[0];
 if(person.role==='owner'||person.id===me.id)throw new AppError(403,'Cannot change this account');
 const b=await parseBody(req);
 if(typeof b.age_restricted!=='boolean')throw new AppError(400,'Invalid safety restriction');
 const updated=await db()`UPDATE profiles SET age_restricted=${b.age_restricted},
 allow_messages=CASE WHEN ${b.age_restricted} THEN false ELSE allow_messages END,
 updated_at=now() WHERE id=${person.id} RETURNING handle,age_restricted,allow_messages`;
 await db()`INSERT INTO staff_action_events(actor_id,action,subject_type,subject_id,detail)
 VALUES(${me.id},'account_safety_restriction','profile',${person.id},
 ${JSON.stringify({previous:person.age_restricted,next:b.age_restricted,reason:String(b.reason||'staff_safety').slice(0,120)})}::jsonb)`;
 await db()`INSERT INTO notifications(recipient_id,actor_id,kind,body)
 VALUES(${person.id},${me.id},'account_safety',
 'Your messaging permissions were updated by Kova staff. You may contact support to appeal.')`;
 return json(updated[0]);
}
async function profile(req,handle){
 const who=await viewer(req,false);
 const id=who?.id||'00000000-0000-0000-0000-000000000000';
 const rows=await db()`SELECT p.id,p.handle,p.display_name,p.bio,p.avatar_url,p.avatar_key,
 p.is_verified,p.is_private,p.age_restricted,p.allow_messages,p.banner_style,p.pronouns,
 p.banner_key,p.banner_animated,COALESCE(pr.role,p.role) AS role,
 (SELECT count(*)::int FROM follows f WHERE f.following_id=p.id AND f.status='accepted') AS followers_count,
 (SELECT count(*)::int FROM follows f WHERE f.follower_id=p.id AND f.status='accepted') AS following_count,
 EXISTS(SELECT 1 FROM follows f WHERE f.following_id=p.id AND f.follower_id=${id}::uuid
 AND f.status='accepted') AS is_following
 FROM profiles p LEFT JOIN profile_staff_roles pr ON pr.profile_id=p.id
 WHERE p.handle=${handle} AND p.disabled_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE
 (b.blocker_id=${id}::uuid AND b.blocked_id=p.id)
 OR (b.blocker_id=p.id AND b.blocked_id=${id}::uuid)) LIMIT 1`;
 if(!rows.length)throw new AppError(404,'User not found');
 const p=rows[0];
 const visible=!p.is_private||p.id===who?.id||p.is_following;
 const videos=visible?await db()`SELECT v.id,v.caption,v.description,v.video_key,
 v.thumbnail_url,v.created_at,v.duration_seconds,v.music_title,v.status,
 v.visibility,v.allow_remix,v.source_video_id,
 author.id AS author_id,author.handle,author.display_name,
 author.avatar_url,author.avatar_key,author.is_verified,
 (SELECT count(*)::int FROM likes l WHERE l.video_id=v.id) AS likes_count,
 (SELECT count(*)::int FROM comments c WHERE c.video_id=v.id AND c.deleted_at IS NULL) AS comments_count,
 (SELECT count(*)::int FROM video_reposts r WHERE r.video_id=v.id) AS reposts_count,
 EXISTS(SELECT 1 FROM likes l WHERE l.video_id=v.id AND l.user_id=${id}::uuid) AS liked,
 EXISTS(SELECT 1 FROM bookmarks b WHERE b.video_id=v.id AND b.user_id=${id}::uuid) AS bookmarked,
 EXISTS(SELECT 1 FROM video_reposts r WHERE r.video_id=v.id AND r.user_id=${id}::uuid) AS reposted
 FROM videos v JOIN profiles author ON author.id=v.author_id
 WHERE v.author_id=${p.id} AND v.status='approved'
 AND (v.visibility='public' OR v.author_id=${id}::uuid
 OR (v.visibility='followers' AND ${Boolean(p.is_following)}))
 ORDER BY v.created_at DESC LIMIT 80`:[];
 return json({profile:await mediaProfile(p),videos:await signVideoRows(videos)});
}

async function follow(req,handle){
 const me=await viewer(req);
 const rows=await db()`SELECT id,is_private FROM profiles WHERE handle=${handle} AND disabled_at IS NULL LIMIT 1`;
 if(!rows.length)throw new AppError(404,'User not found');
 const id=rows[0].id;
 if(id===me.id)throw new AppError(400,'You cannot follow yourself');
 if(req.method==='DELETE'){await db()`DELETE FROM follows WHERE follower_id=${me.id} AND following_id=${id}`;return json({following:false});}
 const blocks=await db()`SELECT 1 FROM blocks WHERE (blocker_id=${me.id} AND blocked_id=${id}) OR (blocker_id=${id} AND blocked_id=${me.id}) LIMIT 1`;
 if(blocks.length)throw new AppError(403,'Unavailable');
 const status=rows[0].is_private?'pending':'accepted';
 await db()`INSERT INTO follows(follower_id,following_id,status) VALUES(${me.id},${id},${status})
 ON CONFLICT(follower_id,following_id) DO UPDATE SET status=EXCLUDED.status`;
 return json({status});
}
async function followRequests(req,id,kind){
 const me=await viewer(req);
 if(!id){
 const rows=await db()`SELECT f.follower_id AS id,p.handle,p.display_name,f.created_at
 FROM follows f JOIN profiles p ON p.id=f.follower_id
 WHERE f.following_id=${me.id} AND f.status='pending' ORDER BY f.created_at DESC LIMIT 100`;
 return json({items:rows});
 }
 if(!validUUID(id))throw new AppError(400,'Invalid follow request');
 if(kind==='reject'){
 await db()`DELETE FROM follows WHERE follower_id=${id} AND following_id=${me.id} AND status='pending'`;
 return json({status:'rejected'});
 }
 const rows=await db()`UPDATE follows SET status='accepted' WHERE follower_id=${id}
 AND following_id=${me.id} AND status='pending' RETURNING status`;
 if(!rows.length)throw new AppError(404,'Request not found');
 return json({status:'accepted'});
}
async function markNotifications(req){
 const me=await viewer(req);
 const rows=await db()`UPDATE notifications SET is_read=true WHERE recipient_id=${me.id} AND is_read=false RETURNING id`;
 return json({marked_read:rows.length});
}
async function notifications(req){
 const me=await viewer(req);
 const rows=await db()`SELECT id,kind,body,ticket_id,is_read,created_at FROM notifications
 WHERE recipient_id=${me.id} ORDER BY created_at DESC LIMIT 100`;
 return json({items:rows});
}
async function ownVideos(req){
 const me=await viewer(req);
 const rows=await db()`SELECT v.id,v.caption,v.description,v.video_key,v.thumbnail_url,
 v.created_at,v.duration_seconds,v.music_title,v.visibility,v.status,v.allow_remix,v.source_video_id,v.remix_type,
 p.id AS author_id,p.handle,p.display_name,p.avatar_url,p.avatar_key,p.is_verified,
 (SELECT count(*)::int FROM likes l WHERE l.video_id=v.id) AS likes_count,
 (SELECT count(*)::int FROM comments c WHERE c.video_id=v.id AND c.deleted_at IS NULL) AS comments_count,
 (SELECT count(*)::int FROM video_reposts r WHERE r.video_id=v.id) AS reposts_count,
 EXISTS(SELECT 1 FROM likes l WHERE l.video_id=v.id AND l.user_id=${me.id}) AS liked,
 EXISTS(SELECT 1 FROM bookmarks b WHERE b.video_id=v.id AND b.user_id=${me.id}) AS bookmarked,
 EXISTS(SELECT 1 FROM video_reposts r WHERE r.video_id=v.id AND r.user_id=${me.id}) AS reposted
 FROM videos v JOIN profiles p ON p.id=v.author_id WHERE v.author_id=${me.id}
 ORDER BY v.created_at DESC LIMIT 100`;
 const published=rows.filter(v=>v.status==='approved');
 const rest=rows.filter(v=>v.status!=='approved').map(({video_key,avatar_key,...row})=>({...row,video_url:''}));
 return json({items:[...await signVideoRows(published),...rest]});
}

async function saved(req){
 const me=await viewer(req);
 const rows=await db()`SELECT v.id,v.caption,v.video_key,v.thumbnail_url,v.created_at,v.duration_seconds,v.music_title,p.id AS author_id,p.handle,p.display_name,p.avatar_url,p.avatar_key,p.is_verified,
 (SELECT count(*)::int FROM likes l WHERE l.video_id=v.id) AS likes_count,
 (SELECT count(*)::int FROM comments c WHERE c.video_id=v.id AND c.deleted_at IS NULL) AS comments_count,
 EXISTS(SELECT 1 FROM likes l WHERE l.video_id=v.id AND l.user_id=${me.id}) AS liked,
 true AS bookmarked
 FROM bookmarks b JOIN videos v ON v.id=b.video_id JOIN profiles p ON p.id=v.author_id
 WHERE b.user_id=${me.id} AND v.status='approved' AND p.disabled_at IS NULL
 AND (v.author_id=${me.id} OR (v.visibility='public' AND p.is_private=false)
 OR (v.visibility='followers' AND EXISTS(SELECT 1 FROM follows f WHERE f.following_id=p.id AND f.follower_id=${me.id} AND f.status='accepted')))
 ORDER BY b.created_at DESC LIMIT 100`;
 return json({items:await signVideoRows(rows),next_cursor:null});
}
// Explicit "Not interested": a signed-in viewer controls their own feed.
async function videoPreference(req,vid){
 const me=await viewer(req);
 if(!validUUID(vid))throw new AppError(400,'Invalid video');
 if(req.method==='POST'){
  const visible=await db()`SELECT 1 FROM videos v JOIN profiles p ON p.id=v.author_id
   WHERE v.id=${vid} AND v.status='approved' AND v.visibility='public'
     AND p.is_private=false AND p.disabled_at IS NULL LIMIT 1`;
  if(!visible.length)throw new AppError(404,'Video unavailable');
  await db()`INSERT INTO video_not_interested(user_id,video_id)
   VALUES(${me.id},${vid}) ON CONFLICT DO NOTHING`;
 } else {
  await db()`DELETE FROM video_not_interested WHERE user_id=${me.id} AND video_id=${vid}`;
 }
 return json({hidden:req.method==='POST'});
}
async function singleVideo(req,vid){
 if(!validUUID(vid))throw new AppError(400,'Invalid video');
 const me=await viewer(req,false);
 const id=me?.id||'00000000-0000-0000-0000-000000000000';
 const rows=await db()`SELECT v.id,v.caption,v.description,v.video_key,v.thumbnail_url,
 v.created_at,v.duration_seconds,v.music_title,v.visibility,v.status,v.allow_remix,v.source_video_id,v.remix_type,
 p.id AS author_id,p.handle,p.display_name,p.avatar_url,p.avatar_key,p.is_verified,
 (SELECT count(*)::int FROM likes l WHERE l.video_id=v.id) AS likes_count,
 (SELECT count(*)::int FROM comments c WHERE c.video_id=v.id AND c.deleted_at IS NULL) AS comments_count,
 (SELECT count(*)::int FROM video_reposts r WHERE r.video_id=v.id) AS reposts_count,
 EXISTS(SELECT 1 FROM likes l WHERE l.video_id=v.id AND l.user_id=${id}::uuid) AS liked,
 EXISTS(SELECT 1 FROM bookmarks b WHERE b.video_id=v.id AND b.user_id=${id}::uuid) AS bookmarked,
 EXISTS(SELECT 1 FROM video_reposts r WHERE r.video_id=v.id AND r.user_id=${id}::uuid) AS reposted
 FROM videos v JOIN profiles p ON p.id=v.author_id
 WHERE v.id=${vid} AND v.status='approved' AND p.disabled_at IS NULL
 AND (v.author_id=${id}::uuid
 OR (v.visibility='public' AND p.is_private=false)
 OR (v.visibility IN ('public','followers') AND EXISTS(
 SELECT 1 FROM follows f WHERE f.follower_id=${id}::uuid
 AND f.following_id=p.id AND f.status='accepted')))
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE
 (b.blocker_id=${id}::uuid AND b.blocked_id=p.id)
 OR (b.blocker_id=p.id AND b.blocked_id=${id}::uuid)) LIMIT 1`;
 if(!rows.length)throw new AppError(404,'Video unavailable');
 const signed=await signVideoRows(rows);
 return json(signed[0]);
}
async function videoAction(req,vid,action){
 if(!validUUID(vid))throw new AppError(400,'Invalid video');
 const me=await viewer(req);
 const allowed=await db()`SELECT v.id,v.author_id,v.visibility FROM videos v JOIN profiles p ON p.id=v.author_id
 WHERE v.id=${vid} AND v.status='approved' AND (v.author_id=${me.id} OR (v.visibility='public' AND p.is_private=false)
 OR (v.visibility='followers' AND EXISTS(SELECT 1 FROM follows f WHERE f.follower_id=${me.id}
 AND f.following_id=p.id AND f.status='accepted')))
 AND p.disabled_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${me.id} AND b.blocked_id=p.id)
 OR (b.blocker_id=p.id AND b.blocked_id=${me.id})) LIMIT 1`;
 if(!allowed.length)throw new AppError(404,'Video unavailable');
 if(action==='repost'){
  // Reposts redistribute PUBLIC posts only and cannot bypass private profiles.
  const publicVideo=await db()`SELECT 1 FROM videos v JOIN profiles p ON p.id=v.author_id
   WHERE v.id=${vid} AND v.visibility='public' AND p.is_private=false
    AND v.status='approved' AND p.disabled_at IS NULL LIMIT 1`;
  if(!publicVideo.length)throw new AppError(403,'Only public videos can be reposted');
  if(req.method==='POST')await db()`INSERT INTO video_reposts(user_id,video_id)
    VALUES(${me.id},${vid}) ON CONFLICT DO NOTHING`;
  else await db()`DELETE FROM video_reposts WHERE user_id=${me.id} AND video_id=${vid}`;
  const counts=await db()`SELECT count(*)::int AS count FROM video_reposts WHERE video_id=${vid}`;
  return json({reposted:req.method==='POST',reposts_count:counts[0].count});
 }
 if(action==='like'){
  if(req.method==='POST')await db()`INSERT INTO likes(user_id,video_id)
   VALUES(${me.id},${vid}) ON CONFLICT DO NOTHING`;
  else await db()`DELETE FROM likes WHERE user_id=${me.id} AND video_id=${vid}`;
  return json({liked:req.method==='POST'});
 }
 if(req.method==='POST')await db()`INSERT INTO bookmarks(user_id,video_id)
  VALUES(${me.id},${vid}) ON CONFLICT DO NOTHING`;
 else await db()`DELETE FROM bookmarks WHERE user_id=${me.id} AND video_id=${vid}`;
 return json({bookmarked:req.method==='POST'});
}

async function comments(req,vid,cid){
 if(!validUUID(vid))throw new AppError(400,'Invalid video');
 if(cid&&req.method==='DELETE'){
 const me=await viewer(req);
 const rows=await db()`UPDATE comments SET deleted_at=now() WHERE id=${cid} AND video_id=${vid} AND user_id=${me.id}
 AND deleted_at IS NULL RETURNING id`;
 if(!rows.length)throw new AppError(404,'Comment not found');
 return json({deleted:true});
 }
 if(req.method==='GET'){
 const me=await viewer(req,false);
 const id=me?.id||'00000000-0000-0000-0000-000000000000';
 const rows=await db()`SELECT c.id,c.body,c.created_at,p.handle,p.display_name,p.avatar_url
 FROM comments c JOIN profiles p ON p.id=c.user_id JOIN videos v ON v.id=c.video_id
 JOIN profiles author ON author.id=v.author_id
 WHERE c.video_id=${vid} AND c.deleted_at IS NULL AND v.status='approved'
 AND (v.author_id=${id}::uuid OR (v.visibility='public' AND author.is_private=false)
 OR (v.visibility IN ('public','followers') AND EXISTS(SELECT 1 FROM follows f
 WHERE f.follower_id=${id}::uuid AND f.following_id=v.author_id AND f.status='accepted')))
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE (b.blocker_id=${id}::uuid AND b.blocked_id=p.id) OR (b.blocker_id=p.id AND b.blocked_id=${id}::uuid))
 ORDER BY c.created_at DESC LIMIT 100`;
 return json({items:rows});
 }
 const me=await viewer(req);await throttle(req,'comment',30,10);
 const body=String((await parseBody(req)).body||'').trim();
 if(!body||body.length>500)throw new AppError(400,'Comment must be 1–500 characters.');
 const r=await db()`INSERT INTO comments(video_id,user_id,body)
 SELECT v.id,${me.id},${body} FROM videos v JOIN profiles p ON p.id=v.author_id
 WHERE v.id=${vid} AND v.status='approved' AND
 ((v.visibility='public' AND p.is_private=false)
 OR (v.visibility IN ('public','followers') AND EXISTS(SELECT 1 FROM follows f
 WHERE f.follower_id=${me.id}::uuid AND f.following_id=v.author_id AND f.status='accepted')))
 AND NOT EXISTS(SELECT 1 FROM blocks b WHERE
 (b.blocker_id=${me.id}::uuid AND b.blocked_id=v.author_id)
 OR (b.blocker_id=v.author_id AND b.blocked_id=${me.id}::uuid))
 RETURNING id,body,created_at`;
 if(!r.length)throw new AppError(404,'Video unavailable');
 return json(r[0],201);
}
async function blockUser(req){
 const me=await viewer(req);
 const b=await parseBody(req);
 const handle=cleanHandle(b.handle);
 if(!validHandle(handle))throw new AppError(400,'Invalid username');
 const rows=await db()`SELECT id FROM profiles WHERE handle=${handle} AND disabled_at IS NULL LIMIT 1`;
 if(!rows.length)throw new AppError(404,'User not found');
 const id=rows[0].id;
 if(id===me.id)throw new AppError(400,'Cannot block your own account');
 await db()`INSERT INTO blocks(blocker_id,blocked_id) VALUES(${me.id},${id}) ON CONFLICT DO NOTHING`;
 await db()`DELETE FROM follows WHERE (follower_id=${me.id} AND following_id=${id}) OR (follower_id=${id} AND following_id=${me.id})`;
 return json({blocked:true});
}
async function unblockUser(req,handle){
 const me=await viewer(req);
 await db()`DELETE FROM blocks WHERE blocker_id=${me.id} AND blocked_id=(SELECT id FROM profiles WHERE handle=${handle})`;
 return json({blocked:false});
}
async function blocks(req){
 const me=await viewer(req);
 const rows=await db()`SELECT p.handle,p.display_name FROM blocks b JOIN profiles p ON p.id=b.blocked_id
 WHERE b.blocker_id=${me.id} ORDER BY b.created_at DESC`;
 return json({items:rows});
}
async function reports(req){
 const me=await viewer(req);await throttle(req,'report',15,60);
 const b=await parseBody(req);
 const types=['user','video','comment'];
 const reasons=['bullying','sexual_content','violence','hate','spam','privacy','other'];
 if(!types.includes(b.target_type)||!validUUID(String(b.target_id||''))||!reasons.includes(b.reason))
 throw new AppError(400,'Invalid report');
 const detail=String(b.detail||'').trim().slice(0,500);
 const rows=await db()`INSERT INTO reports(reporter_id,target_type,target_id,reason,detail)
 VALUES(${me.id},${b.target_type},${b.target_id},${b.reason},${detail}) RETURNING id,status`;
 return json(rows[0],201);
}
async function moderation(req,videoId){
 const me=await viewer(req);
 if(!['moderator','admin','owner'].includes(me.role))throw new AppError(403,'Moderator access required');
 if(!videoId){
  // Moderators can act on already-published videos. Private video posts
  // do not appear in public discovery; abuse reports remain reviewable.
  const rows=await db()`SELECT v.id,v.caption,v.video_key,v.created_at,p.handle,v.status,v.visibility
  FROM videos v JOIN profiles p ON p.id=v.author_id
  WHERE v.status='approved' AND v.visibility <> 'private' AND p.disabled_at IS NULL
  ORDER BY v.created_at DESC LIMIT 80`;
  const videos=await signVideoRows(rows);
  const reports=await db()`SELECT r.id,r.target_type,r.target_id,r.reason,r.detail,r.created_at,
   COALESCE(p.handle,author.handle,'') AS handle,
   COALESCE(v.caption,'') AS caption
   FROM reports r LEFT JOIN videos v ON r.target_type='video' AND r.target_id=v.id
   LEFT JOIN profiles author ON v.author_id=author.id
   LEFT JOIN profiles p ON r.target_type='user' AND r.target_id=p.id
   WHERE r.status='open' ORDER BY r.created_at ASC LIMIT 120`;
  return json({videos,reports});
 }
 if(!validUUID(videoId))throw new AppError(400,'Invalid video');
 const b=await parseBody(req);
 if(!['approved','rejected'].includes(b.status))throw new AppError(400,'Invalid decision');
 const status=b.status;
 const rows=await db()`UPDATE videos SET status=${status},moderated_at=now(),moderated_by=${me.id}
 WHERE id=${videoId} AND status<>${status} RETURNING id,status,author_id`;
 if(!rows.length)throw new AppError(404,'Video not found or no status change required');
 await db()`INSERT INTO staff_action_events(actor_id,action,subject_type,subject_id,detail)
 VALUES(${me.id},${'video_'+status},'video',${videoId},${JSON.stringify({reason:String(b.reason||'moderation').slice(0,120)})}::jsonb)`;
 if(status==='rejected'){
  await db()`INSERT INTO notifications(recipient_id,actor_id,video_id,kind,body)
  VALUES(${rows[0].author_id},${me.id},${videoId},'content_removed','One of your videos was removed by Kova moderators. Contact support if you think this was a mistake.')`;
 }
 return json({id:rows[0].id,status:rows[0].status});
}
async function resolveReport(req,reportId){
 const me=await viewer(req);
 if(!['moderator','admin','owner'].includes(me.role))throw new AppError(403,'Moderator access required');
 if(!validUUID(reportId))throw new AppError(400,'Invalid report identifier');
 const b=await parseBody(req);
 if(!['reviewed','dismissed'].includes(b.status))throw new AppError(400,'Invalid report resolution');
 const rows=await db()`UPDATE reports SET status=${b.status} WHERE id=${reportId} AND status='open'
 RETURNING id,status`;
 if(!rows.length)throw new AppError(404,'Open report not found');
 await db()`INSERT INTO staff_action_events(actor_id,action,subject_type,subject_id)
 VALUES(${me.id},${'report_'+b.status},'report',${reportId})`;
 return json(rows[0]);
}

async function uploadURL(req){
 const me=await viewer(req);await throttle(req,'upload',15,60);
 const b=await parseBody(req);
 if(!['video/mp4','video/quicktime'].includes(b.mime))throw new AppError(400,'Upload MP4 or MOV video');
 const key='videos/'+me.id+'/'+randomUUID()+(b.mime==='video/mp4'?'.mp4':'.mov');
 const url=await presignS3('PUT',key,600);
 return json({key,url,method:'PUT',mime:b.mime,expires_in_seconds:600,max_bytes:100*1024*1024});
}
async function postVideo(req){
 const me=await viewer(req);
 const b=await parseBody(req);
 const key=String(b.key||'');
 if(!new RegExp('^videos/'+me.id.replace(/[.*+?^@$()|[\]{}]/g,'\\$&')+'/[a-f0-9-]{36}\\.(mp4|mov)$').test(key))
 throw new AppError(400,'Invalid upload identifier');
 const caption=String(b.caption||'').trim();
 if(caption.length>2200)throw new AppError(400,'Caption too long');
 const duration=Number(b.duration_seconds||0);
 if(!Number.isFinite(duration)||duration<1||duration>600)throw new AppError(400,'Video must be 1–600 seconds');
 const visibility=['public','followers','private'].includes(b.visibility)?b.visibility:'private';
 let head;
 try{head=await fetch(await presignS3('HEAD',key,300),{method:'HEAD',signal:AbortSignal.timeout(15000)});}
 catch{throw new AppError(503,'Cannot verify uploaded video');}
 if(!head.ok)throw new AppError(400,'Upload not found');
 const length=Number(head.headers.get('content-length')||0);
 if(length<1||length>100*1024*1024)throw new AppError(400,'Video must be 1–100 MB');
 const contentType=head.headers.get('content-type')||'';
 if(!['video/mp4','video/quicktime'].includes(contentType))throw new AppError(400,'Unsupported video format');
 const title=String(b.music_title||'Original audio').trim().slice(0,140);
 const description=String(b.description||'').trim();
 if(description.length>1200)throw new AppError(400,'Description is too long');
 const allowRemix=b.allow_remix===true && visibility==='public';
 const sourceID=b.source_video_id==null?null:String(b.source_video_id);
 const remixType=b.remix_type==null?null:String(b.remix_type);
 if((sourceID===null)!==(remixType===null))throw new AppError(400,'Remix requires a source video and type');
 if(sourceID!==null){
  if(!validUUID(sourceID)||!['stitch','duet'].includes(remixType))
   throw new AppError(400,'Invalid remix');
  const source=await db()`SELECT 1 FROM videos v JOIN profiles p ON p.id=v.author_id
    WHERE v.id=${sourceID} AND v.allow_remix=true AND v.visibility='public'
    AND v.status='approved' AND p.is_private=false AND p.disabled_at IS NULL
    AND NOT EXISTS(SELECT 1 FROM blocks x WHERE
     (x.blocker_id=${me.id} AND x.blocked_id=p.id) OR
     (x.blocker_id=p.id AND x.blocked_id=${me.id})) LIMIT 1`;
  if(!source.length)throw new AppError(403,'This creator has not allowed remixes');
 }
 const rows=await db()`INSERT INTO videos(author_id,video_key,video_url,caption,description,duration_seconds,music_title,visibility,status,allow_remix,source_video_id,remix_type)
 VALUES(${me.id},${key},'private',${caption},${description},${duration},${title},${visibility},'approved',${allowRemix},${sourceID},${remixType})
 ON CONFLICT(video_key) DO NOTHING RETURNING id,status,created_at`;
 if(!rows.length)throw new AppError(409,'This upload has already been posted.');
 // Resolve up to five genuine account mentions; do not notify blocked accounts.
 const found=[...new Set(((caption+' '+description).match(/@([a-z0-9_]{3,25})/gi)||[])
  .map(v=>v.slice(1).toLowerCase()))].slice(0,5);
 for(const handle of found){
  const targets=await db()`SELECT p.id FROM profiles p
   WHERE p.handle=${handle} AND p.disabled_at IS NULL AND p.id<>${me.id}
   AND NOT EXISTS (SELECT 1 FROM blocks b WHERE
    (b.blocker_id=p.id AND b.blocked_id=${me.id})
    OR (b.blocker_id=${me.id} AND b.blocked_id=p.id)) LIMIT 1`;
  if(targets.length){
   await db()`INSERT INTO video_mentions(video_id,mentioned_id)
    VALUES(${rows[0].id},${targets[0].id}) ON CONFLICT DO NOTHING`;
   await db()`INSERT INTO notifications(recipient_id,actor_id,video_id,kind,body)
    VALUES(${targets[0].id},${me.id},${rows[0].id},'mention','@' || ${me.handle} || ' mentioned you in a video')`;
  }
 }
 return json({...rows[0],message:'Video published. You can remove it anytime; staff can take down content that violates community rules.'},201);
}
async function remixPreference(req,vid){
 const me=await viewer(req);
 if(!validUUID(vid))throw new AppError(400,'Invalid video');
 const b=await parseBody(req);
 if(typeof b.allow_remix!=='boolean')throw new AppError(400,'Invalid remix setting');
 const updated=await db()`UPDATE videos SET allow_remix=${b.allow_remix}
 WHERE id=${vid} AND author_id=${me.id} AND visibility='public'
 AND status='approved' RETURNING id,allow_remix`;
 if(!updated.length)throw new AppError(404,'Public video not found');
 return json(updated[0]);
}
async function deleteVideo(req,vid){
 const me=await viewer(req);
 const rows=await db()`DELETE FROM videos WHERE id=${vid} AND author_id=${me.id} RETURNING id`;
 if(!rows.length)throw new AppError(404,'Video not found');
 return json({deleted:true});
}
async function recentAccounts(req){
 const me=await viewer(req);
 const rows=await db()`SELECT id,created_at,expires_at FROM sessions WHERE user_id=${me.id} ORDER BY created_at DESC LIMIT 20`;
 return json({items:rows.map(row=>({...row,is_current:row.id===me.session_id}))});
}
async function revokeOthers(req){
 const me=await viewer(req);
 const rows=await db()`DELETE FROM sessions WHERE user_id=${me.id} AND id<>${me.session_id} RETURNING id`;
 return json({revoked:rows.length});
}
async function staffDashboard(req){
 const me=await viewer(req);
 if(!['moderator','admin','owner'].includes(me.role))throw new AppError(403,'Staff access required');
 const rows=await db()`SELECT
 (SELECT count(*)::int FROM reports WHERE status='open') AS open_reports,
 (SELECT count(*)::int FROM videos WHERE status='pending') AS pending_videos,
 (SELECT count(*)::int FROM videos WHERE status='approved') AS live_videos,
 (SELECT count(*)::int FROM profiles WHERE disabled_at IS NULL) AS accounts,
 (SELECT count(*)::int FROM profiles WHERE is_verified=true) AS verified_accounts`;
 return json({...rows[0],role:me.role});
}
async function developerOverview(req){
 const me=await viewer(req);
 if(!['developer','owner'].includes(me.role))throw new AppError(403,'Developer access required');
 const rows=await db()`SELECT
 (SELECT count(*)::int FROM videos WHERE author_id=${me.id} AND status='approved') AS published_videos,
 (SELECT count(*)::int FROM videos WHERE author_id=${me.id} AND status='pending') AS pending_videos,
 (SELECT count(*)::int FROM follows WHERE following_id=${me.id} AND status='accepted') AS followers,
 (SELECT count(*)::int FROM likes l JOIN videos v ON l.video_id=v.id WHERE v.author_id=${me.id}) AS total_likes`;
 return json({...rows[0],role:me.role,features:['creator_analytics','developer_badge','early_feedback']});
}
async function staffUsers(req){
 const me=await viewer(req);
 if(!['owner','admin'].includes(me.role))throw new AppError(403,'Administrator access required');
 const q=(new URL(req.url).searchParams.get('q')||'').trim().slice(0,35);
 if(q.length<2)return json({items:[]});
 const term='%'+q+'%';
 const rows=await db()`SELECT p.id,p.handle,p.display_name,p.is_verified,p.age_restricted,COALESCE(r.role,p.role) AS role
 FROM profiles p LEFT JOIN profile_staff_roles r ON r.profile_id=p.id
 WHERE (p.handle ILIKE ${term} OR p.display_name ILIKE ${term}) AND p.disabled_at IS NULL
 ORDER BY p.handle LIMIT 30`;
 return json({items:rows});
}
async function staffChange(req,handle,action){
 const me=await viewer(req);
 if(action==='verification'&&!['admin','owner'].includes(me.role))throw new AppError(403,'Verification permission required');
 if(action==='role'&&me.role!=='owner')throw new AppError(403,'Only owners can assign staff roles');
 const targets=await db()`SELECT p.id,p.is_verified,COALESCE(r.role,p.role) AS role
 FROM profiles p LEFT JOIN profile_staff_roles r ON r.profile_id=p.id
 WHERE p.handle=${handle} AND p.disabled_at IS NULL LIMIT 1`;
 if(!targets.length)throw new AppError(404,'Account not found');
 const target=targets[0];
 if(target.role==='owner')throw new AppError(403,'Owner accounts cannot be modified here');
 if(me.id===target.id)throw new AppError(403,'You cannot change your own verification or role');
 const b=await parseBody(req);
 if(action==='verification'){
  if(typeof b.is_verified!=='boolean')throw new AppError(400,'Verification must be true or false');
  const updated=await db()`UPDATE profiles SET is_verified=${b.is_verified},updated_at=now()
  WHERE id=${target.id} RETURNING handle,is_verified`;
  await db()`INSERT INTO profile_staff_audit(actor_id,target_id,action,old_value,new_value)
  VALUES(${me.id},${target.id},'verification',${String(target.is_verified)},${String(b.is_verified)})`;
  return json(updated[0]);
 }
 const permitted=['member','developer','moderator','admin'];
 if(!permitted.includes(b.role))throw new AppError(400,'Invalid staff role');
 const role=b.role;
 if(role==='member'){
  await db()`DELETE FROM profile_staff_roles WHERE profile_id=${target.id}`;
 }else{
  await db()`INSERT INTO profile_staff_roles(profile_id,role,granted_by)
  VALUES(${target.id},${role},${me.id})
  ON CONFLICT (profile_id) DO UPDATE SET role=excluded.role,granted_by=excluded.granted_by,granted_at=now()`;
 }
 await db()`INSERT INTO profile_staff_audit(actor_id,target_id,action,old_value,new_value)
 VALUES(${me.id},${target.id},'role',${target.role},${role})`;
 return json({handle,role});
}


const allStaff=['owner','admin','moderator'];
const privateContactKey=()=>{
 const raw=process.env.KOVA_CONTACT_ENCRYPTION_KEY;
 if(!raw)throw new AppError(503,'Private contact storage is unavailable');
 const b=Buffer.from(raw,'base64');
 if(b.length!==32)throw new AppError(503,'Private contact storage is unavailable');
 return b;
};
function encryptContact(value){
 if(!value)return null;
 const iv=randomBytes(12),cipher=createCipheriv('aes-256-gcm',privateContactKey(),iv);
 const body=Buffer.concat([cipher.update(value,'utf8'),cipher.final()]);
 return Buffer.concat([iv,cipher.getAuthTag(),body]).toString('base64');
}
function decryptContact(value){
 if(!value)return '';
 const bytes=Buffer.from(value,'base64');
 const decipher=createDecipheriv('aes-256-gcm',privateContactKey(),bytes.subarray(0,12));
 decipher.setAuthTag(bytes.subarray(12,28));
 return Buffer.concat([decipher.update(bytes.subarray(28)),decipher.final()]).toString('utf8');
}
async function contacts(req){
 const me=await viewer(req);
 if(req.method==='GET'){
  const result=await db()`SELECT email_encrypted,phone_encrypted,email_verified,phone_verified
  FROM account_contacts WHERE profile_id=${me.id}`;
  const row=result[0]||{};
  return json({email:decryptContact(row.email_encrypted),phone:decryptContact(row.phone_encrypted),
   email_verified:false,phone_verified:false});
 }
 const body=await parseBody(req);
 const email=String(body.email||'').trim().toLowerCase(),phone=String(body.phone||'').trim();
 if(email.length>254 || (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)))throw new AppError(400,'Enter a valid optional email address');
 if(phone && !/^\+[1-9]\d{7,14}$/.test(phone))throw new AppError(400,'Phone number must use international format, e.g. +15551234567');
 await db()`INSERT INTO account_contacts(profile_id,email_encrypted,phone_encrypted,email_verified,phone_verified)
 VALUES(${me.id},${encryptContact(email)},${encryptContact(phone)},false,false)
 ON CONFLICT(profile_id) DO UPDATE SET email_encrypted=excluded.email_encrypted,
 phone_encrypted=excluded.phone_encrypted,email_verified=false,phone_verified=false,updated_at=now()`;
 return json({email,phone,email_verified:false,phone_verified:false});
}
async function uploadProfileMedia(req){
 const me=await viewer(req);
 await throttle(req,'profile_media',12,60);
 const body=await parseBody(req),kind=String(body.kind||''),mime=String(body.mime||'');
 if(!['avatar','banner'].includes(kind))throw new AppError(400,'Invalid profile media');
 if(!['image/jpeg','image/png','image/webp','image/gif'].includes(mime))throw new AppError(400,'Use JPG, PNG, WebP or GIF images');
 if(kind==='avatar'&&mime==='image/gif')throw new AppError(400,'Animated avatars are not supported');
 if(mime==='image/gif'){
  const count=await db()`SELECT count(*)::int AS n FROM follows WHERE following_id=${me.id} AND status='accepted'`;
  if(Number(count[0]?.n||0)<=500)throw new AppError(403,'Animated banners unlock after 500 real followers');
 }
 const limit=mime==='image/gif'?15000000:6000000;
 const ext={'image/jpeg':'jpg','image/png':'png','image/webp':'webp','image/gif':'gif'}[mime];
 const key='profile-media/'+me.id+'/'+randomUUID()+'.'+ext;
 return json({key,url:await presignS3('PUT',key,600),method:'PUT',mime,max_bytes:limit});
}
// Verify uploaded file signatures, not just user-provided MIME metadata.
// This is a format check, not a guarantee that user-generated content is safe.
async function checkImageSignature(key,mime){
 let response;
 try{
  response=await fetch(await presignS3('GET',key,180),{
   headers:{Range:'bytes=0-31'},signal:AbortSignal.timeout(12000)});
 }catch{throw new AppError(503,'Could not validate the uploaded image. Please retry.');}
 if(!response.ok)throw new AppError(400,'Uploaded image could not be read');
 const reader=response.body?.getReader();
 if(!reader)throw new AppError(503,'Image validation is temporarily unavailable');
 const {value}=await reader.read();
 await reader.cancel().catch(()=>{});
 const bytes=value||new Uint8Array();
 const ascii=(lo,hi)=>String.fromCharCode(...bytes.slice(lo,hi));
 let okay=false;
 if(mime==='image/jpeg')okay=bytes.length>=3&&bytes[0]===0xff&&bytes[1]===0xd8&&bytes[2]===0xff;
 if(mime==='image/png')okay=bytes.length>=8&&
  [137,80,78,71,13,10,26,10].every((v,i)=>bytes[i]===v);
 if(mime==='image/gif')okay=bytes.length>=6&&
  ['GIF87a','GIF89a'].includes(ascii(0,6));
 if(mime==='image/webp')okay=bytes.length>=12&&
  ascii(0,4)==='RIFF'&&ascii(8,12)==='WEBP';
 if(!okay)throw new AppError(400,'The uploaded image format does not match its file type');
}
async function completeProfileMedia(req){
 const me=await viewer(req);
 const b=await parseBody(req),kind=String(b.kind||''),key=String(b.key||'');
 if(!['avatar','banner'].includes(kind)||!key.startsWith('profile-media/'+me.id+'/')||
    !/^profile-media\/[0-9a-f-]{36}\/[0-9a-f-]{36}\.(jpg|png|webp|gif)$/.test(key))
    throw new AppError(400,'Invalid upload identifier');
 const ext=key.split('.').pop();
 const mime={'jpg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif'}[ext];
 if(ext==='gif'&&kind!=='banner')throw new AppError(400,'Only banners can be animated');
 if(ext==='gif'){
  const count=await db()`SELECT count(*)::int AS n FROM follows WHERE following_id=${me.id} AND status='accepted'`;
  if(Number(count[0]?.n||0)<=500)throw new AppError(403,'Animated banners need more than 500 real followers');
 }
 const response=await fetch(await presignS3('HEAD',key,200),{method:'HEAD',signal:AbortSignal.timeout(14000)}).catch(()=>null);
 if(!response?.ok)throw new AppError(400,'The image upload was not found');
 const bytes=Number(response.headers.get('content-length')||0);
 if(bytes<1||bytes>(ext==='gif'?15000000:6000000))throw new AppError(400,'Image is too large');
 const contentType=String(response.headers.get('content-type')||'').split(';')[0].toLowerCase();
 if(contentType!==mime)throw new AppError(400,'Unexpected image format');
 await checkImageSignature(key,mime);
 const rows=await db()`INSERT INTO profile_media(owner_id,kind,object_key,mime,byte_length,status)
 VALUES(${me.id},${kind},${key},${mime},${bytes},'approved')
 ON CONFLICT(object_key) DO NOTHING RETURNING id,status`;
 if(!rows.length)throw new AppError(409,'This image was already uploaded.');
 // Publish immediately after the stored object's size and media type are verified.
 // Reports and the staff media panel still support removal and auditing.
 if(kind==='avatar'){
  await db()`UPDATE profiles SET avatar_key=${key},avatar_url=NULL,updated_at=now() WHERE id=${me.id}`;
 }else{
  await db()`UPDATE profiles SET banner_key=${key},banner_animated=${mime==='image/gif'},updated_at=now() WHERE id=${me.id}`;
 }
 return json({...rows[0],message:'Your '+(kind==='avatar'?'profile photo':'banner')+' is live.'},201);
}
async function myMedia(req){
 const me=await viewer(req);
 const rows=await db()`SELECT id,kind,mime,status,created_at FROM profile_media WHERE owner_id=${me.id} ORDER BY created_at DESC LIMIT 40`;
 return json({items:rows});
}
async function staffMedia(req,id){
 const me=await viewer(req);
 if(!allStaff.includes(me.role))throw new AppError(403,'Staff access required');
 if(!id){
  const rows=await db()`SELECT m.id,m.kind,m.mime,m.object_key,m.status,m.created_at,p.handle
  FROM profile_media m JOIN profiles p ON p.id=m.owner_id
  WHERE m.status='approved' AND (
   (m.kind='avatar' AND p.avatar_key=m.object_key)
    OR (m.kind='banner' AND p.banner_key=m.object_key))
  ORDER BY m.created_at DESC LIMIT 100`;
  return json({items:await Promise.all(rows.map(async ({object_key,...row})=>
   ({...row,preview_url:await presignS3('GET',object_key,300)})))});
 }
 if(!validUUID(id))throw new AppError(400,'Invalid media identifier');
 const b=await parseBody(req);
 if(b.status!=='rejected')throw new AppError(400,'Only takedown of live media is supported');
 const rows=await db()`UPDATE profile_media SET status='rejected',reviewed_by=${me.id},reviewed_at=now()
 WHERE id=${id} AND status='approved' RETURNING id,owner_id,kind,mime,object_key,status`;
 if(!rows.length)throw new AppError(404,'Active profile media not found');
 const row=rows[0];
 if(row.kind==='avatar'){
  await db()`UPDATE profiles SET avatar_key=NULL,updated_at=now()
    WHERE id=${row.owner_id} AND avatar_key=${row.object_key}`;
 }else{
  await db()`UPDATE profiles SET banner_key=NULL,banner_animated=false,updated_at=now()
    WHERE id=${row.owner_id} AND banner_key=${row.object_key}`;
 }
 await db()`INSERT INTO staff_action_events(actor_id,action,subject_type,subject_id,detail)
 VALUES(${me.id},'media_removed','profile_media',${id},
 ${JSON.stringify({kind:row.kind})}::jsonb)`;
 await db()`INSERT INTO notifications(recipient_id,actor_id,kind,body)
 VALUES(${row.owner_id},${me.id},'profile_media_removed',
 'A profile image was removed by Kova moderators. Please contact support if this was a mistake.')`;
 return json({id,status:'rejected'});
}
// Support v2: stored threads, unread state, priority, history, and auditable staff actions.
async function ticketEvent(ticketId,actorId,eventType,details={}){
 await db()`INSERT INTO support_ticket_events(ticket_id,actor_id,event_type,details)
 VALUES(${ticketId},${actorId},${eventType},${JSON.stringify(details)}::jsonb)`;
}
async function tickets(req,tid){
 const me=await viewer(req),staff=allStaff.includes(me.role);
 if(!tid){
  if(req.method==='GET'){
   const rows=await db()`SELECT id,subject,category,status,priority,created_at,updated_at,
    (last_staff_reply_at IS NOT NULL AND (last_user_read_at IS NULL OR last_staff_reply_at>last_user_read_at)) AS unread
    FROM support_tickets WHERE author_id=${me.id}
    ORDER BY CASE WHEN status IN ('open','in_progress') THEN 0 ELSE 1 END,updated_at DESC LIMIT 100`;
   return json({items:rows,open:rows.filter(r=>r.status==='open'||r.status==='in_progress').length,
    unread:rows.filter(r=>r.unread).length});
  }
  await throttle(req,'support_create',5,60);
  const b=await parseBody(req);
  const subject=String(b.subject||'').trim(),body=String(b.message||'').trim(),category=String(b.category||'other');
  if(subject.length<5||subject.length>100||body.length<10||body.length>2000)throw new AppError(400,'Use a subject of 5–100 characters and a message of 10–2000 characters');
  if(!['account','technical','safety','other'].includes(category))throw new AppError(400,'Invalid support category');
  const priority=category==='safety'?'high':'normal';
  const rows=await db()`WITH created AS (
    INSERT INTO support_tickets(author_id,subject,category,priority,last_user_reply_at)
    VALUES(${me.id},${subject},${category},${priority},now()) RETURNING id
   )
   INSERT INTO support_ticket_messages(ticket_id,author_id,body,is_staff)
   SELECT id,${me.id},${body},false FROM created RETURNING ticket_id AS id`;
  // Ticket creation and its initial message are atomic.
  await ticketEvent(rows[0].id,me.id,'created',{category});
  return json({id:rows[0].id,status:'open'},201);
 }
 if(!validUUID(tid))throw new AppError(400,'Invalid ticket');
 const allowed=await db()`SELECT t.id,t.author_id,t.subject,t.category,t.status,t.priority,t.assigned_to,t.created_at,t.updated_at,p.handle,
   (t.last_staff_reply_at IS NOT NULL AND (t.last_user_read_at IS NULL OR t.last_staff_reply_at>t.last_user_read_at)) AS unread
   FROM support_tickets t JOIN profiles p ON p.id=t.author_id
   WHERE t.id=${tid} AND (t.author_id=${me.id} OR ${staff}) LIMIT 1`;
 if(!allowed.length)throw new AppError(404,'Support ticket not found');
 if(req.method==='GET'){
  const messages=await db()`SELECT m.id,m.body,m.is_staff,m.created_at,p.display_name
   FROM support_ticket_messages m JOIN profiles p ON p.id=m.author_id
   WHERE m.ticket_id=${tid} ORDER BY m.created_at LIMIT 250`;
  const events=await db()`SELECT e.id,e.event_type,e.details,e.created_at FROM support_ticket_events e
   WHERE e.ticket_id=${tid} ORDER BY e.created_at DESC LIMIT 40`;
  if(allowed[0].author_id===me.id){
   await db()`UPDATE support_tickets SET last_user_read_at=now() WHERE id=${tid}`;
  }else if(staff){
   await db()`UPDATE support_tickets SET last_staff_read_at=now() WHERE id=${tid}`;
  }
  return json({ticket:{...allowed[0],unread:false},messages,
   events:events.map(e=>({...e,id:Number(e.id)}))});
 }
 if(allowed[0].status==='closed')throw new AppError(403,'Ticket is closed. Start a new ticket for more help.');
 await throttle(req,'support_reply',25,60);
 const b=await parseBody(req),body=String(b.message||'').trim();
 if(body.length<1||body.length>2000)throw new AppError(400,'Reply must be 1–2000 characters');
 // Prevent staff-role users creating staff-labeled replies in their own user ticket.
 const staffResponse=staff && allowed[0].author_id!==me.id;
 await db()`INSERT INTO support_ticket_messages(ticket_id,author_id,body,is_staff)
 VALUES(${tid},${me.id},${body},${staffResponse})`;
 const reopened=!staffResponse && allowed[0].status==='resolved';
 await db()`UPDATE support_tickets SET
 status=CASE WHEN ${staffResponse} THEN 'in_progress'
   WHEN status='resolved' THEN 'open' ELSE status END,
 last_staff_reply_at=CASE WHEN ${staffResponse} THEN now() ELSE last_staff_reply_at END,
 last_user_reply_at=CASE WHEN ${staffResponse} THEN last_user_reply_at ELSE now() END,
 updated_at=now() WHERE id=${tid}`;
 if(staffResponse){
  await db()`INSERT INTO notifications(recipient_id,actor_id,kind,body,ticket_id)
  VALUES(${allowed[0].author_id},${me.id},'support_reply','You have a new reply on your support ticket.',${tid})`;
 }
 if(reopened)await ticketEvent(tid,me.id,'reopened',{});
 return json({ok:true},201);
}
async function staffTickets(req,id,operation='status'){
 const me=await viewer(req);
 if(!allStaff.includes(me.role))throw new AppError(403,'Staff access required');
 if(!id){
  const url=new URL(req.url);
  const filter=String(url.searchParams.get('status')||'all');
  const category=String(url.searchParams.get('category')||'all');
  if(!['all','open','in_progress','resolved','closed'].includes(filter))throw new AppError(400,'Invalid status filter');
  if(!['all','account','technical','safety','other'].includes(category))throw new AppError(400,'Invalid category filter');
  const queryTerm=String(url.searchParams.get('q')||'').trim().slice(0,80);
  const term='%'+queryTerm+'%';
  const rows=await db()`SELECT t.id,t.subject,t.category,t.status,t.priority,t.created_at,t.updated_at,p.handle,
   (t.last_user_reply_at IS NOT NULL AND (t.last_staff_read_at IS NULL OR t.last_user_reply_at>t.last_staff_read_at)) AS unread
   FROM support_tickets t JOIN profiles p ON p.id=t.author_id
   WHERE (${filter}='all' OR t.status=${filter})
     AND (${category}='all' OR t.category=${category})
     AND (${queryTerm}='' OR t.subject ILIKE ${term} OR p.handle ILIKE ${term})
   ORDER BY CASE t.status WHEN 'open' THEN 0 WHEN 'in_progress' THEN 1 ELSE 2 END,
    CASE t.priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 ELSE 2 END,
    t.updated_at DESC LIMIT 150`;
  return json({items:rows,unread:rows.filter(r=>r.unread).length});
 }
 if(!validUUID(id))throw new AppError(400,'Invalid ticket identifier');
 const b=await parseBody(req);
 if(operation==='priority'){
  if(!['normal','high','urgent'].includes(b.priority))throw new AppError(400,'Invalid support priority');
  const found=await db()`UPDATE support_tickets SET priority=${b.priority},updated_at=now()
   WHERE id=${id} AND priority<>${b.priority} RETURNING id,priority`;
  if(!found.length)throw new AppError(404,'Ticket missing or priority unchanged');
  await ticketEvent(id,me.id,'priority_changed',{priority:b.priority});
  await db()`INSERT INTO staff_action_events(actor_id,action,subject_type,subject_id)
   VALUES(${me.id},'ticket_priority','support_ticket',${id})`;
  return json(found[0]);
 }
 if(!['open','in_progress','resolved','closed'].includes(b.status))throw new AppError(400,'Invalid ticket status');
 const rows=await db()`UPDATE support_tickets SET status=${b.status},updated_at=now(),assigned_to=${me.id}
 WHERE id=${id} RETURNING id,status,author_id`;
 if(!rows.length)throw new AppError(404,'Ticket not found');
 await ticketEvent(id,me.id,'status_changed',{status:b.status});
 await db()`INSERT INTO staff_action_events(actor_id,action,subject_type,subject_id)
 VALUES(${me.id},'ticket_'+b.status,'support_ticket',${id})`;
 if(b.status==='resolved'||b.status==='closed'){
  await db()`INSERT INTO notifications(recipient_id,actor_id,kind,body,ticket_id)
  VALUES(${rows[0].author_id},${me.id},'support_status','A support ticket has been ' || ${b.status} || '.',${id})`;
 }
 return json({id:rows[0].id,status:rows[0].status});
}

async function ownerOverview(req){
 const me=await viewer(req);
 if(me.role!=='owner')throw new AppError(403,'Owner access required');
 const totals=await db()`SELECT
 (SELECT count(*)::int FROM profiles WHERE disabled_at IS NULL) AS accounts,
 (SELECT count(*)::int FROM profiles WHERE created_at>=now()-interval '7 days') AS new_accounts_week,
 (SELECT count(*)::int FROM videos WHERE status='approved') AS approved_videos,
 (SELECT count(*)::int FROM videos WHERE status='pending') AS pending_videos,
 (SELECT count(*)::int FROM videos WHERE status='rejected') AS removed_videos,
 (SELECT count(*)::int FROM support_tickets WHERE status IN ('open','in_progress')) AS open_support,
 (SELECT count(*)::int FROM profile_media WHERE status='pending') AS pending_media,
 (SELECT count(*)::int FROM profile_media WHERE status='approved') AS live_profile_media,
 (SELECT count(*)::int FROM reports WHERE status='open') AS open_reports,
 (SELECT count(*)::int FROM follows WHERE status='accepted') AS real_follow_relationships`;
 const events=await db()`SELECT e.id,e.action,e.subject_type,e.created_at,p.handle AS actor
 FROM staff_action_events e JOIN profiles p ON p.id=e.actor_id
 ORDER BY e.created_at DESC LIMIT 25`;
 const privilegeEvents=await db()`SELECT a.id,a.action,a.old_value,a.new_value,a.created_at,p.handle AS actor
 FROM profile_staff_audit a JOIN profiles p ON p.id=a.actor_id
 ORDER BY a.created_at DESC LIMIT 25`;
 return json({...totals[0],events:events.map(e=>({...e,id:Number(e.id)})),privilege_events:privilegeEvents.map(e=>({...e,id:Number(e.id)}))});
}

async function handle(req){
 const url=new URL(req.url);
 const pathname=url.pathname.replace(/\/+$/,'')||'/';
 const method=req.method.toUpperCase();
 if(method==='GET'&&(pathname==='/'||pathname==='/api/health'))
 return json({service:'kova-api',status:'ok',version:'0.9.0',account_provider:'Neon Managed Better Auth',storage_ready:Boolean((process.env.AWS_ACCESS_KEY_ID||process.env.S3_ACCESS_KEY_ID)&&(process.env.AWS_SECRET_ACCESS_KEY||process.env.S3_SECRET_ACCESS_KEY)&&(process.env.AWS_ENDPOINT_URL_S3||process.env.S3_ENDPOINT))});
 if(method==='GET'&&pathname==='/api/health/db'){await db()`SELECT 1`;return json({status:'connected'});}
 if(method==='GET'&&pathname==='/api/auth/username-available'){
  const h=cleanHandle(url.searchParams.get('handle'));if(!validHandle(h))return json({available:false,reason:'invalid'});
  const rows=await db()`SELECT 1 FROM profiles WHERE handle=${h} LIMIT 1`;
  return json({available:rows.length===0});
 }
 if(method==='POST'&&pathname==='/api/auth/register')return register(req);
 if(method==='POST'&&pathname==='/api/auth/login')return login(req);
 if(method==='GET'&&pathname==='/api/auth/me')return json(await mediaProfile(await viewer(req)));
 if(method==='POST'&&pathname==='/api/auth/logout')return logout(req);
 if(method==='GET'&&pathname==='/api/auth/sessions')return recentAccounts(req);
 if(method==='POST'&&pathname==='/api/auth/sessions/revoke-others')return revokeOthers(req);
 if((method==='GET'||method==='PATCH')&&pathname==='/api/account/contact')return contacts(req);
 if(method==='POST'&&pathname==='/api/profile/media/upload-url')return uploadProfileMedia(req);
 if(method==='POST'&&pathname==='/api/profile/media/complete')return completeProfileMedia(req);
 if(method==='GET'&&pathname==='/api/profile/media/mine')return myMedia(req);
 if(method==='GET'&&pathname==='/api/staff/media')return staffMedia(req);
 const mediaRoute=pathname.match(/^\/api\/staff\/media\/([0-9a-f-]{36})$/);
 if(method==='PATCH'&&mediaRoute)return staffMedia(req,mediaRoute[1]);
 if((method==='GET'||method==='POST')&&pathname==='/api/support/tickets')return tickets(req);
 const ticketRoute=pathname.match(/^\/api\/support\/tickets\/([0-9a-f-]{36})$/);
 if(ticketRoute&&(method==='GET'||method==='POST'))return tickets(req,ticketRoute[1]);
 if(method==='GET'&&pathname==='/api/staff/tickets')return staffTickets(req);
 const staffTicket=pathname.match(/^\/api\/staff\/tickets\/([0-9a-f-]{36})$/);
 if(method==='PATCH'&&staffTicket)return staffTickets(req,staffTicket[1]);
 const staffPriority=pathname.match(/^\/api\/staff\/tickets\/([0-9a-f-]{36})\/priority$/);
 if(method==='PATCH'&&staffPriority)return staffTickets(req,staffPriority[1],'priority');
 if(method==='GET'&&pathname==='/api/owner/overview')return ownerOverview(req);
 if(method==='GET'&&pathname==='/api/staff/dashboard')return staffDashboard(req);
 if((method==='GET'||method==='PATCH')&&pathname==='/api/account/messages')return messageOptions(req);
 if(method==='GET'&&pathname==='/api/messages')return dmInbox(req);
 const dmPath=pathname.match(/^\/api\/messages\/([a-z0-9_]{3,25})$/);
 if(dmPath&&(method==='GET'||method==='POST'))return dmConversation(req,dmPath[1]);
 const dmReportPath=pathname.match(/^\/api\/messages\/report\/([0-9a-f-]{36})$/);
 if(dmReportPath&&method==='POST')return dmReport(req,dmReportPath[1]);
 const safetyPath=pathname.match(/^\/api\/staff\/users\/([a-z0-9_]{3,25})\/safety$/);
 if(safetyPath&&method==='PATCH')return ageSafety(req,safetyPath[1]);
 if(method==='GET'&&pathname==='/api/staff/users')return staffUsers(req);
 if(method==='GET'&&pathname==='/api/developer/overview')return developerOverview(req);
 const verifiedPath=pathname.match(/^\/api\/staff\/users\/([a-z0-9_]{3,25})\/verification$/);
 if(method==='PATCH'&&verifiedPath)return staffChange(req,verifiedPath[1],'verification');
 const rolePath=pathname.match(/^\/api\/staff\/users\/([a-z0-9_]{3,25})\/role$/);
 if(method==='PATCH'&&rolePath)return staffChange(req,rolePath[1],'role');
 if(method==='GET'&&pathname==='/api/discover/trending')return trending(req);
 if((method==='GET'||method==='DELETE')&&pathname==='/api/feed/preferences')return feedPreferences(req);
 if(method==='GET'&&pathname==='/api/feed')return feed(req);
 if(method==='GET'&&pathname==='/api/search')return search(req);
 if(method==='GET'&&pathname==='/api/users/me/stats')return accountStats(req);
 if((method==='GET'||method==='PATCH')&&pathname==='/api/users/me')return userMe(req);
 if(method==='POST'&&pathname==='/api/users/me/block')return blockUser(req);
 if(method==='GET'&&pathname==='/api/users/me/blocks')return blocks(req);
 if(method==='DELETE'&&pathname.startsWith('/api/users/me/blocks/'))return unblockUser(req,cleanHandle(pathname.split('/').pop()));
 if(method==='GET'&&pathname==='/api/videos/mine')return ownVideos(req);
 if(method==='GET'&&pathname==='/api/bookmarks')return saved(req);
 if(method==='GET'&&pathname==='/api/notifications')return notifications(req);
 if(method==='POST'&&pathname==='/api/notifications/read-all')return markNotifications(req);
 if(method==='POST'&&pathname==='/api/videos/upload-url')return uploadURL(req);
 if(method==='POST'&&pathname==='/api/videos')return postVideo(req);
 if(method==='POST'&&pathname==='/api/reports')return reports(req);
 if(method==='GET'&&pathname==='/api/follows/requests')return followRequests(req);
 const fl=pathname.match(/^\/api\/follows\/requests\/([a-f0-9-]+)(?:\/(reject))?$/);
 if(fl&&(method==='POST'||method==='DELETE'))return followRequests(req,fl[1],fl[2]|| (method==='DELETE'?'reject':null));
 if(method==='GET'&&pathname==='/api/moderation/queue')return moderation(req);
 const mod=pathname.match(/^\/api\/moderation\/videos\/([a-f0-9-]+)$/);
 if(mod&&method==='PATCH')return moderation(req,mod[1]);
 const moderationReport=pathname.match(/^\/api\/moderation\/reports\/([a-f0-9-]+)$/);
 if(moderationReport&&method==='PATCH')return resolveReport(req,moderationReport[1]);
 const cm=pathname.match(/^\/api\/videos\/([a-f0-9-]+)\/comments(?:\/([a-f0-9-]+))?$/);
 if(cm&&(method==='GET'||method==='POST'||method==='DELETE'))return comments(req,cm[1],cm[2]);
 const pref=pathname.match(/^\/api\/videos\/([a-f0-9-]+)\/not-interested$/);
 if(pref&&(method==='POST'||method==='DELETE'))return videoPreference(req,pref[1]);
 const act=pathname.match(/^\/api\/videos\/([a-f0-9-]+)\/(like|bookmark|repost)$/);
 if(act&&(method==='POST'||method==='DELETE'))return videoAction(req,act[1],act[2]);
 const remixAllowed=pathname.match(/^\/api\/videos\/([a-f0-9-]+)\/remix-permission$/);
 if(remixAllowed&&method==='PATCH')return remixPreference(req,remixAllowed[1]);
 const single=pathname.match(/^\/api\/videos\/([a-f0-9-]+)$/);
 if(single&&method==='DELETE')return deleteVideo(req,single[1]);
 if(single&&method==='GET')return singleVideo(req,single[1]);
 const f=pathname.match(/^\/api\/users\/([a-z0-9_]{3,25})\/follow$/);
 if(f&&(method==='POST'||method==='DELETE'))return follow(req,f[1]);
 const profilePath=pathname.match(/^\/api\/users\/([a-z0-9_]{3,25})$/);
 if(profilePath&&method==='GET')return profile(req,profilePath[1]);
 return problem('Kova API route not found: '+method+' '+pathname,404);
}
export default {async fetch(req){try{return await handle(req);}catch(err){return safeError(err);}}};
