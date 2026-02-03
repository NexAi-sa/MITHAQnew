import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../session/app_session.dart';
import '../../../features/seeker/domain/profile.dart';
import '../../../features/avatar/domain/avatar_config.dart';
import 'backend_client.dart';
import 'backend_exceptions.dart' as be;

class SupabaseBackendClient implements BackendClient {
  final SupabaseClient _supabase;

  static const String _publicProfileFields = '''
    id, 
    profile_public_id, 
    first_name, 
    owner_user_id, 
    dob, 
    city, 
    marital_status, 
    education_level, 
    tribe, 
    is_paused, 
    gender, 
    job, 
    managed_by_guardian, 
    role_context, 
    name_visibility, 
    shufa_card_active, 
    shufa_card_is_verified,
    guardian_user_id,
    height, 
    build, 
    skin_color, 
    bio, 
    smoking, 
    hijab_preference,
    relationship,
    partner_preferences
  ''';

  SupabaseBackendClient(this._supabase);

  @override
  Future<AppSession> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw const be.AuthException('Sign in failed');

      return AppSession(
        authStatus: AuthStatus.signedIn,
        userId: response.user!.id,
      );
    } catch (e) {
      throw be.AuthException(e.toString());
    }
  }

  @override
  Future<AppSession> signUp(
    String email,
    String password, {
    String? phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) throw const be.AuthException('Sign up failed');

      if (phoneNumber != null) {
        await _supabase
            .from('users_private')
            .update({'phone': phoneNumber})
            .eq('id', response.user!.id);
      }

      return AppSession(
        authStatus: AuthStatus.signedIn,
        userId: response.user!.id,
      );
    } catch (e) {
      throw be.AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<SeekerProfile?> fetchProfile(String profileId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select(_publicProfileFields)
          .eq('id', profileId)
          .maybeSingle();

      if (data == null) return null;
      return _mapToProfile(data);
    } catch (e) {
      throw const be.NetworkException();
    }
  }

  @override
  Future<SeekerProfile> upsertProfile(SeekerProfile profile) async {
    try {
      final data = await _supabase
          .from('profiles')
          .upsert(_mapFromProfile(profile))
          .select(_publicProfileFields)
          .single();
      return _mapToProfile(data);
    } catch (e) {
      throw const be.NetworkException();
    }
  }

  @override
  Future<List<SeekerProfile>> fetchDiscoveryFeed({
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = _supabase
          .from('profiles')
          .select(_publicProfileFields)
          .eq('is_paused', false);

      query = query.inFilter('role_context', ['seeker', 'dependent']);

      final data = await query;
      return (data as List).map((p) => _mapToProfile(p)).toList();
    } catch (e) {
      throw const be.NetworkException();
    }
  }

  @override
  Future<List<SeekerProfile>> fetchManagedProfiles(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select(_publicProfileFields)
          .or('owner_user_id.eq.$userId,guardian_user_id.eq.$userId');

      return (data as List).map((p) => _mapToProfile(p)).toList();
    } catch (e) {
      throw const be.NetworkException();
    }
  }

  @override
  Future<void> createContactRequest(String targetProfileId) async {
    // Phase 2 implementation
  }

  @override
  Future<void> pauseAccount(bool isPaused, {String? profileId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final query = _supabase.from('profiles').update({'is_paused': isPaused});

    if (profileId != null) {
      await query.eq('id', profileId);
    } else {
      await query.eq('owner_user_id', user.id).eq('role_context', 'seeker');
    }
  }

  @override
  Future<void> deleteAccount({
    required String userId,
    String? reason,
    String? feedback,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.functions.invoke(
      'delete_account',
      body: {'user_id': userId, 'reason': reason, 'feedback': feedback},
    );
    await _supabase.auth.signOut();
  }

  @override
  Future<void> reportProfile({
    required String reportedProfileId,
    required String reason,
    String? details,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('reports').insert({
      'reporter_id': user.id,
      'reported_profile_id': reportedProfileId,
      'reason': reason,
      'details': details,
    });
  }

  @override
  Future<Map<String, dynamic>?> fetchGuardianContactInfo(
    String profileId,
  ) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select(
            'shufa_card_guardian_name, shufa_card_guardian_phone, shufa_card_guardian_title',
          )
          .eq('id', profileId)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> unlockGuardianContact(String targetProfileId) async {
    try {
      await _supabase.rpc(
        'unlock_guardian_contact',
        params: {'target_id': targetProfileId},
      );
    } catch (e) {
      print('RPC unlock_guardian_contact error: $e');
    }
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('blocks').upsert({
        'blocker_id': user.id,
        'blocked_id': targetUserId,
      });
    } catch (e) {
      print('Block user error: $e');
    }
  }

  @override
  Future<List<String>> fetchBlockedUsers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', user.id);

      return (data as List)
          .map((attr) => attr['blocked_id'] as String)
          .toList();
    } catch (e) {
      print('Fetch blocked users error: $e');
      return [];
    }
  }

  // Mappers
  SeekerProfile _mapToProfile(Map<String, dynamic> data) {
    final dobData = data['dob'];
    final dob = dobData != null
        ? DateTime.parse(dobData)
        : DateTime(2000, 1, 1);

    return SeekerProfile(
      profileId: data['id'],
      profilePublicId: data['profile_public_id'] ?? '',
      name: data['first_name'] ?? data['full_name'] ?? '',
      userId: data['owner_user_id'],
      dob: dob,
      city: data['city'] ?? '',
      maritalStatus: _parseMaritalStatus(data['marital_status']),
      educationLevel: _parseEducationLevel(data['education_level']),
      tribe: data['tribe'],
      isPaused: data['is_paused'] ?? false,
      gender: data['gender'] == 'male' ? Gender.male : Gender.female,
      job: data['job'] ?? '',
      isManagedByGuardian: data['managed_by_guardian'] ?? false,
      profileOwnerRole: data['role_context'] == 'seeker'
          ? ProfileOwnerRole.seekerSelf
          : ProfileOwnerRole.seekerDependent,
      nameVisibility: data['name_visibility'] ?? 'hidden',
      shufaCardActive: data['shufa_card_active'] ?? false,
      shufaCardGuardianName: data['shufa_card_guardian_name'],
      shufaCardGuardianTitle: data['shufa_card_guardian_title'],
      shufaCardGuardianPhone: data['shufa_card_guardian_phone'],
      shufaCardIsVerified: data['shufa_card_is_verified'] ?? false,
      guardianUserId: data['guardian_user_id'],
      height: data['height'],
      build: data['build'],
      skinColor: data['skin_color'],
      relationship: data['relationship'],
      bio: data['bio'],
      suitorPreferences: SuitorPreferences(
        smoking: _parseSmokingHabit(data['smoking']),
        hijab: _parseHijabPreference(data['hijab_preference']),
      ),
      partnerPreferences: data['partner_preferences'] != null
          ? _parsePartnerPreferences(data['partner_preferences'])
          : null,
    );
  }

  PartnerPreferences _parsePartnerPreferences(Map<String, dynamic> json) {
    return PartnerPreferences(
      minAge: json['min_age'],
      maxAge: json['max_age'],
      acceptedMaritalStatus: (json['accepted_marital_status'] as List?)
          ?.map((e) => _parseMaritalStatus(e as String?))
          .toSet(),
      preferredEducation: (json['preferred_education'] as List?)
          ?.map((e) => _parseEducationLevel(e as String?))
          .toSet(),
      preferredCities: (json['preferred_cities'] as List?)?.cast<String>(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> _mapPartnerPreferences(PartnerPreferences? p) {
    if (p == null) return {};
    return {
      'min_age': p.minAge,
      'max_age': p.maxAge,
      'accepted_marital_status': p.acceptedMaritalStatus
          ?.map((e) => e.name)
          .toList(),
      'preferred_education': p.preferredEducation?.map((e) => e.name).toList(),
      'preferred_cities': p.preferredCities,
      'notes': p.notes,
    };
  }

  Map<String, dynamic> _mapFromProfile(SeekerProfile p) {
    final String publicId = p.profilePublicId.isNotEmpty
        ? p.profilePublicId
        : 'MITH-${DateTime.now().microsecondsSinceEpoch.toString().substring(10)}';

    return {
      if (p.profileId != 'new') 'id': p.profileId,
      'owner_user_id': p.userId,
      'role_context': p.profileOwnerRole == ProfileOwnerRole.seekerSelf
          ? 'seeker'
          : 'dependent',
      'profile_public_id': publicId,
      'first_name': p.name,
      'dob': p.dob?.toIso8601String().split('T')[0],
      'gender': p.gender.name,
      'job': p.job,
      'city': p.city,
      'marital_status': p.maritalStatus.name,
      'education_level': p.educationLevel?.name ?? EducationLevel.other.name,
      'tribe': p.tribe,
      'is_paused': p.isPaused,
      'name_visibility': p.nameVisibility,
      'managed_by_guardian': p.isManagedByGuardian,
      'shufa_card_active': p.shufaCardActive,
      'shufa_card_guardian_name': p.shufaCardGuardianName,
      'shufa_card_guardian_title': p.shufaCardGuardianTitle,
      'shufa_card_guardian_phone': p.shufaCardGuardianPhone,
      'shufa_card_is_verified': p.shufaCardIsVerified,
      'guardian_user_id': p.guardianUserId,
      'height': p.height,
      'build': p.build,
      'skin_color': p.skinColor,
      'relationship': p.relationship,
      'bio': p.bio,
      'smoking': p.suitorPreferences?.smoking?.name,
      'hijab_preference': p.suitorPreferences?.hijab?.name,
      'partner_preferences': _mapPartnerPreferences(p.partnerPreferences),
    };
  }

  MaritalStatus _parseMaritalStatus(String? val) {
    return MaritalStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => MaritalStatus.single,
    );
  }

  EducationLevel _parseEducationLevel(String? val) {
    return EducationLevel.values.firstWhere(
      (e) => e.name == val,
      orElse: () => EducationLevel.other,
    );
  }

  SmokingHabit? _parseSmokingHabit(String? val) {
    if (val == null) return null;
    return SmokingHabit.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SmokingHabit.no,
    );
  }

  HijabPreference? _parseHijabPreference(String? val) {
    if (val == null) return null;
    return HijabPreference.values.firstWhere(
      (e) => e.name == val,
      orElse: () => HijabPreference.hijab,
    );
  }
}
