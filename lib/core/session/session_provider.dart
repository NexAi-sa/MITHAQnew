import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_session.dart';
import 'session_storage.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

final sessionProvider = StateNotifierProvider<SessionNotifier, AppSession>((
  ref,
) {
  final storage = ref.watch(sessionStorageProvider);
  return SessionNotifier(storage);
});

class SessionNotifier extends StateNotifier<AppSession> {
  final SessionStorage _storage;

  SessionNotifier(this._storage) : super(_storage.loadSession());

  Future<void> _persist(AppSession newState) async {
    state = newState;
    await _storage.saveSession(state);
  }

  Future<void> setAuthSignedIn(
    String userId, {
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    await _persist(
      state.copyWith(
        authStatus: AuthStatus.signedIn,
        userId: userId,
        fullName: name,
        email: email,
        phoneNumber: phoneNumber,
      ),
    );
  }

  Future<void> setAuthSignedOut() async {
    await _storage.clearSession();
    state = const AppSession(authStatus: AuthStatus.signedOut);
  }

  Future<void> setRole(UserRole role) async {
    await _persist(state.copyWith(role: role));
  }

  Future<void> setOnboardingStatus(OnboardingStatus status) async {
    await _persist(state.copyWith(onboardingStatus: status));
  }

  Future<void> setProfileStatus(ProfileStatus status) async {
    await _persist(state.copyWith(profileStatus: status));
  }

  Future<void> setProfileData({
    String? profileId,
    String? city,
    String? tribe,
    SessionGender? gender,
    int? height,
    String? build,
    String? skinColor,
  }) async {
    // تحديث الحالة فوراً وبصمت لضمان عدم حدوث "رمشة" في الواجهة
    await _persist(
      state.copyWith(
        profileId: profileId,
        city: city,
        tribe: tribe,
        gender: gender,
        height: height,
        build: build,
        skinColor: skinColor,
      ),
    );
  }

  /// تعيين التابع النشط (للولي)
  Future<void> setActiveDependent(String? dependentProfileId) async {
    await _persist(state.copyWith(activeDependentId: dependentProfileId));
  }

  /// إعادة تعيين الجلسة بالكامل (للخروج أو حذف الحساب)
  Future<void> resetSessionSafely() async {
    await _storage.clearSession();
    state = const AppSession(authStatus: AuthStatus.signedOut);
  }

  /// تبديل حالة تجميد الحساب (إخفاء/إظهار الملف)
  Future<void> togglePaused() async {
    await _persist(state.copyWith(isPaused: !state.isPaused));
  }

  /// تعيين خطوة التسجيل الحالية (للـ Onboarding)
  Future<void> setOnboardingStep(int step) async {
    await _persist(state.copyWith(onboardingStep: step));
  }

  /// تعيين جنس المستخدم في الجلسة
  Future<void> setGender(SessionGender gender) async {
    await _persist(state.copyWith(gender: gender));
  }
}
