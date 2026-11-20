# Kova v0.6: Support and app persistence

## Storage layers
- Login token: Keychain. Never stored in local drafts.
- Current tab: `@AppStorage("kova.selectedTab")` persists across app relaunches.
- Feed mode/active video and Discover search: `@SceneStorage`; survives scene restoration where iOS permits.
- Last known user profile: data-protected Application Support file; used for offline display only. Live API authentication still determines access. Staff settings hidden until a session is confirmed.
- Ticket subjects/messages/replies and upload form text: data-protected, account-scoped Application Support drafts, excluded from iCloud backups. Signing out doesn't delete same-user drafts.
- Sent tickets, staff replies, status and audit history: Neon PostgreSQL, not only local storage.

## Ticket features
User: create category-specific support ticket; automatically prioritize safety reports; search; active/resolved tabs; unread indicators; detailed thread; attachment-free messaging; locally saved drafts; status notifications linking to the correct ticket.

Staff: account-scoped server authorization; search/filter queue; review private threads, adjust priority, change status, view event history; notifications to the ticket owner; status/audit trail. Ordinary users can't access staff queue or staff functions.

## Existing data
All migrations are additive. Do not delete the existing Kova user and their saved ticket. Do not auto-assign owner from username strings or client-stored roles.

## Known limitations
Staff replies aren't guaranteed to be instantaneous. Real push alerts require APNs implementation. A previously selected video file may need re-selection after OS termination. Real-device and accessibility QA must be completed before public launch; full production incident-response staffing remains necessary.
