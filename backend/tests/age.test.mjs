import test from 'node:test';
import assert from 'node:assert/strict';
// Verify policy config expressed in SQL and app docs; full TS coverage requires a test runner.
import {readFileSync} from 'node:fs';
const sql=readFileSync(new URL('../../database/migrations/001_initial.sql',import.meta.url),'utf8');
test('private profiles default',()=> assert.match(sql,/is_private BOOLEAN NOT NULL DEFAULT TRUE/));
test('uploads are moderated by default',()=> assert.match(sql,/status TEXT NOT NULL DEFAULT 'pending'/));
test('schema has block and report tables',()=> {assert.match(sql,/CREATE TABLE IF NOT EXISTS blocks/);assert.match(sql,/CREATE TABLE IF NOT EXISTS reports/)});
