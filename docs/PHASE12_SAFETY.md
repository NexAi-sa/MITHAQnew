# Phase 12: Store Safety Compliance (Apple + Google)

This phase implemented the mandatory safety features required for App Store and Play Store submission (TestFlight/Internal Testing).

## Key Implementations

### 1. Account Deletion (Irreversible)
- **UI**: Added a specialized "Delete Account" flow in Settings with reason selection and a mandatory "Irreversible" confirmation bottom sheet.
- **Backend**: Implemented a Supabase Edge Function `delete_account` that uses the Service Role key to fully purge user data, including profiles, private data, and the Auth record itself.
- **Logic**: Calls the backend function and immediately signs out and redirects to the Splash screen on success.

### 2. Enhanced Account Pausing
- **UI**: Updated the "Pause Account" toggle in Settings with clearer empathy-driven language.
- **Backend Integration**: Connected the UI toggle to the `ProfileRepository` and `SupabaseBackendClient` to update the `is_paused` flag in the database.
- **Effect**: Profiles with `is_paused = true` are automatically excluded from the discovery feed via database-level filtering (RLS and Query).

### 3. Reporting System (Apple Mandatory)
- **Feature**: "Report Profile" added to `ProfileDetailsScreen`.
- **UI**: A modal sheet allowing users to report others for "Fake Profile", "Harassment", "Inappropriate Content", or "Other".
- **Backend**: Created a `reports` table in Supabase with strict RLS (Write-only for reporter, Read-only for Admin/Service Role).

### 4. Local Blocking
- **Feature**: "Block Profile" added to `ProfileDetailsScreen`.
- **Logic**: Implemented local blocking stored in `SharedPreferences`, namespaced by the active profile ID (Seeker or Dependent).
- **Discovery Filter**: The `discoveryProfilesProvider` now automatically filters out blocked profiles from the feed.

### 5. Legal Compliance
- **Screens**: Created `PrivacyPolicyScreen` and `TermsOfUseScreen` with placeholder content ready for actual legal text.
- **Access**: Strategic links added in the Settings menu under "معلومات قانونية".

### 6. Psychological Safety (Language)
- **Wording**: Global replacement of harsh terms:
    - `"لا يوجد"` -> `"غير متاح حالياً"`
    - `"رفض"` -> `"غير مناسب"` (where applicable)
- **Empty States**: Friendly, supportive messages implemented across Home and Guardian screens.

## Technical Details
- **New Files**:
    - `lib/core/safety/safety_repository.dart`
    - `lib/features/settings/presentation/legal_screens.dart`
    - `supabase/functions/delete_account/index.ts`
- **Modified**: `router.dart`, `main.dart`, `settings_screen.dart`, `profile_details_screen.dart`, `profile_repository.dart`, `supabase_backend_client.dart`.

---
*Status: Phase 12 Ready for Internal Review*
