import '../domain/personality_test.dart';

class PersonalityAnalyzer {
  static PersonalityTestResult analyze({
    required PersonalitySilenceInterpretation silence,
    required PersonalityHomeType home,
    required List<PriorityIcon> priorities,
  }) {
    // 1. Determine Pattern Name
    String typeName = '';
    String analysis = '';
    String advice = '';

    if (home == PersonalityHomeType.castle ||
        priorities.contains(PriorityIcon.fence)) {
      typeName = 'صاحب الحصن المنيع';
      analysis =
          'أنت شخص تضع "الولاء والخصوصية" فوق كل اعتبار. بيتك هو مملكتك الخاصة التي لا تسمح لأحد بتجاوز حدودها. أنت حذر في منح ثقتك، لكنك بمجرد أن تثق، تصبح شريكاً وفياً ومخلصاً جداً.';
      advice =
          'تحتاج إلى شخص "متفهم للحدود". لا يناسبك الشخص الذي يشارك تفاصيل حياته مع الأهل أو الأصدقاء. يناسبك الشريك الذي يكتفي بك، ويقدر الأمان والاستقرار، ويحترم حاجتك للانعزال أحياناً داخل عالمكما الخاص.';
    } else if (home == PersonalityHomeType.camping ||
        priorities.contains(PriorityIcon.tree)) {
      typeName = 'روح المغامرة الحرّة';
      analysis =
          'أنت تكره القيود والروتين القاتل. ترى الزواج رحلة استكشافية وليس مجرد "مسؤوليات". أنت مرن، تتقبل التغيير، وتبحث دائماً عن معنى أعمق في الحوارات والعلاقات. العفوية هي محركك الأساسي.';
      advice =
          'تحتاج إلى شريك "مرن وعفوي". الشخص التقليدي جداً أو "المنظم بصرامة" سيشعرك بالاختناق. يناسبك من لديه فضول تجاه الحياة، ويستمتع بالخروج عن النص، ويشاركك الرغبة في التطور الدائم.';
    } else if (home == PersonalityHomeType.rustic ||
        priorities.contains(PriorityIcon.house)) {
      typeName = 'الجذر الثابت';
      analysis =
          'أنت شخص دافئ، تقدّر العائلة الكبيرة والترابط الاجتماعي. ترى الزواج "سكينة" واستقراراً. أنت مستمع جيد، وتحب الاهتمام بالتفاصيل الصغيرة التي تصنع جو المنزل.';
      advice =
          'تحتاج إلى شخص "بيتوتي وعاطفي". يناسبك من يقدر قيمة "اللمة" والعائلة، ومن يبحث عن الاستقرار المادي والعاطفي طويل الأمد. الشريك الذي يضع الأسرة كأولوية قصوى هو من سيجعلك سعيداً.';
    } else {
      typeName = 'الطموح العصري';
      analysis =
          'أنت شخص تقدر النجاح، التميز، والتوافق الفكري. تريد شريكاً يكون "واجهة" مشرفة لك وتكون أنت سنداً له. الزواج بالنسبة لك هو "شراكة ذكية" لبناء مستقبل أفضل.';
      advice =
          'تحتاج إلى شريك "طموح ومستقل". يناسبك الشخص الذي لديه أهدافه الخاصة ولا يعتمد عليك كلياً، الشخص الذي يحفزك فكرياً ويشاركك التخطيط للمستقبل بذكاء ومنطق.';
    }

    return PersonalityTestResult(
      silence: silence,
      home: home,
      priorities: priorities,
      personalityTypeName: typeName,
      analysis: analysis,
      matchingAdvice: advice,
    );
  }
}
