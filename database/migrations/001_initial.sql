-- Kova v0.1: apply to a NEW, separate Neon project after reviewing.
-- Initial code makes 13+ the only social account age group; under-13 signup is rejected.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS profiles (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 handle VARCHAR(25) NOT NULL UNIQUE CHECK(handle ~ '^[a-z0-9_]{3,25}$'),
 display_name VARCHAR(50) NOT NULL,
 password_hash TEXT NOT NULL,
 bio VARCHAR(160) NOT NULL DEFAULT '',
 avatar_url TEXT,
 age_band TEXT NOT NULL CHECK (age_band IN ('13_15','16_17','18_plus')),
 role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('member','moderator','admin')),
 is_private BOOLEAN NOT NULL DEFAULT TRUE,
 is_verified BOOLEAN NOT NULL DEFAULT FALSE,
 allow_messages BOOLEAN NOT NULL DEFAULT FALSE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 disabled_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS sessions (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 token_hash CHAR(64) NOT NULL UNIQUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expiry ON sessions(expires_at);
CREATE TABLE IF NOT EXISTS videos (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 video_key TEXT NOT NULL UNIQUE,
 video_url TEXT NOT NULL,
 thumbnail_url TEXT,
 caption VARCHAR(2200) NOT NULL DEFAULT '',
 duration_seconds DOUBLE PRECISION NOT NULL CHECK(duration_seconds BETWEEN 1 AND 600),
 music_title VARCHAR(140) NOT NULL DEFAULT 'Original audio',
 visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public','followers','private')),
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 moderated_at TIMESTAMPTZ,
 moderated_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_videos_approved ON videos(status,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_videos_author ON videos(author_id,created_at DESC);
CREATE TABLE IF NOT EXISTS likes (
 user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(user_id,video_id)
);
CREATE TABLE IF NOT EXISTS bookmarks (
 user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(user_id,video_id)
);
CREATE TABLE IF NOT EXISTS comments (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
 body VARCHAR(500) NOT NULL CHECK(length(trim(body))>0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_comments_video ON comments(video_id,created_at DESC) WHERE deleted_at IS NULL;
CREATE TABLE IF NOT EXISTS follows (
 follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','accepted')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(follower_id,following_id),
 CONSTRAINT no_follow_self CHECK(follower_id<>following_id)
);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id,status);
CREATE TABLE IF NOT EXISTS blocks (
 blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY(blocker_id,blocked_id),
 CONSTRAINT no_block_self CHECK(blocker_id<>blocked_id)
);
CREATE TABLE IF NOT EXISTS reports (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 target_type TEXT NOT NULL CHECK(target_type IN ('video','comment','user')),
 target_id UUID NOT NULL,
 reason TEXT NOT NULL CHECK(reason IN ('bullying','sexual_content','violence','hate','spam','privacy','other')),
 detail VARCHAR(500) NOT NULL DEFAULT '',
 status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','reviewed','dismissed')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reports_open ON reports(status,created_at) WHERE status='open';
CREATE TABLE IF NOT EXISTS notifications (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
 video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
 kind TEXT NOT NULL,
 body VARCHAR(300),
 is_read BOOLEAN NOT NULL DEFAULT FALSE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id,created_at DESC);
CREATE TABLE IF NOT EXISTS rate_events (
 id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
 key CHAR(64) NOT NULL,
 at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rate_events_key_at ON rate_events(key,at);
