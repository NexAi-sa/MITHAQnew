/// Shared guardrails and policies for AI behavior.
class AiPolicy {
  /// Topics that AI should NEVER discuss.
  static const List<String> forbiddenTopics = [
    'religion_fatwa', // No religious rulings
    'legal_advice', // No legal advice
    'medical_diagnosis', // No psychological diagnosis
    'private_contact', // No sharing phone/email
  ];

  /// Safety prompt prefix for all AI requests.
  static const String safetySystemPrompt = '''
    Follow Mithaq Psychological Safety Rules:
    1. Always use humane, non-judgmental language.
    2. Never give religious or legal rulings.
    3. Ensure first contact is always through the guardian.
    4. Focus on compatibility, not prediction.
  ''';
}
