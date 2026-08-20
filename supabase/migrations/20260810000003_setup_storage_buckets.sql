-- Setup Storage Buckets and Policies

-- 1. Create buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('records', 'records', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']),
    ('profile-image', 'profile-image', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']),
    ('post-image', 'post-image', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']),
    ('auto-reply-image', 'auto-reply-image', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'])
ON CONFLICT (id) DO UPDATE SET 
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];

-- 2. Drop old restrictive storage policies
DROP POLICY IF EXISTS "Allow public select objects" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated insert objects" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update objects" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated delete objects" ON storage.objects;

-- 3. Create comprehensive storage policies
CREATE POLICY "Allow public select objects" ON storage.objects 
    FOR SELECT TO public 
    USING (bucket_id IN ('records', 'profile-image', 'post-image', 'auto-reply-image'));

CREATE POLICY "Allow authenticated insert objects" ON storage.objects 
    FOR INSERT TO authenticated 
    WITH CHECK (bucket_id IN ('records', 'profile-image', 'post-image', 'auto-reply-image'));

CREATE POLICY "Allow authenticated update objects" ON storage.objects 
    FOR UPDATE TO authenticated 
    USING (bucket_id IN ('records', 'profile-image', 'post-image', 'auto-reply-image'));

CREATE POLICY "Allow authenticated delete objects" ON storage.objects 
    FOR DELETE TO authenticated 
    USING (bucket_id IN ('records', 'profile-image', 'post-image', 'auto-reply-image'));
