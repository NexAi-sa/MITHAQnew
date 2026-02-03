import 'package:flutter/material.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/theme/design_system.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isLight
            ? MithaqColors.navy
            : MithaqColors.textPrimaryDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سياسة الخصوصية لميثاق',
              style: TextStyle(
                fontSize: MithaqTypography.titleSmall,
                fontWeight: FontWeight.bold,
                color: isLight
                    ? MithaqColors.navy
                    : MithaqColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'سياسة الخصوصية – تطبيق ميثاق (Mithaq)\nتاريخ آخر تحديث: 2026-02-01\n\nنحن في ميثاق نأخذ خصوصيتك على محمل الجد. تم تصميم تطبيقنا ليكون "مساحة آمنة" للبحث عن الزواج بجدية، ونلتزم بحماية بياناتك الشخصية بشفافية تامة.\nتوضح هذه السياسة نوع البيانات التي نجمعها، وكيف نستخدمها، وحقوقك فيما يتعلق بهذه البيانات.\n\n1. البيانات التي نجمعها (Data Collection)\nبما أننا نركز على الجوهر وليس المظهر، فإننا نجمع الحد الأدنى من البيانات اللازمة لعمل خوارزمية التوافق:\n• أ. المعلومات التي تقدمها بنفسك:\n    ◦ بيانات الحساب: رقم الهاتف (لغرض التحقق والتسجيل).\n    ◦ البيانات الشخصية: (الاسم أو اللقب، العمر، المدينة، القبيلة/العائلة، الحالة الاجتماعية).\n    ◦ المواصفات الجسدية: (الطول، الوزن، لون البشرة) – يتم جمعها كبيانات نصية/رقمية فقط.\n    ◦ بيانات التوافق: إجاباتك في "اختبار الشخصية" وتفضيلاتك في الشريك.\n    ◦ بيانات ولي الأمر (لحسابات العائلة): اسم ورقم ولي الأمر (يتم حفظها بسرية تامة ولا تظهر إلا بعد الدفع والموافقة).\n• ب. البيانات التي يتم جمعها تلقائياً:\n    ◦ بيانات الجهاز (نوع الجهاز، نظام التشغيل) لغرض تحسين الأداء.\n    ◦ سجلات التفاعل (Log Data) لضمان أمان التطبيق ومنع االسلوكيات المسيئة.\n\n2. الكاميرا والصور (Camera & Photos)\nنحن لا نطلب الوصول إلى صورك أو الكاميرا. تطبيق ميثاق يعتمد على البيانات والمواصفات المكتوبة. لا يتطلب التطبيق، ولا يطلب إذن الوصول إلى مكتبة الصور الخاصة بك أو الكاميرا في أي مرحلة من مراحل التسجيل أو االستخدام.\n\n3. كيف نستخدم بياناتك؟ (Data Usage)\nنستخدم البيانات المذكورة أعلاه لأغراض محددة فقط:\n1. حساب التوافق: لربطك مع الأشخاص اأكثر توافقاً معك بناءً على القيم والشخصية.\n2. إدارة االشتراكات: لمعالجة عمليات الدفع عبر متجر التطبيقات (مثل تفعيل الباقات أو إضافة ملفات عائلية).\n3. األمان والحماية: مراقبة المحادثات آلياً (باستخدام الذكاء االصطناعي) لمنع تبادل أرقام الهواتف أو الكلمات المسيئة قبل الوقت المسموح به، وحظر الحسابات المخالفة.\n\n4. مشاركة البيانات (Third-Party Sharing)\nنحن ال نبيع بياناتك ألي طرف ثالث. تتم مشاركة البيانات فقط مع مزودي الخدمات األساسيين لتشغيل التطبيق:\n• مزودو خدمات الدفع (Apple Pay / RevenueCat): لمعالجة االشتراكات (نحن ال نخزن بيانات بطاقتك االئتمانية).\n• خدمات االستضافة وقواعد البيانات (Supabase): لتخزين البيانات بشكل مشفر وآمن.\n\n5. حذف الحساب والبيانات (Data Deletion)\nوفقاً لقوانين متجر أبل، لديك الحق في حذف حسابك وبياناتك نهائياً في أي وقت.\n• يمكنك الذهاب إلى اإلعدادات > حذف الحساب داخل التطبيق.\n• عند تأكيد الحذف، سيتم محو جميع بياناتك الشخصية، وسجالت المحادثات، ونتائج االختبارات فوراً من خوادمنا ولن يمكن استعادتها.\n\n6. التغييرات على هذه السياسة\nقد نقوم بتحديث سياسة الخصوصية من وقت آلخر. سيتم إشعارك بأي تغييرات جوهرية داخل التطبيق.\n\n7. اتصل بنا\nإذا كان لديك أي استفسار حول خصوصيتك، يرجى التواصل معنا عبر:\nmithaqapp300@gmail.com',
              style: TextStyle(
                color: isLight ? Colors.grey[700] : Colors.grey[400],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('شروط الاستخدام'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isLight
            ? MithaqColors.navy
            : MithaqColors.textPrimaryDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'شروط الاستخدام لميثاق',
              style: TextStyle(
                fontSize: MithaqTypography.titleSmall,
                fontWeight: FontWeight.bold,
                color: isLight
                    ? MithaqColors.navy
                    : MithaqColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'باستخدامك لميثاق، أنت توافق على الشروط التالية:\n\n1. الالتزام بالأمانة والصدق في تقديم المعلومات.\n2. استخدام التطبيق لغرض الزواج الشرعي فقط.\n3. احترام خصوصية الآخرين وعدم تداول بياناتهم خارج إطار التطبيق.\n4. الالتزام ببروتوكول التواصل المرحلي لضمان الجدية.\n\n[نص شروط الاستخدام الكامل]',
              style: TextStyle(
                color: isLight ? Colors.grey[700] : Colors.grey[400],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
