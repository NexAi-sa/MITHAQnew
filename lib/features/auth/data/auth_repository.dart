import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/integrations/backend/backend_client.dart';
import '../../../core/integrations/backend/backend_providers.dart';
import '../../../core/session/app_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(backendClientProvider);
  return AuthRepository(client);
});

class AuthRepository {
  final BackendClient _client;

  AuthRepository(this._client);

  Future<AppSession> signIn(String email, String password) async {
    return _client.signIn(email, password);
  }

  Future<AppSession> signUp(String email, String password) async {
    return _client.signUp(email, password);
  }

  Future<void> signOut() async {
    await _client.signOut();
  }
}
