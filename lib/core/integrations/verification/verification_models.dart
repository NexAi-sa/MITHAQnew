/// Types of verification available in Mithaq.
enum VerificationType {
  email,
  phone,
  identity, // Future KYC
}

/// Status of a verification process.
enum VerificationStatus { notStarted, pending, verified, rejected, notRequired }

/// Result of a verification check.
class VerificationResult {
  final VerificationType type;
  final VerificationStatus status;
  final String? message;

  const VerificationResult({
    required this.type,
    required this.status,
    this.message,
  });
}
