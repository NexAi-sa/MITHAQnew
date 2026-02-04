import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_soft_icon.dart';

/// Entry card for advisor feature (shown on Seeker Home)
class AdvisorEntryCard extends ConsumerWidget {
  const AdvisorEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: MithaqSpacing.m,
        vertical: MithaqSpacing.s,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MithaqColors.navy,
            MithaqColors.navy.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MithaqRadius.l),
        boxShadow: [
          BoxShadow(
            color: MithaqColors.navy.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/advisor'),
          borderRadius: BorderRadius.circular(MithaqRadius.l),
          child: Padding(
            padding: const EdgeInsets.all(MithaqSpacing.l),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(MithaqSpacing.m),
                  decoration: BoxDecoration(
                    color: MithaqColors.mint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(MithaqRadius.m),
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: MithaqColors.mint,
                    size: MithaqIconSize.l,
                  ),
                ),
                const SizedBox(width: MithaqSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'استشر خبير التوافق',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MithaqTypography.titleSmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: MithaqSpacing.xs),
                      Text(
                        'دع الذكاء الاصطناعي يساعدك في فهم التوافق',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: MithaqTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: MithaqIconSize.s,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact button for profile detail screen
class AdvisorProfileButton extends StatelessWidget {
  final String profileId;

  const AdvisorProfileButton({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).brightness == Brightness.light
        ? MithaqColors.navy
        : MithaqColors.mint;
    return OutlinedButton.icon(
      onPressed: () => context.push('/advisor?profileId=$profileId'),
      icon: MithaqSoftIcon(
        icon: Icons.psychology_outlined,
        size: MithaqIconSize.s,
        padding: 4,
        iconColor: primaryColor,
      ),
      label: const Text('استشر خبير التوافق عن هذا الحساب'),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: MithaqSpacing.m,
          vertical: MithaqSpacing.s,
        ),
      ),
    );
  }
}
