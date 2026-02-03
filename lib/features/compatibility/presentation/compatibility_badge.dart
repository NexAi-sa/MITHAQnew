import 'package:flutter/material.dart';
import '../../../core/theme/design_system.dart';
import '../domain/compatibility_model.dart';

/// Compact badge showing overall compatibility for grid cards
class CompatibilityBadge extends StatelessWidget {
  final int score;
  final bool isComplete;

  const CompatibilityBadge({
    super.key,
    required this.score,
    this.isComplete = true,
  });

  /// Create from a full result
  factory CompatibilityBadge.fromResult(CompatibilityResult result) {
    return CompatibilityBadge(
      score: result.overallScore,
      isComplete: !result.hasIncompleteData,
    );
  }

  Color get _color {
    if (!isComplete) return Colors.grey;
    if (score >= 75) return MithaqColors.mint;
    if (score >= 50) return Colors.orange;
    return MithaqColors.pink;
  }

  String get _label {
    if (!isComplete) return 'جزئي';
    if (score >= 75) return 'ممتاز';
    if (score >= 50) return 'جيد';
    return 'يحتاج نقاش';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.insights : Icons.hourglass_empty,
            color: _color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isComplete ? '$score%' : _label,
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini progress bar for compact display
class CompatibilityMiniBar extends StatelessWidget {
  final int score;
  final double width;

  const CompatibilityMiniBar({super.key, required this.score, this.width = 40});

  Color get _color {
    if (score >= 75) return MithaqColors.mint;
    if (score >= 50) return Colors.orange;
    return MithaqColors.pink;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          color: _color,
          minHeight: 4,
        ),
      ),
    );
  }
}
