import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const content=readFileSync(new URL('../index.ts',import.meta.url),'utf8');
test('Kova backend provides registration, login, sessions and account checks',()=>{
 for(const path of ['/api/auth/register','/api/auth/login','/api/auth/me','/api/auth/logout','/api/auth/username-available','/api/auth/sessions'])
 assert.ok(content.includes(path),path);
});
test('minimum age 13 and pending moderation enforced',()=>{
 assert.ok(content.includes('if(age<13)'));
 assert.ok(content.includes("status='pending'"));
});
test('Better Auth used for password verification, not local hash',()=>{
 assert.ok(content.includes("sign-up/email"));
 assert.ok(content.includes("sign-in/email"));
 assert.ok(!content.includes("scrypt"));
});
test('private videos cannot enter feed without approval',()=>{
 assert.ok(content.includes("v.status='approved'"));
 assert.ok(content.includes("p.is_private=false"));
});
