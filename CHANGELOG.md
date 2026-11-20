# Kova release history

## 0.9.0 — Profiles, sound studio, remix and safer chats

- Open playable grids from own and other users' profiles with real likes, comments, saves, reposts, and follows.
- Separate creator avatar navigation and larger independent follow controls.
- Caption, video description, hashtags, user mentions and credited sound metadata.
- Original locally synthesized sounds and imported authorized soundtracks.
- Creator-consented Stitch and side-by-side Duet rendered locally through AVFoundation.
- Private, opt-in mutual-follow messaging restricted to matching age groups; message reports, block checks and server rate limiting.
- Staff safety restriction without modifying profile privacy; logged actions and appeals via support.
- Expanded accent colors and optional GitHub Release update checker (no silent IPA installation).
- iOS 0.9.0, build 10.


## 0.8.0 — Native camera, edited exports, reposting, smarter discovery

- AVFoundation camera with recording length, countdown, flash control, flip, framing grid and preview presets.
- Editor for actual trimming, six color filters, text, emoji stickers and mute, with MP4 export.
- Post/undo repost to followers without exposing private videos.
- For You feed ranking with bounded engagement signals, freshness and creator variety, plus Not Interested and reset controls.
- Real 30-day hashtag trends in Discover.
- Animated three-line drawer with all accessible sections and role-aware staff links.
- Dedicated Verification Center for Owner and Admin, with server-side access checks and audit.
- Version 0.8.0, build 9.


## 0.7.0 — Publish now and moderate afterward

- Verified @taithedev while keeping the Owner role.
- Immediate publication of video, avatar, banner and eligible GIF uploads.
- Staff takedown and report resolution with notices and audit logging.
- Published/removed counts in staff and owner dashboards.
- Preserved private account defaults and per-video visibility.


## 0.6.0 — Support 2.0 and resume exactly where you left off

- Persisted selected tab across launches, remembered Explore search, Home feed mode/video position and Upload caption/visibility.
- Added account-scoped device-protected ticket drafts and reply drafts; returning to Kova doesn't discard them.
- Cached support lists and conversations to prevent repeated loading when navigating between app tabs.
- Preserved last signed-in profile while reconnecting after a temporary outage, with server revalidation of staff permissions.
- Added searchable support tickets, unread status, active/resolved filters, ticket numbers, message history, staff priority handling and audit trail.
- Support notifications now link directly to the relevant ticket. Safety tickets receive higher review priority.
- Existing Neon tickets, accounts and messages retained; no destructive migrations.
- No AI agents or fake support users added.

## 0.5.0 — Native tabs, media, support and accent colors

- Removed double navigation bar; use the single native Liquid Glass TabView on iOS 26.
- Added seven accent palettes to Light, Dark, OLED and System appearance.
- Added custom photo uploads, reviewed banner images and GIF banners gated at more than 500 real followers.
- Added server-side media review queue, encrypted optional email/phone contacts and support tickets.
- Added owner analytics for real engagement, staff action audit history and ticket moderation.
- Added improved feed scroll snapping and selection haptics.
- Kept verification and account-role assignment server-enforced, not exposed to ordinary users.
- No fake followers, bot accounts or AI functionality.

## 0.4.0 — Liquid Glass profiles and human-first social

- Built with an iOS 26 SDK for native Liquid Glass tab navigation and panels, with translucent fallback for older supported iOS versions.
- Light, Dark, OLED Black, and System appearance; black-and-white UI accent and original-color videos.
- TikTok-style profiles with colorful banner presets, curated avatar presets, optional hosted HTTPS profile photos, pronouns, editable biography, public/private controls, follower counts and three-column video grids.
- New accounts default to private. Teen and adult accounts may explicitly choose public, with an in-app disclosure before opening visibility.
- Server-issued blue checkmarks rendered consistently in feed, search and profile.
- Server-enforced owner, administrator, moderator and developer roles with audit-logged staff role and verification changes.
- Admin/owner verification management, owner-only delegation of developer/moderator/admin roles, staff moderation counts and developer creator analytics.
- Search and welcome redesigns plus real-content guest browsing; mock creator accounts removed.
- No generative AI or bot account features are shipped. Rate limiting and human moderation remain necessary.

**Owner provisioning:** An owner role is not issued on signup or derived solely from usernames; a verified operator must assign it to a proven account in the database. Media upload and real-device acceptance testing are still outstanding.

## 0.3.0 — Live accounts, easier signup, and account tools

- Neon Managed Better Auth enabled on Kova; live Neon Function API deployed.
- Verified register/login/profile/logout/DB responses via a live GitHub Actions smoke test.
- Removed API URL setup from the iPhone experience. One fixed public Kova service URL.
- Username and password signup (date of birth only for 13+ eligibility); username-availability checks.
- Show/hide password, confirmation, length feedback and inline input validation.
- Better app launch restore, Keychain session retention after network outages and error explanations.
- New Account Center: activity counts, active sessions, sign out other sessions, blocked users and unblock.
- Notification history and mark-all-read actions.
- Accept or decline follow requests; pending state.
- Delete your own videos and comments; refresh video list.
- Report and block user profiles, safety confirmation.
- Pull to refresh and pagination in vertical feed; empty-feed retry.
- Enhanced teen-private account settings and profile editing.
- Backend Following feed now supports approved followers-only videos with accepted follow relationships.
- Black/white UI remains; uploads retain their original color.

**Known limits:** private video upload credentials and real-device media testing still outstanding. Managed Better Auth's internal identities do not offer an email recovery address, so password reset requires further design. This is not yet a public-launch-ready platform.

## 0.2.1 — In-app server connection

- Configure the public HTTPS Kova API origin inside the sign-in screen; no Swift rebuild required after hosting.
- Keep video uploads private on Neon Storage; approved videos use expiring signed playback links.
- Compiled unsigned iOS binary through GitHub Actions. Public hosting and device testing are still pending.

## 0.2.0 — Monochrome

- Redesigned the native UI with a strict black-and-white interface: new handcrafted K mark, welcome flow, custom navigation, buttons, avatar surfaces, action controls, demo cards, inbox and settings.
- Real videos stay in full original color; only interface and demo placeholders use grayscale.
- Video playback gains tap-to-pause and a persistent start-muted preference.
- Sharing uses a stable, approved-public-only web watch link.
- Private Neon Object Storage and signed video playback URLs replace permanent public media URLs.
- Added server-side lightweight engagement/recency feed ordering.
- Neon Kova database initialized with separate user, video, social and moderation tables.
- No adult monetization, shop or direct messages. Public release still requires moderation capacity and testing.

This source update does not by itself guarantee a signed or installable IPA. GitHub Actions builds an unsigned IPA for external signing. The Swift UI, uploading, permissions and API must be tested on a real iPhone.
