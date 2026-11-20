# KOVA — native iPhone video app

**Version 0.2.1 — Black and white interface, original K icon, full-color videos.**

This is a SwiftUI + AVPlayer iOS client and a Next.js API for Neon PostgreSQL. The source includes a native video feed, camera/library upload, search, follow requests, profiles, likes, bookmarks, comments, reporting and moderation. Direct messages and adult commerce are excluded.

## Download for iPhone

GitHub Actions > Build Kova iPhone IPA (unsigned) > latest successful run > Kova-iPhone-unsigned-IPA. Extract the ZIP to get an unsigned .ipa. The app must be signed by the device owner before sideloading. The CI builds with Apple's macOS SDK; signing and testing are separate.

## Back-end status

The dedicated Neon project Kova has been initialized: database kova, initial 11 social/moderation tables and a private kova-videos storage bucket. The Next.js API is **not yet hosted**. It needs a public HTTPS deployment and server-only credentials from backend/.env.example.

When the API is deployed, open Kova > Enter Kova > Connect your Kova API and enter its HTTPS origin, e.g. https://your-kova-api.vercel.app. An IPA rebuild is not necessary to change that URL. Verify /api/health and /api/health/db first. The current app does not have live login/upload service without that deployment.

The first migration is at database/migrations/001_initial.sql. Do not run destructive migrations or replace the existing Kova database. Do not embed DATABASE_URL or storage credentials in the iPhone app or commit them to Git.

## Safety and readiness

Social accounts are restricted to ages 13+. Under-13 registration is disabled. Users start with private accounts; follow requests and the moderator review queue are present. No uploaded video becomes public until a moderator approves it. DMs and shopping are absent. Public launch requires staffed moderation, automated media screening, privacy/legal review, rights-cleared music, video optimization and on-device testing.

## Source structure

- Sources/Kova: native SwiftUI app
- Assets: monochrome hand-designed app icon and editable SVG
- backend: Next.js and Neon API
- database/migrations: SQL schema
- .github/workflows: API validation and unsigned IPA build

See CHANGELOG.md for versioned changes.
