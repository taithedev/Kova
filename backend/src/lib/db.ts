import { neon } from '@neondatabase/serverless';
let client: ReturnType<typeof neon> | undefined;
export function db(): ReturnType<typeof neon> {
  if (!client) {
    const url = process.env.DATABASE_URL;
    if (!url) throw new Error('DATABASE_URL is not configured on the API server');
    client = neon(url);
  }
  return client;
}
