import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';

/// Premium Role Selection Screen
/// Feels like an invitation, not a decision
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Welcome Header
                  _buildWelcomeHeader(context),

                  const Spacer(flex: 1),

                  // Role Cards
                  _buildRoleCard(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    emoji: '💍',
                    title: 'أنا هنا لأجد شريك عمري',
                    subtitle: 'أبحث عن نصفك الآخر بأمان',
                    description:
                        'سجّل ملفك وابدأ رحلتك السامية نحو المودة والاستقرار',
                    onTap: () =>
                        _selectRole(UserRole.seeker, '/seeker/onboarding'),
                    isPrimary: true,
                  ),

                  const SizedBox(height: 20),

                  _buildRoleCard(
                    context: context,
                    icon: Icons.family_restroom_rounded,
                    emoji: '🤝',
                    title: 'أنا هنا لأكون عوناً لمن أحب',
                    subtitle: 'سند وساعٍ في الخير لعائلتي',
                    description:
                        'سجّل كطرف معاون لإدارة ملف ابنك أو ابنتك بيسر وخصوصية',
                    onTap: () =>
                        _selectRole(UserRole.guardian, '/guardian/onboarding'),
                    isPrimary: false,
                  ),

                  const SizedBox(height: 32),

                  // Reassurance text
                  _buildReassuranceText(context),

                  const Spacer(flex: 2),

                  // Privacy note
                  _buildPrivacyNote(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Column(
      children: [
        // App logo small
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MithaqColors.mint.withValues(alpha: 0.15),
          ),
          child: Image.asset(
            'assets/logo_transparent.png',
            width: 32,
            height: 32,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'أهلاً بك في ${AppLocalizations.of(context, 'app_title')}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'نسعد بانضمامك لمجتمعنا الآمن',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'كيف تودّ المتابعة؟',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isPrimary
                ? MithaqColors.mint.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border.all(
              color: isPrimary
                  ? MithaqColors.mint
                  : Colors.grey.withValues(alpha: 0.3),
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Emoji/Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPrimary
                      ? MithaqColors.mint.withValues(alpha: 0.25)
                      : Colors.grey.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isPrimary ? MithaqColors.mint : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isPrimary ? MithaqColors.mint : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReassuranceText(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: MithaqColors.mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'يمكنك التعديل لاحقاً في أي وقت',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            'معلوماتك محمية وآمنة',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRole(UserRole role, String route) async {
    final notifier = ref.read(sessionProvider.notifier);
    await notifier.setRole(role);
    await notifier.setOnboardingStatus(OnboardingStatus.notStarted);
    if (mounted) context.go(route);
  }
}
