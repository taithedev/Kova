# Deployment playbook

1. Create/edit the Kova Neon database (`kova`) and review the migration. Test on a temporary Neon branch; then apply to Kova main only after approval.
2. In Vercel select this repo, Root Directory `backend`, Framework Next.js. Keep `DATABASE_URL` a server environment variable.
3. Configure S3-compatible media object storage and HTTPS CDN domain. Ensure upload secrets are not shipped to iOS. Turn on bucket size/lifecycle quotas and server-side content inspection before public use.
4. Deploy the backend. Confirm `/api/health`, then `/api/health/db`.
5. Edit `AppConfig.swift` with the backend HTTPS origin. Build/deploy using xtool on Windows + an Apple-authorized device.
6. Approve test uploads through the account given a role in Neon. Real moderators and policies required before public signup.
7. Set monitoring, alerting, error reporting and cost caps for media bandwidth, storage and API calls.

Do not disable age checks, moderation, or private-by-default rules to speed up launch.
