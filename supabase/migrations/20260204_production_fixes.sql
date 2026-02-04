-- Production Fixes Migration
-- Run this in Supabase SQL Editor to prepare for Apple Review and production users

-- ==========================================
-- 1. CREATE REPORTS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reported_profile_id UUID NOT NULL REFERENCES profiles(id),
  reporter_profile_id UUID REFERENCES profiles(id),
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_reports_reported_profile ON reports(reported_profile_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);

-- ==========================================
-- 2. RLS POLICIES FOR REPORTS TABLE
-- ==========================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports
CREATE POLICY "Users can create reports" ON reports
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can view their own reports
CREATE POLICY "Users can view own reports" ON reports
  FOR SELECT
  TO authenticated
  USING (
    reporter_profile_id IN (
      SELECT profile_id FROM profiles WHERE user_id = auth.uid()
    )
  );

-- ==========================================
-- 3. RLS POLICIES FOR CHAT_SESSIONS
-- ==========================================
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view their chat sessions" ON chat_sessions;
DROP POLICY IF EXISTS "Users can create chat sessions" ON chat_sessions;
DROP POLICY IF EXISTS "Users can update their chat sessions" ON chat_sessions;

-- Users can view sessions they are part of
CREATE POLICY "Users can view their chat sessions" ON chat_sessions
  FOR SELECT
  TO authenticated
  USING (
    seeker_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
    OR 
    target_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
  );

-- Users can create chat sessions
CREATE POLICY "Users can create chat sessions" ON chat_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    seeker_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
  );

-- Users can update sessions they are part of
CREATE POLICY "Users can update their chat sessions" ON chat_sessions
  FOR UPDATE
  TO authenticated
  USING (
    seeker_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
    OR 
    target_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
  );

-- ==========================================
-- 4. RLS POLICIES FOR CHAT_MESSAGES
-- ==========================================
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view messages in their sessions" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages in their sessions" ON chat_messages;

-- Users can view messages in sessions they are part of
CREATE POLICY "Users can view messages in their sessions" ON chat_messages
  FOR SELECT
  TO authenticated
  USING (
    session_id IN (
      SELECT id FROM chat_sessions 
      WHERE seeker_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
      OR target_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
    )
  );

-- Users can send messages in sessions they are part of
CREATE POLICY "Users can send messages in their sessions" ON chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    session_id IN (
      SELECT id FROM chat_sessions 
      WHERE seeker_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
      OR target_profile_id IN (SELECT profile_id FROM profiles WHERE user_id = auth.uid())
    )
  );

-- ==========================================
-- 5. VERIFY PROFILES RLS IS ENABLED
-- ==========================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Ensure basic profile policies exist
DROP POLICY IF EXISTS "Users can view published profiles" ON profiles;
DROP POLICY IF EXISTS "Users can manage own profiles" ON profiles;

-- Anyone can view published profiles
CREATE POLICY "Users can view published profiles" ON profiles
  FOR SELECT
  TO authenticated
  USING (
    profile_status = 'published' 
    OR user_id = auth.uid()
  );

-- Users can manage their own profiles
CREATE POLICY "Users can manage own profiles" ON profiles
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ==========================================
-- 6. GRANT NECESSARY PERMISSIONS
-- ==========================================
GRANT ALL ON reports TO authenticated;
GRANT ALL ON chat_sessions TO authenticated;
GRANT ALL ON chat_messages TO authenticated;
GRANT ALL ON profiles TO authenticated;

-- ==========================================
-- SUCCESS MESSAGE
-- ==========================================
DO $$
BEGIN
  RAISE NOTICE 'Production fixes applied successfully!';
  RAISE NOTICE 'Tables created: reports';
  RAISE NOTICE 'RLS enabled on: reports, chat_sessions, chat_messages, profiles';
END $$;
