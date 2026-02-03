import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';

import '../../../core/ui/components/subscription_paywall.dart';

/// Messages Screen - Placeholder inbox with protocol explanation
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    // Enforce subscription for Guardians
    if (session.role == UserRole.guardian && !session.hasActiveSubscription) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('الرسائل'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const SubscriptionPaywall(
          title: 'الرسائل والمحادثات',
          message:
              'للتواصل مع الأعضاء أو الرد على استفساراتهم، يرجى تفعيل اشتراكك.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('الرسائل'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildEmptyState(context, session),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppSession session) {
    // Determine if user is managed by guardian
    final isManagedByGuardian = session.activeDependentId != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MithaqSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty inbox illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: MithaqColors.mint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: MithaqColors.mint.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: MithaqSpacing.xl),

            // Title
            const Text(
              'لا توجد محادثات بعد',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),

            // Protocol explanation card
            MithaqCard(
              padding: const EdgeInsets.all(MithaqSpacing.m),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: MithaqColors.navy.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  const SizedBox(height: MithaqSpacing.s),
                  Text(
                    isManagedByGuardian
                        ? 'حسابك بإدارة ولي الأمر'
                        : 'بروتوكول ميثاق',
                    style: const TextStyle(
                      color: MithaqColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: MithaqTypography.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: MithaqSpacing.s),
                  Text(
                    isManagedByGuardian
                        ? 'سيتم التواصل الأولي عبر ولي أمرك حفاظاً على الخصوصية والجدية. بعد الموافقة المبدئية، تُتاح لك المحادثة المباشرة.'
                        : 'عند القبول المتبادل تبدأ المحادثة مع عداد ٧ أيام. بعدها يمكن طلب بطاقة الشوفة للتواصل مع الولي خارج المنصة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MithaqColors.navy.withValues(alpha: 0.7),
                      fontSize: MithaqTypography.bodySmall,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MithaqSpacing.xl),

            // CTA Button
            ElevatedButton.icon(
              onPressed: () => context.go('/seeker/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: MithaqSpacing.xl,
                  vertical: MithaqSpacing.m,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MithaqRadius.m),
                ),
              ),
              icon: const Icon(Icons.explore_outlined),
              label: const Text(
                'استعرض الحالات',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: MithaqSpacing.l),

            // Hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: MithaqColors.mint.withValues(alpha: 0.8),
                ),
                const SizedBox(width: MithaqSpacing.xs),
                Text(
                  'ابدأ باستعراض الملفات وأبدِ اهتمامك',
                  style: TextStyle(
                    color: MithaqColors.navy.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
