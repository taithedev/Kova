# REST API v0.1

All responses use `{"data": ...}` or `{"error": "..."}`. Protected operations require `Authorization: Bearer <session token>`. POST/PATCH use `application/json`. All sensitive credentials are server-only.

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/auth/register` | Create account; age >=13 |
| POST | `/api/auth/login` | Login with handle/password |
| GET | `/api/auth/me` | Restore session |
| POST | `/api/auth/logout` | Revoke current session |
| GET | `/api/feed?mode=for-you` | Public approved feed |
| GET | `/api/feed?mode=following` | Approved creators you follow |
| POST | `/api/videos/upload-url` | Request short-lived media upload URL |
| POST | `/api/videos` | Submit uploaded metadata as pending |
| GET | `/api/videos/mine` | Own videos including pending |
| POST/DELETE | `/api/videos/{id}/like` | Like/unlike |
| POST/DELETE | `/api/videos/{id}/bookmark` | Save/unsave |
| GET/POST | `/api/videos/{id}/comments` | Read/create comments |
| GET | `/api/users/{handle}` | View profile with privacy check |
| POST/DELETE | `/api/users/{handle}/follow` | Follow/unfollow or request access |
| PATCH | `/api/users/me` | Update profile (`GET /api/auth/me` reads session) |
| POST | `/api/users/me/block` | Block user and remove follows |
| GET | `/api/follows/requests` | Pending incoming follow requests |
| POST/DELETE | `/api/follows/requests/{id}` | Accept/decline incoming request |
| GET | `/api/bookmarks` | Saved videos |
| GET | `/api/search?q=` | Search people and captions |
| POST | `/api/reports` | Report content or users |
| GET | `/api/notifications` | Notification list |
| GET | `/api/moderation/queue` | Moderator queue |
| PATCH | `/api/moderation/videos/{id}` | Approve/reject video |
| GET | `/api/health` | Process health |
| GET | `/api/health/db` | Database health |

Caution: this release does not implement recommendation ranking, threaded comments, follow-request notifications, DM chat, group calls, live streams, creator monetization, or creator music library.
