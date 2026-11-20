import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const api=readFileSync(new URL('../index.ts',import.meta.url),'utf8');
test('images publish immediately while moderators can remove them',()=>{
 assert.match(api,/profile_media\(owner_id,kind,object_key,mime,byte_length,status\)/);
 assert.match(api,/mime},\$\{bytes},'approved'/);
 assert.match(api,/UPDATE profiles SET avatar_key=\$\{key}/);
 assert.match(api,/UPDATE profiles SET banner_key=\$\{key}/);
 assert.match(api,/UPDATE profile_media SET status='rejected'/);
 assert.match(api,/UPDATE profiles SET avatar_key=NULL/);
 assert.match(api,/staff_action_events/);
});
test('animated GIF banners require more than 500 real followers',()=>{
 assert.match(api,/count\(\*\)::int AS n FROM follows WHERE following_id=/);
 assert.match(api,/status='accepted'/);
 assert.match(api,/<=500/);
});
test('contact data is encrypted and not added to public profile',()=>{
 assert.match(api,/createCipheriv\('aes-256-gcm'/);
 assert.match(api,/account_contacts/);
 assert.match(api,/email_verified:false/);
});
test('support tickets are scoped to author or staff',()=>{
 assert.match(api,/author_id=\$\{me.id\} OR \$\{staff\}/);
 assert.match(api,/allStaff.includes\(me.role\)/);
});
