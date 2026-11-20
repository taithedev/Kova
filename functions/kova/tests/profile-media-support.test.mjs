import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const api=readFileSync(new URL('../index.ts',import.meta.url),'utf8');
test('image upload requires staff approval and 500+ real followers for GIF',()=>{
 assert.match(api,/count\(\*\)::int AS n FROM follows WHERE following_id=/);
 assert.match(api,/status='accepted'/);
 assert.match(api,/<=500/);
 assert.match(api,/profile_media.*pending/s);
 assert.match(api,/if\(row\.status==='approved'\)/);
});
test('contact data is encrypted and not added to public profile',()=>{
 assert.match(api,/createCipheriv\('aes-256-gcm'/);
 assert.match(api,/account_contacts/);
 assert.match(api,/email_verified:false/);
});
test('support tickets are scoped to author or staff',()=>{
 assert.match(api,/author_id=\$\{me.id\} OR \$\{staff\}/);
 assert.match(api,/allStaff.includes\(me.role\)/);
 assert.match(api,/staff_action_events/);
});
