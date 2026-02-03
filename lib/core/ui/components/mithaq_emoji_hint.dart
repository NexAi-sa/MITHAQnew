import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../design_tokens.dart';

class MithaqEmojiHint extends StatelessWidget {
  final String emoji;
  final String text;

  const MithaqEmojiHint({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MithaqSpacing.m,
        vertical: MithaqSpacing.s,
      ),
      decoration: BoxDecoration(
        color: MithaqColors.pink.withValues(alpha: 0.2),
        borderRadius: MithaqRadius.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: MithaqSpacing.s),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.bodySmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
