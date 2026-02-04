import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/chat_models.dart';
import '../data/chat_repository.dart' as chat_repo;
import '../../../core/session/session_provider.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../seeker/data/profile_repository.dart';
import '../../../core/session/app_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/shufa_card_widget.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../seeker/domain/profile.dart';
import '../../compatibility/domain/compatibility_model.dart';
import '../../compatibility/data/compatibility_engine.dart';
import 'widgets/ice_breaker_suggestions.dart';

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((
  ref,
  sessionId,
) {
  return ref.watch(chat_repo.chatRepositoryProvider).getMessages(sessionId);
});

final chatMessagesStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, sessionId) {
      return Stream.periodic(const Duration(seconds: 3)).asyncMap(
        (_) =>
            ref.read(chat_repo.chatRepositoryProvider).getMessages(sessionId),
      );
    });

final chatSessionProvider = FutureProvider.family<ChatSession?, String>((
  ref,
  targetId,
) async {
  final session = ref.watch(sessionProvider);
  final activeId = session.role == UserRole.seeker
      ? (session.profileId ?? session.userId)
      : session.activeDependentId;
  if (activeId == null) return null;
  return ref
      .watch(chat_repo.chatRepositoryProvider)
      .getSession(activeId, targetId);
});

final shufaUnlockProvider = FutureProvider.family<bool, String>((
  ref,
  targetId,
) async {
  final session = ref.watch(sessionProvider);
  final activeId = session.role == UserRole.seeker
      ? (session.profileId ?? session.userId)
      : session.activeDependentId;
  if (activeId == null) return false;
  return ref
      .watch(chat_repo.chatRepositoryProvider)
      .isShufaCardUnlocked(activeId, targetId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String targetProfileId;
  const ChatScreen({super.key, required this.targetProfileId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final RegExp _safetyFilter = RegExp(
    r'(\d{7,})|(http[s]?:\/\/[^\s]+)|(www\.[^\s]+)',
  );

  @override
  void initState() {
    super.initState();
    _checkProtocolIntro();
  }

  Future<void> _checkProtocolIntro() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_protocol_intro') ?? false;
    if (!hasSeen && mounted) {
      _showProtocolIntro();
      await prefs.setBool('has_seen_protocol_intro', true);
    }
  }

  void _showProtocolIntro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProtocolIntroSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(chatSessionProvider(widget.targetProfileId));
    final targetProfileAsync = ref.watch(
      singleProfileProvider(widget.targetProfileId),
    );
    final currentUserSession = ref.watch(sessionProvider);

    final activeId = currentUserSession.role == UserRole.seeker
        ? currentUserSession.userId
        : currentUserSession.activeDependentId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: targetProfileAsync.when(
          data: (p) => InkWell(
            onTap: () => context.push('/profile/${widget.targetProfileId}'),
            child: Text(p?.name ?? 'تواصل'),
          ),
          loading: () => const Text('...'),
          error: (_, __) => const Text('تواصل'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('إبلاغ عن إساءة'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_flipped, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'حظر وإنهاء المحادثة',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: MithaqColors.navy,
      ),
      body: sessionAsync.when(
        data: (session) {
          final isRecipient = session?.targetProfileId == activeId;
          if (session == null || session.stage == ChatStage.requestSent) {
            return Column(
              children: [
                Expanded(child: _buildAwaitingApprovalUI(session, isRecipient)),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: _buildChatUI(session, currentUserSession)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إبلاغ عن إساءة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportOption('محتوى غير لائق'),
            _buildReportOption('سلوك عدواني'),
            _buildReportOption('طلب تواصل خارجي'),
            _buildReportOption('حساب وهمي'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return ListTile(
      title: Text(reason),
      onTap: () async {
        await ref
            .read(profileRepositoryProvider)
            .reportProfile(
              reportedProfileId: widget.targetProfileId,
              reason: reason,
            );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال بلاغك بنجاح. سنقوم بمراجعته فوراً.'),
            ),
          );
        }
      },
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر وإنهاء المحادثة'),
        content: const Text(
          'هل أنت متأكد من حظر هذا المستخدم؟ سيتم إنهاء المحادثة فوراً ولن يتمكن من التواصل معك مجدداً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(profileRepositoryProvider)
                  .blockUser(widget.targetProfileId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                context.pop(); // Go back from chat
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حظر المستخدم بنجاح.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'تأكيد الحظر',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingApprovalUI(ChatSession? session, bool isRecipient) {
    if (isRecipient && session != null) {
      return _buildApprovalRequestUI(session);
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(MithaqSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, size: 64, color: Colors.grey),
            SizedBox(height: MithaqSpacing.l),
            Text(
              'بانتظار الرد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MithaqColors.navy,
              ),
            ),
            SizedBox(height: MithaqSpacing.m),
            Text(
              'طلبك قيد المراجعة حاليًا.\nخذ وقتك، فالتواصل الجاد لا يُستعجل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalRequestUI(ChatSession session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MithaqSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_outline,
              size: 64,
              color: MithaqColors.pink,
            ),
            const SizedBox(height: MithaqSpacing.l),
            const Text(
              'طلب تواصل جديد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MithaqColors.navy,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),
            const Text(
              'وصلك طلب اهتمام من الطرف الآخر. هل ترغب في فتح باب التواصل للمرحلة الأولى؟',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: MithaqSpacing.xl),
            ElevatedButton(
              onPressed: () =>
                  _handleUpdateStage(session.id, ChatStage.initialApproval),
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('بدء المحادثة (الفيصل ٧ أيام)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatUI(ChatSession session, AppSession currentUser) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(session.id));
    final activeId = currentUser.role == UserRole.seeker
        ? currentUser.userId
        : currentUser.activeDependentId;

    return Column(
      children: [
        if (session.stage == ChatStage.initialApproval)
          _buildTransitionHeader(session),
        if (session.stage == ChatStage.activeCommunication)
          _buildTimerHeader(session),
        if (session.stage == ChatStage.shufaRequested) ...[
          _buildShufaInfoBanner(session),
          _buildTimerHeader(session),
        ],
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );
              // Show ice-breaker suggestions if no messages yet
              if (messages.isEmpty) {
                final targetProfileAsync = ref.watch(
                  singleProfileProvider(session.targetProfileId),
                );
                final compatibilityAsync = ref.watch(
                  compatibilityResultProvider(session.targetProfileId),
                );
                return targetProfileAsync.when(
                  data: (targetProfile) => compatibilityAsync.when(
                    data: (compatibility) => EmptyChatWithSuggestions(
                      compatibility: compatibility,
                      targetProfile: targetProfile,
                      onSuggestionSelected: (suggestion) {
                        _messageController.text = suggestion;
                      },
                    ),
                    loading: () => EmptyChatWithSuggestions(
                      targetProfile: targetProfile,
                      onSuggestionSelected: (suggestion) {
                        _messageController.text = suggestion;
                      },
                    ),
                    error: (_, __) => EmptyChatWithSuggestions(
                      targetProfile: targetProfile,
                      onSuggestionSelected: (suggestion) {
                        _messageController.text = suggestion;
                      },
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(MithaqSpacing.m),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  if (msg.isSystemMessage) return _buildSystemMessage(msg);
                  return _buildMessageBubble(
                    msg,
                    msg.senderProfileId == activeId,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, __) => Center(child: Text('Error: $err')),
          ),
        ),
        if (session.stage != ChatStage.closed && !session.isExpired)
          _buildMessageInput(session, activeId!)
        else
          _buildClosedUI(session),
      ],
    );
  }

  Widget _buildTransitionHeader(ChatSession session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MithaqSpacing.s),
      color: MithaqColors.pink.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'المرحلة الأولى: تعارف مبدئي',
            style: TextStyle(
              fontSize: 11,
              color: MithaqColors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: MithaqSpacing.m),
          TextButton(
            onPressed: () =>
                _handleUpdateStage(session.id, ChatStage.activeCommunication),
            style: TextButton.styleFrom(
              backgroundColor: MithaqColors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'بدء المرحلة الثانية',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerHeader(ChatSession session) {
    final remaining = session.remainingTime;
    if (remaining == null) return const SizedBox();
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MithaqSpacing.m),
      decoration: BoxDecoration(
        color: MithaqColors.mint.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: MithaqColors.mint.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'بروتوكول الفيصل (٧ أيام)',
            style: TextStyle(
              fontSize: 10,
              color: MithaqColors.navy,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(days.toString(), 'يوم'),
              _buildTimeSeparator(),
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'ساعة'),
              _buildTimeSeparator(),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'دقيقة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: MithaqColors.navy,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: MithaqColors.navy.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: MithaqColors.navy.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildShufaInfoBanner(ChatSession session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MithaqSpacing.s),
      color: MithaqColors.mint.withValues(alpha: 0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 16, color: MithaqColors.mint),
          SizedBox(width: 8),
          Text(
            'تم طلب "الشوفة الشرعية" رسمياً. تواصل بجدية للترتيب.',
            style: TextStyle(
              fontSize: 11,
              color: MithaqColors.mint,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? MithaqColors.navy : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isMe ? Radius.zero : const Radius.circular(16),
            bottomRight: isMe ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : MithaqColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatSession session, String activeId) {
    final targetProfileAsync = ref.watch(
      singleProfileProvider(widget.targetProfileId),
    );
    final shufaUnlockedAsync = ref.watch(
      shufaUnlockProvider(widget.targetProfileId),
    );

    return targetProfileAsync.when(
      data: (targetProfile) {
        final canShowShufa =
            targetProfile != null &&
            targetProfile.shufaCardActive &&
            targetProfile.gender == Gender.female;

        return Container(
          padding: const EdgeInsets.all(MithaqSpacing.m),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              if (canShowShufa)
                shufaUnlockedAsync.when(
                  data: (isUnlocked) => IconButton(
                    onPressed: () =>
                        _handleShufaAction(targetProfile, isUnlocked, activeId),
                    icon: Icon(
                      isUnlocked
                          ? Icons.contact_phone
                          : Icons.contact_phone_outlined,
                      color: isUnlocked ? MithaqColors.mint : MithaqColors.navy,
                    ),
                  ),
                  loading: () => const SizedBox(width: 48),
                  error: (_, __) => const SizedBox(),
                ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة محترمة...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _sendMessage(session, activeId),
                icon: const Icon(Icons.send_rounded, color: MithaqColors.navy),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  void _handleShufaAction(
    SeekerProfile target,
    bool isUnlocked,
    String activeId,
  ) async {
    if (isUnlocked) {
      final info = await ref.read(
        guardianContactInfoProvider(target.profileId).future,
      );
      if (!mounted) return;
      showShufaCard(
        context,
        name: info?['shufa_card_guardian_name'] ?? 'غير متوفر',
        title: info?['shufa_card_guardian_title'] ?? '',
        phone: info?['shufa_card_guardian_phone'] ?? '',
        isVerified: target.shufaCardIsVerified,
      );
    } else {
      _showUnlockShufaDialog(target, activeId);
    }
  }

  void _showUnlockShufaDialog(SeekerProfile target, String activeId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.contact_phone_outlined,
              color: MithaqColors.mint,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'طلب الشوفة الشرعية',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MithaqColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'للحصول على معلومات التواصل المباشرة مع ولي الأمر، يتطلب ذلك دفع رسوم إثبات الجدية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _unlockShufa(target.profileId, activeId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.navy,
                  foregroundColor: Colors.white,
                ),
                child: const Text('دفع وأظهر البطاقة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlockShufa(String targetId, String activeId) async {
    final repo = ref.read(chat_repo.chatRepositoryProvider);
    await repo.unlockShufaCard(activeId, targetId);
    _handleUpdateStage(targetId, ChatStage.shufaRequested);
  }

  void _handleUpdateStage(String sessionId, ChatStage newStage) async {
    await ref
        .read(chat_repo.chatRepositoryProvider)
        .updateStage(sessionId, newStage);
    ref.invalidate(chatSessionProvider(widget.targetProfileId));
  }

  void _sendMessage(ChatSession session, String activeId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_safetyFilter.hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مشاركة معلومات التواصل غير مسموح في هذه المرحلة.'),
        ),
      );
      return;
    }

    _messageController.clear();
    await ref
        .read(chat_repo.chatRepositoryProvider)
        .sendMessage(session.id, activeId, text);
    ref.invalidate(chatMessagesStreamProvider(session.id));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildClosedUI(ChatSession session) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      width: double.infinity,
      child: Column(
        children: [
          const Icon(Icons.lock_person_outlined, color: Colors.grey, size: 32),
          const SizedBox(height: 12),
          const Text(
            'هذه المحادثة مغلقة',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            session.isExpired
                ? 'انتهت مدة الفيصل المحددة (٧ أيام).'
                : 'تم إنهاء التواصل من قبل أحد الطرفين.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ProtocolIntroSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: MithaqColors.navy, size: 48),
          const SizedBox(height: 16),
          const Text(
            'بروتوكول ميثاق للتواصل',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MithaqColors.navy,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'التواصل في ميثاق يعتمد الصدق والجدية.\n١- تعارف مبدئي\n٢- تعارف أعمق\n٣- رقم الولي',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.8),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.navy,
                foregroundColor: Colors.white,
              ),
              child: const Text('فهمت، نبدأ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RespectfulClosureSheet extends StatefulWidget {
  final Function(String reason) onConfirm;
  const _RespectfulClosureSheet({required this.onConfirm});

  @override
  State<_RespectfulClosureSheet> createState() =>
      _RespectfulClosureSheetState();
}

class _RespectfulClosureSheetState extends State<_RespectfulClosureSheet> {
  String? selectedReason;
  final List<String> reasons = [
    'عدم توافق في الرؤى',
    'عدم جدية',
    'ظروف خاصة',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'إنهاء التواصل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MithaqColors.navy,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: reasons
                .map(
                  (r) => ChoiceChip(
                    label: Text(r),
                    selected: selectedReason == r,
                    onSelected: (s) =>
                        setState(() => selectedReason = s ? r : null),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: selectedReason == null
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onConfirm(selectedReason!);
                  },
            child: const Text('تأكيد الإنهاء'),
          ),
        ],
      ),
    );
  }
}
