/// Represents a single message in the advisor chat
class AdvisorMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final String? relatedProfileId;

  const AdvisorMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.relatedProfileId,
  });
}

enum MessageSender { user, advisor }
