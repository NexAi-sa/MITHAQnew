import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/advisor_message.dart';
import '../domain/advisor_summary.dart';
import '../domain/advisor_policies.dart';
import '../data/advisor_repository.dart';
import '../data/advisor_mock_engine.dart';
import '../../seeker/data/profile_repository.dart';

/// State for the advisor feature
class AdvisorState {
  final List<AdvisorMessage> messages;
  final bool isLoading;
  final String? targetProfileId;
  final String? error;
  final AdvisorSummary? currentSummary;

  const AdvisorState({
    this.messages = const [],
    this.isLoading = false,
    this.targetProfileId,
    this.error,
    this.currentSummary,
  });

  AdvisorState copyWith({
    List<AdvisorMessage>? messages,
    bool? isLoading,
    String? targetProfileId,
    String? error,
    AdvisorSummary? currentSummary,
    bool clearTargetProfile = false,
    bool clearError = false,
    bool clearSummary = false,
  }) {
    return AdvisorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      targetProfileId: clearTargetProfile
          ? null
          : (targetProfileId ?? this.targetProfileId),
      error: clearError ? null : (error ?? this.error),
      currentSummary: clearSummary
          ? null
          : (currentSummary ?? this.currentSummary),
    );
  }
}

/// Provider for advisor repository (singleton)
final advisorRepositoryProvider = Provider<AdvisorRepository>((ref) {
  return AdvisorRepository();
});

/// Provider for mock engine
final advisorMockEngineProvider = Provider<AdvisorMockEngine>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return AdvisorMockEngine(profileRepo);
});

/// Main controller for advisor feature
class AdvisorController extends StateNotifier<AdvisorState> {
  final AdvisorRepository _repository;
  final AdvisorMockEngine _engine;

  AdvisorController(this._repository, this._engine)
    : super(const AdvisorState());

  /// Start a new consultation, optionally with a target profile
  void startConsultation({String? targetProfileId}) {
    _repository.clearMessages();

    // Welcome message
    String welcomeContent;
    if (targetProfileId == 'support') {
      welcomeContent =
          'أهلاً بك في الدعم الفني لميثاق 🛠️\n\nأنا وكيل الذكاء الاصطناعي الخاص بالدعم. يمكنني الإجابة على استفساراتك حول شروط الاستخدام، سياسة الخصوصية، أو أي مشكلة تقنية تواجهها.';
    } else if (targetProfileId != null) {
      welcomeContent =
          'أهلاً بك في استشارة التوافق 💫\n\nأنا هنا لمساعدتك في فهم هذا الحساب بشكل أفضل. كيف أقدر أساعدك؟';
    } else {
      welcomeContent =
          'أهلاً بك في استشارة التوافق 💫\n\nأنا هنا لمساعدتك في رحلة البحث عن شريك الحياة. كيف أقدر أساعدك اليوم؟';
    }

    final welcomeMessage = AdvisorMessage(
      id: 'msg_welcome',
      content: welcomeContent,
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
      relatedProfileId: targetProfileId,
    );

    _repository.addMessage(welcomeMessage);

    state = state.copyWith(
      messages: [welcomeMessage],
      targetProfileId: targetProfileId,
      clearError: true,
      clearSummary: true,
    );
  }

  /// Send a user message and get response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Check for sensitive info sharing
    if (AdvisorGuardrails.detectSensitiveSharing(text)) {
      state = state.copyWith(
        error: 'لسلامتك، مشاركة أرقام التواصل أو البريد غير مسموح داخل ميثاق.',
      );
      return;
    }

    // Add user message
    final userMessage = AdvisorMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      relatedProfileId: state.targetProfileId,
    );
    _repository.addMessage(userMessage);

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate response
    final response = await _engine.generateResponse(
      userMessage: text,
      conversationHistory: state.messages,
      targetProfileId: state.targetProfileId,
    );
    _repository.addMessage(response);

    state = state.copyWith(
      messages: [...state.messages, response],
      isLoading: false,
    );
  }

  /// Set target profile for consultation
  void setTargetProfile(String profileId) {
    state = state.copyWith(targetProfileId: profileId);
  }

  /// Generate and show summary
  Future<void> generateSummary() async {
    final summary = await _engine.generateSummary(
      conversationHistory: state.messages,
      targetProfileId: state.targetProfileId,
    );
    _repository.saveSummary(summary);
    state = state.copyWith(currentSummary: summary);
  }

  /// Get after-marriage scenario
  String getAfterMarriageScenario() {
    return _engine.generateAfterMarriageScenario(
      targetProfileId: state.targetProfileId,
      currentUserId: null, // Would come from session in real app
    );
  }

  /// Clear current error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset consultation
  void reset() {
    _repository.clearMessages();
    state = const AdvisorState();
  }
}

/// Provider for advisor controller
final advisorControllerProvider =
    StateNotifierProvider<AdvisorController, AdvisorState>((ref) {
      final repository = ref.watch(advisorRepositoryProvider);
      final engine = ref.watch(advisorMockEngineProvider);
      return AdvisorController(repository, engine);
    });
