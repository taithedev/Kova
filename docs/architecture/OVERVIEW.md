# Architecture

Native iOS SwiftUI client → HTTPS JSON API (Vercel Next.js) → Neon Postgres. Uploads go **iPhone → expiring signed S3-compatible PUT URL → object storage**, and metadata is submitted to API for moderation. Delivery requires a configured HTTPS media host. The database is never directly contacted by iOS.

The system has four trust boundaries: the device, API authentication, database authorization (enforced by server SQL and endpoint checks) and object storage. No OAuth or third-party music licensing is claimed.

## System concerns

- Feed initially chronological among approved, public content; a recommendation ranking engine is future work.
- iOS native AVPlayer uses progressive MP4/MOV; HLS transcoding is future work.
- Sessions are random 256-bit tokens; only SHA-256 token hashes are stored in Neon, while raw tokens reside on device in Keychain.
- Passwords are hashed with scrypt salts. Strong anti-abuse rate limits and recovery must be added before wide release.
- Posts require human or automated approval plus sufficient review capability.
