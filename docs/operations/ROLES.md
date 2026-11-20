# Kova staff and verification policy

Roles are stored in `public.profile_staff_roles`, separate from Neon Managed Better Auth credential records. They are never supplied by clients. The API joins the role on every authenticated request.

- `member`: can personalize profile, change public/private, upload and interact where allowed
- `developer`: developer role badge and self-only creator studio analytics. No moderation permissions
- `moderator`: moderation queue, video approval/rejection, pending counts and reports, with no user privilege assignment
- `admin`: moderation plus verification controls for non-owner accounts. Cannot assign roles
- `owner`: all the above, creator studio, and ability to assign member/developer/moderator/admin roles. Cannot grant another owner through public API
- `is_verified`: separate blue check badge, only modified by admin/owner with server checks and `profile_staff_audit` records

**First owner**: Only a trusted database operator should bootstrap the owner role after independently confirming the authenticated Neon Auth account and corresponding `public.profiles.id` belong to the rightful owner. Do not grant by username alone; anyone could register an unclaimed name. No signup code awards an owner role.

Trusted operator template (after independent identity verification):

```sql
INSERT INTO public.profile_staff_roles (profile_id, role)
VALUES ('<verified-profile-uuid>', 'owner')
ON CONFLICT (profile_id) DO UPDATE SET role = EXCLUDED.role;
```

Replace with an independently verified profile UUID, not an unverified handle. Restrict this SQL to the trusted Neon operator. Staff endpoint authorization is verified at request time, so role changes take effect without any updated IPA.

Privacy: All new accounts are private initially. Users 13+ can choose to switch to public after an explicit in-app confirmation. Only approved posts can enter public feeds. Direct messages remain disabled for all users.

The current client supports curated color avatars and optional HTTPS image links, not a native photo-upload service. Private media delivery remains unverified pending storage credentials and real-device testing.
