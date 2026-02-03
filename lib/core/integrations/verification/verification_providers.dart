import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/feature_flags.dart';
import 'verification_client.dart';
import 'verification_models.dart';

/// Provider for Verification Client.
final verificationClientProvider = Provider<VerificationClient>((ref) {
  if (FeatureFlags.enableVerification) {
    throw UnimplementedError('RealVerificationClient is not implemented yet.');
  }
  return MockVerificationClient();
});

/// V1 Implementation that always returns "not_required" or "verified" for testing.
class MockVerificationClient implements VerificationClient {
  @override
  Future<VerificationResult> checkStatus(VerificationType type) async {
    return VerificationResult(
      type: type,
      status: VerificationStatus.notRequired,
    );
  }

  @override
  Future<void> requestVerification(VerificationType type) async {}

  @override
  Future<VerificationResult> verifyCode(
    VerificationType type,
    String code,
  ) async {
    return VerificationResult(type: type, status: VerificationStatus.verified);
  }
}
