# Kova release history

## 0.2.1 — In-app server connection

- Configure the public HTTPS Kova API origin inside the sign-in screen; no Swift rebuild required after hosting.
- Keep video uploads private on Neon Storage; approved videos use expiring signed playback links.
- Compiled unsigned iOS binary through GitHub Actions. Public hosting and device testing are still pending.

## 0.2.0 — Monochrome

- Redesigned the native UI with a strict black-and-white interface: new handcrafted K mark, welcome flow, custom navigation, buttons, avatar surfaces, action controls, demo cards, inbox and settings.
- Real videos stay in full original color; only interface and demo placeholders use grayscale.
- Video playback gains tap-to-pause and a persistent start-muted preference.
- Sharing uses a stable, approved-public-only web watch link.
- Private Neon Object Storage and signed video playback URLs replace permanent public media URLs.
- Added server-side lightweight engagement/recency feed ordering.
- Neon Kova database initialized with separate user, video, social and moderation tables.
- No adult monetization, shop or direct messages. Public release still requires moderation capacity and testing.

This source update does not by itself guarantee a signed or installable IPA. GitHub Actions builds an unsigned IPA for external signing. The Swift UI, uploading, permissions and API must be tested on a real iPhone.
