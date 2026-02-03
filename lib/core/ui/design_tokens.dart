import 'package:flutter/material.dart';

class MithaqSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class MithaqRadius {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double full = 999.0;

  static BorderRadius get small => BorderRadius.circular(s);
  static BorderRadius get medium => BorderRadius.circular(m);
  static BorderRadius get large => BorderRadius.circular(l);
  static BorderRadius get extraLarge => BorderRadius.circular(xl);
  static BorderRadius get rounded => BorderRadius.circular(full);
}

class MithaqTypography {
  static const double bodySmall = 12.0;
  static const double bodyMedium = 14.0;
  static const double bodyLarge = 16.0;
  static const double titleSmall = 18.0;
  static const double titleMedium = 20.0;
  static const double titleLarge = 24.0;
  static const double displaySmall = 32.0;
}

class MithaqIconSize {
  static const double s = 16.0;
  static const double m = 24.0;
  static const double l = 32.0;
  static const double xl = 48.0;
}

/// Animation durations for consistent micro-interactions
class MithaqDurations {
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration page = Duration(milliseconds: 350);
}

/// Elevation shadows for depth hierarchy
class MithaqShadows {
  static List<BoxShadow> get none => [];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
