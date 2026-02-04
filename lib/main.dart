import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/router.dart';
import 'core/theme/design_system.dart';
import 'core/theme/theme_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/session/session_storage.dart';
import 'core/session/session_provider.dart';
import 'features/subscription/data/subscription_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL') != ''
        ? const String.fromEnvironment('SUPABASE_URL')
        : dotenv.get('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY') != ''
        ? const String.fromEnvironment('SUPABASE_ANON_KEY')
        : dotenv.get('SUPABASE_ANON_KEY'),
  );

  // Initialize RevenueCat
  await SubscriptionService().init();

  final prefs = await SharedPreferences.getInstance();
  final sessionStorage = SessionStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sessionStorageProvider.overrideWithValue(sessionStorage),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MithaqApp(),
    ),
  );
}

class MithaqApp extends ConsumerWidget {
  const MithaqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mithaq',
      debugShowCheckedModeBanner: false,

      // Router configuration
      routerConfig: router,

      // Theme configuration
      theme: MithaqTheme.lightTheme,
      darkTheme: MithaqTheme.darkTheme,
      themeMode: themeMode,

      // Localization configuration
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'), // Set default to Arabic for now
      // RTL Support is automatic with Arabic locale
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Explicitly RTL for Arabic-first
          child: child!,
        );
      },
    );
  }
}
