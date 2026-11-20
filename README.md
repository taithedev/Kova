# KOVA — native iPhone video app

**Kova 0.3.0:** black-and-white interface, original K mark, and full-color user videos.

## Accounts — live Neon Managed Better Auth
A public Neon Function now serves the Kova API:
`https://br-autumn-water-bc3ti0gm-kovaapi.compute.c-16.us-east-1.aws.neon.tech`

The iPhone app connects automatically. Users need **only a username, password, and date of birth for age eligibility**; there is no server URL field or email form. Account identities and password credentials are managed by **Neon Managed Better Auth**, using an internal non-deliverable identity address (not a recovery email). The app's own profiles, follows and session metadata are stored in the separate Kova Postgres database. Password reset/recovery is not yet provided—**do not use this for a public launch without a secure recovery process**.

A live GitHub Actions test verified POST /api/auth/register (201), POST /api/auth/login (200), GET /api/auth/me (200), POST /api/auth/logout (200), and GET /api/health/db (200).

## 20+ functional updates in 0.3.0
- Zero-config API, direct account creation, login, password show/hide, confirmation and minimum-length feedback
- Username validation and live availability checking
- DOB eligibility check (13+), no DOB stored in profiles, teen-private profiles
- Keychain sessions, restore indicator, logout, clearer network and server errors
- Account center: video/comment/bookmark/unread statistics, active sessions, revoke other sessions, blocked accounts list and unblock
- Notification history, mark all notifications read, refresh
- Accept or decline follow requests; follow-request status
- Profile editing and teen privacy explanation
- Report or block profiles and exclude blocked accounts
- Delete your own video or comment
- Pull-to-refresh, retry empty feed and cursor pagination
- Existing likes, bookmarks, search, camera/video upload UI and moderator review controls

## Build / install
The GitHub Actions workflow **Build Kova iPhone IPA (unsigned)** produces an unsigned `.ipa`. You need to sign it using your own Apple signing method before installing it on an iPhone. The build is not App Store published and cannot be installed without signing.

## Media readiness and limitations
A private Neon `kova-videos` object-storage bucket exists. **Private upload credentials and end-to-end playback/upload verification are still outstanding**, so video uploads may return a configuration error. No video enters public feeds before moderator approval. For You is public-approved only; Following includes approved posts visible to accepted followers. Public release still requires staffed moderation, abuse screening, rights-cleared music, privacy and safety review, recovery and on-device QA.

## Repository
- `Sources/Kova`: SwiftUI iOS client
- `functions/kova`: deployed standalone Neon Function API source (canonical backend)
- `database/migrations`: Postgres schema
- `backend`: older Next.js API code for reference, **not the active Managed Better Auth backend**
- `Assets`: black-and-white icon and SVG
- `.github/workflows`: bundle/verify/unsigned-IPA pipelines

See `CHANGELOG.md` for details.
