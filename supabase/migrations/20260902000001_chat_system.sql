-- ==============================================================================
-- Migration: 20260902000001_chat_system.sql
-- Description: 1:1 and Group Chat System with Realtime, Unread Tracking, and Media
-- ==============================================================================

-- 1. Chat Rooms Table
CREATE TABLE IF NOT EXISTS public.chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL CHECK (type IN ('DIRECT', 'GROUP')),
    title TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Chat Members Table
CREATE TABLE IF NOT EXISTS public.chat_members (
    room_id UUID REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    last_read_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    custom_title TEXT,
    PRIMARY KEY (room_id, user_id)
);

-- 3. Chat Messages Table
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('TEXT', 'IMAGE', 'EMOTICON', 'SYSTEM')),
    content TEXT,
    image_urls TEXT[],
    emoticon_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for optimal performance
CREATE INDEX IF NOT EXISTS idx_chat_rooms_updated ON public.chat_rooms(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_members_user ON public.chat_members(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_time ON public.chat_messages(room_id, created_at ASC);

-- 4. Storage Bucket for Chat Images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('chat-images', 'chat-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif', 'image/gif'])
ON CONFLICT (id) DO UPDATE SET 
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif', 'image/gif'];

-- Storage Policies for chat-images
CREATE POLICY "Allow public select chat-images" ON storage.objects 
    FOR SELECT TO public 
    USING (bucket_id = 'chat-images');

CREATE POLICY "Allow authenticated insert chat-images" ON storage.objects 
    FOR INSERT TO authenticated 
    WITH CHECK (bucket_id = 'chat-images');

-- 5. Trigger to update chat_rooms.updated_at on message insert
CREATE OR REPLACE FUNCTION public.handle_chat_message_inserted()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.chat_rooms
    SET updated_at = NEW.created_at
    WHERE id = NEW.room_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_chat_message_inserted ON public.chat_messages;
CREATE TRIGGER tr_chat_message_inserted
AFTER INSERT ON public.chat_messages
FOR EACH ROW EXECUTE FUNCTION public.handle_chat_message_inserted();

-- 6. Enable Realtime Replication
ALTER TABLE public.chat_rooms REPLICA IDENTITY FULL;
ALTER TABLE public.chat_members REPLICA IDENTITY FULL;
ALTER TABLE public.chat_messages REPLICA IDENTITY FULL;

DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_rooms;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_members;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- 7. Enable RLS
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_rooms
CREATE POLICY "Users can view chat rooms they belong to" ON public.chat_rooms
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_members
            WHERE chat_members.room_id = chat_rooms.id
              AND chat_members.user_id = auth.uid()
              AND chat_members.is_active = true
        )
    );

CREATE POLICY "Authenticated users can create chat rooms" ON public.chat_rooms
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Users can update chat rooms they belong to" ON public.chat_rooms
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_members
            WHERE chat_members.room_id = chat_rooms.id
              AND chat_members.user_id = auth.uid()
              AND chat_members.is_active = true
        )
    );

-- RLS Policies for chat_members
CREATE POLICY "Users can view members of their chat rooms" ON public.chat_members
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_members AS my_cm
            WHERE my_cm.room_id = chat_members.room_id
              AND my_cm.user_id = auth.uid()
              AND my_cm.is_active = true
        )
    );

CREATE POLICY "Authenticated users can insert chat members" ON public.chat_members
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "Users can update their own membership in chat rooms" ON public.chat_members
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- RLS Policies for chat_messages
CREATE POLICY "Users can view messages of their chat rooms" ON public.chat_messages
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_members
            WHERE chat_members.room_id = chat_messages.room_id
              AND chat_members.user_id = auth.uid()
              AND chat_members.is_active = true
        )
    );

CREATE POLICY "Users can insert messages into their chat rooms" ON public.chat_messages
    FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.chat_members
            WHERE chat_members.room_id = chat_messages.room_id
              AND chat_members.user_id = auth.uid()
              AND chat_members.is_active = true
        )
    );

-- 8. RPC: Get or Create 1:1 Direct Chat Room
CREATE OR REPLACE FUNCTION public.get_or_create_direct_chat_room(p_other_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_my_id UUID := auth.uid();
    v_room_id UUID;
BEGIN
    IF v_my_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF v_my_id = p_other_user_id THEN
        RAISE EXCEPTION 'Cannot create direct chat room with oneself';
    END IF;

    -- Find existing 1:1 room between the two users
    SELECT cm1.room_id INTO v_room_id
    FROM public.chat_members cm1
    JOIN public.chat_members cm2 ON cm1.room_id = cm2.room_id
    JOIN public.chat_rooms r ON r.id = cm1.room_id
    WHERE r.type = 'DIRECT'
      AND cm1.user_id = v_my_id
      AND cm2.user_id = p_other_user_id
    LIMIT 1;

    -- If found, make sure membership is active
    IF v_room_id IS NOT NULL THEN
        UPDATE public.chat_members
        SET is_active = true
        WHERE room_id = v_room_id AND user_id = v_my_id;
        RETURN v_room_id;
    END IF;

    -- If not found, create new DIRECT room
    INSERT INTO public.chat_rooms (type, created_by)
    VALUES ('DIRECT', v_my_id)
    RETURNING id INTO v_room_id;

    -- Add both users as members
    INSERT INTO public.chat_members (room_id, user_id, is_active)
    VALUES 
        (v_room_id, v_my_id, true),
        (v_room_id, p_other_user_id, true);

    RETURN v_room_id;
END;
$$;

-- 9. RPC: Create Group Chat Room
CREATE OR REPLACE FUNCTION public.create_group_chat_room(p_title TEXT, p_member_user_ids UUID[])
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_my_id UUID := auth.uid();
    v_room_id UUID;
    v_uid UUID;
BEGIN
    IF v_my_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Create new GROUP room
    INSERT INTO public.chat_rooms (type, title, created_by)
    VALUES ('GROUP', p_title, v_my_id)
    RETURNING id INTO v_room_id;

    -- Add creator as member
    INSERT INTO public.chat_members (room_id, user_id, is_active)
    VALUES (v_room_id, v_my_id, true)
    ON CONFLICT (room_id, user_id) DO UPDATE SET is_active = true;

    -- Add other members
    IF p_member_user_ids IS NOT NULL THEN
        FOREACH v_uid IN ARRAY p_member_user_ids
        LOOP
            IF v_uid <> v_my_id THEN
                INSERT INTO public.chat_members (room_id, user_id, is_active)
                VALUES (v_room_id, v_uid, true)
                ON CONFLICT (room_id, user_id) DO UPDATE SET is_active = true;
            END IF;
        END LOOP;
    END IF;

    -- Add initial SYSTEM message
    INSERT INTO public.chat_messages (room_id, sender_id, type, content)
    VALUES (v_room_id, v_my_id, 'SYSTEM', '그룹 대화방이 개설되었습니다.');

    RETURN v_room_id;
END;
$$;

-- 10. RPC: Mark Chat Room as Read
CREATE OR REPLACE FUNCTION public.mark_chat_room_as_read(p_room_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_my_id UUID := auth.uid();
BEGIN
    IF v_my_id IS NULL THEN
        RETURN;
    END IF;

    UPDATE public.chat_members
    SET last_read_at = NOW()
    WHERE room_id = p_room_id AND user_id = v_my_id;
END;
$$;

-- 11. RPC: Leave Chat Room
CREATE OR REPLACE FUNCTION public.leave_chat_room(p_room_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_my_id UUID := auth.uid();
    v_my_name TEXT;
    v_room_type TEXT;
BEGIN
    IF v_my_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT type INTO v_room_type FROM public.chat_rooms WHERE id = p_room_id;

    UPDATE public.chat_members
    SET is_active = false
    WHERE room_id = p_room_id AND user_id = v_my_id;

    -- If group room, insert SYSTEM message that user left
    IF v_room_type = 'GROUP' THEN
        SELECT name INTO v_my_name FROM public.users WHERE user_id = v_my_id;
        INSERT INTO public.chat_messages (room_id, sender_id, type, content)
        VALUES (p_room_id, v_my_id, 'SYSTEM', COALESCE(v_my_name, '사용자') || '님이 대화방을 나갔습니다.');
    END IF;
END;
$$;
