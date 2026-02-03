-- Seed a demo profile for testing purposes
-- Note: This requires a dummy user ID or bypasses some constraints for testing.
-- For the purpose of this demo, we assume there's a system user or we use a fixed ID.

INSERT INTO profiles (
    id,
    owner_user_id,
    role_context,
    profile_public_id,
    first_name,
    full_name,
    dob,
    gender,
    job,
    city,
    marital_status,
    education_level,
    is_paused,
    managed_by_guardian,
    name_visibility
) VALUES (
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '00000000-0000-0000-0000-000000000000', -- Dummy owner
    'seeker',
    'DEMO-999',
    'تجربة ميثاق',
    'حساب تجريبي للاختبار',
    '1995-01-01',
    'female',
    'مهندس تجريبي',
    'الرياض',
    'single',
    'bachelor',
    false,
    false,
    'first'
) ON CONFLICT (id) DO NOTHING;
