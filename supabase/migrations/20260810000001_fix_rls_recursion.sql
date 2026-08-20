-- Fix infinite recursion in RLS policies for rooms and room_members

-- 1. Helper function for RLS without recursion (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.is_room_member(p_room_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.room_members WHERE room_id = p_room_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_room_host(p_room_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.rooms WHERE room_id = p_room_id AND host_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2. Fix Rooms Policy
DROP POLICY IF EXISTS "Allow read rooms if member or host" ON public.rooms;
CREATE POLICY "Allow read rooms if member or host" ON public.rooms FOR SELECT TO authenticated 
    USING (host_id = auth.uid() OR public.is_room_member(room_id, auth.uid()));

-- 3. Fix Room Members Policy
DROP POLICY IF EXISTS "Allow read room members" ON public.room_members;
CREATE POLICY "Allow read room members" ON public.room_members FOR SELECT TO authenticated 
    USING (user_id = auth.uid() OR public.is_room_member(room_id, auth.uid()) OR public.is_room_host(room_id, auth.uid()));

-- 4. Fix Records Policy
DROP POLICY IF EXISTS "Allow read records in room" ON public.records;
CREATE POLICY "Allow read records in room" ON public.records FOR SELECT TO authenticated 
    USING (public.is_room_member(room_id, auth.uid()) OR public.is_room_host(room_id, auth.uid()));
