import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../seeker/domain/profile.dart';
import '../../seeker/presentation/widgets/profile_grid_card.dart';
import '../../personality/domain/personality_indicators.dart';

/// AI Compatibility Agent
///
/// Responsible for:
/// - Monitoring user profiles and personality data
/// - Analyzing compatibility between users
/// - Updating compatibility badges on profile cards
/// - Providing real-time compatibility insights
class CompatibilityAgent {
  // Cache for compatibility scores
  final Map<String, CompatibilityResult> _compatibilityCache = {};

  // Stream controller for compatibility updates
  final _compatibilityUpdates =
      StreamController<CompatibilityUpdate>.broadcast();

  CompatibilityAgent();

  /// Stream of compatibility updates for UI reactivity
  Stream<CompatibilityUpdate> get updates => _compatibilityUpdates.stream;

  /// Calculate compatibility between current user and a target profile
  Future<CompatibilityResult> analyzeCompatibility({
    required String currentUserId,
    required SeekerProfile targetProfile,
    PersonalityIndicators? currentUserIndicators,
    PersonalityIndicators? targetIndicators,
  }) async {
    final cacheKey = '${currentUserId}_${targetProfile.profileId}';

    // Check cache first
    if (_compatibilityCache.containsKey(cacheKey)) {
      final cached = _compatibilityCache[cacheKey]!;
      // Cache valid for 1 hour
      if (DateTime.now().difference(cached.analyzedAt).inHours < 1) {
        return cached;
      }
    }

    // Perform analysis
    final result = await _performAnalysis(
      currentUserId: currentUserId,
      targetProfile: targetProfile,
      currentIndicators: currentUserIndicators,
      targetIndicators: targetIndicators,
    );

    // Cache result
    _compatibilityCache[cacheKey] = result;

    // Notify listeners
    _compatibilityUpdates.add(
      CompatibilityUpdate(
        targetProfileId: targetProfile.profileId,
        result: result,
      ),
    );

    return result;
  }

  /// Get compatibility level for display on profile cards
  CompatibilityLevel getCompatibilityLevel(String targetProfileId) {
    // Find in cache
    for (final entry in _compatibilityCache.entries) {
      if (entry.key.endsWith('_$targetProfileId')) {
        return entry.value.level;
      }
    }
    return CompatibilityLevel.unclear;
  }

  /// Batch analyze multiple profiles
  Future<Map<String, CompatibilityLevel>> analyzeMultiple({
    required String currentUserId,
    required List<SeekerProfile> profiles,
    PersonalityIndicators? currentUserIndicators,
  }) async {
    final results = <String, CompatibilityLevel>{};

    for (final profile in profiles) {
      final result = await analyzeCompatibility(
        currentUserId: currentUserId,
        targetProfile: profile,
        currentUserIndicators: currentUserIndicators,
      );
      results[profile.profileId] = result.level;
    }

    return results;
  }

  /// Core analysis logic
  Future<CompatibilityResult> _performAnalysis({
    required String currentUserId,
    required SeekerProfile targetProfile,
    PersonalityIndicators? currentIndicators,
    PersonalityIndicators? targetIndicators,
    SeekerProfile? currentProfile,
  }) async {
    // Calculate dimension scores
    double totalScore = 0;
    final reasons = <String>[];
    final suggestions = <String>[];

    double emotionalScore = 0.5;
    double relationalScore = 0.5;
    double decisionScore = 0.5;
    double uncertaintyScore = 0.5;
    double preferencesScore = 0.5;
    double bioScore = 0.5;

    // ==========================================
    // 1. PERSONALITY TEST MATCH (40% total)
    // ==========================================
    if (currentIndicators != null && targetIndicators != null) {
      // 1a. Emotional Regulation Match (10%)
      final emotionalMatch = _matchEmotionalRegulation(
        currentIndicators.emotionalRegulation,
        targetIndicators.emotionalRegulation,
      );
      emotionalScore = emotionalMatch.score;
      totalScore += emotionalMatch.score * 0.10;
      if (emotionalMatch.insight != null) reasons.add(emotionalMatch.insight!);

      // 1b. Relational Orientation Match (12%)
      final relationalMatch = _matchRelationalOrientation(
        currentIndicators.relationalOrientation,
        targetIndicators.relationalOrientation,
      );
      relationalScore = relationalMatch.score;
      totalScore += relationalMatch.score * 0.12;
      if (relationalMatch.insight != null) {
        reasons.add(relationalMatch.insight!);
      }

      // 1c. Decision Style Match (10%)
      final decisionMatch = _matchDecisionStyle(
        currentIndicators.decisionStyle,
        targetIndicators.decisionStyle,
      );
      decisionScore = decisionMatch.score;
      totalScore += decisionMatch.score * 0.10;
      if (decisionMatch.insight != null) reasons.add(decisionMatch.insight!);

      // 1d. Comfort with Uncertainty Match (8%)
      final uncertaintyMatch = _matchUncertaintyComfort(
        currentIndicators.uncertaintyComfort,
        targetIndicators.uncertaintyComfort,
      );
      uncertaintyScore = uncertaintyMatch.score;
      totalScore += uncertaintyMatch.score * 0.08;
      if (uncertaintyMatch.insight != null) {
        reasons.add(uncertaintyMatch.insight!);
      }
    } else {
      // Personality test not completed - partial analysis
      suggestions.add('أكمل اختبار تحليل الشخصية للحصول على نتائج أدق');
    }

    // ==========================================
    // 2. PARTNER PREFERENCES MATCH (35%)
    // ==========================================
    if (currentProfile != null) {
      final preferencesMatch = _matchPartnerPreferences(
        currentProfile: currentProfile,
        targetProfile: targetProfile,
      );
      preferencesScore = preferencesMatch.score;
      totalScore += preferencesMatch.score * 0.35;
      if (preferencesMatch.insight != null) {
        reasons.add(preferencesMatch.insight!);
      }

      // Add specific suggestions based on preferences match
      if (preferencesMatch.score < 0.5) {
        suggestions.add('يوجد بعض الاختلافات في المواصفات المطلوبة');
      }
    }

    // ==========================================
    // 3. BIO/ABOUT SIMILARITY (15%)
    // ==========================================
    if (currentProfile?.bio != null && targetProfile.bio != null) {
      final bioMatch = _analyzeBioCompatibility(
        currentProfile!.bio!,
        targetProfile.bio!,
      );
      bioScore = bioMatch.score;
      totalScore += bioMatch.score * 0.15;
      if (bioMatch.insight != null) reasons.add(bioMatch.insight!);
    } else {
      // Bio not provided
      totalScore += 0.5 * 0.15; // Neutral score
    }

    // ==========================================
    // 4. BASIC PROFILE MATCH (10%)
    // ==========================================
    if (currentProfile != null) {
      final basicMatch = _matchBasicProfile(
        currentProfile: currentProfile,
        targetProfile: targetProfile,
      );
      totalScore += basicMatch.score * 0.10;
      if (basicMatch.insight != null) reasons.add(basicMatch.insight!);
    }

    // Determine compatibility level
    CompatibilityLevel level;
    if (totalScore >= 0.80) {
      level = CompatibilityLevel.excellent;
      suggestions.add('توافق عالي في معظم الجوانب الشخصية والمواصفات');
    } else if (totalScore >= 0.60) {
      level = CompatibilityLevel.good;
      suggestions.add('توافق جيد مع بعض الاختلافات التي يمكن التفاهم عليها');
    } else if (totalScore >= 0.40) {
      level = CompatibilityLevel.unclear;
      suggestions.add('يحتاج تواصل أكثر لفهم التوافق بشكل أفضل');
    } else {
      level = CompatibilityLevel.notCompatible;
      suggestions.add('اختلافات في المواصفات والتفضيلات');
    }

    return CompatibilityResult(
      level: level,
      score: totalScore,
      reasons: reasons,
      suggestions: suggestions,
      analyzedAt: DateTime.now(),
      dimensions: CompatibilityDimensions(
        emotionalRegulation: emotionalScore,
        relationalOrientation: relationalScore,
        decisionStyle: decisionScore,
        uncertaintyComfort: uncertaintyScore,
        preferencesMatch: preferencesScore,
        bioSimilarity: bioScore,
      ),
    );
  }

  /// Match emotional regulation styles
  DimensionMatch _matchEmotionalRegulation(
    EmotionalRegulation? a,
    EmotionalRegulation? b,
  ) {
    if (a == null || b == null) {
      return const DimensionMatch(score: 0.5);
    }

    // Similar styles = good match
    if (a == b) {
      return const DimensionMatch(
        score: 1.0,
        insight: 'تشابه في أسلوب إدارة المشاعر',
      );
    }

    // Complementary matches
    if ((a == EmotionalRegulation.calm && b == EmotionalRegulation.observant) ||
        (a == EmotionalRegulation.observant && b == EmotionalRegulation.calm)) {
      return const DimensionMatch(
        score: 0.85,
        insight: 'تكامل جيد في التعامل مع المواقف',
      );
    }

    // Challenging matches
    if ((a == EmotionalRegulation.reactive &&
            b == EmotionalRegulation.avoidant) ||
        (a == EmotionalRegulation.avoidant &&
            b == EmotionalRegulation.reactive)) {
      return const DimensionMatch(
        score: 0.3,
        insight: 'قد يحتاج تفهم متبادل في طريقة التعامل',
      );
    }

    return const DimensionMatch(score: 0.6);
  }

  /// Match relational orientation
  DimensionMatch _matchRelationalOrientation(
    RelationalOrientation? a,
    RelationalOrientation? b,
  ) {
    if (a == null || b == null) {
      return const DimensionMatch(score: 0.5);
    }

    if (a == b) {
      return const DimensionMatch(
        score: 1.0,
        insight: 'تشابه في أسلوب التواصل والعلاقات',
      );
    }

    // Connected + Independent = challenging
    if ((a == RelationalOrientation.connected &&
            b == RelationalOrientation.independent) ||
        (a == RelationalOrientation.independent &&
            b == RelationalOrientation.connected)) {
      return const DimensionMatch(
        score: 0.5,
        insight: 'اختلاف في مستوى القرب المتوقع',
      );
    }

    return const DimensionMatch(score: 0.7);
  }

  /// Match decision styles
  DimensionMatch _matchDecisionStyle(DecisionStyle? a, DecisionStyle? b) {
    if (a == null || b == null) {
      return const DimensionMatch(score: 0.5);
    }

    if (a == b) {
      return const DimensionMatch(score: 1.0, insight: 'تشابه في أسلوب اتخاذ القرار');
    }

    // Deliberate + Spontaneous = complementary but challenging
    if ((a == DecisionStyle.deliberate && b == DecisionStyle.spontaneous) ||
        (a == DecisionStyle.spontaneous && b == DecisionStyle.deliberate)) {
      return const DimensionMatch(
        score: 0.55,
        insight: 'اختلاف في سرعة اتخاذ القرارات قابل للتكيف',
      );
    }

    // Consultative works well with both
    if (a == DecisionStyle.consultative || b == DecisionStyle.consultative) {
      return const DimensionMatch(
        score: 0.8,
        insight: 'ميل للتشاور يساعد على التفاهم',
      );
    }

    return const DimensionMatch(score: 0.65);
  }

  /// Match uncertainty comfort levels
  DimensionMatch _matchUncertaintyComfort(
    UncertaintyComfort? a,
    UncertaintyComfort? b,
  ) {
    if (a == null || b == null) {
      return const DimensionMatch(score: 0.5);
    }

    if (a == b) {
      return const DimensionMatch(score: 1.0, insight: 'تشابه في التعامل مع التغيير');
    }

    // Adaptive + Exploratory = great match
    if ((a == UncertaintyComfort.adaptive &&
            b == UncertaintyComfort.exploratory) ||
        (a == UncertaintyComfort.exploratory &&
            b == UncertaintyComfort.adaptive)) {
      return const DimensionMatch(score: 0.9, insight: 'مرونة مشتركة تجاه التغيير');
    }

    // Risk-averse + Exploratory = challenging
    if ((a == UncertaintyComfort.riskAverse &&
            b == UncertaintyComfort.exploratory) ||
        (a == UncertaintyComfort.exploratory &&
            b == UncertaintyComfort.riskAverse)) {
      return const DimensionMatch(score: 0.4, insight: 'اختلاف في الرغبة بالمخاطرة');
    }

    return const DimensionMatch(score: 0.65);
  }

  // ==========================================
  // PARTNER PREFERENCES MATCHING
  // ==========================================

  /// Match partner preferences - checks if target meets current user's preferences
  DimensionMatch _matchPartnerPreferences({
    required SeekerProfile currentProfile,
    required SeekerProfile targetProfile,
  }) {
    final prefs = currentProfile.partnerPreferences;
    if (prefs == null) {
      return const DimensionMatch(
        score: 0.7,
        insight: 'لم تحدد تفضيلات محددة للشريك',
      );
    }

    double score = 1.0;
    final issues = <String>[];

    // Check age range
    final targetAge = targetProfile.age;
    if (targetAge != null) {
      if (prefs.minAge != null && targetAge < prefs.minAge!) {
        score -= 0.2;
        issues.add('العمر أقل من الحد الأدنى');
      }
      if (prefs.maxAge != null && targetAge > prefs.maxAge!) {
        score -= 0.2;
        issues.add('العمر أكبر من الحد الأقصى');
      }
    } else {
      score -= 0.1;
      issues.add('العمر غير متوفر للتحقق');
    }

    // Check marital status preference
    if (prefs.acceptedMaritalStatus != null &&
        prefs.acceptedMaritalStatus!.isNotEmpty &&
        !prefs.acceptedMaritalStatus!.contains(targetProfile.maritalStatus)) {
      score -= 0.25;
      issues.add('الحالة الاجتماعية مختلفة');
    }

    // Check education preference
    if (prefs.preferredEducation != null &&
        prefs.preferredEducation!.isNotEmpty &&
        targetProfile.educationLevel != null &&
        !prefs.preferredEducation!.contains(targetProfile.educationLevel)) {
      score -= 0.15;
      issues.add('المستوى التعليمي مختلف');
    }

    // Check city preference
    if (prefs.preferredCities != null &&
        prefs.preferredCities!.isNotEmpty &&
        !prefs.preferredCities!.contains(targetProfile.city)) {
      score -= 0.15;
      issues.add('المدينة مختلفة');
    }

    // Clamp score
    score = score.clamp(0.0, 1.0);

    // Generate insight
    String? insight;
    if (score >= 0.9) {
      insight = 'يطابق تفضيلاتك بشكل ممتاز';
    } else if (score >= 0.7) {
      insight = 'يتوافق مع معظم تفضيلاتك';
    } else if (score >= 0.5) {
      insight = 'يوجد بعض الاختلافات: ${issues.take(2).join("، ")}';
    } else {
      insight = 'اختلافات في التفضيلات: ${issues.join("، ")}';
    }

    return DimensionMatch(score: score, insight: insight);
  }

  // ==========================================
  // BIO/ABOUT SIMILARITY ANALYSIS
  // ==========================================

  /// Analyze bio compatibility using keyword matching
  DimensionMatch _analyzeBioCompatibility(String bio1, String bio2) {
    if (bio1.isEmpty || bio2.isEmpty) {
      return const DimensionMatch(score: 0.5);
    }

    // Normalize and tokenize
    final words1 = _extractKeywords(bio1);
    final words2 = _extractKeywords(bio2);

    if (words1.isEmpty || words2.isEmpty) {
      return const DimensionMatch(score: 0.5);
    }

    // Calculate Jaccard similarity
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);

    final similarity = intersection.length / union.length;

    // Look for matching interests/values
    final commonInterests = _findCommonInterests(words1, words2);

    String? insight;
    if (commonInterests.isNotEmpty) {
      insight = 'اهتمامات مشتركة: ${commonInterests.take(3).join("، ")}';
    } else if (similarity > 0.3) {
      insight = 'تشابه في أسلوب التعبير';
    }

    // Boost score if common interests found
    final score = (similarity * 0.7 + (commonInterests.isNotEmpty ? 0.3 : 0))
        .clamp(0.0, 1.0);

    return DimensionMatch(score: score, insight: insight);
  }

  /// Extract meaningful keywords from Arabic text
  Set<String> _extractKeywords(String text) {
    // Arabic stop words to filter out
    const stopWords = {
      'في',
      'من',
      'على',
      'إلى',
      'عن',
      'مع',
      'هذا',
      'هذه',
      'التي',
      'الذي',
      'أنا',
      'أن',
      'إن',
      'كان',
      'كانت',
      'هو',
      'هي',
      'نحن',
      'أنت',
      'هم',
      'قد',
      'لقد',
      'ما',
      'لا',
      'لم',
      'بعد',
      'قبل',
      'كل',
      'بين',
      'حتى',
    };

    // Normalize and split
    final normalized = text
        .replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), ' ')
        .toLowerCase();

    final words = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet();

    return words;
  }

  /// Find common interest keywords
  Set<String> _findCommonInterests(Set<String> words1, Set<String> words2) {
    // Interest-related keywords
    const interestKeywords = {
      'رياضة',
      'سفر',
      'قراءة',
      'كتب',
      'طبخ',
      'موسيقى',
      'فن',
      'تصوير',
      'برمجة',
      'تقنية',
      'أعمال',
      'تجارة',
      'استثمار',
      'طبيعة',
      'حيوانات',
      'أفلام',
      'مسلسلات',
      'ألعاب',
      'تعلم',
      'لغات',
      'دين',
      'عبادة',
      'عائلة',
      'أطفال',
      'صحة',
      'لياقة',
      'طموح',
      'هدوء',
      'مغامرة',
    };

    final interests1 = words1.where(
      (w) => interestKeywords.any((k) => w.contains(k) || k.contains(w)),
    );
    final interests2 = words2.where(
      (w) => interestKeywords.any((k) => w.contains(k) || k.contains(w)),
    );

    return interests1.toSet().intersection(interests2.toSet());
  }

  // ==========================================
  // BASIC PROFILE MATCHING
  // ==========================================

  /// Match basic profile attributes
  DimensionMatch _matchBasicProfile({
    required SeekerProfile currentProfile,
    required SeekerProfile targetProfile,
  }) {
    double score = 0.5;
    final matches = <String>[];

    // Same city bonus
    if (currentProfile.city == targetProfile.city) {
      score += 0.2;
      matches.add('نفس المدينة');
    }

    // Same tribe bonus (if both specified)
    if (currentProfile.tribe != null &&
        targetProfile.tribe != null &&
        currentProfile.tribe == targetProfile.tribe) {
      score += 0.15;
      matches.add('نفس القبيلة');
    }

    // Similar education level
    if (currentProfile.educationLevel != null &&
        targetProfile.educationLevel != null &&
        currentProfile.educationLevel == targetProfile.educationLevel) {
      score += 0.15;
      matches.add('نفس المستوى التعليمي');
    }

    // Clamp score
    score = score.clamp(0.0, 1.0);

    String? insight;
    if (matches.isNotEmpty) {
      insight = 'قواسم مشتركة: ${matches.join("، ")}';
    }

    return DimensionMatch(score: score, insight: insight);
  }

  /// Clear cache for a specific user
  void clearCache(String userId) {
    _compatibilityCache.removeWhere(
      (key, value) => key.startsWith('${userId}_'),
    );
  }

  /// Dispose resources
  void dispose() {
    _compatibilityUpdates.close();
  }
}

/// Result of compatibility analysis
class CompatibilityResult {
  final CompatibilityLevel level;
  final double score;
  final List<String> reasons;
  final List<String> suggestions;
  final DateTime analyzedAt;
  final CompatibilityDimensions? dimensions;

  const CompatibilityResult({
    required this.level,
    required this.score,
    required this.reasons,
    required this.suggestions,
    required this.analyzedAt,
    this.dimensions,
  });
}

/// Detailed dimension scores
class CompatibilityDimensions {
  final double emotionalRegulation;
  final double relationalOrientation;
  final double decisionStyle;
  final double uncertaintyComfort;
  final double preferencesMatch;
  final double bioSimilarity;

  const CompatibilityDimensions({
    required this.emotionalRegulation,
    required this.relationalOrientation,
    required this.decisionStyle,
    required this.uncertaintyComfort,
    this.preferencesMatch = 0.5,
    this.bioSimilarity = 0.5,
  });
}

/// Update notification for compatibility changes
class CompatibilityUpdate {
  final String targetProfileId;
  final CompatibilityResult result;

  const CompatibilityUpdate({
    required this.targetProfileId,
    required this.result,
  });
}

/// Helper class for dimension matching
class DimensionMatch {
  final double score;
  final String? insight;

  const DimensionMatch({required this.score, this.insight});
}

// ============================================
// Riverpod Providers
// ============================================

/// Main compatibility agent provider
final compatibilityAgentProvider = Provider<CompatibilityAgent>((ref) {
  final agent = CompatibilityAgent();
  ref.onDispose(() => agent.dispose());
  return agent;
});

/// Stream provider for compatibility updates
final compatibilityUpdatesProvider = StreamProvider<CompatibilityUpdate>((ref) {
  final agent = ref.watch(compatibilityAgentProvider);
  return agent.updates;
});

/// Provider for getting compatibility level for a specific profile
final profileCompatibilityProvider =
    Provider.family<CompatibilityLevel, String>((ref, profileId) {
      final agent = ref.watch(compatibilityAgentProvider);
      return agent.getCompatibilityLevel(profileId);
    });
