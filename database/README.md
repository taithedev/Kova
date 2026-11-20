# Kova database

Neon project created for this app: **Kova** (separate from ZuzuCord). The SQL in `migrations/001_initial.sql` is NOT automatically applied by GitHub upload. Apply after review using Neon's SQL editor or a tested migration procedure. Never place `DATABASE_URL` in an iOS app.

## Privacy and launch checklist
- 13+ social signup only; do not enable under-13 social access without an age-appropriate, compliant separate product.
- Seed the first moderator **out of band**, from the database console after verifying the account owner: `UPDATE profiles SET role='admin' WHERE handle='<reviewed_handle>';`.
- Moderate every video before publishing. Review reports, audit moderation, investigate abuse, set retention, and implement automated+human moderation before opening to the public.
- Set a retention policy for `rate_events` and expired sessions.
- Use HTTPS and restrict CORS; never expose database credentials to an app.
