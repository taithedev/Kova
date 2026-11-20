# Legacy Next.js backend (not Kova's active API)

Kova 0.3.0 now uses the standalone **Neon Function** source at `functions/kova/index.ts`, deployed to:
`https://br-autumn-water-bc3ti0gm-kovaapi.compute.c-16.us-east-1.aws.neon.tech`

**Do not point current Kova clients at this older Next.js server.** Its earlier password/scrypt routes are not synchronized with the Neon Managed Better Auth account integration. The active Kova API creates and verifies account credentials through Neon Managed Better Auth; the native app uses that Neon Function automatically.

This folder is retained only for historical reference during migration. It is not deployed in the latest Kova release. Neon Function changes require the `Bundle Kova Neon API` CI workflow and a function deployment, not simply a Next.js build.

Never expose Neon database/storage credentials inside the iPhone app or the repository. Teen privacy, content moderation, safe account recovery, upload scanning and production security checks remain required before public launch.
