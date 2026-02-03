import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/name_visibility.dart';
import 'privacy_notifier.dart';
import 'widgets/name_preview_card.dart';
import '../../../../core/theme/design_system.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(privacyProvider);
    final notifier = ref.read(privacyProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('خصوصية الاسم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NamePreviewCard(),
            const SizedBox(height: 40),
            Text(
              'اختر كيف يظهر اسمك للآخرين',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: MithaqColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نحن نهتم بخصوصيتك وراحتك النفسية، يمكنك تغيير إعدادات الظهور في أي وقت.',
              style: TextStyle(color: MithaqColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            RadioGroup<NameVisibility>(
              groupValue: state.visibility,
              onChanged: (val) => notifier.setVisibility(val!),
              child: Column(
                children: [
                  _VisibilityOption(
                    title: 'إخفاء الاسم (نوصي به)',
                    subtitle: 'سيظهر معرفك التعريفي فقط بدلاً من اسمك.',
                    value: NameVisibility.hidden,
                    groupValue: state.visibility,
                  ),
                  _VisibilityOption(
                    title: 'الاسم الأول فقط',
                    subtitle: 'سيظهر اسمك الأول فقط دون اسم العائلة.',
                    value: NameVisibility.firstName,
                    groupValue: state.visibility,
                  ),
                  _VisibilityOption(
                    title: 'الاسم الكامل',
                    subtitle: 'سيظهر اسمك كاملاً للآخرين.',
                    value: NameVisibility.fullName,
                    groupValue: state.visibility,
                  ),
                ],
              ),
            ),
            if (state.visibility == NameVisibility.fullName) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('إظهار الاسم الكامل للمشتركين فقط'),
                subtitle: const Text('سيظهر اسمك الأول فقط لغير المشتركين.'),
                value: state.showFullNameToSubscribersOnly,
                onChanged: notifier.toggleFullNameToSubscribers,
                activeThumbColor: MithaqColors.mint,
                activeTrackColor: MithaqColors.mint.withValues(alpha: 0.5),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('حفظ الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final NameVisibility value;
  final NameVisibility groupValue;

  const _VisibilityOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: value == groupValue
              ? MithaqColors.navy
              : MithaqColors.outlineLight,
          width: value == groupValue ? 2 : 1,
        ),
      ),
      child: RadioListTile<NameVisibility>(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: value == groupValue
                ? MithaqColors.navy
                : MithaqColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        // groupValue and onChanged are now managed by the RadioGroup ancestor
        activeColor: MithaqColors.navy,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
