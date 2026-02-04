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

  AdvisorMessage copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    DateTime? timestamp,
    String? relatedProfileId,
  }) {
    return AdvisorMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      relatedProfileId: relatedProfileId ?? this.relatedProfileId,
    );
  }
}

enum MessageSender { user, advisor }
