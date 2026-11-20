# Kova — native iPhone social video app

## Kova 0.7.0 — Instant posts, staff takedowns

- Owner account @taithedev is verified with the blue checkmark in Neon.
- Uploaded profile photos, static banners, GIF banners and videos publish immediately after server-side file checks, without an approval queue. Animated banners still require more than 500 accepted real followers.
- Moderators can remove live videos and active profile media, handle reports and keep an audit history. Removed creators receive in-app notifications.
- Accounts still begin private, videos retain their chosen public/followers/private visibility, and reporting and blocking remain available. Public posts are discoverable only from public accounts.
- The native iPhone tab bar, persistent support ticket drafts, offline account cache, Liquid Glass appearance and accent color options remain.
- No bots or fake followers were added. Instant user-generated publishing requires prompt human moderation and end-to-end on-device QA before broad release.
- Builds are unsigned iPhone IPA files that must be signed to install.

## Kova 0.6.0 — Persistent app state and Support 2.0

**Switch apps without losing your place:** The selected tab persists across app switches and relaunches. Home remembers the selected feed mode and video position; Discover remembers your search. Kova caches account data to avoid a blank sign-in screen during temporary connectivity loss, while still validating login with the live server. Foregrounding quietly refreshes your session when needed without replacing the main navigation view.

**Saved drafts:** New support ticket subjects, categories, and message drafts are saved locally per account. Ticket replies keep unsent text. Upload captions and visibility preferences are remembered as well. On-device files use iOS file protection and aren't included in iCloud backups; sent ticket conversations persist in Neon. Selected video files may still need to be reselected after a force quit.

**Support 2.0:** Searchable personal ticket list, unread message indicators, active/resolved filters, clearer message threads, ticket IDs, priority queue for safety issues, status activity history, staff-only status/priority tools, queue search and category filters, support reply notifications that open the correct ticket, and fast cached ticket navigation.

**No fake support or automatic bot replies.** Support tickets are stored, private and reviewed by people. A support ticket is not an instant emergency service.

**Verification:** A Kova ticket exists under the @taithedev account. Owner permissions remain unchanged pending privileged account-role assignment; a ticket by itself does not override account authorization.

**Build:** iOS 17+ native SwiftUI (Apple native Liquid Glass appearance on iOS 26+). Releases are unsigned IPA builds and need signing before installation. Full device QA and end-to-end support staff operations remain necessary.

## v0.5.0 — Native tab bar, accent colors, profiles, support

**System navigation:** removed the duplicate handcrafted bottom bar. SwiftUI TabView now owns the single, native iOS 26 Liquid Glass tab bar. On iOS 17–25 it uses the standard system tab bar. Paging video feed has native snapping, sensible bounce and selection haptics.

**Appearance:** grayscale UI with optional Classic, Ocean, Violet, Mint, Rose, Amber and Sky accent colors. Users can choose System, Light, Dark or OLED Black. Video content and custom media are not artificially recolored.

**Profiles:** everyone starts private at sign-up, with an explicit public-account opt-in. Users can select personalized color banners, curated avatars or upload JPEG profile photos and banners via PhotosPicker. GIF banners unlock **above 500 accepted real followers**. Uploaded profile media must be approved by authorized staff before appearing publicly. New banner/photo uploads strip photo metadata by JPEG re-encoding.

**Support:** users can create support tickets, follow their status and reply to staff. Staff roles can review support tickets and uploaded profile media. Optional email and phone fields are private and AES-256-GCM encrypted server-side; these are unverified contact fields and do not currently provide password recovery.

**Permissions:** server-side owner/admin/moderator/developer roles and verification remain access-controlled. Owner dashboard includes live platform counts, ticket queues, media review and auditable actions. Roles are not awarded based on matching a username; an authenticated Kova account must be independently proven before initial owner assignment.

**No hidden follower fabrication:** follower numbers are computed from real accepted relationships; owner analytics distinguish real followers from staff roles. The app does not create bot accounts or provide AI-generated content.

**Shipping:** GitHub Actions produces an unsigned iOS IPA with iOS 26 SDK. Sign it before installing. Live API auth/route tests passed; profile uploads, GIF playback, support cases, real-device QA and contact verification remain to be tested end-to-end. Never treat this release as a fully safety-reviewed public launch. Kova serves ages 13+.

[Release history](CHANGELOG.md) · [Roles](docs/operations/ROLES.md) · [v0.5 details](docs/operations/RELEASE_0_5.md)
