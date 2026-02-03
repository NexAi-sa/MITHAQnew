import '../domain/advisor_message.dart';
import '../domain/advisor_summary.dart';
import '../domain/advisor_policies.dart';
import '../../seeker/data/profile_repository.dart';
import '../../seeker/domain/profile.dart';

/// Mock AI engine that simulates advisor responses
class AdvisorMockEngine {
  final ProfileRepository _profileRepo;

  AdvisorMockEngine(this._profileRepo);

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

    // Support Agent Logic
    if (targetProfileId == 'support') {
      return _generateSupportResponse(userMessage);
    }

    // Check for profile lookup request

    // Check for profile lookup request
    if (userMessage.contains('حلّل حساب') ||
        userMessage.contains('Profile ID')) {
      final profileIdMatch = RegExp(r'p\d+').firstMatch(userMessage);
      if (profileIdMatch != null) {
        return _generateProfileAnalysis(profileIdMatch.group(0)!);
      }
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: 'يرجى تزويدي برقم الحساب (مثال: p1) لأتمكن من تحليله.',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    }

    // Check for compatibility question
    if (userMessage.contains('مناسب لي') || userMessage.contains('توافق')) {
      if (targetProfileId != null) {
        return _generateCompatibilityResponse(targetProfileId);
      }
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'لتقييم التوافق، أحتاج معرفة الحساب المطلوب. هل تريد فتح ملف معين؟',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    }

    // Check for conflict points question
    if (userMessage.contains('خلاف') || userMessage.contains('مشكلة')) {
      if (targetProfileId != null) {
        return _generateConflictPointsResponse(targetProfileId);
      }
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'لتحديد نقاط الخلاف المحتملة، أحتاج معرفة الحساب. هل يمكنك تحديده؟',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
      );
    }

    // Check for first question suggestion
    if (userMessage.contains('أول سؤال') || userMessage.contains('أسأل')) {
      return AdvisorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: '''بناءً على خبرتي، أنصح بالبدء بسؤال مفتوح وودي مثل:

"ما هي أهم ثلاث قيم تبحث عنها في شريك الحياة؟"

هذا السؤال يفتح باب الحوار بشكل إيجابي ويعطيك فكرة عن أولوياته/ها.''',
        sender: MessageSender.advisor,
        timestamp: DateTime.now(),
        relatedProfileId: targetProfileId,
      );
    }

    // Default empathetic response
    return AdvisorMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: '''شكراً لمشاركتك معي. 

أفهم أن اختيار شريك الحياة قرار مهم ويحتاج تأني. كيف أقدر أساعدك اليوم؟

يمكنني مساعدتك في:
• تحليل توافق مع حساب معين
• اقتراح أسئلة للتعارف
• فهم نقاط القوة والتحديات المحتملة''',
      sender: MessageSender.advisor,
      timestamp: DateTime.now(),
      relatedProfileId: targetProfileId,
    );
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
          '''نظرت في الحساب وهذه ملاحظاتي الأولية:

👤 ${profile.name} - ${profile.age} سنة
📍 ${profile.city}
💼 ${profile.job}
${profile.tribe != null ? '🏛 ${profile.tribe}' : ''}

${profile.isManagedByGuardian ? '✨ هذا الحساب بإدارة ولي الأمر، مما يدل على جدية واضحة.' : ''}

هل تريد تحليل توافق تفصيلي؟''',
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
    if (targetProfileId != null) {
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
        'التحدث عن دور هر طرف في العلاقة',
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
    // Basic AI simulation for support
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
