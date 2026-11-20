# Kova — native iPhone social video app

## v0.4.0 — Liquid Glass and real profiles

This release improves the app's native design with a four-mode appearance selector (System, Light, Dark, OLED Black), genuine iOS 26 Liquid Glass where available, custom profile banners, preset avatars and optional externally hosted HTTPS profile photos. Black-and-white controls are consistent; user videos and profile colors remain colorful.

### Account experience
- Username/password sign-in via Neon Managed Better Auth; no server URL to configure.
- Age 13+ signup. All new accounts are **private by default**. Users may deliberately switch to public through Edit Profile with a privacy warning.
- Display name, bio, optional pronouns, verified blue checkmark (issued by staff only), banner presets, avatars, follower counts, and a three-column video gallery.
- Public Explore searches real accounts and approved public posts. Guest browsing does not create fake users or show fabricated video cards.

### Real permissions
- **Owner**: staff dashboard, creator studio, approve/remove verification, assign developer/moderator/admin roles.
- **Admin**: staff dashboard, moderation queue, approve/remove verification on permitted accounts.
- **Moderator**: content review queue, reports, and moderation stats.
- **Developer**: developer label and creator studio with personal video/follower/like stats.
- **Verified user**: blue checkmark on feed, profile and discovery. Verified status does not grant staff rights.

All privileged operations are checked on the server and logged. Owner privileges do not come from entering a special username. They must be assigned to a verified existing account using a trusted database procedure. See `docs/operations/ROLES.md`.

### Code and distribution
- `Sources/Kova/`: Native SwiftUI app (iOS 17+, native glass on iOS 26+).
- `functions/kova/index.ts`: active Neon-hosted API.
- `database/migrations/`: additive Kova PostgreSQL schemas.
- `Assets/`: original geometric black-and-white Kova icon.
- `.github/workflows/`: tests and macOS unsigned IPA builder, using Xcode 26 SDK.

The built artifact is an **unsigned IPA**: sign using your own Apple credentials before sideloading. This is not a public launch and has not undergone a full real-device security, abuse, privacy, or video upload/playback test. Accounts under 13 remain disabled. Password recovery, upload scanning, media storage credentials, and staffed public moderation are still required.

**No AI creators, AI-generated feeds, or automated account bots are built into this version.** This is not a guarantee the service is bot-free; rate limits, reporting and active moderation must be maintained.
