-- ==============================================================================
-- Migration: 20260902000003_add_public_users_fk.sql
-- Description: Add foreign key constraints to public.users for PostgREST joins
-- ==============================================================================

ALTER TABLE public.chat_members 
    DROP CONSTRAINT IF EXISTS chat_members_user_id_fkey,
    ADD CONSTRAINT chat_members_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE public.chat_messages 
    DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey,
    ADD CONSTRAINT chat_messages_sender_id_fkey 
    FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE public.chat_rooms 
    DROP CONSTRAINT IF EXISTS chat_rooms_created_by_fkey,
    ADD CONSTRAINT chat_rooms_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
