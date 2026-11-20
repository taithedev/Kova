import { db } from './db';
import { ApiError } from './errors';
import { createHash } from 'node:crypto';
export async function rateLimit(req:Request,action:string,limit:number,windowMinutes:number) {
 // Not a substitute for edge/WAF throttling: request IP headers are only trusted behind a controlled proxy.
 const address=req.headers.get('x-real-ip')||'unknown';
 const identifier=createHash('sha256').update(`${action}:${address}`).digest('hex');
 const results=await db()`SELECT count(*)::int AS n FROM rate_events WHERE key=${identifier} AND at > NOW()-(${windowMinutes}::int * INTERVAL '1 minute')`;
 if(Number(results[0]?.n||0)>=limit) throw new ApiError(429,'Too many requests. Try again later.');
 await db()`INSERT INTO rate_events(key) VALUES(${identifier})`;
}
