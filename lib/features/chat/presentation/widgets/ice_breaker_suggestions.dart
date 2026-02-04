import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/ui/design_tokens.dart';
import '../../domain/ice_breaker_generator.dart';
import '../../../compatibility/domain/compatibility_model.dart';
import '../../../seeker/domain/profile.dart';

/// Ice-breaker suggestion chips for new chat conversations
class IceBreakerSuggestions extends StatelessWidget {
  final CompatibilityResult? compatibility;
  final SeekerProfile? targetProfile;
  final Function(String) onSuggestionSelected;

  const IceBreakerSuggestions({
    super.key,
    this.compatibility,
    this.targetProfile,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = IceBreakerGenerator.getQuickSuggestions(
      compatibility: compatibility,
      targetProfile: targetProfile,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MithaqSpacing.m,
        vertical: MithaqSpacing.s,
      ),
      decoration: BoxDecoration(
        color: MithaqColors.mint.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: MithaqColors.mint.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '✨ اقتراحات للتعارف',
                style: TextStyle(
                  fontSize: 12,
                  color: MithaqColors.navy.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: MithaqColors.mint.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: MithaqSpacing.s),
          // Suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              final isMainSuggestion = index == 0;

              return _SuggestionChip(
                text: suggestion,
                isHighlighted: isMainSuggestion,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSuggestionSelected(suggestion);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? MithaqColors.mint.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? MithaqColors.mint : Colors.grey.shade300,
            width: isHighlighted ? 1.5 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: MithaqColors.mint.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHighlighted) ...[
              Icon(Icons.psychology, size: 14, color: MithaqColors.mint),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: isHighlighted
                      ? MithaqColors.navy
                      : Colors.grey.shade700,
                  fontWeight: isHighlighted
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget with ice-breaker suggestions
class EmptyChatWithSuggestions extends StatelessWidget {
  final CompatibilityResult? compatibility;
  final SeekerProfile? targetProfile;
  final Function(String) onSuggestionSelected;

  const EmptyChatWithSuggestions({
    super.key,
    this.compatibility,
    this.targetProfile,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Ghost text / hint
        Container(
          margin: const EdgeInsets.symmetric(horizontal: MithaqSpacing.xl),
          padding: const EdgeInsets.all(MithaqSpacing.l),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(MithaqRadius.l),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: MithaqSpacing.m),
              Text(
                'ابدأ المحادثة بأفضل طريقة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MithaqColors.navy.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: MithaqSpacing.s),
              Text(
                'اختر من الاقتراحات المخصصة أدناه\nأو اكتب رسالتك الخاصة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Suggestions at bottom
        IceBreakerSuggestions(
          compatibility: compatibility,
          targetProfile: targetProfile,
          onSuggestionSelected: onSuggestionSelected,
        ),
      ],
    );
  }
}
