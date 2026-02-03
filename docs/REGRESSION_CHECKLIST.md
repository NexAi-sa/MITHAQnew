# Regression Checklist & Critical Scenarios

This document tracks the verification of critical user journeys to prevent regressions after new phases.

## 1. New Seeker Flow
- [ ] **Step**: Launch app -> choose seeker -> mock auth -> onboarding -> home.
- [ ] **Expected**: User lands on `/seeker/onboarding` if status is not completed. After completion, lands on `/seeker/home`.
- [ ] **Expected**: No "Guardian" menu items or screens visible.
- [ ] **Expected**: Home shows "Empty" state if no profiles match, or "Draft" banner if profile is incomplete.

## 2. New Guardian Flow
- [ ] **Step**: Launch app -> choose guardian -> mock auth -> dashboard.
- [ ] **Expected**: User lands on `/guardian/dashboard`.
- [ ] **Expected**: No "Discover" (Seeker Home) screens visible.

## 3. Dependent Limit (Guardian)
- [ ] **Step**: Add dependents until limit (Free: 1).
- [ ] **Expected**: Adding 1st dependent works. Attempting more shows "Locked" slot or upgrade message.
- [ ] **Expected**: No crashes or silent failures.

## 4. Name Visibility Policy
- [ ] **Step**: View profiles in grid and details.
- [ ] **Expected**: Name display follows `ProfileDetailsScreen` logic. 
- [ ] **Expected**: Private names are masked appropriately until contact is established (Current mock shows full name, needs verification).

## 5. Avatar-Only Policy
- [ ] **Step**: Open avatar customizer / View profiles.
- [ ] **Expected**: No mention of "Upload Photo" or gallery icons.
- [ ] **Expected**: `AvatarRenderer` used consistently across all cards and details.

## 6. Zero-Data Safety (The "Empty Profile" Bug)
- [ ] **Step**: User with `ProfileStatus.missing` tries to access `/seeker/profile/p1`.
- [ ] **Expected**: Redirected to `/seeker/onboarding` or shown a "Missing Profile" UI with a clear CTA to create one.
- [ ] **Expected**: NO blank white screens.
