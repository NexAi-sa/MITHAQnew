/// Feature flags for V2 readiness.
/// All flags MUST default to false for V1.
class FeatureFlags {
  /// Toggle to enable real backend integration (Supabase, Firebase, etc.)
  static const bool enableBackend = true;

  /// Toggle to enable real AI integration (OpenAI, Gemini, etc.)
  /// NOTE: Disabled due to Gemini free tier quota exceeded
  static const bool enableRealAI = false;

  /// Toggle to enable verification flows (Phone, Email, Identity)
  static const bool enableVerification = false;
}
