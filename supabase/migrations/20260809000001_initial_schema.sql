-- Migration: 20260809000001_initial_schema.sql
-- Description: Rebuild database with 9 core tables, RLS, Circular Matching RPC, and seed data.

-- 1. Drop Legacy Tables & Types (Cascade)
DROP TABLE IF EXISTS public.badges_comment CASCADE;
DROP TABLE IF EXISTS public.badges CASCADE;
DROP TABLE IF EXISTS public.mission_propose CASCADE;
DROP TABLE IF EXISTS public.reports_post CASCADE;
DROP TABLE IF EXISTS public.reports_user CASCADE;
DROP TABLE IF EXISTS public.blacklist CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.mission_tasks CASCADE;
DROP TABLE IF EXISTS public.mission_participants CASCADE;
DROP TABLE IF EXISTS public.mission_sessions CASCADE;
DROP TABLE IF EXISTS public.missions CASCADE;
DROP TABLE IF EXISTS public.mission_content CASCADE;
DROP TABLE IF EXISTS public.content_library CASCADE;
DROP TABLE IF EXISTS public.friend_requests CASCADE;
DROP TABLE IF EXISTS public.friends CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP TYPE IF EXISTS public.mission_type CASCADE;
DROP TYPE IF EXISTS public.session_status CASCADE;
DROP TYPE IF EXISTS public.task_status CASCADE;

-- 2. Create the 9 New Tables

-- 2.1 Users
CREATE TABLE public.users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    unique_code VARCHAR(8) UNIQUE NOT NULL,
    name VARCHAR(12) NOT NULL,
    profile_image_url TEXT NULL,
    status_message VARCHAR(30) NULL,
    manito_auto_reply_text VARCHAR(100) NULL,
    manito_auto_reply_img TEXT NULL,
    guess_auto_reply_text VARCHAR(100) NULL,
    guess_auto_reply_img TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.2 Friendships
CREATE TABLE public.friendships (
    friendship_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('REQUESTED', 'ACCEPTED', 'BLOCKED')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ NULL,
    CONSTRAINT friendships_no_self CHECK (requester_id <> receiver_id),
    CONSTRAINT friendships_unique_pair UNIQUE (requester_id, receiver_id)
);

-- 2.3 Rooms
CREATE TABLE public.rooms (
    room_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'WAITING' CHECK (status IN ('WAITING', 'PREPARING', 'ONGOING', 'ENDED')),
    mission_category VARCHAR(50) NULL,
    game_start_time TIMESTAMPTZ NULL,
    game_end_time TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.4 Missions
CREATE TABLE public.missions (
    mission_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    content_ko TEXT NOT NULL,
    content_en TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.5 Room_Members
CREATE TABLE public.room_members (
    room_member_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    target_user_id UUID NULL REFERENCES public.users(user_id) ON DELETE SET NULL,
    join_status VARCHAR(10) NOT NULL DEFAULT '-' CHECK (join_status IN ('-', '✔️', 'X')),
    assigned_mission_id BIGINT NULL REFERENCES public.missions(mission_id) ON DELETE SET NULL,
    is_mission_selected BOOLEAN DEFAULT FALSE,
    is_invite_viewed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT room_members_unique_room_user UNIQUE (room_id, user_id)
);

-- 2.6 Mission_Candidates
CREATE TABLE public.mission_candidates (
    candidate_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_member_id BIGINT NOT NULL REFERENCES public.room_members(room_member_id) ON DELETE CASCADE,
    candidate_mission_1_id BIGINT NOT NULL REFERENCES public.missions(mission_id) ON DELETE CASCADE,
    candidate_mission_2_id BIGINT NOT NULL REFERENCES public.missions(mission_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.7 Records
CREATE TABLE public.records (
    record_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    record_type VARCHAR(20) NOT NULL CHECK (record_type IN ('MISSION_PERFORM', 'SUSPECT_GUESS')),
    suspect_user_id UUID NULL REFERENCES public.users(user_id) ON DELETE SET NULL,
    content JSONB NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.8 Comments
CREATE TABLE public.comments (
    comment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    record_id BIGINT NOT NULL REFERENCES public.records(record_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.9 Comment_Read_Logs
CREATE TABLE public.comment_read_logs (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    comment_id BIGINT NOT NULL REFERENCES public.comments(comment_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ NULL,
    CONSTRAINT comment_read_logs_unique UNIQUE (comment_id, user_id)
);

-- 3. Indexes for Performance
CREATE INDEX idx_users_unique_code ON public.users(unique_code);
CREATE INDEX idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX idx_friendships_receiver ON public.friendships(receiver_id);
CREATE INDEX idx_rooms_host ON public.rooms(host_id);
CREATE INDEX idx_rooms_status ON public.rooms(status);
CREATE INDEX idx_room_members_room ON public.room_members(room_id);
CREATE INDEX idx_room_members_user ON public.room_members(user_id);
CREATE INDEX idx_records_room ON public.records(room_id);
CREATE INDEX idx_records_user ON public.records(user_id);
CREATE INDEX idx_comments_record ON public.comments(record_id);
CREATE INDEX idx_comment_read_logs_user_read ON public.comment_read_logs(user_id, is_read);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_read_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Users: Everyone authenticated can read users (for friend search / profiles), users can update their own
CREATE POLICY "Allow authenticated read users" ON public.users FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow user update self" ON public.users FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Allow user insert self" ON public.users FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Friendships
CREATE POLICY "Allow users to read own friendships" ON public.friendships FOR SELECT TO authenticated 
    USING (auth.uid() = requester_id OR auth.uid() = receiver_id);
CREATE POLICY "Allow users to create friendships" ON public.friendships FOR INSERT TO authenticated 
    WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Allow users to update own friendships" ON public.friendships FOR UPDATE TO authenticated 
    USING (auth.uid() = requester_id OR auth.uid() = receiver_id);
CREATE POLICY "Allow users to delete own friendships" ON public.friendships FOR DELETE TO authenticated 
    USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

-- Missions: Public readable for authenticated users
CREATE POLICY "Allow authenticated read missions" ON public.missions FOR SELECT TO authenticated USING (true);

-- Rooms: Readable if user is host or member
CREATE POLICY "Allow read rooms if member or host" ON public.rooms FOR SELECT TO authenticated 
    USING (host_id = auth.uid() OR EXISTS (SELECT 1 FROM public.room_members rm WHERE rm.room_id = rooms.room_id AND rm.user_id = auth.uid()));
CREATE POLICY "Allow create room" ON public.rooms FOR INSERT TO authenticated WITH CHECK (host_id = auth.uid());
CREATE POLICY "Allow host update room" ON public.rooms FOR UPDATE TO authenticated USING (host_id = auth.uid());
CREATE POLICY "Allow host delete room" ON public.rooms FOR DELETE TO authenticated USING (host_id = auth.uid());

-- Room Members
CREATE POLICY "Allow read room members" ON public.room_members FOR SELECT TO authenticated 
    USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.room_members rm2 WHERE rm2.room_id = room_members.room_id AND rm2.user_id = auth.uid()) OR EXISTS (SELECT 1 FROM public.rooms r WHERE r.room_id = room_members.room_id AND r.host_id = auth.uid()));
CREATE POLICY "Allow insert room members" ON public.room_members FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow update room member" ON public.room_members FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow delete room member" ON public.room_members FOR DELETE TO authenticated USING (true);

-- Mission Candidates
CREATE POLICY "Allow member read candidates" ON public.mission_candidates FOR SELECT TO authenticated 
    USING (EXISTS (SELECT 1 FROM public.room_members rm WHERE rm.room_member_id = mission_candidates.room_member_id AND rm.user_id = auth.uid()));

-- Records
CREATE POLICY "Allow read records in room" ON public.records FOR SELECT TO authenticated 
    USING (EXISTS (SELECT 1 FROM public.room_members rm WHERE rm.room_id = records.room_id AND rm.user_id = auth.uid()));
CREATE POLICY "Allow insert own record" ON public.records FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Allow update own record" ON public.records FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Comments
CREATE POLICY "Allow read comments in record" ON public.comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow insert comment" ON public.comments FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Allow delete own comment" ON public.comments FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Comment Read Logs
CREATE POLICY "Allow read own logs" ON public.comment_read_logs FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Allow update own logs" ON public.comment_read_logs FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- 6. Trigger: Auto Create Comment Read Logs on New Comment
CREATE OR REPLACE FUNCTION public.fn_on_comment_created()
RETURNS TRIGGER AS $$
DECLARE
    v_room_id UUID;
    v_member RECORD;
BEGIN
    -- get room_id from record
    SELECT room_id INTO v_room_id FROM public.records WHERE record_id = NEW.record_id;
    
    -- For each member in the room
    FOR v_member IN SELECT user_id FROM public.room_members WHERE room_id = v_room_id LOOP
        IF v_member.user_id = NEW.user_id THEN
            INSERT INTO public.comment_read_logs (comment_id, user_id, is_read, read_at)
            VALUES (NEW.comment_id, v_member.user_id, TRUE, NOW())
            ON CONFLICT (comment_id, user_id) DO NOTHING;
        ELSE
            INSERT INTO public.comment_read_logs (comment_id, user_id, is_read, read_at)
            VALUES (NEW.comment_id, v_member.user_id, FALSE, NULL)
            ON CONFLICT (comment_id, user_id) DO NOTHING;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_on_comment_created ON public.comments;
CREATE TRIGGER trg_on_comment_created
AFTER INSERT ON public.comments
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_comment_created();

-- 7. RPC Function: 1:1 Circular Matching & Setup Mission Candidates
CREATE OR REPLACE FUNCTION public.start_game_and_match(p_room_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_members UUID[];
    v_member_ids BIGINT[];
    v_count INT;
    v_i INT;
    v_category VARCHAR(50);
    v_mission1_id BIGINT;
    v_mission2_id BIGINT;
    v_member_id BIGINT;
    v_user_id UUID;
    v_target_id UUID;
BEGIN
    -- 1. Fetch room category
    SELECT mission_category INTO v_category FROM public.rooms WHERE room_id = p_room_id;

    -- 2. Fetch accepted members in random order
    SELECT array_agg(user_id), array_agg(room_member_id)
    INTO v_members, v_member_ids
    FROM (
        SELECT user_id, room_member_id 
        FROM public.room_members 
        WHERE room_id = p_room_id AND join_status = '✔️'
        ORDER BY random()
    ) sub;

    v_count := cardinality(v_members);
    IF v_count < 2 THEN
        RAISE EXCEPTION 'At least 2 participating members are required to start.';
    END IF;

    -- 3. Assign circular target: 1->2, 2->3, ..., N->1
    FOR v_i IN 1..v_count LOOP
        v_user_id := v_members[v_i];
        v_member_id := v_member_ids[v_i];
        
        IF v_i = v_count THEN
            v_target_id := v_members[1];
        ELSE
            v_target_id := v_members[v_i + 1];
        END IF;

        -- Update target_user_id
        UPDATE public.room_members 
        SET target_user_id = v_target_id,
            is_mission_selected = FALSE
        WHERE room_member_id = v_member_id;

        -- Pick 2 random missions for candidate
        SELECT mission_id INTO v_mission1_id 
        FROM public.missions 
        WHERE (v_category IS NULL OR category = v_category) AND is_active = TRUE 
        ORDER BY random() LIMIT 1;

        SELECT mission_id INTO v_mission2_id 
        FROM public.missions 
        WHERE (v_category IS NULL OR category = v_category) AND is_active = TRUE AND mission_id <> v_mission1_id
        ORDER BY random() LIMIT 1;

        -- Fallback if not enough distinct missions in category
        IF v_mission2_id IS NULL THEN
            SELECT mission_id INTO v_mission2_id FROM public.missions WHERE is_active = TRUE ORDER BY random() LIMIT 1;
        END IF;

        -- Insert into mission_candidates
        INSERT INTO public.mission_candidates (room_member_id, candidate_mission_1_id, candidate_mission_2_id)
        VALUES (v_member_id, v_mission1_id, v_mission2_id);
    END LOOP;

    -- 4. Update room status to PREPARING
    UPDATE public.rooms 
    SET status = 'PREPARING' 
    WHERE room_id = p_room_id;

    RETURN jsonb_build_object('success', true, 'member_count', v_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. RPC Function: Finalize Mission Selection (User select or Timeout fallback)
CREATE OR REPLACE FUNCTION public.finalize_member_mission(
    p_room_member_id BIGINT,
    p_selected_mission_id BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_mission_id BIGINT;
    v_c1 BIGINT;
    v_c2 BIGINT;
BEGIN
    IF p_selected_mission_id IS NOT NULL THEN
        v_mission_id := p_selected_mission_id;
    ELSE
        -- Timeout fallback: select random candidate
        SELECT candidate_mission_1_id, candidate_mission_2_id 
        INTO v_c1, v_c2 
        FROM public.mission_candidates 
        WHERE room_member_id = p_room_member_id 
        ORDER BY candidate_id DESC LIMIT 1;
        
        IF random() < 0.5 THEN
            v_mission_id := v_c1;
        ELSE
            v_mission_id := v_c2;
        END IF;
    END IF;

    UPDATE public.room_members 
    SET assigned_mission_id = v_mission_id,
        is_mission_selected = TRUE 
    WHERE room_member_id = p_room_member_id;

    RETURN jsonb_build_object('success', true, 'assigned_mission_id', v_mission_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Realtime Publication
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.rooms;
    EXCEPTION WHEN duplicate_object THEN END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.room_members;
    EXCEPTION WHEN duplicate_object THEN END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.records;
    EXCEPTION WHEN duplicate_object THEN END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
    EXCEPTION WHEN duplicate_object THEN END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.comment_read_logs;
    EXCEPTION WHEN duplicate_object THEN END;
END $$;

-- 10. Seed Data: 30 Presets from legacy mission_content
INSERT INTO public.missions (category, content_ko, content_en, is_active) VALUES
('daily', '음식 먹여주기', 'Feed You!', true),
('daily', '3가지 이상 칭찬하기', '3+ Compliments Challenge', true),
('daily', '단둘이 사진찍기', 'Our Exclusive Selfie', true),
('daily', '고민 들어주기', 'Lend an Ear', true),
('daily', '재미 없어도 웃어주기', 'Laugh on Demand', true),
('daily', '모든 의견 수긍하기', 'No Disagreements Allowed', true),
('daily', '하자는 대로 다 하기', 'The ''Yes-Man'' Challenge', true),
('daily', '칭찬 폭격', 'Compliment Overload', true),
('daily', '웃겨주기', 'Make ''Em Laugh!', true),
('daily', '집에 데려다 주기', 'Get You Home Safely', true),
('daily', '음료 또는 간식 사주기', 'Treat Them to a Drink/Snack', true),
('school', '필기구 빌려주기', 'Lend a Pen', true),
('school', '공부 도와주기', 'Help with Studying', true),
('school', '간식 나눠 먹기', 'Share a Snack', true),
('school', '단둘이 사진찍기', 'Our Exclusive Selfie', true),
('school', '3가지 이상 칭찬하기', '3+ Compliments Challenge', true),
('school', '재미 없어도 웃어주기', 'Laugh on Demand', true),
('school', '하자는 대로 다 하기', 'The ''Yes-Man'' Challenge', true),
('school', '집에 데려다 주기', 'Get You Home Safely', true),
('school', '모든 의견 수긍하기', 'No Disagreements Allowed', true),
('school', '외모 체크 해주기', 'Help a Friend with Their Look', true),
('school', '점심시간에 같이 산책하기', 'Lunchtime Stroll', true),
('school', '등교(하교)길에 가방 들어주기', 'designated bag carrier', true),
('work', '업무 도와주기', 'Help a Colleague', true),
('work', '업무 능력 칭찬해주기', 'Compliment a Colleague''s Work', true),
('work', '음료 주기', 'Treat to a Drink', true),
('work', '간식 주기', 'Share a Snack', true),
('work', '재미없어도 웃어주기', 'Laugh on Demand', true),
('work', '외모 체크 해주기', 'Help a Friend with Their Look', true),
('work', '응원의 한마디 해주기', 'Pump up a friend', true);
