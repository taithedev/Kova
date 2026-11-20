# Kova hosted API and account system

The public iOS app connects to the active Kova Neon Function automatically. There is **no user-entered API address**. All HTTPS calls use the same base host and route paths, e.g. `/api/auth/register`, `/api/auth/login`, `/api/auth/me`, `/api/auth/logout`, `/api/health` and `/api/health/db`.

Managed Better Auth is provisioned inside the Kova Neon project in the `neon_auth` schema. Kova's app profiles remain in `public.profiles` and reference managed accounts with `neon_auth_id`. The server creates a random, non-deliverable email identity for each username because Managed Better Auth requires email for email/password signup. Users do not see or type this address. **Do not treat it as verified email or recovery contact.** A secure account recovery design is still required.

Age policy: registration requires a date of birth indicating at least age 13; only coarse age bands are stored. Teen accounts stay private and DMs are disabled. Under-13 registration is blocked. The self-reported DOB is not a verified-age system.

Live CI verification has confirmed signup, login, session restore, logout, and Neon SQL connectivity. The API returns JSON `{"data":...}` on success and `{"error":"..."}` on failure. The native client decodes this format.

Object storage: private `kova-videos` bucket exists but server-side S3 credentials and live upload/download verification are outstanding; do not market video hosting as fully operational. Never make pending videos public, bypass moderation, or publish raw storage keys or credentials.
