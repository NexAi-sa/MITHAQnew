import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../features/advisor/domain/advisor_message.dart';
import '../../../features/advisor/domain/compatibility_advisor_knowledge.dart';

/// Real Gemini AI Client for Mithaq Advisor
class GeminiAdvisorClient {
  late final GenerativeModel _model;
  final List<Content> _conversationHistory = [];
  bool _isInitialized = false;

  /// Initialize the Gemini client with API key
  Future<void> init() async {
    if (_isInitialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(compatibilityAdvisorSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );

    _isInitialized = true;
  }

  /// Get AI response for user message
  Future<AdvisorMessage> chat(String userMessage) async {
    if (!_isInitialized) await init();

    // Add user message to history
    _conversationHistory.add(Content.text(userMessage));

    try {
      // Create chat session with history
      final chat = _model.startChat(history: _conversationHistory);

      // Send message and get response
      final response = await chat.sendMessage(Content.text(userMessage));
      final responseText =
          response.text ?? 'عذراً، لم أتمكن من معالجة طلبك. حاول مرة أخرى.';

      // Add response to history
      _conversationHistory.add(Content.model([TextPart(responseText)]));

      return AdvisorMessage(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        content: responseText,
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    } catch (e, stack) {
      // Debug logging for AI errors
      print('🤖❌ Gemini AI Error: $e');
      print('🤖❌ Stack: $stack');
      return AdvisorMessage(
        id: 'msg_error_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'عذراً، حدث خطأ في الاتصال بالمستشار الذكي. يرجى المحاولة لاحقاً.',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Reset conversation history
  void resetConversation() {
    _conversationHistory.clear();
  }

  /// Get technical support response
  Future<AdvisorMessage> supportChat(String userMessage) async {
    if (!_isInitialized) await init();

    const supportPrompt = '''
أنت وكيل الدعم الفني لتطبيق ميثاق. 
مهمتك: الإجابة على الاستفسارات التقنية، شروط الاستخدام، وسياسة الخصوصية.
لا تجيب على أسئلة التوافق أو الزواج - وجه المستخدم لـ "خبير التوافق" بدلاً من ذلك.
كن مختصراً وواضحاً ومهذباً.
''';

    try {
      final supportModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: dotenv.env['GEMINI_API_KEY']!,
        systemInstruction: Content.system(supportPrompt),
      );

      final response = await supportModel.generateContent([
        Content.text(userMessage),
      ]);

      return AdvisorMessage(
        id: 'msg_support_${DateTime.now().millisecondsSinceEpoch}',
        content: response.text ?? 'عذراً، لم أتمكن من معالجة طلبك.',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
        relatedProfileId: 'support',
      );
    } catch (e) {
      return AdvisorMessage(
        id: 'msg_error_${DateTime.now().millisecondsSinceEpoch}',
        content: 'عذراً، حدث خطأ. للتواصل المباشر: support@mithaq.app',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
        relatedProfileId: 'support',
      );
    }
  }
}
