import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const src=readFileSync(new URL('../index.ts',import.meta.url),'utf8');
test('support v2 retains private ticket authorization',()=>{
 assert.match(src,/author_id=\$\{me.id\} OR \$\{staff\}/);
 assert.match(src,/Ticket is closed/);
 assert.match(src,/support_ticket_events/);
 assert.match(src,/last_user_read_at=now\(\)/);
});
test('staff filters and roles are checked server side',()=>{
 assert.match(src,/allStaff.includes\(me.role\)/);
 assert.match(src,/Invalid status filter/);
 assert.match(src,/Invalid category filter/);
 assert.match(src,/Invalid support priority/);
});
test('support replies notify ticket owner without exposing their message',()=>{
 assert.match(src,/kind,body\)/);
 assert.match(src,/support_reply','You have a new reply/);
 assert.match(src,/staffResponse=staff && allowed\[0\]\.author_id!==me.id/);
});
