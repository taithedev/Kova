# Kova — native iPhone social video app

## Kova 0.9.0 — Interactive creator profiles, opt-in DMs, remix studio

**Tap a creator photo or username** on a feed video to open that real user profile; the heart still likes the video. A much larger, separate Follow button is available in video actions and on profiles. Creator and own-profile grids now open a paged full-screen viewer with playback, likes, comments, bookmarks, reposts, reports and creator navigation. Private posts can be viewed only by their author or permitted followers; removed videos stay unavailable. No fake interactions or follower counts.

**Create:** captions of up to 2,200 characters, a separate video description (up to 1,200 characters), #hashtags, @mentions with notifications and server-side block checks, original audio attribution, an explicit opt-in for allowing others to remix public videos, plus local media editing. Kova Original loops (Orbit, Shimmer, Pulse, Drift) are synthesized locally; importing audio is allowed only for content the creator owns or is licensed to use. The editor exports a real MP4 with trim, color filters, text, emoji stickers and sound mixing. The app supports Stitch (creator clip preceded by up to four seconds of an opted-in public video) and side-by-side Duet, with source attribution validated again on upload. Hardware and real-device testing remain necessary.

**Messaging safety:** Members can enable messaging, which starts off. Both must opt in, mutually follow each other, and be in the same age band (13–15, 16–17, or 18+). Blocked and safety-restricted accounts cannot chat. Links and phone numbers are blocked in chat. Messages can be reported to moderators. No unrestricted adult-to-minor messaging. Kova is a 13+ service and does not support 18+ video content; staff age-safety restrictions disable messaging without changing whether a profile is private or public.

**Owner and moderation:** Owner, Admin and Moderator can apply/restore audited messaging safety restrictions. Verification remains a separate, audited Owner/Admin permission. Role pages are only shown to authenticated staff, and rights are checked server-side.

**Style and releases:** Sixteen accent colors, polished scrollable color picker, native system tab bar and a three-line page drawer. A GitHub Release checker can notify members about new Kova releases on launch or manually. **iOS cannot silently install or sign an unsigned IPA**; the user follows the linked signed update instructions. No third-party copyrighted sound catalog is bundled.

**Not fully implemented:** Rich clip transitions, full multi-track animated effects, licensed sound marketplace, APNs push delivery, always-on moderation automation, and reliable resume-across-restart for uploads. This iPhone build requires signing and thorough end-to-end verification with real accounts before public launch.

## Kova 0.8.0 — Create, discover and manage

**Native Kova Camera (iPhone):** AVFoundation portrait capture with microphone permission, timed recording up to 120 seconds, countdown, front/back camera, torch on supported devices, framing grid, and selectable visual presets. The chosen preset passes into the clip editor.

**Actual edited exports:** Open recordings or imported MOV/MP4 files in the editor. Trim start/end, apply six Core Image filters, render text overlays and emoji stickers into the video, or mute original audio. Edits are exported as a separate MP4 using AVFoundation and uploaded with the existing 100 MB limit. A commercial/licensed sound library, clip transitions, Duet/Stitch compositor and live multi-clip recording are not included yet; don't advertise these as finished.

**Reposts and a user-controlled feed:** Real, authenticated repost and undo-repost buttons. Following sees posts reposted by accounts the viewer follows, but only if the original post is public. "Not interested" hides a video from recommendations. A For You Controls page explains recency, bounded community engagement, followed creators and author diversity, and allows resetting hidden-video choices. No tracking of sensitive traits or watch-time profiling is required.

**Trending discovery:** Trends derive from real hashtags in published public videos over the previous 30 days. They appear as tappable search chips; no fabricated trends.

**Navigation:** A responsive three-line side drawer can take users to Home, Discover, Camera/Create, Inbox, Profile, settings and help, with staff/owner tools visible only to signed-in authorized roles. Owner/Admin can open the new Verification Center to search, verify and unverify other accounts; authorization and audit enforcement remains server-side.

**Retained:** The app remembers the selected tab and feed position, keeps support drafts, and retains initial private-account defaults, content reporting, creator blocking, staff takedowns, real follower numbers, and native Liquid Glass (iOS 26+) aesthetics.

**Reality check:** This is a functional development build, not a production-complete TikTok replacement. Camera, editor export, repost visibility and feed ranking require testing with real devices and multiple accounts. APNs push delivery, licenses for popular music, duet/stitch editing, polished transitions, multi-clip composing, creator playlists and upload-resume servers require additional implementation. App Store submission requires proper moderation processes for teen communities.

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
