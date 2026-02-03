import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../integrations/backend/backend_client.dart';
import '../integrations/backend/backend_providers.dart';
import '../../main.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  final client = ref.watch(backendClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SafetyRepository(client, prefs);
});

class SafetyRepository {
  final BackendClient _client;
  final SharedPreferences _prefs;

  SafetyRepository(this._client, this._prefs);

  static const String _blockingPrefix = 'blocked_profiles_';

  // 1. Reporting
  Future<void> reportProfile({
    required String reportedProfileId,
    required String reason,
    String? details,
  }) async {
    await _client.reportProfile(
      reportedProfileId: reportedProfileId,
      reason: reason,
      details: details,
    );
  }

  // 2. Blocking (Local Only)
  Future<void> blockProfile(
    String activeProfileId,
    String targetProfileId,
  ) async {
    final key = '$_blockingPrefix$activeProfileId';
    final blocked = _prefs.getStringList(key) ?? [];
    if (!blocked.contains(targetProfileId)) {
      blocked.add(targetProfileId);
      await _prefs.setStringList(key, blocked);
    }
  }

  Future<void> unblockProfile(
    String activeProfileId,
    String targetProfileId,
  ) async {
    final key = '$_blockingPrefix$activeProfileId';
    final blocked = _prefs.getStringList(key) ?? [];
    if (blocked.contains(targetProfileId)) {
      blocked.remove(targetProfileId);
      await _prefs.setStringList(key, blocked);
    }
  }

  List<String> getBlockedProfiles(String activeProfileId) {
    final key = '$_blockingPrefix$activeProfileId';
    return _prefs.getStringList(key) ?? [];
  }

  // 3. Deletion
  Future<void> deleteAccount({
    required String userId,
    String? reason,
    String? feedback,
  }) async {
    await _client.deleteAccount(
      userId: userId,
      reason: reason,
      feedback: feedback,
    );
  }
}
