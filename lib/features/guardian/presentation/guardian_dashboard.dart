import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../seeker/data/profile_repository.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../avatar/presentation/widgets/avatar_renderer.dart';
import '../../seeker/domain/profile.dart';
import '../../../core/ui/components/mithaq_soft_icon.dart';

class GuardianDashboard extends ConsumerWidget {
  const GuardianDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final dependentsAsync = ref.watch(guardianDependentsProvider);

    const int maxSlots = 4;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'لوحة إدارة التابعين',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: MithaqSoftIcon(
            icon: Icons.settings,
            iconColor: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.go('/guardian/settings'),
        ),
        actions: const [],
      ),
      body: dependentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MithaqSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: MithaqSpacing.m),
                Text(
                  'عذراً، حدث خطأ في الاتصال',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: MithaqTypography.titleSmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: MithaqSpacing.s),
                Text(
                  'يرجى التأكد من اتصال الإنترنت والمحاولة مرة أخرى',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: MithaqSpacing.l),
                ElevatedButton(
                  onPressed: () => ref.invalidate(guardianDependentsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (dependents) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(MithaqSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guardian Welcome Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MithaqColors.mint.withValues(alpha: 0.15),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: MithaqColors.mint),
                          ),
                        ),
                        const SizedBox(width: MithaqSpacing.m),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً بك،',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              (session.fullName ?? '').isEmpty
                                  ? 'ولي الأمر'
                                  : session.fullName!,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: MithaqSpacing.xl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التابعين المشرف عليهم',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: MithaqTypography.titleSmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MithaqSpacing.m,
                  ),
                  itemCount: maxSlots,
                  itemBuilder: (context, index) {
                    if (index < dependents.length) {
                      final dep = dependents[index];
                      return _buildDependentCard(
                        context,
                        ref,
                        dep,
                        session.activeDependentId == dep.profileId,
                      );
                    } else if (index == dependents.length) {
                      // Only show as "First Slot" (free) if user has no dependents yet
                      return _buildEmptySlot(context, ref, dependents.isEmpty);
                    } else {
                      return _buildEmptySlot(context, ref, false);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDependentWizard(BuildContext context) {
    context.push('/guardian/add-dependent');
  }

  void _handleFirstSlotAccess(BuildContext context, WidgetRef ref) {
    // First dependent is always free
    _showAddDependentWizard(context);
  }

  void _showPaymentSheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(MithaqSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MithaqSpacing.l),
            const Text(
              'هذه الميزة تتطلب تفعيل الاشتراك أو رسوم إضافية لمرة واحدة.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MithaqSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.navy,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إتمام الدفع الآمن'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot(
    BuildContext context,
    WidgetRef ref,
    bool isFirstSlot,
  ) {
    final primaryColor = Theme.of(context).brightness == Brightness.light
        ? MithaqColors.navy
        : MithaqColors.textPrimaryDark;

    return Card(
      margin: const EdgeInsets.only(bottom: MithaqSpacing.m),
      elevation: 0,
      color: isFirstSlot
          ? MithaqColors.mint.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MithaqRadius.l),
        side: BorderSide(
          color: isFirstSlot
              ? MithaqColors.mint
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isFirstSlot) {
            _handleFirstSlotAccess(context, ref);
          } else {
            _showPaymentSheet(context, 'إنشاء ملف إضافي');
          }
        },
        borderRadius: BorderRadius.circular(MithaqRadius.l),
        child: Padding(
          padding: const EdgeInsets.all(MithaqSpacing.xl),
          child: Column(
            children: [
              Icon(
                isFirstSlot ? Icons.add_circle_outline : Icons.lock_open,
                color: primaryColor,
                size: 32,
              ),
              const SizedBox(height: MithaqSpacing.s),
              Text(
                isFirstSlot ? 'إضافة التابع الأول' : 'إضافة تابع إضافي',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                isFirstSlot ? 'مجانية بالكامل' : 'رسوم إنشاء ملف جديد: 99 ريال',
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed _buildLockedSlot as it's merged into _buildEmptySlot

  Widget _buildDependentCard(
    BuildContext context,
    WidgetRef ref,
    SeekerProfile dep,
    bool isActive,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Card(
      margin: const EdgeInsets.only(bottom: MithaqSpacing.m),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MithaqRadius.l),
        side: isActive
            ? BorderSide(
                color: isLight ? MithaqColors.navy : MithaqColors.mint,
                width: 2,
              )
            : BorderSide(
                color: isLight
                    ? Colors.grey.withValues(alpha: 0.1)
                    : MithaqColors.outlineDark,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MithaqSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarRenderer(
                  config: AvatarConfig(gender: dep.gender),
                  size: 50,
                ),
                const SizedBox(width: MithaqSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dep.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _StatusPill(
                            status: dep.isManagedByGuardian
                                ? ProfileStatus.ready
                                : ProfileStatus.draft,
                          ),
                        ],
                      ),
                      Text(
                        '${dep.age} سنة • ${dep.city}',
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[600]
                              : MithaqColors.textPrimaryDark.withValues(
                                  alpha: 0.6,
                                ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MithaqSpacing.m),
            const Divider(),
            const SizedBox(height: MithaqSpacing.s),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(sessionProvider.notifier)
                          .setActiveDependent(dep.profileId);
                      if (context.mounted) {
                        context.go(
                          '/guardian/dependents/${dep.profileId}/profile',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                    ),
                    child: const Text('عرض الملف'),
                  ),
                ),
                const SizedBox(width: MithaqSpacing.s),
                MithaqIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () {
                    // Navigate to full profile editor
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MithaqIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const MithaqIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProfileStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ProfileStatus.missing:
        color = Colors.orange.shade300;
        label = 'غير مكتمل';
        break;
      case ProfileStatus.draft:
        color = Colors.orange.shade400;
        label = 'مسودة';
        break;
      case ProfileStatus.ready:
        color = MithaqColors.mint;
        label = 'جاهز';
        break;
      case ProfileStatus.loading:
        color = Colors.grey;
        label = 'جاري التحميل';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
