/// Hidden AI-only insight (never shown raw to user)
class AdvisorInsight {
  final String id;
  final InsightType type;
  final String tag;
  final double confidence;
  final String sourceMessageId;
  final String? relatedProfileId;
  final DateTime createdAt;

  const AdvisorInsight({
    required this.id,
    required this.type,
    required this.tag,
    required this.confidence,
    required this.sourceMessageId,
    this.relatedProfileId,
    required this.createdAt,
  });
}

enum InsightType { preference, value, sensitivity, compatibilityNote }

/// Allowed insight tags (no medical/diagnostic/moral labels)
class AllowedInsightTags {
  static const List<String> preferences = [
    'non_smoker_strict',
    'smoker_tolerant',
    'hijab_preference',
    'niqab_preference',
    'career_focused',
    'homemaker_preference',
    'city_preference',
    'tribe_importance',
  ];

  static const List<String> values = [
    'family_oriented',
    'independence_valued',
    'traditional_values',
    'modern_outlook',
    'religious_practice',
    'education_priority',
  ];

  static const List<String> sensitivities = [
    'divorce_sensitive',
    'age_gap_concern',
    'relocation_hesitant',
    'financial_expectations',
  ];

  static bool isAllowed(String tag) {
    return preferences.contains(tag) ||
        values.contains(tag) ||
        sensitivities.contains(tag);
  }
}
