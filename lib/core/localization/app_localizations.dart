import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('ar'); // Default to Arabic
});

class AppLocalizations {
  static const List<Locale> supportedLocales = [Locale('ar'), Locale('en')];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Mithaq',
      'welcome': 'Welcome to Mithaq',
      'role_selection': 'Who are you?',
      'seeker': 'Marriage Seeker',
      'guardian': 'Guardian',
      'continue': 'Continue',
      'language': 'English',
    },
    'ar': {
      'app_title': 'ميثاق',
      'welcome': 'مرحباً بك في ميثاق',
      'role_selection': 'من أنت؟',
      'seeker': 'باحث عن زواج',
      'guardian': 'ولي أمر',
      'continue': 'استمرار',
      'language': 'العربية',
    },
  };

  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}
