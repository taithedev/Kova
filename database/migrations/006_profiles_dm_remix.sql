-- Kova 0.9.0 additive profile, video and private-message schema
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age_restricted boolean NOT NULL DEFAULT false;
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS allow_remix boolean NOT NULL DEFAULT false;
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS source_video_id uuid REFERENCES public.videos(id) ON DELETE SET NULL;
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS description text NOT NULL DEFAULT '';
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS remix_type text;
DO $check$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='kova_remix_type_check') THEN
  ALTER TABLE public.videos ADD CONSTRAINT kova_remix_type_check
   CHECK (remix_type IS NULL OR remix_type IN ('stitch','duet'));
 END IF;
END $check$;
ALTER TABLE public.videos ALTER COLUMN allow_remix SET DEFAULT false;
CREATE TABLE IF NOT EXISTS public.direct_messages (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 recipient_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 body text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
 created_at timestamptz NOT NULL DEFAULT now(),
 deleted_at timestamptz,
 CHECK (sender_id <> recipient_id)
);
CREATE INDEX IF NOT EXISTS idx_kova_dm_recipient ON public.direct_messages(recipient_id,sender_id,created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_kova_dm_sender ON public.direct_messages(sender_id,recipient_id,created_at DESC) WHERE deleted_at IS NULL;
CREATE TABLE IF NOT EXISTS public.video_mentions (
 video_id uuid NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
 mentioned_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 PRIMARY KEY(video_id,mentioned_id)
);
CREATE INDEX IF NOT EXISTS idx_kova_mentions_target ON public.video_mentions(mentioned_id);
CREATE INDEX IF NOT EXISTS idx_kova_video_source ON public.videos(source_video_id) WHERE source_video_id IS NOT NULL;
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_target_type_check;
ALTER TABLE public.reports ADD CONSTRAINT reports_target_type_check
 CHECK (target_type IN ('video','comment','user','message'));
