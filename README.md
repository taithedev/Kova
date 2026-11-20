# Kova — native iPhone social video app

## Kova 0.5.0 — Native tab bar, accent colors, profiles, support

**System navigation:** removed the duplicate handcrafted bottom bar. SwiftUI TabView now owns the single, native iOS 26 Liquid Glass tab bar. On iOS 17–25 it uses the standard system tab bar. Paging video feed has native snapping, sensible bounce and selection haptics.

**Appearance:** grayscale UI with optional Classic, Ocean, Violet, Mint, Rose, Amber and Sky accent colors. Users can choose System, Light, Dark or OLED Black. Video content and custom media are not artificially recolored.

**Profiles:** everyone starts private at sign-up, with an explicit public-account opt-in. Users can select personalized color banners, curated avatars or upload JPEG profile photos and banners via PhotosPicker. GIF banners unlock **above 500 accepted real followers**. Uploaded profile media must be approved by authorized staff before appearing publicly. New banner/photo uploads strip photo metadata by JPEG re-encoding.

**Support:** users can create support tickets, follow their status and reply to staff. Staff roles can review support tickets and uploaded profile media. Optional email and phone fields are private and AES-256-GCM encrypted server-side; these are unverified contact fields and do not currently provide password recovery.

**Permissions:** server-side owner/admin/moderator/developer roles and verification remain access-controlled. Owner dashboard includes live platform counts, ticket queues, media review and auditable actions. Roles are not awarded based on matching a username; an authenticated Kova account must be independently proven before initial owner assignment.

**No hidden follower fabrication:** follower numbers are computed from real accepted relationships; owner analytics distinguish real followers from staff roles. The app does not create bot accounts or provide AI-generated content.

**Shipping:** GitHub Actions produces an unsigned iOS IPA with iOS 26 SDK. Sign it before installing. Live API auth/route tests passed; profile uploads, GIF playback, support cases, real-device QA and contact verification remain to be tested end-to-end. Never treat this release as a fully safety-reviewed public launch. Kova serves ages 13+.

[Release history](CHANGELOG.md) · [Roles](docs/operations/ROLES.md) · [v0.5 details](docs/operations/RELEASE_0_5.md)
