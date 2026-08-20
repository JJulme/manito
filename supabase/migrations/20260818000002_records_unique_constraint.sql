-- Add updated_at column and unique constraint for upserting records
ALTER TABLE public.records ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'records_room_user_type_unique'
    ) THEN
        ALTER TABLE public.records ADD CONSTRAINT records_room_user_type_unique UNIQUE (room_id, user_id, record_type);
    END IF;
END $$;
