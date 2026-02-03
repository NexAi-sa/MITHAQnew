import '../../../features/seeker/domain/profile.dart';
import '../../session/app_session.dart';

/// Abstract contract for Mithaq Backend.
/// To be implemented by RealBackendClient (V2) or MockBackendClient (V1).
abstract class BackendClient {
  // Auth
  Future<AppSession> signIn(String email, String password);
  Future<AppSession> signUp(
    String email,
    String password, {
    String? phoneNumber,
  });
  Future<void> signOut();

  // Profiles
  Future<SeekerProfile?> fetchProfile(String profileId);
  Future<SeekerProfile> upsertProfile(SeekerProfile profile);
  Future<List<SeekerProfile>> fetchDiscoveryFeed({
    Map<String, dynamic>? filters,
  });
  Future<List<SeekerProfile>> fetchManagedProfiles(String guardianId);

  // Actions
  Future<void> createContactRequest(String targetProfileId);
  Future<void> pauseAccount(bool isPaused, {String? profileId});
  Future<void> deleteAccount({
    required String userId,
    String? reason,
    String? feedback,
  });
  Future<void> reportProfile({
    required String reportedProfileId,
    required String reason,
    String? details,
  });

  // Secure sensitive data fetching
  Future<Map<String, dynamic>?> fetchGuardianContactInfo(String profileId);
  Future<void> unlockGuardianContact(String targetProfileId);

  // UGC: Block & Report
  Future<void> blockUser(String targetUserId);
  Future<List<String>> fetchBlockedUsers();
}
