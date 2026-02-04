import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../application/advisor_controller.dart';
import '../domain/advisor_message.dart';
import 'advisor_summary_sheet.dart';

/// Main chat screen for advisor consultations
class AdvisorChatScreen extends ConsumerStatefulWidget {
  final String? initialProfileId;

  const AdvisorChatScreen({super.key, this.initialProfileId});

  @override
  ConsumerState<AdvisorChatScreen> createState() => _AdvisorChatScreenState();
}

class _AdvisorChatScreenState extends ConsumerState<AdvisorChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    // Start consultation after build (only once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStarted) {
        _hasStarted = true;
        ref
            .read(advisorControllerProvider.notifier)
            .startConsultation(targetProfileId: widget.initialProfileId);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(advisorControllerProvider.notifier).sendMessage(text);
    _textController.clear();

    // Scroll to bottom after message
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

  void _sendSuggestion(String text) {
    _textController.text = text;
    _sendMessage();
  }

  void _showSummary() {
    ref.read(advisorControllerProvider.notifier).generateSummary();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdvisorSummarySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(advisorControllerProvider);

    // Show error toast if any
    ref.listen<AdvisorState>(advisorControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: MithaqColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(advisorControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MithaqColors.navy),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: MithaqColors.mint,
              radius: 18,
              child: Icon(
                widget.initialProfileId == 'support'
                    ? Icons.support_agent
                    : Icons.psychology_outlined,
                color: MithaqColors.navy,
                size: 20,
              ),
            ),
            const SizedBox(width: MithaqSpacing.s),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialProfileId == 'support'
                      ? 'وكيل الدعم الذكي'
                      : 'خبير التوافق',
                  style: const TextStyle(
                    color: MithaqColors.navy,
                    fontSize: MithaqTypography.bodyLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.initialProfileId == 'support'
                      ? 'جاهز لمساعدتك'
                      : 'مستشارك الذكي',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: MithaqTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (state.messages.length > 2)
            IconButton(
              icon: const Icon(
                Icons.summarize_outlined,
                color: MithaqColors.navy,
              ),
              onPressed: _showSummary,
              tooltip: 'الخلاصة الذكية',
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(MithaqSpacing.m),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length && state.isLoading) {
                  return _TypingIndicator();
                }
                return _MessageBubble(message: state.messages[index]);
              },
            ),
          ),

          // Suggestion chips
          if (!state.isLoading && state.targetProfileId != 'support')
            _SuggestionChips(onSelect: _sendSuggestion),

          // Input area
          _InputArea(
            controller: _textController,
            onSend: _sendMessage,
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AdvisorMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: MithaqSpacing.m),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(MithaqSpacing.m),
        decoration: BoxDecoration(
          color: isUser
              ? MithaqColors.navy
              : MithaqColors.mint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(MithaqRadius.l),
            topRight: const Radius.circular(MithaqRadius.l),
            bottomLeft: Radius.circular(
              isUser ? MithaqRadius.l : MithaqRadius.s,
            ),
            bottomRight: Radius.circular(
              isUser ? MithaqRadius.s : MithaqRadius.l,
            ),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : MithaqColors.navy,
            fontSize: MithaqTypography.bodyMedium,
            height: 1.5,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: MithaqSpacing.m),
        padding: const EdgeInsets.all(MithaqSpacing.m),
        decoration: BoxDecoration(
          color: MithaqColors.mint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(MithaqRadius.l),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MithaqColors.navy,
              ),
            ),
            SizedBox(width: MithaqSpacing.s),
            Text(
              'يكتب...',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final void Function(String) onSelect;

  const _SuggestionChips({required this.onSelect});

  static const List<String> suggestions = [
    'هل هذا الحساب مناسب لي؟',
    'وش النقاط اللي ممكن تسبب خلاف؟',
    'وش أسأل أول سؤال؟',
    'حلّل حساب برقم Profile ID',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MithaqSpacing.m,
        vertical: MithaqSpacing.s,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((s) {
            return Padding(
              padding: const EdgeInsets.only(left: MithaqSpacing.s),
              child: ActionChip(
                label: Text(
                  s,
                  style: const TextStyle(
                    fontSize: MithaqTypography.bodySmall,
                    color: MithaqColors.navy,
                  ),
                ),
                backgroundColor: MithaqColors.pink.withValues(alpha: 0.3),
                side: BorderSide.none,
                onPressed: () => onSelect(s),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const _InputArea({
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: MithaqSpacing.m,
        right: MithaqSpacing.m,
        top: MithaqSpacing.s,
        bottom: MediaQuery.of(context).padding.bottom + MithaqSpacing.s,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: MithaqColors.navy),
              decoration: InputDecoration(
                hintText: 'اكتب سؤالك هنا...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(
                  color: MithaqColors.navy.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MithaqRadius.l),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MithaqSpacing.m,
                  vertical: MithaqSpacing.m,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: MithaqSpacing.s),
          CircleAvatar(
            backgroundColor: MithaqColors.navy,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: isLoading ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
