import 'package:flutter/material.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../domain/compatibility_model.dart';

/// Bottom sheet explaining why the compatibility scores are what they are
class CompatibilityExplainerSheet extends StatelessWidget {
  final CompatibilityResult result;

  const CompatibilityExplainerSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MithaqRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: MithaqSpacing.m),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(MithaqSpacing.l),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(MithaqSpacing.s),
                      decoration: BoxDecoration(
                        color: MithaqColors.mint.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(MithaqRadius.m),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: MithaqColors.navy,
                      ),
                    ),
                    const SizedBox(width: MithaqSpacing.m),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ليش طلعت النتيجة كذا؟',
                            style: TextStyle(
                              color: MithaqColors.navy,
                              fontSize: MithaqTypography.titleSmall,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'شرح مفصل لكل محور',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: MithaqTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(MithaqSpacing.l),
                  children: [
                    // Basic axis explanation
                    _AxisExplanation(
                      axisName: 'التوافق الأساسي',
                      score: result.basic,
                      description:
                          'يشمل العمر، المدينة، الحالة الاجتماعية، والتعليم',
                      icon: Icons.foundation,
                    ),

                    const SizedBox(height: MithaqSpacing.l),

                    // Style axis explanation
                    _AxisExplanation(
                      axisName: 'التوافق النمطي',
                      score: result.style,
                      description: 'يشمل نمط الحياة، التدخين، واللباس المفضل',
                      icon: Icons.style,
                    ),

                    const SizedBox(height: MithaqSpacing.l),

                    // Psychological axis explanation
                    _AxisExplanation(
                      axisName: 'التوافق النفسي',
                      score: result.psychological,
                      description: 'مبني على الاستشارات والتقييمات السلوكية',
                      icon: Icons.psychology,
                    ),

                    const SizedBox(height: MithaqSpacing.xl),

                    // Summary section
                    if (result.allPositiveReasons.isNotEmpty) ...[
                      const Text(
                        '✅ نقاط التوافق الإيجابية',
                        style: TextStyle(
                          color: MithaqColors.navy,
                          fontSize: MithaqTypography.bodyLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: MithaqSpacing.s),
                      ...result.allPositiveReasons
                          .take(3)
                          .map(
                            (reason) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: MithaqSpacing.s,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: MithaqColors.mint,
                                    size: 18,
                                  ),
                                  const SizedBox(width: MithaqSpacing.s),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: const TextStyle(
                                        color: MithaqColors.navy,
                                        fontSize: MithaqTypography.bodyMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: MithaqSpacing.l),
                    ],

                    if (result.allDiscussionPoints.isNotEmpty) ...[
                      const Text(
                        '💬 نقاط تحتاج حوار',
                        style: TextStyle(
                          color: MithaqColors.navy,
                          fontSize: MithaqTypography.bodyLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: MithaqSpacing.s),
                      ...result.allDiscussionPoints
                          .take(2)
                          .map(
                            (point) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: MithaqSpacing.s,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: MithaqSpacing.s),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style: const TextStyle(
                                        color: MithaqColors.navy,
                                        fontSize: MithaqTypography.bodyMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],

                    const SizedBox(height: MithaqSpacing.xl),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(MithaqSpacing.m),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(MithaqRadius.m),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 16,
                          ),
                          SizedBox(width: MithaqSpacing.s),
                          Expanded(
                            child: Text(
                              'هذه مؤشرات استرشادية وليست حكماً نهائياً. القرار الأخير يعود لكما.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: MithaqTypography.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Explanation card for a single axis
class _AxisExplanation extends StatelessWidget {
  final String axisName;
  final AxisScore score;
  final String description;
  final IconData icon;

  const _AxisExplanation({
    required this.axisName,
    required this.score,
    required this.description,
    required this.icon,
  });

  Color get _scoreColor {
    if (!score.isComplete) return Colors.grey;
    if (score.score >= 75) return MithaqColors.mint;
    if (score.score >= 50) return Colors.orange;
    return MithaqColors.pink;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      decoration: BoxDecoration(
        color: _scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MithaqRadius.m),
        border: Border.all(color: _scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _scoreColor, size: 20),
              const SizedBox(width: MithaqSpacing.s),
              Expanded(
                child: Text(
                  axisName,
                  style: const TextStyle(
                    color: MithaqColors.navy,
                    fontSize: MithaqTypography.bodyLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score.isComplete ? '${score.score}%' : 'غير مكتمل',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: MithaqTypography.bodySmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MithaqSpacing.s),
          Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: MithaqTypography.bodySmall,
            ),
          ),
          if (score.positiveReasons.isNotEmpty) ...[
            const SizedBox(height: MithaqSpacing.m),
            ...score.positiveReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: MithaqColors.navy),
                    ),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          color: MithaqColors.navy,
                          fontSize: MithaqTypography.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
