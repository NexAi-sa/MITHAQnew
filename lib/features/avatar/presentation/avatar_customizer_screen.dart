import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/avatar_config.dart';
import 'avatar_notifier.dart';
import 'widgets/avatar_renderer.dart';
import '../../../../core/theme/design_system.dart';

class AvatarCustomizerScreen extends ConsumerWidget {
  const AvatarCustomizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(avatarProvider);
    final notifier = ref.read(avatarProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('تصميم الهوية البصرية')),
      body: Column(
        children: [
          const SizedBox(height: 32),
          AvatarRenderer(config: config, size: 180),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'حفاظًا على الخصوصية، لا نستخدم صورًا حقيقية',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MithaqColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MithaqColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(title: 'الجنس'),
                    Row(
                      children: [
                        _ChoiceChip<Gender>(
                          label: 'ذكر',
                          value: Gender.male,
                          groupValue: config.gender,
                          onSelected: (val) => notifier.setGender(val),
                        ),
                        const SizedBox(width: 12),
                        _ChoiceChip<Gender>(
                          label: 'أنثى',
                          value: Gender.female,
                          groupValue: config.gender,
                          onSelected: (val) => notifier.setGender(val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'لون البشرة'),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: SkinTone.values
                            .map(
                              (tone) => _SkinToneChip(
                                tone: tone,
                                isSelected: config.skinTone == tone,
                                onTap: () => notifier.setSkinTone(tone),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'شكل الوجه'),
                    Row(
                      children: FaceShape.values
                          .map(
                            (shape) => _ChoiceChip<FaceShape>(
                              label: _getShapeLabel(shape),
                              value: shape,
                              groupValue: config.faceShape,
                              onSelected: (val) => notifier.setFaceShape(val),
                            ),
                          )
                          .toList()
                          .expand((w) => [w, const SizedBox(width: 8)])
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'النمط'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getAvailableHeadStyles(config.gender)
                          .map(
                            (style) => _ChoiceChip<HeadStyle>(
                              label: _getStyleLabel(style),
                              value: style,
                              groupValue: config.headStyle,
                              onSelected: (val) => notifier.setHeadStyle(val),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('حفظ الهوية'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getShapeLabel(FaceShape shape) {
    switch (shape) {
      case FaceShape.oval:
        return 'بيضاوي';
      case FaceShape.round:
        return 'دائري';
      case FaceShape.square:
        return 'مربع';
    }
  }

  String _getStyleLabel(HeadStyle style) {
    switch (style) {
      case HeadStyle.hijab:
        return 'حجاب';
      case HeadStyle.shortHair:
        return 'شعر قصير';
      case HeadStyle.longHair:
        return 'شعر طويل';
      case HeadStyle.bald:
        return 'بدون شعر';
      case HeadStyle.beard:
        return 'لحية';
      case HeadStyle.none:
        return 'طبيعي';
    }
  }

  List<HeadStyle> _getAvailableHeadStyles(Gender gender) {
    if (gender == Gender.female) {
      return [
        HeadStyle.hijab,
        HeadStyle.shortHair,
        HeadStyle.longHair,
        HeadStyle.none,
      ];
    } else {
      return [
        HeadStyle.shortHair,
        HeadStyle.bald,
        HeadStyle.beard,
        HeadStyle.none,
      ];
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _ChoiceChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T> onSelected;

  const _ChoiceChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: MithaqColors.navy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : MithaqColors.navy,
      ),
      side: const BorderSide(color: MithaqColors.navy),
      checkmarkColor: Colors.white,
    );
  }
}

class _SkinToneChip extends StatelessWidget {
  final SkinTone tone;
  final bool isSelected;
  final VoidCallback onTap;

  const _SkinToneChip({
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _getSkinColor(tone),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? MithaqColors.navy : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  Color _getSkinColor(SkinTone tone) {
    switch (tone) {
      case SkinTone.light:
        return const Color(0xFFFFDBAC);
      case SkinTone.medium:
        return const Color(0xFFF1C27D);
      case SkinTone.tan:
        return const Color(0xFFE0AC69);
      case SkinTone.mediumDeep:
        return const Color(0xFF8D5524);
      case SkinTone.deep:
        return const Color(0xFF5D3117);
    }
  }
}
