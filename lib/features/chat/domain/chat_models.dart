enum ChatStage {
  requestSent(0, 'بانتظار الرد'),
  initialApproval(1, 'تواصل أولي'),
  activeCommunication(2, 'تواصل نشط'),
  shufaRequested(3, 'طلب الشوفة'),
  closed(4, 'انتهى التواصل');

  final int value;
  final String label;
  const ChatStage(this.value, this.label);

  static ChatStage fromInt(int value) {
    return ChatStage.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChatStage.requestSent,
    );
  }
}

class ChatSession {
  final String id;
  final String seekerProfileId;
  final String targetProfileId;
  final ChatStage stage;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? closedAt;

  ChatSession({
    required this.id,
    required this.seekerProfileId,
    required this.targetProfileId,
    required this.stage,
    this.startedAt,
    this.expiresAt,
    this.closedAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

class ChatMessage {
  final String id;
  final String sessionId;
  final String? senderProfileId;
  final String text;
  final bool isSystemMessage;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    this.senderProfileId,
    required this.text,
    this.isSystemMessage = false,
    required this.createdAt,
  });
}
