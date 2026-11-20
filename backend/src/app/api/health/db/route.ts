import { db } from '@/lib/db';
import { guarded,json } from '@/lib/errors';
// Keep details private. This endpoint reports connectivity only.
export async function GET(){return guarded(async()=>{await db()`SELECT 1 AS ok`;return json({status:'connected'});});}
