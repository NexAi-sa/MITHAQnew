import 'package:shared_preferences/shared_preferences.dart';
import 'app_session.dart';

class SessionStorage {
  static const String _keyUserId = 'mithaq_user_id';
  static const String _keyRole = 'mithaq_role';
  static const String _keyOnboardingStatus = 'mithaq_onboarding_status';
  static const String _keyProfileStatus = 'mithaq_profile_status';
  static const String _keyActiveDependentId = 'mithaq_active_dependent_id';
  static const String _keyGender = 'mithaq_gender';
  static const String _keyCity = 'mithaq_city';
  static const String _keyTribe = 'mithaq_tribe';
  static const String _keyFullName = 'mithaq_full_name';
  static const String _keyEmail = 'mithaq_email';
  static const String _keyPhone = 'mithaq_phone';
  static const String _keyOnboardingStep = 'mithaq_onboarding_step';
  static const String _keyHasActiveSubscription =
      'mithaq_has_active_subscription';

  final SharedPreferences _prefs;

  SessionStorage(this._prefs);

  Future<void> saveSession(AppSession session) async {
    if (session.userId != null) {
      await _prefs.setString(_keyUserId, session.userId!);
    } else {
      await _prefs.remove(_keyUserId);
    }

    await _prefs.setString(_keyRole, session.role.name);
    await _prefs.setString(_keyOnboardingStatus, session.onboardingStatus.name);
    await _prefs.setString(_keyProfileStatus, session.profileStatus.name);
    await _prefs.setString(_keyGender, session.gender.name);
    await _prefs.setInt(_keyOnboardingStep, session.onboardingStep);
    await _prefs.setBool(
      _keyHasActiveSubscription,
      session.hasActiveSubscription,
    );

    if (session.activeDependentId != null) {
      await _prefs.setString(_keyActiveDependentId, session.activeDependentId!);
    } else {
      await _prefs.remove(_keyActiveDependentId);
    }

    if (session.city != null) {
      await _prefs.setString(_keyCity, session.city!);
    } else {
      await _prefs.remove(_keyCity);
    }

    if (session.tribe != null) {
      await _prefs.setString(_keyTribe, session.tribe!);
    } else {
      await _prefs.remove(_keyTribe);
    }

    if (session.fullName != null) {
      await _prefs.setString(_keyFullName, session.fullName!);
    } else {
      await _prefs.remove(_keyFullName);
    }

    if (session.email != null) {
      await _prefs.setString(_keyEmail, session.email!);
    } else {
      await _prefs.remove(_keyEmail);
    }

    if (session.phoneNumber != null) {
      await _prefs.setString(_keyPhone, session.phoneNumber!);
    } else {
      await _prefs.remove(_keyPhone);
    }
  }

  AppSession loadSession() {
    final userId = _prefs.getString(_keyUserId);
    final roleName = _prefs.getString(_keyRole);
    final onboardingName = _prefs.getString(_keyOnboardingStatus);
    final profileName = _prefs.getString(_keyProfileStatus);
    final activeDependentId = _prefs.getString(_keyActiveDependentId);
    final genderName = _prefs.getString(_keyGender);
    final onboardingStep = _prefs.getInt(_keyOnboardingStep) ?? 0;
    final hasActiveSubscription =
        _prefs.getBool(_keyHasActiveSubscription) ?? false;
    final city = _prefs.getString(_keyCity);
    final tribe = _prefs.getString(_keyTribe);
    final fullName = _prefs.getString(_keyFullName);
    final email = _prefs.getString(_keyEmail);
    final phoneNumber = _prefs.getString(_keyPhone);

    UserRole role = UserRole.none;
    if (roleName != null) {
      role = UserRole.values.firstWhere(
        (e) => e.name == roleName,
        orElse: () => UserRole.none,
      );
    }

    OnboardingStatus onboarding = OnboardingStatus.notStarted;
    if (onboardingName != null) {
      onboarding = OnboardingStatus.values.firstWhere(
        (e) => e.name == onboardingName,
        orElse: () => OnboardingStatus.notStarted,
      );
    }

    ProfileStatus profile = ProfileStatus.missing;
    if (profileName != null) {
      profile = ProfileStatus.values.firstWhere(
        (e) => e.name == profileName,
        orElse: () => ProfileStatus.missing,
      );
    }

    SessionGender gender = SessionGender.unknown;
    if (genderName != null) {
      gender = SessionGender.values.firstWhere(
        (e) => e.name == genderName,
        orElse: () => SessionGender.unknown,
      );
    }

    return AppSession(
      authStatus: userId != null ? AuthStatus.signedIn : AuthStatus.signedOut,
      userId: userId,
      role: role,
      onboardingStatus: onboarding,
      profileStatus: profile,
      onboardingStep: onboardingStep,
      activeDependentId: activeDependentId,
      gender: gender,
      city: city,
      tribe: tribe,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      hasActiveSubscription: hasActiveSubscription,
    );
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyRole);
    await _prefs.remove(_keyOnboardingStatus);
    await _prefs.remove(_keyProfileStatus);
    await _prefs.remove(_keyActiveDependentId);
    await _prefs.remove(_keyGender);
    await _prefs.remove(_keyOnboardingStep);
    await _prefs.remove(_keyHasActiveSubscription);
    await _prefs.remove(_keyCity);
    await _prefs.remove(_keyTribe);
    await _prefs.remove(_keyFullName);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyPhone);
  }
}
