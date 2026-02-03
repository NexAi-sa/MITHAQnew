-- Mithaq V2 Schema MVP (Supabase)

-- 1. Users Private (Auto-synced with Auth)
CREATE TABLE users_private (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger to create users_private on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users_private (id, email)
    VALUES (new.id, new.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. Profiles (Seekers & Managed Dependents)
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    role_context TEXT NOT NULL CHECK (role_context IN ('seeker', 'dependent')),
    managed_by_guardian BOOLEAN DEFAULT FALSE,
    guardian_user_id UUID REFERENCES auth.users,
    profile_public_id TEXT UNIQUE NOT NULL,
    first_name TEXT,
    full_name TEXT,
    name_visibility TEXT DEFAULT 'hidden' CHECK (name_visibility IN ('hidden', 'first', 'full_subscribers_only')),
    dob DATE,
    gender TEXT,
    job TEXT,
    city TEXT,
    marital_status TEXT,
    tribe TEXT,
    education_level TEXT,
    smoking TEXT,
    hijab_preference TEXT,
    height INTEGER,
    build TEXT,
    skin_color TEXT,
    relationship TEXT,
    bio TEXT,
    partner_preferences JSONB DEFAULT '{}'::jsonb,
    is_paused BOOLEAN DEFAULT FALSE,
    shufa_card_active BOOLEAN DEFAULT FALSE,
    shufa_card_guardian_name TEXT,
    shufa_card_guardian_title TEXT,
    shufa_card_guardian_phone TEXT,
    shufa_card_is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Guardian Dependents (Join table)
CREATE TABLE guardian_dependents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guardian_user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    dependent_profile_id UUID NOT NULL REFERENCES profiles ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(guardian_user_id, dependent_profile_id)
);

-- 4. Settings
CREATE TABLE settings (
    owner_user_id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    theme_mode TEXT DEFAULT 'system' CHECK (theme_mode IN ('system', 'light', 'dark')),
    language TEXT DEFAULT 'ar' CHECK (language IN ('ar', 'en')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS POLICIES

ALTER TABLE users_private ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardian_dependents ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- users_private: Only owner can read/write
CREATE POLICY "Users can view own private data" ON users_private
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own private data" ON users_private
    FOR UPDATE USING (auth.uid() = id);

-- profiles:
-- 1. Discovery Isolation: Seekers only see Seekers, Guardians only see Dependents
-- 2. Owner can read/write their own profiles

-- Policy for Seekers to discovery other Seekers
CREATE POLICY "Seekers see other seekers" ON profiles
    FOR SELECT USING (
        is_paused = FALSE AND 
        role_context = 'seeker' AND
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE p.owner_user_id = auth.uid() AND p.role_context = 'seeker'
        )
    );

-- Policy for Guardians to discovery other Dependents
CREATE POLICY "Guardians see other dependents" ON profiles
    FOR SELECT USING (
        is_paused = FALSE AND 
        role_context = 'dependent' AND
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE p.owner_user_id = auth.uid() AND p.role_context = 'dependent'
            -- Or check guardian_user_id if that's the link
        )
    );

-- Policy for owners to manage their own records (overrides discovery logic for self)
CREATE POLICY "Users manage own profiles" ON profiles
    FOR ALL USING (
        auth.uid() = owner_user_id OR auth.uid() = guardian_user_id
    );

-- settings: Only owner
CREATE POLICY "Users manage own settings" ON settings
    FOR ALL USING (auth.uid() = owner_user_id);

-- guardian_dependents
CREATE POLICY "Guardians view own connections" ON guardian_dependents
    FOR ALL USING (auth.uid() = guardian_user_id);

-- 6. Chat & Phased Communication
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seeker_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    stage INTEGER DEFAULT 0 CHECK (stage BETWEEN 0 AND 4),
    started_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    closed_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger for Phased Communication (Protocol Al-Faisal)
CREATE OR REPLACE FUNCTION set_chat_expiry()
RETURNS TRIGGER AS $$
BEGIN
    -- Transition to Active Communication (Stage 2)
    IF NEW.stage = 2 AND (OLD.stage IS NULL OR OLD.stage < 2) THEN
        NEW.started_at = NOW();
        NEW.expires_at = NOW() + INTERVAL '7 days';
    END IF;
    
    -- Transition to Closed (Stage 4)
    IF NEW.stage = 4 THEN
        NEW.closed_at = NOW();
    END IF;
    
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_chat_stage_update
    BEFORE UPDATE ON chat_sessions
    FOR EACH ROW
    EXECUTE PROCEDURE public.set_chat_expiry();

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    sender_profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- NULL for system messages
    text TEXT NOT NULL,
    is_system_message BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for Chat
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can only see sessions where they own the profile or are the guardian
CREATE POLICY "Participants can view own sessions" ON chat_sessions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE (p.id = chat_sessions.seeker_profile_id OR p.id = chat_sessions.target_profile_id)
            AND (p.owner_user_id = auth.uid() OR p.guardian_user_id = auth.uid())
        )
    );

CREATE POLICY "Participants can view own messages" ON chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chat_sessions s
            JOIN profiles p ON (p.id = s.seeker_profile_id OR p.id = s.target_profile_id)
            WHERE s.id = chat_messages.chat_session_id
            AND (p.owner_user_id = auth.uid() OR p.guardian_user_id = auth.uid())
        )
    );

CREATE POLICY "Participants can insert messages" ON chat_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM chat_sessions s
            JOIN profiles p ON (p.id = s.seeker_profile_id OR p.id = s.target_profile_id)
            WHERE s.id = chat_messages.chat_session_id
            AND (p.owner_user_id = auth.uid() OR p.guardian_user_id = auth.uid())
            AND s.stage BETWEEN 1 AND 2 -- Only Stages 1 and 2 allow messaging
        )
    );

-- INDEXES
CREATE INDEX idx_chat_sessions_seeker ON chat_sessions(seeker_profile_id);
CREATE INDEX idx_chat_sessions_target ON chat_sessions(target_profile_id);
CREATE INDEX idx_chat_messages_session ON chat_messages(chat_session_id);

-- 5. Reports Table (Apple Safety Mandatory)
CREATE TABLE reports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reason text NOT NULL,
    details text,
    created_at timestamptz DEFAULT now()
);

-- RLS for Reports
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create reports" ON reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- SELECT is disabled for all by default (already implicit if no SELECT policy exists)
-- Service role only can read (also implicit in Supabase)

-- ============================================
-- 6. Personality Indicators (AI Compatibility Agent)
-- ============================================
CREATE TABLE personality_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    emotional_regulation TEXT CHECK (emotional_regulation IN ('calm', 'reactive', 'avoidant', 'observant')),
    relational_orientation TEXT CHECK (relational_orientation IN ('connected', 'independent', 'cautious')),
    decision_style TEXT CHECK (decision_style IN ('deliberate', 'spontaneous', 'consultative')),
    uncertainty_comfort TEXT CHECK (uncertainty_comfort IN ('adaptive', 'exploratory', 'riskAverse')),
    raw_responses JSONB,
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- RLS for Personality Indicators
ALTER TABLE personality_indicators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own indicators" ON personality_indicators
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own indicators" ON personality_indicators
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own indicators" ON personality_indicators
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- 7. Compatibility Scores (AI Agent Managed)
-- ============================================
CREATE TABLE compatibility_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_1 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id_2 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    score DECIMAL(5,4) NOT NULL CHECK (score >= 0 AND score <= 1),
    level TEXT NOT NULL CHECK (level IN ('excellent', 'good', 'notCompatible', 'unclear')),
    dimensions JSONB,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id_1, user_id_2)
);

-- Indexes for Compatibility Scores
CREATE INDEX idx_compatibility_user1 ON compatibility_scores(user_id_1);
CREATE INDEX idx_compatibility_user2 ON compatibility_scores(user_id_2);
CREATE INDEX idx_compatibility_level ON compatibility_scores(level);

-- RLS for Compatibility Scores
ALTER TABLE compatibility_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own compatibility" ON compatibility_scores
    FOR SELECT USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

CREATE POLICY "Service role can manage compatibility" ON compatibility_scores
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- 8. Personality Test Progress (Track test completion)
-- ============================================
CREATE TABLE personality_test_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    test_id TEXT NOT NULL,
    answers JSONB,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, test_id)
);

-- RLS for Test Progress
ALTER TABLE personality_test_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own test progress" ON personality_test_progress
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 9. Shufa Card Unlocks
-- ============================================
CREATE TABLE shufa_card_unlocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unlocker_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(unlocker_profile_id, target_profile_id)
);

ALTER TABLE shufa_card_unlocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own unlocks" ON shufa_card_unlocks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE (p.id = shufa_card_unlocks.unlocker_profile_id OR p.id = shufa_card_unlocks.target_profile_id)
            AND (p.owner_user_id = auth.uid() OR p.guardian_user_id = auth.uid())
        )
    );
CREATE POLICY "Users can insert own unlocks" ON shufa_card_unlocks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE p.id = shufa_card_unlocks.unlocker_profile_id
            AND (p.owner_user_id = auth.uid() OR p.guardian_user_id = auth.uid())
        )
    );
