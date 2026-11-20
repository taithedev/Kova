import { z } from 'zod';
import { ApiError } from './errors';
export async function body<T extends z.ZodTypeAny>(req: Request, schema: T): Promise<z.output<T>> {
  let raw: unknown;
  try { raw = await req.json(); } catch { throw new ApiError(400, 'Invalid JSON body'); }
  const result = schema.safeParse(raw);
  if (!result.success) throw new ApiError(400, result.error.issues[0]?.message || 'Invalid input');
  return result.data;
}
export const handle = z.string().trim().toLowerCase().regex(/^[a-z0-9_]{3,25}$/, 'Username: 3–25 letters, numbers or underscores');
export const caption = z.string().trim().max(2200);
export const id = z.string().uuid();
