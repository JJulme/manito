-- 1. Ensure unique index on records
CREATE UNIQUE INDEX IF NOT EXISTS records_room_user_type_idx ON public.records(room_id, user_id, record_type);

-- 2. Create server-side finalize function
CREATE OR REPLACE FUNCTION public.finalize_game_and_fill_auto_replies(p_room_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_member RECORD;
    v_user RECORD;
    v_perform_blocks JSONB;
    v_guess_blocks JSONB;
BEGIN
    -- Loop through all accepted members of this room
    FOR v_member IN 
        SELECT rm.user_id 
        FROM public.room_members rm 
        WHERE rm.room_id = p_room_id 
          AND rm.join_status = '✔️'
    LOOP
        -- Get user auto-reply presets
        SELECT * INTO v_user 
        FROM public.users 
        WHERE user_id = v_member.user_id;

        IF FOUND THEN
            -- A. Check if MISSION_PERFORM record exists
            IF NOT EXISTS (
                SELECT 1 FROM public.records 
                WHERE room_id = p_room_id 
                  AND user_id = v_member.user_id 
                  AND record_type = 'MISSION_PERFORM'
            ) THEN
                v_perform_blocks := '[]'::jsonb;
                IF v_user.manito_auto_reply_img IS NOT NULL AND TRIM(v_user.manito_auto_reply_img) <> '' THEN
                    v_perform_blocks := v_perform_blocks || jsonb_build_object('type', 'image', 'value', v_user.manito_auto_reply_img);
                END IF;
                IF v_user.manito_auto_reply_text IS NOT NULL AND TRIM(v_user.manito_auto_reply_text) <> '' THEN
                    v_perform_blocks := v_perform_blocks || jsonb_build_object('type', 'text', 'value', v_user.manito_auto_reply_text);
                END IF;

                IF jsonb_array_length(v_perform_blocks) = 0 THEN
                    v_perform_blocks := jsonb_build_array(jsonb_build_object('type', 'text', 'value', '비밀리에 마니또 작전을 완료했습니다!'));
                END IF;

                INSERT INTO public.records (room_id, user_id, record_type, content, is_deleted, created_at)
                VALUES (p_room_id, v_member.user_id, 'MISSION_PERFORM', v_perform_blocks, false, NOW())
                ON CONFLICT (room_id, user_id, record_type) DO NOTHING;
            END IF;

            -- B. Check if SUSPECT_GUESS record exists
            IF NOT EXISTS (
                SELECT 1 FROM public.records 
                WHERE room_id = p_room_id 
                  AND user_id = v_member.user_id 
                  AND record_type = 'SUSPECT_GUESS'
            ) THEN
                v_guess_blocks := '[]'::jsonb;
                IF v_user.guess_auto_reply_img IS NOT NULL AND TRIM(v_user.guess_auto_reply_img) <> '' THEN
                    v_guess_blocks := v_guess_blocks || jsonb_build_object('type', 'image', 'value', v_user.guess_auto_reply_img);
                END IF;
                IF v_user.guess_auto_reply_text IS NOT NULL AND TRIM(v_user.guess_auto_reply_text) <> '' THEN
                    v_guess_blocks := v_guess_blocks || jsonb_build_object('type', 'text', 'value', v_user.guess_auto_reply_text);
                END IF;

                IF jsonb_array_length(v_guess_blocks) = 0 THEN
                    v_guess_blocks := jsonb_build_array(jsonb_build_object('type', 'text', 'value', '마니또를 찾지 못했습니다.'));
                END IF;

                INSERT INTO public.records (room_id, user_id, record_type, suspect_user_id, content, is_deleted, created_at)
                VALUES (p_room_id, v_member.user_id, 'SUSPECT_GUESS', NULL, v_guess_blocks, false, NOW())
                ON CONFLICT (room_id, user_id, record_type) DO NOTHING;
            END IF;
        END IF;
    END LOOP;

    -- Update room status to ENDED
    UPDATE public.rooms
    SET status = 'ENDED'
    WHERE room_id = p_room_id;

    RETURN jsonb_build_object('success', true, 'room_id', p_room_id);
END;
$$;

-- 3. Update cron job function
CREATE OR REPLACE FUNCTION public.process_rooms_and_games_cron()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_room RECORD;
BEGIN
    DELETE FROM public.rooms 
    WHERE status = 'WAITING' 
      AND created_at < NOW() - INTERVAL '10 minutes';

    FOR v_room IN
        SELECT room_id 
        FROM public.rooms 
        WHERE status = 'ONGOING' 
          AND game_end_time IS NOT NULL 
          AND game_end_time <= NOW()
    LOOP
        PERFORM public.finalize_game_and_fill_auto_replies(v_room.room_id);
    END LOOP;
END;
$$;
