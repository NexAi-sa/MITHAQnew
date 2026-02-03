import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_system.dart';
import '../design_tokens.dart';

/// A polished filter chip with smooth selection animation and haptic feedback.
class MithaqChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const MithaqChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? MithaqColors.navy
        : MithaqColors.navy.withValues(alpha: 0.06);
    final textColor = isSelected ? Colors.white : MithaqColors.navy;
    final borderColor = isSelected
        ? Colors.transparent
        : MithaqColors.navy.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: MithaqDurations.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: MithaqSpacing.m,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: MithaqRadius.rounded,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: MithaqIconSize.s, color: textColor),
              const SizedBox(width: MithaqSpacing.xs),
            ],
            AnimatedDefaultTextStyle(
              duration: MithaqDurations.fast,
              style: TextStyle(
                color: textColor,
                fontSize: MithaqTypography.bodyMedium,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
