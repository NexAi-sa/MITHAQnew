import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/session_provider.dart';
import '../session/app_session.dart';

import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/onboarding/presentation/seeker_onboarding_screen.dart';
import '../../features/onboarding/presentation/guardian_onboarding_screen.dart';
import '../../features/seeker/presentation/seeker_shell.dart';
import '../../features/seeker/presentation/home_screen.dart';
import '../../features/messages/presentation/messages_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/seeker/presentation/seeker_requests_screen.dart';
import '../../features/guardian/presentation/guardian_dashboard.dart';
import '../../features/guardian/presentation/add_dependent_wizard.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/guardian/presentation/guardian_settings_screen.dart';
import '../../features/guardian/presentation/guardian_shell.dart';
import '../../features/advisor/presentation/advisor_chat_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/seeker/presentation/profile_details_screen.dart';
import '../../features/common/presentation/legal_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';

import '../../features/seeker/presentation/filters_screen.dart';

import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/personality/presentation/personality_test_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/seeker/onboarding',
        builder: (context, state) => const SeekerOnboardingScreen(),
      ),
      GoRoute(
        path: '/guardian/onboarding',
        builder: (context, state) => const GuardianOnboardingScreen(),
      ),

      // Seeker Shell
      ShellRoute(
        builder: (context, state, child) =>
            SeekerShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/seeker/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/seeker/requests',
            builder: (context, state) => const SeekerRequestsScreen(),
          ),
          GoRoute(
            path: '/seeker/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/seeker/profile',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/seeker/profile/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProfileDetailsScreen(profileId: id);
            },
          ),
          GoRoute(
            path: '/seeker/account',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/seeker/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/seeker/filters',
            builder: (context, state) => const FiltersScreen(),
          ),
          GoRoute(
            path: '/seeker/support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: '/seeker/personality-test',
            builder: (context, state) => const PersonalityTestScreen(),
          ),
        ],
      ),

      // Guardian Shell
      ShellRoute(
        builder: (context, state, child) =>
            GuardianShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/guardian/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/guardian/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/guardian/dashboard',
            builder: (context, state) => const GuardianDashboard(),
          ),
          GoRoute(
            path: '/guardian/dependents/:id/profile',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return Scaffold(
                appBar: AppBar(title: const Text('ملف التابع')),
                body: Center(child: Text('ملف التابع ID: $id')),
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: '/guardian/add-dependent',
        builder: (context, state) => const AddDependentWizard(),
      ),
      GoRoute(
        path: '/guardian/settings',
        builder: (context, state) => const GuardianSettingsScreen(),
      ),
      GoRoute(
        path: '/advisor',
        builder: (context, state) {
          final profileId = state.uri.queryParameters['profileId'];
          return AdvisorChatScreen(initialProfileId: profileId);
        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final targetProfileId = state.pathParameters['id']!;
          return ChatScreen(targetProfileId: targetProfileId);
        },
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProfileDetailsScreen(profileId: id);
        },
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => const LegalScreen(type: LegalType.terms),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => const LegalScreen(type: LegalType.privacy),
      ),
    ],
    redirect: (context, state) {
      final authStatus = session.authStatus;
      final role = session.role;
      final onboardingStatus = session.onboardingStatus;

      final isSplash = state.matchedLocation == '/';
      final isWelcome = state.matchedLocation == '/welcome';
      final isAuth = state.matchedLocation == '/auth';

      final isOnboarding =
          state.matchedLocation.contains('onboarding') ||
          state.matchedLocation == '/role-selection';

      // If in role selection but role is already selected, move forward
      if (state.matchedLocation == '/role-selection' &&
          authStatus == AuthStatus.signedIn &&
          role != UserRole.none) {
        if (onboardingStatus != OnboardingStatus.completed) {
          return role == UserRole.seeker
              ? '/seeker/onboarding'
              : '/guardian/onboarding';
        }
        return role == UserRole.seeker ? '/seeker/home' : '/guardian/home';
      }

      if (authStatus == AuthStatus.signedIn && isOnboarding) {
        return null;
      }

      if (isSplash || isWelcome) {
        if (authStatus == AuthStatus.signedIn) {
          // If we have a role and a profileId, the user is already "done" with core onboarding
          if (role != UserRole.none && session.profileId != null) {
            return role == UserRole.seeker ? '/seeker/home' : '/guardian/home';
          }

          if (role == UserRole.none) return '/role-selection';
          if (onboardingStatus != OnboardingStatus.completed) {
            return role == UserRole.seeker
                ? '/seeker/onboarding'
                : '/guardian/onboarding';
          }
          return role == UserRole.seeker ? '/seeker/home' : '/guardian/home';
        }
        return null;
      }

      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isLegal = state.matchedLocation.startsWith('/legal');

      if (authStatus == AuthStatus.signedOut &&
          !isAuth &&
          !isForgotPassword &&
          !isLegal) {
        return '/welcome';
      }

      return null;
    },
  );
});
