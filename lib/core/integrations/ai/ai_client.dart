import 'ai_models.dart';
import '../../../features/compatibility/domain/compatibility_model.dart';
import '../../../features/advisor/domain/advisor_message.dart';
import '../../../features/advisor/domain/advisor_summary.dart';

/// Abstract contract for Mithaq AI Services.
abstract class AiClient {
  /// Analyze deeper compatibility between two profiles.
  Future<CompatibilityResult> analyzeCompatibility(
    CompatibilityRequest request,
  );

  /// Get AI Advisor response for chat.
  Future<AdvisorMessage> advisorChat(AdvisorRequest request);

  /// Generate a final summary for a consultation.
  Future<AdvisorSummary> generateSummary(AdvisorRequest request);

  /// Extract psychological insights from conversation history.
  Future<List<HiddenInsight>> extractHiddenInsights(
    List<AdvisorMessage> history,
  );
}
