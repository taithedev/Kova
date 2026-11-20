-- Kova 0.8: both tables are additive and preserve existing user data.
CREATE TABLE IF NOT EXISTS public.video_reposts (
 user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 video_id uuid NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY (user_id,video_id)
);
CREATE INDEX IF NOT EXISTS idx_kova_reposts_video ON public.video_reposts(video_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_kova_reposts_user_time ON public.video_reposts(user_id,created_at DESC);
CREATE TABLE IF NOT EXISTS public.video_not_interested (
 user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 video_id uuid NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY (user_id,video_id)
);
CREATE INDEX IF NOT EXISTS idx_kova_not_interested_user ON public.video_not_interested(user_id);
