import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mithaq/main.dart';
import 'package:mithaq/core/session/app_session.dart';
import 'package:mithaq/core/session/session_provider.dart';
import 'package:mithaq/core/session/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Phase 9 Stabilization Scenarios', () {
    testWidgets('Scenario 1: New Seeker Onboarding Redirect', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStorageProvider.overrideWithValue(storage),
            sessionProvider.overrideWith(
              (ref) => SessionNotifierStub(
                storage,
                const AppSession(
                  authStatus: AuthStatus.signedIn,
                  role: UserRole.seeker,
                  onboardingStatus: OnboardingStatus.notStarted,
                  profileStatus: ProfileStatus.missing,
                ),
              ),
            ),
          ],
          child: const MithaqApp(),
        ),
      );

      await tester.pumpAndSettle();
      // Expect to see Seeker Onboarding Title
      expect(find.text('إعداد الملف الشخصي'), findsOneWidget);
    });

    testWidgets('Scenario 2: New Guardian Dashboard Redirect', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStorageProvider.overrideWithValue(storage),
            sessionProvider.overrideWith(
              (ref) => SessionNotifierStub(
                storage,
                const AppSession(
                  authStatus: AuthStatus.signedIn,
                  role: UserRole.guardian,
                  onboardingStatus: OnboardingStatus.completed,
                  profileStatus: ProfileStatus.ready,
                ),
              ),
            ),
          ],
          child: const MithaqApp(),
        ),
      );

      await tester.pumpAndSettle();
      // Expect to see Guardian Dashboard Title
      expect(find.text('لوحة إدارة التابعين'), findsOneWidget);
    });

    testWidgets('Scenario 3: Dependent Limit (Guardian)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStorageProvider.overrideWithValue(storage),
            sessionProvider.overrideWith(
              (ref) => SessionNotifierStub(
                storage,
                const AppSession(
                  authStatus: AuthStatus.signedIn,
                  role: UserRole.guardian,
                  onboardingStatus: OnboardingStatus.completed,
                  profileStatus: ProfileStatus.ready,
                  userId: 'g1',
                ),
              ),
            ),
          ],
          child: const MithaqApp(),
        ),
      );

      await tester.pumpAndSettle();
      // Expect to find upgrade message instead of add button for second dependent if limit is 1
      expect(find.text('ترقية لإضافة ملف جديد'), findsWidgets);
    });

    testWidgets('Scenario 4: Name Visibility Check', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStorageProvider.overrideWithValue(storage),
            sessionProvider.overrideWith(
              (ref) => SessionNotifierStub(
                storage,
                const AppSession(
                  authStatus: AuthStatus.signedIn,
                  role: UserRole.seeker,
                  onboardingStatus: OnboardingStatus.completed,
                  profileStatus: ProfileStatus.ready,
                ),
              ),
            ),
          ],
          child: const MithaqApp(),
        ),
      );

      await tester.pumpAndSettle();
      // Check for a specific profile name from mock repository
      expect(find.text('سارة'), findsOneWidget);
    });

    testWidgets('Scenario 5: Avatar Only Policy - No Upload UI', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionStorage(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStorageProvider.overrideWithValue(storage),
            sessionProvider.overrideWith(
              (ref) => SessionNotifierStub(
                storage,
                const AppSession(
                  authStatus: AuthStatus.signedIn,
                  role: UserRole.seeker,
                  onboardingStatus: OnboardingStatus.completed,
                  profileStatus: ProfileStatus.ready,
                ),
              ),
            ),
          ],
          child: const MithaqApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('تحميل صورة'), findsNothing);
      expect(find.byIcon(Icons.camera_alt), findsNothing);
    });
    group('Regression: Empty Profile Bug Fix', () {
      testWidgets('Redirect away from profile if status is missing', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = SessionStorage(prefs);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionStorageProvider.overrideWithValue(storage),
              sessionProvider.overrideWith(
                (ref) => SessionNotifierStub(
                  storage,
                  const AppSession(
                    authStatus: AuthStatus.signedIn,
                    role: UserRole.seeker,
                    onboardingStatus: OnboardingStatus.completed,
                    profileStatus: ProfileStatus.missing,
                  ),
                ),
              ),
            ],
            child: const MithaqApp(),
          ),
        );

        await tester.pumpAndSettle();
        // The router should redirect seeker to onboarding if profile is missing
        expect(find.text('أهلاً بك في ميثاق!'), findsOneWidget);
      });
    });
  });
}

class SessionNotifierStub extends SessionNotifier {
  final AppSession initial;
  SessionNotifierStub(super.storage, this.initial) {
    state = initial;
  }
}
