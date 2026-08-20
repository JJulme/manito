-- Migration for 4-tier Comment Unread Badge System

CREATE OR REPLACE FUNCTION public.mark_record_comments_as_read(
    p_record_id BIGINT,
    p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.comment_read_logs
    SET is_read = TRUE,
        read_at = NOW()
    WHERE user_id = p_user_id
      AND is_read = FALSE
      AND comment_id IN (
          SELECT comment_id 
          FROM public.comments 
          WHERE record_id = p_record_id
      );
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_room_comments_as_read(
    p_room_id UUID,
    p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.comment_read_logs
    SET is_read = TRUE,
        read_at = NOW()
    WHERE user_id = p_user_id
      AND is_read = FALSE
      AND comment_id IN (
          SELECT c.comment_id 
          FROM public.comments c
          JOIN public.records r ON c.record_id = r.record_id
          WHERE r.room_id = p_room_id
      );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_unread_comment_counts(
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total BIGINT;
    v_room_counts JSONB;
    v_record_counts JSONB;
BEGIN
    -- 1. Total unread
    SELECT COUNT(*)
    INTO v_total
    FROM public.comment_read_logs
    WHERE user_id = p_user_id AND is_read = FALSE;

    -- 2. Per-room unread
    SELECT COALESCE(jsonb_object_agg(sub.room_id::text, sub.cnt), '{}'::jsonb)
    INTO v_room_counts
    FROM (
        SELECT r.room_id, COUNT(*) AS cnt
        FROM public.comment_read_logs crl
        JOIN public.comments c ON crl.comment_id = c.comment_id
        JOIN public.records r ON c.record_id = r.record_id
        WHERE crl.user_id = p_user_id AND crl.is_read = FALSE
        GROUP BY r.room_id
    ) sub;

    -- 3. Per-record unread
    SELECT COALESCE(jsonb_object_agg(sub.record_id::text, sub.cnt), '{}'::jsonb)
    INTO v_record_counts
    FROM (
        SELECT c.record_id, COUNT(*) AS cnt
        FROM public.comment_read_logs crl
        JOIN public.comments c ON crl.comment_id = c.comment_id
        WHERE crl.user_id = p_user_id AND crl.is_read = FALSE
        GROUP BY c.record_id
    ) sub;

    RETURN jsonb_build_object(
        'total', v_total,
        'rooms', v_room_counts,
        'records', v_record_counts
    );
END;
$$;
