-- Fix RLS policies for profiles table
-- Column owner_user_id is UUID type, auth.uid() returns UUID
-- No casting needed when both are UUID

-- =============================================
-- 1. Allow users to INSERT their own profile
-- =============================================
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = owner_user_id);

-- =============================================
-- 2. Allow guardians to INSERT profiles for dependents
-- =============================================
DROP POLICY IF EXISTS "Guardians can insert for dependents" ON profiles;
CREATE POLICY "Guardians can insert for dependents"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = owner_user_id 
  OR auth.uid() = guardian_user_id
);

-- =============================================
-- 3. Ensure UPDATE policy exists for own profile
-- =============================================
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = owner_user_id)
WITH CHECK (auth.uid() = owner_user_id);

-- =============================================
-- 4. Allow guardians to UPDATE dependent profiles
-- =============================================
DROP POLICY IF EXISTS "Guardians can update dependents" ON profiles;
CREATE POLICY "Guardians can update dependents"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = guardian_user_id)
WITH CHECK (auth.uid() = guardian_user_id);
