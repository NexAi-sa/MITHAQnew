import 'package:flutter/material.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../domain/compatibility_model.dart';

/// Card showing compatibility indicators for a profile
class CompatibilityIndicatorsCard extends StatelessWidget {
  final CompatibilityResult result;
  final VoidCallback? onExplainTap;

  const CompatibilityIndicatorsCard({
    super.key,
    required this.result,
    this.onExplainTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MithaqRadius.l),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(MithaqSpacing.s),
                decoration: BoxDecoration(
                  color: MithaqColors.mint.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(MithaqRadius.s),
                ),
                child: const Icon(
                  Icons.insights,
                  color: MithaqColors.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: MithaqSpacing.s),
              const Text(
                'مؤشرات التوافق',
                style: TextStyle(
                  color: MithaqColors.navy,
                  fontSize: MithaqTypography.titleSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: MithaqSpacing.l),

          // Three axis rows
          _AxisRow(score: result.basic),
          const SizedBox(height: MithaqSpacing.m),
          _AxisRow(score: result.style),
          const SizedBox(height: MithaqSpacing.m),
          _AxisRow(score: result.psychological),

          const SizedBox(height: MithaqSpacing.l),

          // Incomplete data notice
          if (result.hasIncompleteData)
            Container(
              padding: const EdgeInsets.all(MithaqSpacing.s),
              decoration: BoxDecoration(
                color: MithaqColors.pink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(MithaqRadius.s),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: MithaqColors.navy, size: 16),
                  SizedBox(width: MithaqSpacing.s),
                  Expanded(
                    child: Text(
                      'بعض المؤشرات غير مكتملة - يمكن تحسينها بإكمال الاستشارة',
                      style: TextStyle(
                        color: MithaqColors.navy,
                        fontSize: MithaqTypography.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (result.hasIncompleteData) const SizedBox(height: MithaqSpacing.m),

          // Explain button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onExplainTap,
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('ليش طلعت النتيجة؟'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MithaqColors.navy,
                side: const BorderSide(color: MithaqColors.navy),
                padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single axis row with progress bar, score, and label
class _AxisRow extends StatelessWidget {
  final AxisScore score;

  const _AxisRow({required this.score});

  Color get _barColor {
    if (!score.isComplete) return Colors.grey;
    if (score.score >= 75) return MithaqColors.mint;
    if (score.score >= 50) return Colors.orange;
    return MithaqColors.pink;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Axis name
        SizedBox(
          width: 50,
          child: Text(
            score.axisName,
            style: const TextStyle(
              color: MithaqColors.navy,
              fontSize: MithaqTypography.bodySmall,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: MithaqSpacing.s),

        // Progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.isComplete ? score.score / 100 : 0.1,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              color: _barColor,
              minHeight: 8,
            ),
          ),
        ),

        const SizedBox(width: MithaqSpacing.s),

        // Score number
        SizedBox(
          width: 30,
          child: Text(
            score.isComplete ? '${score.score}' : '—',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: score.isComplete ? MithaqColors.navy : Colors.grey,
              fontSize: MithaqTypography.bodySmall,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: MithaqSpacing.s),

        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _barColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            score.label,
            style: TextStyle(
              color: score.isComplete ? MithaqColors.navy : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
