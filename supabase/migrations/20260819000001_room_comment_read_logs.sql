-- Create table for tracking room comment last read timestamp
CREATE TABLE IF NOT EXISTS public.room_comment_read_logs (
    room_id UUID NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    last_read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (room_id, user_id)
);

ALTER TABLE public.room_comment_read_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow read own room_comment_read_logs" ON public.room_comment_read_logs;
CREATE POLICY "Allow read own room_comment_read_logs" ON public.room_comment_read_logs
    FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Allow all own room_comment_read_logs" ON public.room_comment_read_logs;
CREATE POLICY "Allow all own room_comment_read_logs" ON public.room_comment_read_logs
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
