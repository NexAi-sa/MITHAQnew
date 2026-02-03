import 'verification_models.dart';

/// Abstract contract for Verification Services.
abstract class VerificationClient {
  /// Check current verification status for a specific type.
  Future<VerificationResult> checkStatus(VerificationType type);

  /// Initiate a verification flow.
  Future<void> requestVerification(VerificationType type);

  /// Confirm a verification code/token.
  Future<VerificationResult> verifyCode(VerificationType type, String code);
}
