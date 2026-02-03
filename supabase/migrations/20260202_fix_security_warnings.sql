-- Fix function search_path security warnings
-- Run this in Supabase SQL Editor

-- Fix 1: unlock_guardian_contact function
CREATE OR REPLACE FUNCTION public.unlock_guardian_contact(
  p_requester_profile_id text,
  p_target_profile_id text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp  -- 🔒 Security fix
AS $$
DECLARE
  v_result json;
BEGIN
  -- Check if already unlocked
  IF EXISTS (
    SELECT 1 FROM shufa_unlocks
    WHERE requester_profile_id = p_requester_profile_id
    AND target_profile_id = p_target_profile_id
  ) THEN
    -- Return existing data
    SELECT json_build_object(
      'guardian_name', p.shufa_card_guardian_name,
      'guardian_phone', p.shufa_card_guardian_phone,
      'guardian_title', p.shufa_card_guardian_title
    ) INTO v_result
    FROM profiles p
    WHERE p.profile_id = p_target_profile_id;
    
    RETURN v_result;
  END IF;
  
  -- Record the unlock
  INSERT INTO shufa_unlocks (requester_profile_id, target_profile_id)
  VALUES (p_requester_profile_id, p_target_profile_id);
  
  -- Return guardian contact info
  SELECT json_build_object(
    'guardian_name', p.shufa_card_guardian_name,
    'guardian_phone', p.shufa_card_guardian_phone,
    'guardian_title', p.shufa_card_guardian_title
  ) INTO v_result
  FROM profiles p
  WHERE p.profile_id = p_target_profile_id;
  
  RETURN v_result;
END;
$$;

-- Fix 2: handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp  -- 🔒 Security fix
AS $$
BEGIN
  INSERT INTO public.users (id, phone, created_at)
  VALUES (NEW.id, NEW.phone, NOW())
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.unlock_guardian_contact TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user TO service_role;
