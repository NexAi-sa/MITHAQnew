/// Summary generated after a compatibility consultation
class AdvisorSummary {
  final String id;
  final String? targetProfileId;
  final List<String> compatibilityPoints;
  final List<String> discussionPoints;
  final List<String> suggestedQuestions;
  final DateTime generatedAt;

  const AdvisorSummary({
    required this.id,
    this.targetProfileId,
    required this.compatibilityPoints,
    required this.discussionPoints,
    required this.suggestedQuestions,
    required this.generatedAt,
  });
}
