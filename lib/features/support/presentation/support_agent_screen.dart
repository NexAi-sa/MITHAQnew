import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';

/// Predefined quick action buttons for support
enum SupportQuickAction {
  loginIssue('مشكلة تسجيل دخول', Icons.lock_outline),
  profileNotVisible('حسابي لا يظهر', Icons.visibility_off_outlined),
  guardianManagement('إدارة ولي الأمر', Icons.family_restroom),
  reportAbuse('إبلاغ عن إساءة', Icons.report_outlined),
  featureRequest('اقتراح ميزة', Icons.lightbulb_outline);

  final String label;
  final IconData icon;
  const SupportQuickAction(this.label, this.icon);
}

/// Support Agent Screen - AI-powered technical support chat
class SupportAgentScreen extends ConsumerStatefulWidget {
  const SupportAgentScreen({super.key});

  @override
  ConsumerState<SupportAgentScreen> createState() => _SupportAgentScreenState();
}

class _SupportAgentScreenState extends ConsumerState<SupportAgentScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      _ChatMessage(
        text:
            'أهلاً بك! 👋\nأنا هنا أساعدك في أي مشكلة تقنية تواجهك داخل ميثاق.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 24),
            SizedBox(width: 8),
            Text('الدعم الفني'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(MithaqSpacing.m),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Quick actions (only show when no conversation started)
          if (_messages.length == 1) _buildQuickActions(),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: MithaqSpacing.m),
        padding: const EdgeInsets.symmetric(
          horizontal: MithaqSpacing.m,
          vertical: MithaqSpacing.s,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? MithaqColors.navy
              : MithaqColors.navy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(MithaqRadius.m),
            topRight: const Radius.circular(MithaqRadius.m),
            bottomLeft: Radius.circular(message.isUser ? MithaqRadius.m : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : MithaqRadius.m),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : MithaqColors.navy,
            fontSize: MithaqTypography.bodyMedium,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: MithaqSpacing.m),
        padding: const EdgeInsets.all(MithaqSpacing.m),
        decoration: BoxDecoration(
          color: MithaqColors.navy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(MithaqRadius.m),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: MithaqColors.navy.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MithaqSpacing.m,
        vertical: MithaqSpacing.s,
      ),
      child: Wrap(
        spacing: MithaqSpacing.s,
        runSpacing: MithaqSpacing.s,
        children: SupportQuickAction.values
            .map(
              (action) => ActionChip(
                avatar: Icon(action.icon, size: 16, color: MithaqColors.navy),
                label: Text(action.label),
                backgroundColor: MithaqColors.mint.withValues(alpha: 0.15),
                labelStyle: const TextStyle(
                  color: MithaqColors.navy,
                  fontSize: 12,
                ),
                onPressed: () => _handleQuickAction(action),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        MithaqSpacing.m,
        MithaqSpacing.s,
        MithaqSpacing.m,
        MithaqSpacing.m + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: MithaqColors.navy.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب سؤالك هنا...',
                filled: true,
                fillColor: MithaqColors.navy.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MithaqRadius.l),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MithaqSpacing.m,
                  vertical: MithaqSpacing.s,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: MithaqSpacing.s),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded),
            color: MithaqColors.navy,
            style: IconButton.styleFrom(
              backgroundColor: MithaqColors.mint.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(SupportQuickAction action) {
    _messageController.text = action.label;
    _sendMessage();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        final response = _generateResponse(text);
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(text: response, isUser: false));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateResponse(String query) {
    final session = ref.read(sessionProvider);
    final lowerQuery = query.toLowerCase();

    // Empathy and acknowledgement
    String prefix =
        'أهلاً بك.. تفهمت ما ذكرته بخصوص "${query.length > 20 ? query.substring(0, 20) + "..." : query}". سأقوم بمراجعة الأمر لك حالاً. 🛠️\n\n';

    // Compatibility/Relationship - redirect to advisor
    if (_containsAny(lowerQuery, [
      'توافق',
      'زواج',
      'علاقة',
      'شريك',
      'مناسب',
      'خبير',
    ])) {
      return prefix +
          'يبدو أن استفسارك يتعلق بالجوانب الاجتماعية والتوافق.. أنصحك بفتح خبير التوافق (المستشار) من خلال زر "استشر الخبير" في صفحة اكتشف، فهو متخصص تماماً في هذه الأمور. 🟢';
    }

    // Login issues
    if (_containsAny(lowerQuery, [
      'تسجيل دخول',
      'كلمة مرور',
      'دخول',
      'حساب',
      'رقم',
    ])) {
      return prefix + _handleLoginIssue(session);
    }

    // Profile visibility
    if (_containsAny(lowerQuery, ['لا يظهر', 'مخفي', 'ظهور', 'بحث', 'ملفي'])) {
      return prefix + _handleVisibilityIssue(session);
    }

    // Guardian management
    if (_containsAny(lowerQuery, [
      'ولي الأمر',
      'وصي',
      'إدارة',
      'تابع',
      'إضافة',
    ])) {
      return prefix + _handleGuardianIssue(session);
    }

    // Report abuse
    if (_containsAny(lowerQuery, [
      'إبلاغ',
      'إساءة',
      'مضايقة',
      'تحرش',
      'بلاغ',
    ])) {
      return prefix +
          'نحن نأخذ هذا الأمر بجدية تامة. 🛡️\n\nبناءً على ما ذكرته، قمنا برفع مستوى الأولوية. يمكنك أيضاً الضغط على زر "إبلاغ" داخل الملف الشخصي المعني ليقوم النظام بتجميده فوراً حتى انتهاء المراجعة خلال 24 ساعة.';
    }

    // Default response
    return prefix +
        'شكراً لتواصلك الصادق معنا. أنا هنا لمساعدتك في أي عائق تقني.\n\nمن خلال البيانات المتوفرة لدي، يمكنني مساعدتك في:\n• تفعيل ظهور ملفك الشخصي\n• حل مشاكل الدخول\n• إدارة حسابات التابعين\n• الإبلاغ عن تجاوزات الخصوصية\n\nما الذي تود مني القيام به الآن؟';
  }

  String _handleLoginIssue(AppSession session) {
    if (session.authStatus == AuthStatus.signedIn) {
      return 'يبدو أنك مسجل دخولك بنجاح الآن! ✅\n\nإذا كنت تواجه مشكلة معينة، أخبرني بالتفصيل.';
    }
    return 'لحل مشاكل تسجيل الدخول:\n\n1. تأكد من صحة رقم الجوال\n2. استخدم رمز التحقق الجديد\n3. تأكد من اتصالك بالإنترنت\n\nإذا استمرت المشكلة، جرب إعادة تشغيل التطبيق.';
  }

  String _handleVisibilityIssue(AppSession session) {
    if (session.isPaused) {
      return 'حسابك مجمّد حالياً! ❄️\n\nلذلك لا يظهر للآخرين. لإعادة الظهور:\n1. اذهب للإعدادات ⚙️\n2. ألغِ تفعيل "تجميد الحساب"';
    }
    if (session.profileStatus == ProfileStatus.draft) {
      return 'ملفك الشخصي في وضع المسودة. 📝\n\nأكمل جميع البيانات المطلوبة ثم احفظ لتظهر للآخرين.';
    }
    if (session.profileStatus == ProfileStatus.missing) {
      return 'لم تُكمل ملفك الشخصي بعد! 📋\n\nاذهب لـ "حسابي" وأكمل بياناتك لتظهر في نتائج البحث.';
    }
    return 'ملفك مفعّل ويجب أن يظهر للآخرين. ✅\n\nإذا لم يظهر، تأكد من:\n• اكتمال البيانات\n• عدم تفعيل التجميد\n• مطابقة معايير البحث';
  }

  String _handleGuardianIssue(AppSession session) {
    if (session.role == UserRole.guardian) {
      return 'أنت مسجل كولي أمر. 👨‍👧‍👦\n\nيمكنك:\n• إضافة تابع جديد (حتى 3)\n• إدارة ملفات التابعين\n• مراجعة طلبات التواصل\n\nللمساعدة في أي من هذه، أخبرني بالتفصيل.';
    }
    return 'الحسابات المُدارة بواسطة ولي الأمر:\n\n• يتم التواصل الأولي عبر الولي\n• بعد الموافقة المبدئية، تُتاح المحادثة المباشرة\n• هذا يحافظ على الخصوصية والجدية\n\nللتواصل مع ولي أمرك، تواصل معه مباشرة خارج التطبيق.';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
