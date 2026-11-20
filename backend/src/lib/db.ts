import { neon } from '@neondatabase/serverless';

// The app uses Neon's default object-row template-tag mode; neither fullResults
// nor arrayMode is enabled. Keep this explicit to prevent an incorrectly
// inferred union with the full-results and array-results modes.
type DatabaseRow = Record<string, any>;
type DatabaseQuery = (strings: TemplateStringsArray, ...parameters: unknown[]) => Promise<DatabaseRow[]>;
let client: DatabaseQuery | undefined;

export function db(): DatabaseQuery {
  if (!client) {
    const url = process.env.DATABASE_URL;
    if (!url) throw new Error('DATABASE_URL is not configured on the Kova API');
    client = neon(url) as unknown as DatabaseQuery;
  }
  return client;
}
