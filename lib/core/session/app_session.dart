enum AuthStatus { unknown, signedOut, signedIn }

enum UserRole { none, seeker, guardian }

enum OnboardingStatus { notStarted, inProgress, completed }

enum ProfileStatus { loading, draft, missing, ready }

/// Session gender for filtering purposes
enum SessionGender { male, female, unknown }

class AppSession {
  final AuthStatus authStatus;
  final UserRole role;
  final OnboardingStatus onboardingStatus;
  final ProfileStatus profileStatus;
  final String? userId; // Auth UID
  final String? profileId; // Seeker Profile UUID
  final String? city;
  final String? tribe;
  final String? activeDependentId;
  final bool isPaused;
  final SessionGender gender;
  final int onboardingStep;
  final String? fullName; // Added for name during auth
  final int? height;
  final String? build;
  final String? skinColor;
  final String? email;
  final String? phoneNumber;
  final bool hasActiveSubscription;

  const AppSession({
    this.authStatus = AuthStatus.unknown,
    this.role = UserRole.none,
    this.onboardingStatus = OnboardingStatus.notStarted,
    this.profileStatus = ProfileStatus.missing,
    this.userId,
    this.profileId,
    this.city,
    this.tribe,
    this.activeDependentId,
    this.isPaused = false,
    this.gender = SessionGender.unknown,
    this.onboardingStep = 0,
    this.fullName,
    this.height,
    this.build,
    this.skinColor,
    this.email,
    this.phoneNumber,
    this.hasActiveSubscription = false,
  });

  AppSession copyWith({
    AuthStatus? authStatus,
    UserRole? role,
    OnboardingStatus? onboardingStatus,
    ProfileStatus? profileStatus,
    String? userId,
    String? profileId,
    String? city,
    String? tribe,
    String? activeDependentId,
    bool? isPaused,
    SessionGender? gender,
    int? onboardingStep,
    String? fullName,
    int? height,
    String? build,
    String? skinColor,
    String? email,
    String? phoneNumber,
    bool? hasActiveSubscription,
  }) {
    return AppSession(
      authStatus: authStatus ?? this.authStatus,
      role: role ?? this.role,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      profileStatus: profileStatus ?? this.profileStatus,
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      city: city ?? this.city,
      tribe: tribe ?? this.tribe,
      activeDependentId: activeDependentId ?? this.activeDependentId,
      isPaused: isPaused ?? this.isPaused,
      gender: gender ?? this.gender,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      fullName: fullName ?? this.fullName,
      height: height ?? this.height,
      build: build ?? this.build,
      skinColor: skinColor ?? this.skinColor,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
    );
  }
}
