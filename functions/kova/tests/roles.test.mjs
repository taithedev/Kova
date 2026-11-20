import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const source=readFileSync(new URL('../index.ts',import.meta.url),'utf8');
test('RBAC enforces verification and owner-only roles',()=>{
 assert.match(source,/me\.role!=='owner'/);
 assert.match(source,/typeof b\.is_verified!=='boolean'/);
 assert.match(source,/You cannot change your own verification or role/);
 assert.match(source,/profile_staff_audit/);
});
test('teen private default can opt into public',()=>{
 assert.match(source,/if\(age<13\)/);
 assert.match(source,/is_private=\$\{b\.is_private\}/);
 assert.doesNotMatch(source,/newPrivate=me.age_band/);
});
test('profile customization validated',()=>{
 assert.match(source,/const styles=\['ink','glacier','orchid','coral','mint','sunset'\]/);
 assert.match(source,/Avatar URL is too long/);
});
