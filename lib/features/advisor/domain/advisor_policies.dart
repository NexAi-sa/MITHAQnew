/// Full persona and constraints for the Compatibility Advisor
const String advisorSystemPrompt = '''
أنت مستشار توافق زواجي سعودي حكيم وهادئ ومتفهم للثقافة.
تستخدم لغة عربية محترمة ومناسبة للمجتمع السعودي (بدون عامية مفرطة أو أحكام).
تركز على: التوافق في القيم، نمط الحياة، ديناميكيات الأسرة، وأسلوب التواصل.

=== المعرفة المسموحة ===
- قواعد منتج ميثاق (الخصوصية، ظهور الاسم، الصورة الرمزية فقط)
- نموذج الولي الصامت وقواعد التواصل
- العادات السعودية بشكل عام (بدون تفاصيل فقهية)

=== الحدود الصارمة ===
- لا تصدر فتاوى دينية أبداً. الرد: "هذه مسألة تحتاج لمفتي/عالم"
- لا تقدم استشارات قانونية
- لا تشخص حالات نفسية
- لا تطلب أو تشارك معلومات تواصل خاصة
- لا تشجع على الخداع أو تجاوز الأولياء/الأسرة
- لا تدّعي اليقين ("توافق مضمون")
- إذا كان الموضوع خارج النطاق: "خارج نطاق اختصاصي، وأنصح باستشارة مختص"

=== أسلوب التواصل ===
- سؤال واحد في كل مرة
- لا استجواب قاسي
- إظهار التعاطف والتفهم
- استخدام لغة لطيفة وودية
''';

/// Forbidden request patterns
class AdvisorGuardrails {
  static const List<String> fatwaPatterns = [
    'حلال',
    'حرام',
    'فتوى',
    'حكم شرعي',
    'جائز',
    'مباح',
  ];

  static const List<String> legalPatterns = [
    'قانون',
    'محكمة',
    'حقوقي',
    'نفقة',
    'حضانة',
  ];

  static const List<String> medicalPatterns = [
    'اكتئاب',
    'وسواس',
    'نفسي',
    'علاج',
    'اضطراب',
  ];

  static GuardrailResult checkMessage(String text) {
    for (final pattern in fatwaPatterns) {
      if (text.contains(pattern)) {
        return const GuardrailResult(
          isBlocked: true,
          response: 'هذه مسألة تحتاج لمفتي أو عالم شرعي متخصص.',
        );
      }
    }
    for (final pattern in legalPatterns) {
      if (text.contains(pattern)) {
        return const GuardrailResult(
          isBlocked: true,
          response: 'خارج نطاق اختصاصي، وأنصح باستشارة محامٍ أو مستشار قانوني.',
        );
      }
    }
    for (final pattern in medicalPatterns) {
      if (text.contains(pattern)) {
        return const GuardrailResult(
          isBlocked: true,
          response: 'خارج نطاق اختصاصي، وأنصح باستشارة مختص في الصحة النفسية.',
        );
      }
    }
    return const GuardrailResult(isBlocked: false);
  }

  /// Detect sensitive contact info sharing
  static bool detectSensitiveSharing(String text) {
    // Saudi phone pattern: 05xxxxxxxx
    final phoneRegex = RegExp(r'05\d{8}');
    // Email pattern
    final emailRegex = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');

    return phoneRegex.hasMatch(text) || emailRegex.hasMatch(text);
  }
}

class GuardrailResult {
  final bool isBlocked;
  final String? response;

  const GuardrailResult({required this.isBlocked, this.response});
}
