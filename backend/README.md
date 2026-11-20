# Kova API (Next.js / Neon)

`cp .env.example .env.local` and configure private backend secrets. Run `npm install && npm run dev`. Point Kova's iOS `AppConfig.apiBaseURL` at this HTTPS deployment. Vercel deploys `backend/` as Root Directory.

The iPhone app **never** connects to Neon PostgreSQL directly. Access tokens are stored in Keychain, and the API checks every protected operation. Objects upload using short-lived signed S3 PUT URLs, then stay pending until a moderator approves them.

Routes include `/api/auth/{register,login,me,logout}`, `/api/feed`, `/api/videos`, `/api/videos/upload-url`, `/api/videos/mine`, `/api/videos/[id]/{like,bookmark,comments}`, `/api/users/[handle]`, `/api/users/[handle]/follow`, `/api/users/me`, `/api/users/me/block`, `/api/search`, `/api/reports`, `/api/notifications`, `/api/moderation/queue` and moderator actions.

**Not yet production-ready:** email/password recovery, strong anti-bot and abuse screening, consent flow for younger children, verified upload content scanning, full moderation tooling, CDN transcode pipeline, push delivery, real-time chat, LIVE, music licensing and auditing. Don't publicly launch until these are complete and reviewed.
