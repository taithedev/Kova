# Kova v0.2 — protected video delivery

The Neon bucket "kova-videos" is private. The app asks the authenticated API for a short-lived upload URL; uploaded videos remain pending until moderator approval. Public feed/search/watch routes and restricted bookmarks/profile routes check visibility and blocks before signing a playback URL, valid for 15 minutes. Store only private object keys and non-public placeholders in the database, never persistent publicly accessible object links.

Deploy the Next.js backend with DATABASE_URL and scoped S3 credentials from backend/.env.example. No database or storage secrets go in the Swift client. Neon is not a video transcoder/CDN; a broader launch still requires media scanning, HLS variants, abuse monitoring, staffed moderation, age-appropriate protection, privacy/legal review, and delivery cost controls. Under-13 social accounts remain disabled.
