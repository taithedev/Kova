# KOVA

**Create. Watch. Connect.** An original short-form-video social app for iPhone, built with **SwiftUI + xtool** and a **Next.js API backed by Neon PostgreSQL**.

> **State: substantial source-code foundation (v0.1.0), NOT a public-launch-ready TikTok replacement.** The iPhone experience includes preview mode and API-powered flows. Deployment, database migration, video storage, moderation staffing and on-device testing remain required.

## What is here

| Area | Implemented in this repository | Next stage |
|---|---|---|
| Native iPhone | SwiftUI dark UI, vertical scrolling feed, autoplay AVPlayer, demo preview, tab navigation | Device QA, accessibility and performance passes |
| Accounts | 13+ age check on the server, username/password accounts, scrypt hash, token sessions in iOS Keychain | Recovery, verified age/identity appropriate to jurisdiction, broader abuse protection |
| Video | Record/select MOV/MP4, signed upload, moderation queue, approved-only public feed | Transcoding, HLS/CDN optimization, background uploads, full editor, music rights |
| Social | Likes, comments, bookmarks, follows, private-account follow requests, search, profiles | Replies, mentions, reels sharing, ranking, DMs |
| Safety | Report/block endpoints, private-by-default profiles, DMs unavailable, moderator review | Formal policy, staffed moderation, proactive child-safety filtering and escalation |
| Notifications | API list and native inbox | Actual notification producer, APNs push |
| Premium / shop | Deliberately excluded | Not planned for age-gated initial product |

## Project layout

- `Sources/Kova/` — iOS app, components, features, models, video player, API client, Keychain, upload support
- `Package.swift` / `xtool.yml` — SwiftPM + xtool packaging
- `Support/Info.plist` — camera, microphone and photos permission descriptions
- `Assets/AppIcon.png` — Kova icon
- `backend/` — Next.js API with Neon driver and signed S3-compatible media upload
- `database/migrations/` — PostgreSQL migration, **not automatically applied**
- `docs/` — architecture, developer and product guides
- `tests/` — structure validation and policy checks
- `.github/workflows/` — automated API test/typecheck job

## iPhone setup on Windows

1. Install Swift and **xtool** using the [official xtool installation guide](https://xtool.sh/documentation/xtool/).
2. Clone this repo. Run `xtool setup` and sign in using `xtool auth login` if requested by xtool. Plug in your authorized iPhone.
3. Edit `Sources/Kova/Core/Network/AppConfig.swift` to point at your **public HTTPS Kova API**. This is a public URL, not a secret.
4. From the repo root, run `xtool dev run` (or `xtool dev` for help with your installed version). This is intended as a SwiftPM xtool project; a device build has **not** been verified in this environment.
5. To explore the UI without a deployed server, select **Explore preview**. Preview cards are clearly labeled placeholders, not real videos.

## Neon + Vercel API setup

Neon project **Kova** exists, independent of other databases. This commit does **not** apply SQL migrations or deploy your API.

1. Review `database/migrations/001_initial.sql` and apply it to the **Kova** Neon database (`kova`) using the Neon console or a reviewed migration process.
2. In Vercel, import this repository and set **Root Directory** to `backend`.
3. Set server-side `DATABASE_URL` from Neon, plus S3-compatible media secrets and `MEDIA_PUBLIC_URL` from `backend/.env.example`. **Never commit or include them in the iPhone binary.**
4. Deploy and verify `https://YOUR_API/api/health` and `https://YOUR_API/api/health/db`.
5. Update `AppConfig.swift` and build with xtool. Only approved videos appear in the public feed.
6. Create your own account, verify your identity, and promote it **manually in Neon** to `moderator` or `admin` before testing moderation.

**Free tier reality:** Database, API, and storage may incur charges with growth. Video bandwidth/storage will become the biggest cost; Neon itself is **not** a video hosting CDN.

## Age restrictions

This initial Kova social app is **13+**. Users under 13 cannot register. A future 10–12 experience must be separately designed and reviewed for verified parental consent, appropriate data handling, and substantially restricted or disabled social features. Do **not** lower the server minimum-age check to bypass these requirements. The App Store age rating is set by Apple based on a completed age-rating questionnaire, not just an age string in code.

## Security / launch status

All user-generated videos are set to `pending` and require moderation before entering the public feed. This is only a starting point—not content scanning or a complete child-safety system. Videos should not be made public until moderators, privacy policy, reporting response, upload scanning, appeal processes and other safety controls are operational.

Contributions: see `CONTRIBUTING.md`. Report vulnerabilities privately; see `SECURITY.md`.