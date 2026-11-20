-- Kova 0.6: link support reply/status notifications directly to tickets.
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS ticket_id uuid REFERENCES public.support_tickets(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_ticket ON public.notifications(ticket_id) WHERE ticket_id IS NOT NULL;
