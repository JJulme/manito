-- Enable REPLICA IDENTITY FULL for rooms and room_members so Supabase Realtime delivers all column values on DELETE events
ALTER TABLE public.rooms REPLICA IDENTITY FULL;
ALTER TABLE public.room_members REPLICA IDENTITY FULL;
