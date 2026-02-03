import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/feature_flags.dart';
import 'ai_client.dart';
import 'ai_models.dart';
import '../../../features/compatibility/domain/compatibility_model.dart';
import '../../../features/advisor/domain/advisor_message.dart';
import '../../../features/advisor/domain/advisor_summary.dart';

/// Provider for the AI Client.
final aiClientProvider = Provider<AiClient>((ref) {
  if (FeatureFlags.enableRealAI) {
    throw UnimplementedError('RealAiClient is not implemented yet.');
  }
  return MockAiClient();
});

/// V1 Implementation using same mock logic as Phase 6/7.
class MockAiClient implements AiClient {
  @override
  Future<CompatibilityResult> analyzeCompatibility(
    CompatibilityRequest request,
  ) async {
    return CompatibilityResult(
      targetProfileId: request.targetProfile.profileId,
      basic: const AxisScore(axis: CompatibilityAxis.basic, score: 80),
      style: const AxisScore(axis: CompatibilityAxis.style, score: 70),
      psychological: const AxisScore(
        axis: CompatibilityAxis.psychological,
        score: 60,
      ),
      calculatedAt: DateTime.now(),
    );
  }

  @override
  Future<AdvisorMessage> advisorChat(AdvisorRequest request) async {
    return AdvisorMessage(
      id: 'mock_ai_${DateTime.now().millisecondsSinceEpoch}',
      content: 'هذا رد تجريبي من نظام المحاكاة الذكي.',
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<AdvisorSummary> generateSummary(AdvisorRequest request) async {
    return AdvisorSummary(
      id: 'mock_summary',
      targetProfileId: request.targetProfileId,
      compatibilityPoints: ['نقطة توافق 1'],
      discussionPoints: ['نقطة نقاش 1'],
      suggestedQuestions: ['سؤال 1'],
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<HiddenInsight>> extractHiddenInsights(
    List<AdvisorMessage> history,
  ) async {
    return [];
  }
}
