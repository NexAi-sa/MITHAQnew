import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../privacy_notifier.dart';
import '../../../../core/theme/design_system.dart';
import '../../../avatar/presentation/avatar_notifier.dart';
import '../../../avatar/presentation/widgets/avatar_renderer.dart';

class NamePreviewCard extends ConsumerWidget {
  const NamePreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(privacyProvider);
    final avatarConfig = ref.watch(avatarProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MithaqColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: MithaqColors.outlineLight),
      ),
      child: Column(
        children: [
          AvatarRenderer(config: avatarConfig, size: 80),
          const SizedBox(height: 16),
          Text(
            state.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: MithaqColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'باحث عن زواج',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MithaqColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MithaqColors.mint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'معاينة لظهور اسمك للآخرين',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
