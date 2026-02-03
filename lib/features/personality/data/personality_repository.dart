import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/personality_indicators.dart';

/// Repository for personality test data
class PersonalityRepository {
  final SupabaseClient _supabase;

  PersonalityRepository(this._supabase);

  /// Save personality indicators for a user
  Future<void> saveIndicators(PersonalityIndicators indicators) async {
    await _supabase.from('personality_indicators').upsert({
      'user_id': indicators.userId,
      'emotional_regulation': indicators.emotionalRegulation?.name,
      'relational_orientation': indicators.relationalOrientation?.name,
      'decision_style': indicators.decisionStyle?.name,
      'uncertainty_comfort': indicators.uncertaintyComfort?.name,
      'raw_responses': indicators.rawTestResponses,
      'analyzed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get personality indicators for a user
  Future<PersonalityIndicators?> getIndicators(String userId) async {
    final response = await _supabase
        .from('personality_indicators')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return PersonalityIndicators.fromJson(response);
  }

  /// Check if user has completed personality test
  Future<bool> hasCompletedTest(String userId) async {
    final response = await _supabase
        .from('personality_indicators')
        .select('analyzed_at')
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Save compatibility score between two users
  Future<void> saveCompatibilityScore({
    required String userId1,
    required String userId2,
    required double score,
    required String level,
    required Map<String, double> dimensions,
  }) async {
    // Ensure consistent ordering of user IDs
    final sortedIds = [userId1, userId2]..sort();

    await _supabase.from('compatibility_scores').upsert({
      'user_id_1': sortedIds[0],
      'user_id_2': sortedIds[1],
      'score': score,
      'level': level,
      'dimensions': dimensions,
      'calculated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get compatibility score between two users
  Future<Map<String, dynamic>?> getCompatibilityScore(
    String userId1,
    String userId2,
  ) async {
    final sortedIds = [userId1, userId2]..sort();

    final response = await _supabase
        .from('compatibility_scores')
        .select()
        .eq('user_id_1', sortedIds[0])
        .eq('user_id_2', sortedIds[1])
        .maybeSingle();

    return response;
  }

  /// Get all compatibility scores for a user
  Future<List<Map<String, dynamic>>> getAllCompatibilityScores(
    String userId,
  ) async {
    final response = await _supabase
        .from('compatibility_scores')
        .select()
        .or('user_id_1.eq.$userId,user_id_2.eq.$userId');

    return List<Map<String, dynamic>>.from(response);
  }
}

// Providers
final personalityRepositoryProvider = Provider<PersonalityRepository>((ref) {
  return PersonalityRepository(Supabase.instance.client);
});

/// Provider to get current user's personality indicators
final currentUserIndicatorsProvider = FutureProvider<PersonalityIndicators?>((
  ref,
) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final repo = ref.watch(personalityRepositoryProvider);
  return repo.getIndicators(userId);
});

/// Provider to check if current user completed personality test
final hasCompletedPersonalityTestProvider = FutureProvider<bool>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;

  final repo = ref.watch(personalityRepositoryProvider);
  return repo.hasCompletedTest(userId);
});
