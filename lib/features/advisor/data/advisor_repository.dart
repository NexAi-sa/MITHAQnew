import '../domain/advisor_message.dart';
import '../domain/advisor_summary.dart';
import '../domain/advisor_insight.dart';

/// In-memory repository for advisor data
class AdvisorRepository {
  final List<AdvisorMessage> _messages = [];
  final List<AdvisorInsight> _hiddenInsights = [];
  final List<AdvisorSummary> _summaries = [];

  // ===== Messages =====
  List<AdvisorMessage> getMessages() => List.unmodifiable(_messages);

  void addMessage(AdvisorMessage message) {
    _messages.add(message);
  }

  void clearMessages() {
    _messages.clear();
  }

  // ===== Hidden Insights (AI-only) =====
  void saveHiddenInsight({
    required String tag,
    required double confidence,
    required String sourceMessageId,
    String? relatedProfileId,
  }) {
    // Validate tag is allowed
    if (!AllowedInsightTags.isAllowed(tag)) {
      return; // Silently reject forbidden tags
    }

    final insight = AdvisorInsight(
      id: 'insight_${DateTime.now().millisecondsSinceEpoch}',
      type: _determineInsightType(tag),
      tag: tag,
      confidence: confidence.clamp(0.0, 1.0),
      sourceMessageId: sourceMessageId,
      relatedProfileId: relatedProfileId,
      createdAt: DateTime.now(),
    );
    _hiddenInsights.add(insight);
  }

  void saveCompatibilityNote({
    required String noteType,
    required String text,
    String? relatedProfileId,
  }) {
    final insight = AdvisorInsight(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      type: InsightType.compatibilityNote,
      tag: noteType,
      confidence: 1.0,
      sourceMessageId: 'system',
      relatedProfileId: relatedProfileId,
      createdAt: DateTime.now(),
    );
    _hiddenInsights.add(insight);
  }

  /// Future-proof delete method (not exposed in UI yet)
  void deleteInsight(String insightId) {
    _hiddenInsights.removeWhere((i) => i.id == insightId);
  }

  void deleteAllInsightsForProfile(String profileId) {
    _hiddenInsights.removeWhere((i) => i.relatedProfileId == profileId);
  }

  InsightType _determineInsightType(String tag) {
    if (AllowedInsightTags.preferences.contains(tag)) {
      return InsightType.preference;
    }
    if (AllowedInsightTags.values.contains(tag)) {
      return InsightType.value;
    }
    if (AllowedInsightTags.sensitivities.contains(tag)) {
      return InsightType.sensitivity;
    }
    return InsightType.compatibilityNote;
  }

  // ===== Summaries =====
  void saveSummary(AdvisorSummary summary) {
    _summaries.add(summary);
  }

  AdvisorSummary? getLatestSummary({String? forProfileId}) {
    if (forProfileId != null) {
      final matching = _summaries.where(
        (s) => s.targetProfileId == forProfileId,
      );
      return matching.isNotEmpty ? matching.last : null;
    }
    return _summaries.isNotEmpty ? _summaries.last : null;
  }

  // ===== Cleanup =====
  void clearAll() {
    _messages.clear();
    _hiddenInsights.clear();
    _summaries.clear();
  }
}
