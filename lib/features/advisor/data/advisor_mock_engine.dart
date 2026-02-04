import 'package:flutter/foundation.dart';
import '../domain/advisor_message.dart';
import '../domain/advisor_summary.dart';
import '../domain/advisor_policies.dart';
import '../../seeker/data/profile_repository.dart';
import '../../seeker/domain/profile.dart';
import '../../../core/integrations/ai/gemini_advisor_client.dart';
import '../../../core/config/feature_flags.dart';

/// AI engine for advisor - uses real Gemini AI when enabled
class AdvisorMockEngine {
  final ProfileRepository _profileRepo;
  final GeminiAdvisorClient _geminiClient = GeminiAdvisorClient();
  bool _geminiInitialized = false;

  AdvisorMockEngine(this._profileRepo);

  /// Initialize Gemini if enabled
  Future<void> _ensureGeminiInit() async {
    if (FeatureFlags.enableRealAI && !_geminiInitialized) {
      try {
        await _geminiClient.init();
        _geminiInitialized = true;
      } catch (e) {
        debugPrint('Gemini init failed: $e');
      }
    }
  }

  /// Generate a response based on user message and optional target profile
  Future<AdvisorMessage> generateResponse({
    required String userMessage,
    required List<AdvisorMessage> conversationHistory,
    String? targetProfileId,
  }) async {
    // Check guardrails first
    final guardrailCheck = AdvisorGuardrails.checkMessage(userMessage);
    if (guardrailCheck.isBlocked) {
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: guardrailCheck.response!,
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
        relatedProfileId: targetProfileId,
      );
    }

    // Support Agent Logic - use AI
    if (targetProfileId == 'support') {
      return _generateSupportResponse(userMessage);
    }

    // Use real Gemini AI if enabled
    if (FeatureFlags.enableRealAI) {
      await _ensureGeminiInit();
      if (_geminiInitialized) {
        // Add profile context if available
        String enrichedMessage = userMessage;
        if (targetProfileId != null) {
          final profile = await _profileRepo.getProfileById(targetProfileId);
          if (profile != null) {
            enrichedMessage =
                '''
معلومات الحساب المستهدف:
- الاسم: ${profile.name}
- العمر: ${profile.age} سنة
- المدينة: ${profile.city}
- المهنة: ${profile.job}
- الحالة الاجتماعية: ${profile.maritalStatus.label}
- ${profile.tribe != null ? 'القبيلة: ${profile.tribe}' : ''}
- ${profile.isManagedByGuardian ? 'تحت إشراف ولي أمر' : ''}

سؤال المستخدم: $userMessage
''';
          }
        }

        final response = await _geminiClient.chat(enrichedMessage);
        return response.copyWith(relatedProfileId: targetProfileId);
      }
    }

    // Fallback to mock responses
    return _generateMockResponse(userMessage, targetProfileId);
  }

  /// Generate mock response (fallback)
  Future<AdvisorMessage> _generateMockResponse(
    String userMessage,
    String? targetProfileId,
  ) async {
    final sentiment = _analyzeSentiment(userMessage);
    String prefix = _getSentimentPrefix(sentiment);

    // Profile lookup request
    if (userMessage.contains('حلّل') ||
        userMessage.contains('MITH-') ||
        userMessage.contains('معرف') ||
        userMessage.contains('حساب')) {
      final profileIdMatch = RegExp(
        r'(MITH-[A-Z0-9-]+|p\d+)',
      ).firstMatch(userMessage);
      if (profileIdMatch != null) {
        final analysis = await _generateProfileAnalysis(
          profileIdMatch.group(0)!,
        );
        return analysis.copyWith(content: '$prefix ${analysis.content}');
      }
    }

    // Compatibility question
    if (userMessage.contains('مناسب لي') || userMessage.contains('توافق')) {
      if (targetProfileId != null) {
        final compResponse = await _generateCompatibilityResponse(
          targetProfileId,
        );
        return compResponse.copyWith(
          content: '$prefix ${compResponse.content}',
        );
      }
    }

    // Conflict points question
    if (userMessage.contains('خلاف') || userMessage.contains('مشكلة')) {
      if (targetProfileId != null) {
        final conflictResponse = await _generateConflictPointsResponse(
          targetProfileId,
        );
        return conflictResponse.copyWith(
          content: '$prefix ${conflictResponse.content}',
        );
      }
    }

    // Default Response
    return AdvisorMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content:
          '$prefix شكراً لمشاركتك معي. أشعر من كلماتك بـ (${_getSentimentLabel(sentiment)})، وهذا يساعدني جداً في توجيه التوافق لك بشكل أدق. كيف أقدر أساعدك؟',
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
      relatedProfileId: targetProfileId,
    );
  }

  String _analyzeSentiment(String text) {
    final t = text.toLowerCase();
    if (t.contains('خايف') ||
        t.contains('قلق') ||
        t.contains('تردد') ||
        t.contains('صعب')) {
      return 'anxious';
    }
    if (t.contains('حلو') ||
        t.contains('ممتاز') ||
        t.contains('حماس') ||
        t.contains('يا رب')) {
      return 'excited';
    }
    if (t.contains('زعلان') ||
        t.contains('تعبت') ||
        t.contains('ليش') ||
        t.contains('وقت')) {
      return 'frustrated';
    }
    return 'neutral';
  }

  String _getSentimentPrefix(String sentiment) {
    switch (sentiment) {
      case 'anxious':
        return 'أقدّر صدقك، من الطبيعي الشعور بالقلق في هذه المرحلة، وأنا هنا لأطمئنك بالبيانات..';
      case 'excited':
        return 'جميل جداً هذا التفاؤل! الطاقة الإيجابية هي أول خطوة لزواج ناجح..';
      case 'frustrated':
        return 'أتفهمك تماماً، الرحلة قد تكون مرهقة أحياناً لكن ميثاق صُمم ليختصر عليك العناء..';
      default:
        return 'أهلاً بك، قراءة هادئة ومتزنة منك..';
    }
  }

  String _getSentimentLabel(String sentiment) {
    switch (sentiment) {
      case 'anxious':
        return 'حرص واهتمام بالتفاصيل';
      case 'excited':
        return 'انفتاح وحيوية';
      case 'frustrated':
        return 'رغبة في الوضوح والحسم';
      default:
        return 'اتزان وعقلانية';
    }
  }

  Future<AdvisorMessage> _generateProfileAnalysis(String profileId) async {
    final profile = await _profileRepo.getProfileById(profileId);
    if (profile == null) {
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: 'لم أجد حساب بهذا الرقم. يرجى التأكد من صحة الرقم.',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    }

    return AdvisorMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content:
          '''أهلاً بك، لقد قمت بمراجعة بيانات هذا الحساب بعناية.. إليك قراءتي الأولية: 🔍

👤 ${profile.name} - ${profile.age} سنة
📍 ${profile.city}
💼 ${profile.job}
${profile.tribe != null ? '🏛 ${profile.tribe}' : ''}

${profile.isManagedByGuardian ? '✨ ملاحظة مميزة: هذا الحساب تحت إشراف ولي الأمر، وهذا يعطي مؤشر عالي جداً على الجدية والوضوح في هذا الطلب.' : ''}

بناءً على ملفك الشخصي، نرى أن هناك نقاط التقاء جميلة.. هل تود أن نتعمق أكثر في "تحليل التوافق" لنرى مدى انسجامكما في القيم وأسلوب الحياة؟''',
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
      relatedProfileId: profileId,
    );
  }

  Future<AdvisorMessage> _generateCompatibilityResponse(
    String profileId,
  ) async {
    final profile = await _profileRepo.getProfileById(profileId);
    if (profile == null) {
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: 'لم أتمكن من إيجاد الحساب المطلوب.',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    }

    return AdvisorMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content:
          '''بعد دراسة الحساب، هذه ملاحظاتي:

✅ نقاط إيجابية:
• الحساب يبدو جاداً ومكتملاً
• ${profile.city} مدينة مناسبة للاستقرار
• ${profile.educationLevel?.label ?? 'مستوى تعليمي جيد'}

⚡ نقاط تحتاج نقاش:
• ينصح بالتأكد من توافق نمط الحياة
• مناقشة التوقعات بخصوص السكن والعمل

هل تريد نصائح لأسئلة التعارف الأولى؟''',
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
      relatedProfileId: profileId,
    );
  }

  Future<AdvisorMessage> _generateConflictPointsResponse(
    String profileId,
  ) async {
    final profile = await _profileRepo.getProfileById(profileId);
    if (profile == null) {
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: 'لم أتمكن من إيجاد الحساب المطلوب.',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    }

    return AdvisorMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: '''تنبيه ودي 💡

بناءً على المعلومات المتاحة، هذه نقاط قد تحتاج حوار هادئ:

1️⃣ الموقع: تأكد من توافق خطط السكن المستقبلية
2️⃣ العمل: ناقش توقعات كلا الطرفين بخصوص عمل الزوجة
3️⃣ العائلة: تحدث عن دور الأسرة الممتدة في حياتكم

تذكر: هذه ليست مخاوف، بل نقاط حوار صحي. التواصل المبكر يمنع سوء الفهم لاحقاً.''',
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
      relatedProfileId: profileId,
    );
  }

  /// Generate summary after consultation
  Future<AdvisorSummary> generateSummary({
    required List<AdvisorMessage> conversationHistory,
    String? targetProfileId,
  }) async {
    SeekerProfile? profile;
    if (targetProfileId != null && targetProfileId != 'support') {
      profile = await _profileRepo.getProfileById(targetProfileId);
    }

    return AdvisorSummary(
      id: 'summary_${DateTime.now().millisecondsSinceEpoch}',
      targetProfileId: targetProfileId,
      compatibilityPoints: [
        'الحساب يظهر جدية في البحث',
        if (profile != null)
          'مستوى التعليم: ${profile.educationLevel?.label ?? "جيد"}',
        'السن مناسب للزواج',
      ],
      discussionPoints: [
        'مناقشة التوقعات المالية والسكنية',
        'التحدث عن دور كل طرف في العلاقة',
        'فهم علاقة كل طرف بعائلته',
      ],
      suggestedQuestions: [
        'ما هي أهم ثلاث صفات تبحث عنها في شريك الحياة؟',
        'كيف ترى علاقتك بعائلتك بعد الزواج؟',
        'ما هي خططك المهنية للسنوات الخمس القادمة؟',
      ],
      generatedAt: DateTime.now(),
    );
  }

  /// Generate "After Marriage Scenario" simulation
  String generateAfterMarriageScenario({
    required String? targetProfileId,
    required String? currentUserId,
  }) {
    return '''تخيّل ودي 💭

بناءً على المعلومات المتاحة، هذا سيناريو محتمل:

🏠 السيناريو الأول: "يوم عطلة عائلي"
قد يختلف كل منكما في طريقة قضاء العطلة (زيارة الأهل vs وقت خاص). الحل: الاتفاق مسبقاً على جدول متوازن.

💼 السيناريو الثاني: "قرار مهني"
عندما تواجه أحدكما فرصة عمل في مدينة أخرى، كيف ستتخذان القرار معاً؟

تذكر: هذه احتمالات وليست تنبؤات. الهدف هو التفكير المسبق في كيفية التعامل مع التحديات.''';
  }

  Future<AdvisorMessage> _generateSupportResponse(String userMessage) async {
    // Use real AI for support if enabled
    if (FeatureFlags.enableRealAI) {
      await _ensureGeminiInit();
      if (_geminiInitialized) {
        return await _geminiClient.supportChat(userMessage);
      }
    }

    // Fallback mock support response
    String content;
    final msg = userMessage.toLowerCase();

    if (msg.contains('شروط') || msg.contains('سياسات')) {
      content =
          'يمكنك مراجعة شروط الاستخدام وسياسة الخصوصية من خلال صفحة الإعدادات > معلومات التطبيق والدعم. نحن نحرص على حماية بياناتك وخصوصيتك وفق أعلى المعايير.';
    } else if (msg.contains('مشكلة') ||
        msg.contains('خطأ') ||
        msg.contains('عطل')) {
      content =
          'نأسف لسماع أنك تواجه مشكلة. هل يمكنك وصف المشكلة بمزيد من التفصيل؟ يمكنك أيضاً التواصل معنا عبر البريد الإلكتروني support@mithaq.app للحصول على مساعدة أسرع.';
    } else if (msg.contains('تواصل') ||
        msg.contains('ايميل') ||
        msg.contains('بريد')) {
      content = 'بريد الدعم الفني هو: support@mithaq.app';
    } else {
      content =
          'أنا هنا للإجابة على استفساراتك حول التطبيق والسياسات. كيف أقدر أساعدك؟';
    }

    return AdvisorMessage(
      id: 'msg_support_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
      relatedProfileId: 'support',
    );
  }
}
