import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/integrations/backend/backend_client.dart';
import '../../../core/integrations/backend/backend_providers.dart';
import '../domain/profile.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(backendClientProvider);
  return ProfileRepository(client);
});

final singleProfileProvider = FutureProvider.family<SeekerProfile?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfileById(id);
});

final shufaCardUnlockedProvider = FutureProvider.family<bool, (String, String)>(
  (ref, args) async {
    // Real implementation: check via backend logic or local state
    return false;
  },
);

final guardianContactInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      profileId,
    ) async {
      final repository = ref.watch(profileRepositoryProvider);
      return repository.fetchGuardianContactInfo(profileId);
    });

final discoveryProfilesProvider = FutureProvider<List<SeekerProfile>>((
  ref,
) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getAllProfiles();
});

final guardianDependentsProvider = FutureProvider<List<SeekerProfile>>((
  ref,
) async {
  final repository = ref.watch(profileRepositoryProvider);
  final session = ref.watch(sessionProvider);
  final userId = session.userId;
  if (userId == null || session.role != UserRole.guardian) return [];
  return repository.getProfilesByUserId(userId);
});

final myProfileProvider = FutureProvider<SeekerProfile?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  final session = ref.watch(sessionProvider);
  final userId = session.userId;
  if (userId == null) return null;

  try {
    if (session.role == UserRole.seeker) {
      final profiles = await repository.getProfilesByUserId(userId);
      if (profiles.isNotEmpty) return profiles.first;
      return null;
    }

    if (session.role == UserRole.guardian &&
        session.activeDependentId != null) {
      return await repository.getProfileById(session.activeDependentId!);
    }
  } catch (e) {
    print('Error fetching myProfile: $e');
  }
  return null;
});

class ProfileRepository {
  final BackendClient _client;

  ProfileRepository(this._client);

  Future<List<SeekerProfile>> getAllProfiles() async {
    return _client.fetchDiscoveryFeed();
  }

  Future<SeekerProfile?> getProfileById(String id) async {
    return _client.fetchProfile(id);
  }

  Future<void> togglePause(String profileId) async {
    final profile = await _client.fetchProfile(profileId);
    if (profile != null) {
      await _client.pauseAccount(!profile.isPaused, profileId: profileId);
    }
  }

  Future<List<SeekerProfile>> getProfilesByUserId(String userId) async {
    return _client.fetchManagedProfiles(userId);
  }

  Future<SeekerProfile> addProfile(SeekerProfile profile) async {
    return _client.upsertProfile(profile);
  }

  Future<void> savePreferences(
    String profileId,
    PartnerPreferences prefs,
  ) async {
    final profile = await _client.fetchProfile(profileId);
    if (profile != null) {
      final updated = profile.copyWith(partnerPreferences: prefs);
      await _client.upsertProfile(updated);
    }
  }

  Future<List<SeekerProfile>> filterProfiles({
    String? city,
    String? tribe,
    EducationLevel? education,
    Set<MaritalStatus>? maritalStatuses,
  }) async {
    final all = await _client.fetchDiscoveryFeed();
    return all.where((p) {
      if (city != null && p.city != city) return false;
      if (tribe != null && p.tribe != tribe) return false;
      if (education != null && p.educationLevel != education) return false;
      if (maritalStatuses != null &&
          maritalStatuses.isNotEmpty &&
          !maritalStatuses.contains(p.maritalStatus)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> deleteAccount(
    String userId, {
    String? reason,
    String? feedback,
  }) async {
    await _client.deleteAccount(
      userId: userId,
      reason: reason,
      feedback: feedback,
    );
  }

  Future<Map<String, dynamic>?> fetchGuardianContactInfo(
    String profileId,
  ) async {
    return _client.fetchGuardianContactInfo(profileId);
  }

  Future<void> unlockGuardianContact(String targetProfileId) async {
    // This calls the supabase function to request access
    await _client.unlockGuardianContact(targetProfileId);
  }

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

  Future<void> blockUser(String targetUserId) async {
    await _client.blockUser(targetUserId);
  }
}
