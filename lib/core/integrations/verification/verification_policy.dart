import 'verification_models.dart';

/// UX Rules for verification flows.
class VerificationPolicy {
  /// Whether a specific verification is mandatory to browse.
  static bool isMandatory(VerificationType type) =>
      false; // V1 is always optional

  /// Soft message for encouraging verification.
  static String getPrivacyHint(VerificationType type) {
    return 'التوثيق يزيد من احتمالية التوافق الجاد بنسبة تصل إلى 40%';
  }
}
