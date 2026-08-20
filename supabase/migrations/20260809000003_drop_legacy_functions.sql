-- Migration: 20260809000003_drop_legacy_functions.sql
-- Description: Drop legacy DB functions that reference deleted legacy tables.

DROP FUNCTION IF EXISTS public.block_friend CASCADE;
DROP FUNCTION IF EXISTS public.create_mission_propose CASCADE;
DROP FUNCTION IF EXISTS public.add_random_mission_content CASCADE;
DROP FUNCTION IF EXISTS public.delete_user CASCADE;
DROP FUNCTION IF EXISTS public.fetch_missions CASCADE;
DROP FUNCTION IF EXISTS public.create_profile CASCADE;
DROP FUNCTION IF EXISTS public.send_friend_request CASCADE;
DROP FUNCTION IF EXISTS public.create_group_room CASCADE;
DROP FUNCTION IF EXISTS public.fetch_incomplete_missions CASCADE;
DROP FUNCTION IF EXISTS public.accept_friend_request CASCADE;
DROP FUNCTION IF EXISTS public.comment_insert CASCADE;
DROP FUNCTION IF EXISTS public.reject_friend_request CASCADE;
DROP FUNCTION IF EXISTS public.fetch_mission_contents_from_ids CASCADE;
DROP FUNCTION IF EXISTS public.accept_mission CASCADE;
DROP FUNCTION IF EXISTS public.get_user_profile_safe CASCADE;
DROP FUNCTION IF EXISTS public.mission_status_guess CASCADE;
DROP FUNCTION IF EXISTS public.mission_complete CASCADE;
DROP FUNCTION IF EXISTS public.missions_auto_complete CASCADE;
