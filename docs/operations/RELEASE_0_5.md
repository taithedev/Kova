# Kova 0.5
- Native SwiftUI TabView supplies **one** genuine iOS Liquid Glass bottom navigation bar on iOS 26+. No custom overlapping bar.
- Accent color is a local iOS preference, restricted to selected tabs, buttons and indicators. Themes stay light/dark/OLED.
- Profile images are selected with Apple's PhotosPicker and re-encoded to JPEG (dropping original EXIF). GIF banners require **more than 500 real accepted followers**, enforced server-side before a signed upload and again at completion.
- The private S3 bucket holds profile images. They only appear on profiles after staff review. No AI-generated images/bots were added.
- Support tickets are private to their author and staff, with replies, statuses and staff audit events.
- Contact email and E.164 phone are optional, private, encrypted with server-only AES-256-GCM, and not verified/recovery-enabled.
- Verified checks and owner/staff roles remain server-authoritative. Owner role requires identity verification and is not issued by username alone.
- Follower counts are calculated from accepted follows. No hidden synthetic followers or falsified statistics.
- Public release still requires device QA, media validation, abuse report staffing, account recovery and safety review.
