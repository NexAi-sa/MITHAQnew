-- 1. Create a table to track unlocked contacts (Consumables)
-- This ensures a user doesn't pay twice for the same contact
CREATE TABLE IF NOT EXISTS public.guardian_access_grants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    seeker_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    target_profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    transaction_id TEXT, -- Optional: RevenueCat transaction ID for audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Ensure a seeker can only unlock a specific profile once
    UNIQUE(seeker_id, target_profile_id)
);

-- Enable RLS
ALTER TABLE public.guardian_access_grants ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see who they have unlocked
CREATE POLICY "Users can view their own grants"
    ON public.guardian_access_grants
    FOR SELECT
    USING (auth.uid() = seeker_id);

-- Policy: Users can insert their own grants (Called via RPC securely)
-- Note: In a production App, insert should be restricted to Service Role (Edge Function),
-- but for this MVP client-side purchase implementation, we allow authenticated users to insert.
CREATE POLICY "Users can create grants"
    ON public.guardian_access_grants
    FOR INSERT
    WITH CHECK (auth.uid() = seeker_id);


-- 2. Add Subscription Tier column to profiles
-- This allows us to show badges or restrict access based on DB state
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'free'; 
-- Values: 'free', 'explorer', 'serious', 'elite'


-- 3. RPC Function to call from Flutter after successful payment
CREATE OR REPLACE FUNCTION public.unlock_guardian_contact(
    target_id UUID,
    rc_transaction_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with high privileges to ensure insertion
AS $$
DECLARE
    result JSONB;
BEGIN
    -- Insert the grant record
    INSERT INTO public.guardian_access_grants (seeker_id, target_profile_id, transaction_id)
    VALUES (auth.uid(), target_id, rc_transaction_id)
    ON CONFLICT (seeker_id, target_profile_id) DO NOTHING; -- Do nothing if already unlocked

    result := jsonb_build_object(
        'success', true,
        'message', 'Guardian contact unlocked successfully'
    );
    
    RETURN result;
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;
