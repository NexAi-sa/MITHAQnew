-- Mithaq Test Profiles
-- Run this in Supabase SQL Editor to create test users

-- Test Profile 1: Female Seeker
INSERT INTO profiles (
  id, profile_public_id, first_name, owner_user_id, dob, city, 
  marital_status, education_level, tribe, is_paused, gender, job,
  managed_by_guardian, role_context, name_visibility, bio,
  shufa_card_active, shufa_card_is_verified
) VALUES (
  gen_random_uuid(),
  'MITH-TEST-001',
  'سارة',
  gen_random_uuid(),
  '1998-05-15',
  'الرياض',
  'single',
  'bachelors',
  'العتيبي',
  false,
  'female',
  'طبيبة',
  true,
  'seeker',
  'firstName',
  'أبحث عن شريك حياة يتقي الله ويحترم العائلة. أحب القراءة والسفر.',
  true,
  true
);

-- Test Profile 2: Male Seeker
INSERT INTO profiles (
  id, profile_public_id, first_name, owner_user_id, dob, city, 
  marital_status, education_level, tribe, is_paused, gender, job,
  managed_by_guardian, role_context, name_visibility, bio,
  shufa_card_active
) VALUES (
  gen_random_uuid(),
  'MITH-TEST-002',
  'عبدالله',
  gen_random_uuid(),
  '1995-08-20',
  'جدة',
  'single',
  'masters',
  'القحطاني',
  false,
  'male',
  'مهندس برمجيات',
  false,
  'seeker',
  'fullName',
  'أبحث عن زوجة صالحة تشاركني مسيرة الحياة. أهتم بالتقنية والرياضة.',
  false
);

-- Test Profile 3: Female with Guardian
INSERT INTO profiles (
  id, profile_public_id, first_name, owner_user_id, dob, city, 
  marital_status, education_level, is_paused, gender, job,
  managed_by_guardian, role_context, name_visibility, bio,
  shufa_card_active, shufa_card_guardian_name, shufa_card_guardian_phone
) VALUES (
  gen_random_uuid(),
  'MITH-TEST-003',
  'نورة',
  gen_random_uuid(),
  '2000-03-10',
  'الدمام',
  'single',
  'bachelors',
  false,
  'female',
  'معلمة',
  true,
  'dependent',
  'hidden',
  'أحب الهدوء والاستقرار. أبحث عن شخص ملتزم وجاد.',
  true,
  'والد نورة',
  '0500000000'
);

-- Test Profile 4: Male Divorced
INSERT INTO profiles (
  id, profile_public_id, first_name, owner_user_id, dob, city, 
  marital_status, education_level, is_paused, gender, job,
  managed_by_guardian, role_context, name_visibility, bio
) VALUES (
  gen_random_uuid(),
  'MITH-TEST-004',
  'محمد',
  gen_random_uuid(),
  '1990-11-25',
  'مكة',
  'divorced',
  'bachelors',
  false,
  'male',
  'رجل أعمال',
  false,
  'seeker',
  'firstName',
  'مطلق بدون أطفال. أبحث عن شريكة تفهم معنى الحياة الزوجية.'
);

-- Test Profile 5: Female Widow
INSERT INTO profiles (
  id, profile_public_id, first_name, owner_user_id, dob, city, 
  marital_status, education_level, is_paused, gender, job,
  managed_by_guardian, role_context, name_visibility, bio
) VALUES (
  gen_random_uuid(),
  'MITH-TEST-005',
  'هند',
  gen_random_uuid(),
  '1988-07-12',
  'المدينة',
  'widowed',
  'masters',
  false,
  'female',
  'أستاذة جامعية',
  false,
  'seeker',
  'fullName',
  'أرملة بدون أطفال. أبحث عن رفيق الدرب الصادق.'
);
