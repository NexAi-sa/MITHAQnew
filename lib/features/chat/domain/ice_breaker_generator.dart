import '../../compatibility/domain/compatibility_model.dart';
import '../../seeker/domain/profile.dart';

/// Ice-Breaker message generator based on compatibility attributes
class IceBreakerGenerator {
  /// Mapping of compatibility traits to ice-breaker phrases
  static const Map<String, String> _attributePhrases = {
    // Values
    'value_family': 'اهتمامك الكبير بالجو العائلي',
    'value_religion': 'حرصك على الالتزام الديني',
    'value_stability': 'تقديرك للاستقرار والأمان',
    'value_independence': 'اعتزازك باستقلاليتك',
    'value_growth': 'سعيك للتطور والنمو',

    // Traits
    'trait_ambition': 'طموحك المهني الواضح',
    'trait_kindness': 'لطفك وحسن تعاملك',
    'trait_patience': 'صبرك وهدوئك',
    'trait_humor': 'خفة روحك وظلك الجميل',
    'trait_wisdom': 'حكمتك ورجاحة عقلك',

    // Lifestyle
    'style_calm': 'بحثك عن الهدوء والاستقرار',
    'style_active': 'حيويتك ونشاطك',
    'style_social': 'اجتماعيتك الجميلة',
    'style_private': 'حبك للخصوصية والسكينة',
    'style_adventurous': 'حبك للمغامرة واكتشاف الجديد',

    // Compatibility tags from the engine
    'نفس المدينة': 'كوننا من نفس المدينة',
    'تقارب في العمر': 'تقارب أعمارنا',
    'نفس القبيلة': 'كوننا من نفس القبيلة',
    'توافق التعليم': 'توافق مستوانا التعليمي',
    'توافق نمط الحياة': 'توافق أنماط حياتنا',
  };

  /// Default fallback phrases when no specific match found
  static const List<String> _fallbackPhrases = [
    'ما رأيته في ملفك من صفات جميلة',
    'وضوح رؤيتك لما تبحث عنه',
    'جدية اهتمامك بالارتباط الشرعي',
  ];

  /// Generate contextual ice-breaker message based on compatibility result
  static String generateMessage({
    required CompatibilityResult? compatibility,
    required SeekerProfile? targetProfile,
    String senderGender = 'male',
  }) {
    String attributePhrase = _getStrongestAttribute(
      compatibility,
      targetProfile,
    );

    final template =
        'السلام عليكم.. ماشاء الله، لفت انتباهي في ملفك $attributePhrase، وحاب أعرف تفاصيل أكثر وأعرفك بنفسي.';

    // Adjust for female sender
    if (senderGender == 'female') {
      return template.replaceAll('حاب', 'حابة').replaceAll('أعرفك', 'تتعرف');
    }

    return template;
  }

  /// Get the strongest matching attribute phrase
  static String _getStrongestAttribute(
    CompatibilityResult? compatibility,
    SeekerProfile? targetProfile,
  ) {
    // First check compatibility tags
    if (compatibility != null && compatibility.compatibilityTags.isNotEmpty) {
      for (final tag in compatibility.compatibilityTags) {
        if (_attributePhrases.containsKey(tag)) {
          return _attributePhrases[tag]!;
        }
      }
    }

    // Then check positive reasons
    if (compatibility != null && compatibility.allPositiveReasons.isNotEmpty) {
      for (final reason in compatibility.allPositiveReasons) {
        final key = _attributePhrases.keys.firstWhere(
          (k) => reason.contains(k) || k.contains(reason.split(' ').first),
          orElse: () => '',
        );
        if (key.isNotEmpty) {
          return _attributePhrases[key]!;
        }
      }
    }

    // Check specific profile attributes
    if (targetProfile != null) {
      if (targetProfile.bio != null && targetProfile.bio!.isNotEmpty) {
        if (targetProfile.bio!.contains('عائل') ||
            targetProfile.bio!.contains('أسر')) {
          return _attributePhrases['value_family']!;
        }
        if (targetProfile.bio!.contains('طموح') ||
            targetProfile.bio!.contains('عمل')) {
          return _attributePhrases['trait_ambition']!;
        }
        if (targetProfile.bio!.contains('هدوء') ||
            targetProfile.bio!.contains('استقرار')) {
          return _attributePhrases['style_calm']!;
        }
      }
    }

    // Fallback to random phrase
    final random = DateTime.now().millisecond % _fallbackPhrases.length;
    return _fallbackPhrases[random];
  }

  /// Generate quick suggestions as chips
  static List<String> getQuickSuggestions({
    required CompatibilityResult? compatibility,
    required SeekerProfile? targetProfile,
  }) {
    final suggestions = <String>[];

    // Add the main ice-breaker
    suggestions.add(
      generateMessage(
        compatibility: compatibility,
        targetProfile: targetProfile,
      ),
    );

    // Add simpler alternatives
    suggestions.addAll([
      'السلام عليكم.. سعدت بزيارة ملفك 🌸',
      'السلام عليكم، حاب نتعرف بشكل أعمق إن ناسب',
    ]);

    return suggestions;
  }
}
