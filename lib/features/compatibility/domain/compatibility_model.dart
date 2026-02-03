/// Compatibility score for a single axis
class AxisScore {
  final CompatibilityAxis axis;
  final int score; // 0-100
  final bool isComplete;
  final List<String> positiveReasons;
  final List<String> discussionPoints;

  const AxisScore({
    required this.axis,
    required this.score,
    this.isComplete = true,
    this.positiveReasons = const [],
    this.discussionPoints = const [],
  });

  /// Get the qualitative label based on score and axis
  String get label {
    if (!isComplete) {
      return axis == CompatibilityAxis.psychological
          ? 'تقدير أولي'
          : 'غير مكتمل';
    }

    switch (axis) {
      case CompatibilityAxis.basic:
        if (score >= 75) return 'ممتاز';
        if (score >= 50) return 'جيد';
        return 'قد لا يكون الأنسب';

      case CompatibilityAxis.style:
        if (score >= 75) return 'ممتاز';
        if (score >= 50) return 'متوسط';
        return 'يحتاج نقاش';

      case CompatibilityAxis.psychological:
        if (score >= 75) return 'قوي';
        if (score >= 50) return 'متوسط';
        return 'تقدير أولي';
    }
  }

  /// Get Arabic axis name
  String get axisName {
    switch (axis) {
      case CompatibilityAxis.basic:
        return 'أساسي';
      case CompatibilityAxis.style:
        return 'نمطي';
      case CompatibilityAxis.psychological:
        return 'نفسي';
    }
  }
}

enum CompatibilityAxis { basic, style, psychological }

/// Full compatibility result for a profile pair
class CompatibilityResult {
  final String targetProfileId;
  final AxisScore basic;
  final AxisScore style;
  final AxisScore psychological;
  final DateTime calculatedAt;

  const CompatibilityResult({
    required this.targetProfileId,
    required this.basic,
    required this.style,
    required this.psychological,
    required this.calculatedAt,
  });

  /// Overall score (average of complete axes only)
  int get overallScore {
    int total = 0;
    int count = 0;

    if (basic.isComplete) {
      total += basic.score;
      count++;
    }
    if (style.isComplete) {
      total += style.score;
      count++;
    }
    if (psychological.isComplete) {
      total += psychological.score;
      count++;
    }

    return count > 0 ? (total / count).round() : 0;
  }

  /// Overall label (most conservative of all axes)
  String get overallLabel {
    final score = overallScore;
    if (score >= 75) return 'ممتاز';
    if (score >= 50) return 'جيد';
    return 'قد لا يكون الأنسب حالياً';
  }

  /// Check if any axis is incomplete
  bool get hasIncompleteData {
    return !basic.isComplete || !style.isComplete || !psychological.isComplete;
  }

  /// Get all positive reasons across axes
  List<String> get allPositiveReasons {
    return [
      ...basic.positiveReasons,
      ...style.positiveReasons,
      ...psychological.positiveReasons,
    ];
  }

  /// Get all discussion points across axes
  List<String> get allDiscussionPoints {
    return [
      ...basic.discussionPoints,
      ...style.discussionPoints,
      ...psychological.discussionPoints,
    ];
  }
}
