/// Personality Indicators extracted from projective tests
///
/// These are soft psychological indicators used for compatibility analysis.
/// NOT psychological diagnoses - just tendencies and preferences.
class PersonalityIndicators {
  final String userId;
  final EmotionalRegulation? emotionalRegulation;
  final RelationalOrientation? relationalOrientation;
  final DecisionStyle? decisionStyle;
  final UncertaintyComfort? uncertaintyComfort;
  final DateTime? analyzedAt;
  final Map<String, dynamic>? rawTestResponses;

  const PersonalityIndicators({
    required this.userId,
    this.emotionalRegulation,
    this.relationalOrientation,
    this.decisionStyle,
    this.uncertaintyComfort,
    this.analyzedAt,
    this.rawTestResponses,
  });

  /// Check if personality analysis is complete
  bool get isComplete =>
      emotionalRegulation != null &&
      relationalOrientation != null &&
      decisionStyle != null &&
      uncertaintyComfort != null;

  /// Create from test answers
  factory PersonalityIndicators.fromTestAnswers({
    required String userId,
    required Map<String, dynamic> answers,
  }) {
    return PersonalityIndicators(
      userId: userId,
      emotionalRegulation: _parseEmotionalRegulation(answers),
      relationalOrientation: _parseRelationalOrientation(answers),
      decisionStyle: _parseDecisionStyle(answers),
      uncertaintyComfort: _parseUncertaintyComfort(answers),
      analyzedAt: DateTime.now(),
      rawTestResponses: answers,
    );
  }

  /// Parse emotional regulation from answers
  static EmotionalRegulation? _parseEmotionalRegulation(
    Map<String, dynamic> answers,
  ) {
    final feeling = answers['forest_feeling'] as String?;
    switch (feeling) {
      case 'calm':
        return EmotionalRegulation.calm;
      case 'curious':
        return EmotionalRegulation.observant;
      case 'cautious':
        return EmotionalRegulation.avoidant;
      case 'anxious':
        return EmotionalRegulation.reactive;
      default:
        return null;
    }
  }

  /// Parse relational orientation from answers
  static RelationalOrientation? _parseRelationalOrientation(
    Map<String, dynamic> answers,
  ) {
    final perception = answers['perception'] as String?;
    final companion = answers['forest_companion'] as String?;

    if (perception == 'person' || companion == 'known') {
      return RelationalOrientation.connected;
    } else if (companion == 'alone') {
      return RelationalOrientation.independent;
    } else if (companion == 'unknown') {
      return RelationalOrientation.cautious;
    }

    return null;
  }

  /// Parse decision style from answers
  static DecisionStyle? _parseDecisionStyle(Map<String, dynamic> answers) {
    final reaction = answers['forest_reaction'] as String?;
    switch (reaction) {
      case 'observe':
        return DecisionStyle.deliberate;
      case 'continue':
        return DecisionStyle.deliberate;
      case 'investigate':
        return DecisionStyle.spontaneous;
      case 'change':
        return DecisionStyle.spontaneous;
      default:
        return null;
    }
  }

  /// Parse uncertainty comfort from answers
  static UncertaintyComfort? _parseUncertaintyComfort(
    Map<String, dynamic> answers,
  ) {
    final room = answers['room'] as String?;
    switch (room) {
      case 'sit':
        return UncertaintyComfort.adaptive;
      case 'search':
        return UncertaintyComfort.exploratory;
      case 'window':
        return UncertaintyComfort.exploratory;
      case 'leave':
        return UncertaintyComfort.riskAverse;
      default:
        return null;
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'emotional_regulation': emotionalRegulation?.name,
    'relational_orientation': relationalOrientation?.name,
    'decision_style': decisionStyle?.name,
    'uncertainty_comfort': uncertaintyComfort?.name,
    'analyzed_at': analyzedAt?.toIso8601String(),
    'raw_responses': rawTestResponses,
  };

  /// Create from JSON
  factory PersonalityIndicators.fromJson(Map<String, dynamic> json) {
    return PersonalityIndicators(
      userId: json['user_id'] as String,
      emotionalRegulation: _enumFromString(
        json['emotional_regulation'],
        EmotionalRegulation.values,
      ),
      relationalOrientation: _enumFromString(
        json['relational_orientation'],
        RelationalOrientation.values,
      ),
      decisionStyle: _enumFromString(
        json['decision_style'],
        DecisionStyle.values,
      ),
      uncertaintyComfort: _enumFromString(
        json['uncertainty_comfort'],
        UncertaintyComfort.values,
      ),
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'])
          : null,
      rawTestResponses: json['raw_responses'] as Map<String, dynamic>?,
    );
  }

  static T? _enumFromString<T extends Enum>(String? value, List<T> values) {
    if (value == null) return null;
    try {
      return values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}

/// Emotional Regulation Style
/// How does the person manage and express emotions?
enum EmotionalRegulation {
  /// Generally calm, stable emotional response
  calm,

  /// Tends to react quickly to emotional stimuli
  reactive,

  /// Tends to suppress or avoid emotional situations
  avoidant,

  /// Watches and processes before responding
  observant,
}

extension EmotionalRegulationLabels on EmotionalRegulation {
  String get arabicLabel {
    switch (this) {
      case EmotionalRegulation.calm:
        return 'هادئ';
      case EmotionalRegulation.reactive:
        return 'متفاعل';
      case EmotionalRegulation.avoidant:
        return 'متحفظ';
      case EmotionalRegulation.observant:
        return 'ملاحظ';
    }
  }
}

/// Relational Orientation
/// How does the person approach relationships?
enum RelationalOrientation {
  /// Values deep connection and closeness
  connected,

  /// Values personal space and autonomy
  independent,

  /// Careful and gradual in forming relationships
  cautious,
}

extension RelationalOrientationLabels on RelationalOrientation {
  String get arabicLabel {
    switch (this) {
      case RelationalOrientation.connected:
        return 'متواصل';
      case RelationalOrientation.independent:
        return 'مستقل';
      case RelationalOrientation.cautious:
        return 'حذر';
    }
  }
}

/// Decision Style
/// How does the person make decisions?
enum DecisionStyle {
  /// Thinks carefully before deciding
  deliberate,

  /// Decides quickly, trusts intuition
  spontaneous,

  /// Prefers to consult others before deciding
  consultative,
}

extension DecisionStyleLabels on DecisionStyle {
  String get arabicLabel {
    switch (this) {
      case DecisionStyle.deliberate:
        return 'متروي';
      case DecisionStyle.spontaneous:
        return 'عفوي';
      case DecisionStyle.consultative:
        return 'استشاري';
    }
  }
}

/// Comfort with Uncertainty
/// How does the person handle unknown situations?
enum UncertaintyComfort {
  /// Adapts well to change
  adaptive,

  /// Enjoys exploring new things
  exploratory,

  /// Prefers familiar, predictable situations
  riskAverse,
}

extension UncertaintyComfortLabels on UncertaintyComfort {
  String get arabicLabel {
    switch (this) {
      case UncertaintyComfort.adaptive:
        return 'متكيف';
      case UncertaintyComfort.exploratory:
        return 'مستكشف';
      case UncertaintyComfort.riskAverse:
        return 'يفضل الوضوح';
    }
  }
}
