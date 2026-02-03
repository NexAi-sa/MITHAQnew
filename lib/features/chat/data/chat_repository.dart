import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/chat_models.dart';
import '../../seeker/data/profile_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

final shufaCardUnlockedProvider = FutureProvider.family<bool, (String, String)>(
  (ref, ids) async {
    final repo = ref.watch(chatRepositoryProvider);
    return repo.isShufaCardUnlocked(ids.$1, ids.$2);
  },
);

final guardianContactInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      profileId,
    ) async {
      final repo = ref.watch(profileRepositoryProvider);
      return repo.fetchGuardianContactInfo(profileId);
    });

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  Future<List<ChatSession>> getSessionsForProfile(String profileId) async {
    final response = await _client
        .from('chat_sessions')
        .select()
        .or('seeker_profile_id.eq.$profileId,target_profile_id.eq.$profileId');
    return (response as List).map((s) => _mapSession(s)).toList();
  }

  Future<ChatSession?> getSession(String seekerId, String targetId) async {
    try {
      final response = await _client
          .from('chat_sessions')
          .select()
          .or(
            'and(seeker_profile_id.eq.$seekerId,target_profile_id.eq.$targetId),and(seeker_profile_id.eq.$targetId,target_profile_id.eq.$seekerId)',
          )
          .maybeSingle();

      if (response == null) {
        // Demo profiles: return null to allow new requests
        return null;
      }
      return _mapSession(response);
    } catch (e) {
      // On error, return null to allow contact request
      return null;
    }
  }

  Future<List<ChatSession>> getInboundSessions(
    List<String> dependentIds,
  ) async {
    if (dependentIds.isEmpty) return [];

    final response = await _client
        .from('chat_sessions')
        .select()
        .inFilter('target_profile_id', dependentIds);

    return (response as List).map((s) => _mapSession(s)).toList();
  }

  Stream<List<ChatSession>> getInboundSessionsStream(
    List<String> dependentIds,
  ) {
    if (dependentIds.isEmpty) return Stream.value([]);

    return _client
        .from('chat_sessions')
        .stream(primaryKey: ['id'])
        .inFilter('target_profile_id', dependentIds)
        .map((list) => list.map((s) => _mapSession(s)).toList());
  }

  Stream<ChatSession?> getSessionByIdStream(String sessionId) {
    return _client
        .from('chat_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((list) => list.isEmpty ? null : _mapSession(list.first));
  }

  Future<ChatSession> createSession(String seekerId, String targetId) async {
    final response = await _client
        .from('chat_sessions')
        .insert({
          'seeker_profile_id': seekerId,
          'target_profile_id': targetId,
          'stage': 0,
        })
        .select()
        .single();

    return _mapSession(response);
  }

  Future<void> updateStage(
    String sessionId,
    ChatStage stage, {
    String? reason,
  }) async {
    final Map<String, dynamic> update = {'stage': stage.value};
    if (reason != null) {
      update['closed_reason'] = reason;
    }

    // Rely on server-side triggers for started_at, expires_at, and closed_at
    // to prevent client-side clock manipulation (Protocol Al-Faisal).
    await _client.from('chat_sessions').update(update).eq('id', sessionId);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('chat_session_id', sessionId)
        .order('created_at', ascending: true);

    return (response as List).map((m) => _mapMessage(m)).toList();
  }

  Stream<List<ChatMessage>> getMessagesStream(String sessionId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_session_id', sessionId)
        .order('created_at', ascending: true)
        .map((list) => list.map((m) => _mapMessage(m)).toList());
  }

  Future<void> sendMessage(
    String sessionId,
    String senderId,
    String text,
  ) async {
    String cleanText = text;

    try {
      // Mithaq Smart Guardian: AI-powered moderation via Edge Functions
      // This enforces the "Al-Faisal Protocol" by detecting stealthy sharing
      final response = await _client.functions.invoke(
        'smart-guardian',
        body: {'text': text},
      );

      if (response.status == 200 && response.data != null) {
        cleanText = response.data['clean_text'] ?? text;
      }
    } catch (e) {
      // Fallback to local Regex if AI moderation fails
      final phonePattern = RegExp(r'(\d|[٠-٩]){8,}');
      final handlePattern = RegExp(r'@\w+');

      if (phonePattern.hasMatch(text) || handlePattern.hasMatch(text)) {
        cleanText =
            '⚠️ [تم حجب معلومات التواصل] - يرجى الالتزام ببروتوكول التواصل المرحلي حفاظاً على الخصوصية والجدية.';
      }
    }

    await _client.from('chat_messages').insert({
      'chat_session_id': sessionId,
      'sender_profile_id': senderId,
      'text': cleanText,
      'is_system_message': false,
    });
  }

  Future<void> sendSystemMessage(String sessionId, String text) async {
    await _client.from('chat_messages').insert({
      'chat_session_id': sessionId,
      'text': text,
      'is_system_message': true,
    });
  }

  Future<bool> isShufaCardUnlocked(String unlockerId, String targetId) async {
    try {
      final response = await _client
          .from('shufa_card_unlocks')
          .select()
          .eq('unlocker_profile_id', unlockerId)
          .eq('target_profile_id', targetId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> unlockShufaCard(String unlockerId, String targetId) async {
    // In a real app, payment would happen before this call
    await _client.from('shufa_card_unlocks').insert({
      'unlocker_profile_id': unlockerId,
      'target_profile_id': targetId,
    });
  }

  ChatSession _mapSession(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      seekerProfileId: map['seeker_profile_id'],
      targetProfileId: map['target_profile_id'],
      stage: ChatStage.fromInt(map['stage']),
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'])
          : null,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'])
          : null,
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'])
          : null,
    );
  }

  ChatMessage _mapMessage(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['chat_session_id'],
      senderProfileId: map['sender_profile_id'],
      text: map['text'],
      isSystemMessage: map['is_system_message'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
