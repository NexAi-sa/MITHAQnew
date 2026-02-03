/// Custom exceptions for Mithaq Backend.
sealed class BackendException implements Exception {
  final String message;
  const BackendException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends BackendException {
  const NetworkException([
    super.message = 'فشل الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى',
  ]);
}

class AuthException extends BackendException {
  const AuthException(super.message);
}

class ProfileNotFoundException extends BackendException {
  const ProfileNotFoundException(String profileId)
    : super('لم يتم العثور على الملف الشخصي');
}

class ValidationException extends BackendException {
  const ValidationException(super.message);
}
