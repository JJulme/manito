-- Migration: 20260809000002_user_auth_sync.sql
-- Description: Function and trigger to auto-create user profile with 8-character unique code upon auth sign-up, and backfill existing auth users.

-- 1. Helper function to generate 8-digit unique code
CREATE OR REPLACE FUNCTION public.generate_unique_code()
RETURNS VARCHAR(8) AS $$
DECLARE
    v_code VARCHAR(8);
    v_exists BOOLEAN;
BEGIN
    LOOP
        v_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
        SELECT EXISTS (SELECT 1 FROM public.users WHERE unique_code = v_code) INTO v_exists;
        IF NOT v_exists THEN
            RETURN v_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger function on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (
        user_id,
        unique_code,
        name,
        created_at
    )
    VALUES (
        NEW.id,
        public.generate_unique_code(),
        substring(COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', '사용자') from 1 for 12),
        NEW.created_at
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_auth_user();

-- 3. Backfill existing auth.users into public.users
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id, raw_user_meta_data, created_at FROM auth.users LOOP
        INSERT INTO public.users (user_id, unique_code, name, created_at)
        VALUES (
            r.id,
            public.generate_unique_code(),
            substring(COALESCE(r.raw_user_meta_data->>'name', r.raw_user_meta_data->>'full_name', '사용자') from 1 for 12),
            r.created_at
        )
        ON CONFLICT (user_id) DO NOTHING;
    END LOOP;
END $$;
