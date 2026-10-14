-- ==============================================================================
-- Migration: 20260902000002_fix_chat_rls_recursion.sql
-- Description: Fix infinite recursion in RLS policies for chat_members, chat_rooms, and chat_messages
-- ==============================================================================

-- 1. Helper function for chat RLS without recursion (SECURITY DEFINER STABLE)
CREATE OR REPLACE FUNCTION public.is_chat_member(p_room_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.chat_members
        WHERE room_id = p_room_id
          AND user_id = p_user_id
          AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2. Fix chat_rooms Policies
DROP POLICY IF EXISTS "Users can view chat rooms they belong to" ON public.chat_rooms;
CREATE POLICY "Users can view chat rooms they belong to" ON public.chat_rooms
    FOR SELECT TO authenticated
    USING (
        created_by = auth.uid() OR public.is_chat_member(id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can update chat rooms they belong to" ON public.chat_rooms;
CREATE POLICY "Users can update chat rooms they belong to" ON public.chat_rooms
    FOR UPDATE TO authenticated
    USING (
        created_by = auth.uid() OR public.is_chat_member(id, auth.uid())
    );

-- 3. Fix chat_members Policies
DROP POLICY IF EXISTS "Users can view members of their chat rooms" ON public.chat_members;
CREATE POLICY "Users can view members of their chat rooms" ON public.chat_members
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid() OR public.is_chat_member(room_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can update their own membership in chat rooms" ON public.chat_members;
CREATE POLICY "Users can update their own membership in chat rooms" ON public.chat_members
    FOR UPDATE TO authenticated
    USING (
        user_id = auth.uid()
    );

-- 4. Fix chat_messages Policies
DROP POLICY IF EXISTS "Users can view messages of their chat rooms" ON public.chat_messages;
CREATE POLICY "Users can view messages of their chat rooms" ON public.chat_messages
    FOR SELECT TO authenticated
    USING (
        public.is_chat_member(room_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can insert messages into their chat rooms" ON public.chat_messages;
CREATE POLICY "Users can insert messages into their chat rooms" ON public.chat_messages
    FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = auth.uid() AND public.is_chat_member(room_id, auth.uid())
    );
