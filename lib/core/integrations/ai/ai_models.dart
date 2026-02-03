import '../../../features/seeker/domain/profile.dart';
import '../../../features/advisor/domain/advisor_message.dart';

/// Request for compatibility analysis.
class CompatibilityRequest {
  final SeekerProfile userProfile;
  final SeekerProfile targetProfile;

  const CompatibilityRequest({
    required this.userProfile,
    required this.targetProfile,
  });
}

/// Request for advisor consultation.
class AdvisorRequest {
  final List<AdvisorMessage> history;
  final String? targetProfileId;
  final Map<String, dynamic>? context;

  const AdvisorRequest({
    required this.history,
    this.targetProfileId,
    this.context,
  });
}

/// Hidden insights extracted from communication.
class HiddenInsight {
  final String category;
  final String observation;
  final double confidence;

  const HiddenInsight({
    required this.category,
    required this.observation,
    required this.confidence,
  });
}
