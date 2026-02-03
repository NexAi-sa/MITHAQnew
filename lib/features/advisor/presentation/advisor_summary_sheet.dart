import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../application/advisor_controller.dart';

/// Summary sheet shown after consultation
class AdvisorSummarySheet extends ConsumerWidget {
  const AdvisorSummarySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advisorControllerProvider);
    final summary = state.currentSummary;

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MithaqRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: MithaqSpacing.m),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(MithaqSpacing.l),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(MithaqSpacing.s),
                      decoration: BoxDecoration(
                        color: MithaqColors.mint.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(MithaqRadius.m),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: MithaqColors.navy,
                      ),
                    ),
                    const SizedBox(width: MithaqSpacing.m),
                    const Text(
                      'الخلاصة الذكية',
                      style: TextStyle(
                        color: MithaqColors.navy,
                        fontSize: MithaqTypography.titleMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(MithaqSpacing.l),
                  children: [
                    // Compatibility Points
                    _SummarySection(
                      icon: Icons.check_circle_outline,
                      iconColor: MithaqColors.mint,
                      title: 'نقاط توافق واضحة',
                      items: summary.compatibilityPoints,
                    ),

                    const SizedBox(height: MithaqSpacing.l),

                    // Discussion Points
                    _SummarySection(
                      icon: Icons.chat_bubble_outline,
                      iconColor: Colors.orange,
                      title: 'نقاط تحتاج نقاش بهدوء',
                      items: summary.discussionPoints,
                    ),

                    const SizedBox(height: MithaqSpacing.l),

                    // Suggested Questions
                    _SummarySection(
                      icon: Icons.help_outline,
                      iconColor: MithaqColors.navy,
                      title: 'أسئلة مقترحة للطرف الآخر/للولي',
                      items: summary.suggestedQuestions,
                    ),

                    const SizedBox(height: MithaqSpacing.xl),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(MithaqSpacing.m),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(MithaqRadius.m),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 16,
                          ),
                          SizedBox(width: MithaqSpacing.s),
                          Expanded(
                            child: Text(
                              'هذه ملاحظات استرشادية وليست تقييماً نهائياً. القرار الأخير يعود لكما.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: MithaqTypography.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummarySection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _SummarySection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: MithaqSpacing.s),
            Text(
              title,
              style: const TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.bodyLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: MithaqSpacing.m),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: MithaqSpacing.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: TextStyle(
                    color: iconColor,
                    fontSize: MithaqTypography.bodyLarge,
                  ),
                ),
                const SizedBox(width: MithaqSpacing.s),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: MithaqColors.navy,
                      fontSize: MithaqTypography.bodyMedium,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
