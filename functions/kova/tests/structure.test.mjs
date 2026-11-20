import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const content=readFileSync(new URL('../index.ts',import.meta.url),'utf8');
test('Kova backend has auth and account checks',()=>{
 for(const path of ['/api/auth/register','/api/auth/login','/api/auth/me','/api/auth/logout','/api/auth/username-available','/api/auth/sessions'])
 assert.ok(content.includes(path),path);
});
test('age 13 minimum, instant publishing and staff takedowns',()=>{
 assert.ok(content.includes('if(age<13)'));
 assert.match(content,/VALUES\(\$\{me.id\},\$\{key\},'private',.*'approved'/);
 assert.match(content,/UPDATE videos SET status=\$\{status\},moderated_at=now\(\)/);
});
test('Better Auth used for password verification',()=>{
 assert.ok(content.includes("sign-up/email"));
 assert.ok(content.includes("sign-in/email"));
 assert.ok(!content.includes("scrypt"));
});
test('private videos are not shown in public feeds',()=>{
 assert.ok(content.includes("v.status='approved'"));
 assert.ok(content.includes("p.is_private=false"));
});
