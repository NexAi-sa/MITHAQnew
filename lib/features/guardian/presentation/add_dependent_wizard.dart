import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../../../core/ui/components/mithaq_soft_icon.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../seeker/domain/profile.dart';
import '../../seeker/data/profile_repository.dart';
import '../application/wizard_progress_provider.dart';
import '../../../core/session/session_provider.dart';

class AddDependentWizard extends ConsumerStatefulWidget {
  const AddDependentWizard({super.key});

  @override
  ConsumerState<AddDependentWizard> createState() => _AddDependentWizardState();
}

class _AddDependentWizardState extends ConsumerState<AddDependentWizard> {
  int _currentStep = 1;

  // Step 1 data
  String _name = '';
  Gender? _gender;
  Relationship? _relationship;
  DateTime? _dob;
  String _city = '';
  MaritalStatus? _maritalStatus;
  String? _tribe; // Optional
  String _job = '';

  // Step 2 data (Physical)
  SkinColor? _skinColor;
  double _height = 165;
  BuildType? _buildType;

  // Step 3 data (Preferences)
  SmokingHabit? _smokingPreference;
  HijabPreference? _hijabPreference;
  bool _shufaCardActive = false;
  String _shufaGuardianName = '';
  String _shufaGuardianTitle = '';
  String _shufaGuardianPhone = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = ref.read(wizardProgressProvider);
      if (!progress.isEmpty) {
        _showRecoveryDialog(progress);
      }
    });
  }

  void _showRecoveryDialog(WizardProgress progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إكمال الإضافة'),
        content: const Text('تحب تكمل من حيث توقفت؟'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(wizardProgressProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text('بدء جديد'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = progress.step;
                _name = progress.name ?? '';
                _gender = progress.gender;
                _relationship = progress.relationship;
                _dob = progress.dob;
                _city = progress.city;
                _maritalStatus = progress.maritalStatus;
                _tribe = progress.tribe;
                _skinColor = progress.skinColor;
                _job = progress.job ?? '';
                _height = progress.height?.toDouble() ?? 165;
                _buildType = progress.buildType;
                _smokingPreference = progress.smokingPreference;
                _hijabPreference = progress.hijabPreference;
                _shufaCardActive = progress.shufaCardActive ?? false;
                _shufaGuardianName = progress.shufaCardGuardianName ?? '';
                _shufaGuardianTitle = progress.shufaCardGuardianTitle ?? '';
                _shufaGuardianPhone = progress.shufaCardGuardianPhone ?? '';
              });
              Navigator.pop(context);
            },
            child: const Text('إكمال'),
          ),
        ],
      ),
    );
  }

  void _saveProgress() {
    ref
        .read(wizardProgressProvider.notifier)
        .updateData(
          name: _name,
          gender: _gender,
          relationship: _relationship,
          dob: _dob,
          city: _city,
          maritalStatus: _maritalStatus,
          tribe: _tribe,
          skinColor: _skinColor,
          job: _job,
          height: _height.toInt(),
          buildType: _buildType,
          smokingPreference: _smokingPreference,
          hijabPreference: _hijabPreference,
          shufaCardActive: _shufaCardActive,
          shufaCardGuardianName: _shufaGuardianName,
          shufaCardGuardianTitle: _shufaGuardianTitle,
          shufaCardGuardianPhone: _shufaGuardianPhone,
        );
    ref.read(wizardProgressProvider.notifier).updateStep(_currentStep);
  }

  void _nextStep() {
    _saveProgress();
    if (_currentStep == 1) {
      if (_name.isEmpty ||
          _gender == null ||
          _relationship == null ||
          _dob == null ||
          _city.isEmpty ||
          _maritalStatus == null ||
          _job.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إكمال جميع البيانات الأساسية')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_skinColor == null || _buildType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إكمال المواصفات الشكلية')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final session = ref.read(sessionProvider);
    final repository = ref.read(profileRepositoryProvider);

    final newProfile = SeekerProfile(
      profileId:
          'DEP-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(999)}',
      userId: session.userId!,
      name: _name,
      city: _city,
      gender: _gender!,
      relationship: _relationship!.name,
      guardianUserId: session.userId,
      tribe: _tribe,
      maritalStatus: _maritalStatus!,
      job: _job,
      skinColor: _skinColor!.name,
      height: _height.toInt(),
      build: _buildType!.name,
      isManagedByGuardian: true,
      guardianContactAvailable: true,
      profileOwnerRole: ProfileOwnerRole.seekerDependent,
      dob: _dob ?? DateTime(2000, 1, 1),
      suitorPreferences: SuitorPreferences(
        smoking: _smokingPreference,
        hijab: _hijabPreference,
      ),
      shufaCardActive: _shufaCardActive,
      shufaCardGuardianName: _shufaGuardianName,
      shufaCardGuardianTitle: _shufaGuardianTitle,
      shufaCardGuardianPhone: _shufaGuardianPhone,
    );

    try {
      setState(() => _isSubmitting = true);

      // Add profile with a 10-second timeout to prevent Async Hang
      await repository
          .addProfile(newProfile)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('انتهت مهلة الاتصال، يرجى المحاولة لاحقاً'),
          );

      ref.read(wizardProgressProvider.notifier).clear();
      ref.invalidate(guardianDependentsProvider);

      if (mounted) {
        context.go('/guardian/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('عذراً، حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _currentStep == 1
              ? 'الخطوة ١: بيانات أساسية'
              : _currentStep == 2
              ? 'الخطوة ٢: المواصفات الشكلية'
              : 'الخطوة ٣: تفضيلات الخاطب',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            if (_currentStep > 1) {
              _saveProgress();
              setState(() => _currentStep--);
            } else {
              _saveProgress();
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(),
            const SizedBox(height: MithaqSpacing.m),
            if (_currentStep == 1)
              _buildStep1()
            else if (_currentStep == 2)
              _buildPhysicalStep()
            else
              _buildStep2(),
            const SizedBox(height: MithaqSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep < 3 ? 'التالي' : 'إتمام الإضافة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الخطوة $_currentStep من ٣',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              _currentStep == 1
                  ? '33%'
                  : _currentStep == 2
                  ? '66%'
                  : '100%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _currentStep / 3,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أخبرنا عن الشخص الذي ترغب بإضافة ملفه',
          style: TextStyle(
            color: Colors.grey,
            fontSize: MithaqTypography.bodyMedium,
          ),
        ),
        const SizedBox(height: MithaqSpacing.l),

        // Name
        const _InputLabel(label: 'الاسم'),
        _buildTextField(
          initialValue: _name,
          hint: 'أدخل اسم المستفيد',
          onChanged: (val) => _name = val,
        ),
        const SizedBox(height: MithaqSpacing.m),

        // Gender
        const _InputLabel(label: 'الجنس'),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                label: 'ذكر',
                isSelected: _gender == Gender.male,
                onTap: () => setState(() => _gender = Gender.male),
              ),
            ),
            const SizedBox(width: MithaqSpacing.s),
            Expanded(
              child: _ChoiceCard(
                label: 'أنثى',
                isSelected: _gender == Gender.female,
                onTap: () => setState(() => _gender = Gender.female),
              ),
            ),
          ],
        ),
        const SizedBox(height: MithaqSpacing.m),

        // Relationship
        const _InputLabel(label: 'صلة القرابة'),
        Wrap(
          spacing: 8,
          children: Relationship.values.map((r) {
            return ChoiceChip(
              label: Text(r.label),
              selected: _relationship == r,
              onSelected: (val) =>
                  setState(() => _relationship = val ? r : null),
              selectedColor: MithaqColors.mint,
              labelStyle: TextStyle(
                color: _relationship == r
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: _relationship == r
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: MithaqSpacing.m),

        // Date of Birth
        const _InputLabel(label: 'تاريخ الميلاد'),
        MithaqCard(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1960),
              lastDate: DateTime.now(),
              builder: (context, child) => child!,
            );
            if (date != null) setState(() => _dob = date);
          },
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: MithaqSpacing.m),
              Text(
                _dob == null
                    ? 'اختر التاريخ'
                    : '${_dob!.year}/${_dob!.month}/${_dob!.day}',
                style: TextStyle(
                  color: _dob == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: _dob == null
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MithaqSpacing.m),

        // City
        const _InputLabel(label: 'المدينة الحالية'),
        _buildTextField(
          initialValue: _city,
          hint: 'الدمام',
          onChanged: (val) => _city = val,
        ),
        const SizedBox(height: MithaqSpacing.m),

        // Marital Status
        const _InputLabel(label: 'الحالة الاجتماعية'),
        DropdownButtonFormField<MaritalStatus>(
          initialValue: _maritalStatus,
          hint: Text('مطلق/مطلقة', style: TextStyle(color: Colors.grey[400])),
          items: MaritalStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _maritalStatus = val),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: MithaqColors.navy.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: MithaqColors.navy.withValues(alpha: 0.2),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          dropdownColor: Colors.white,
        ),
        const SizedBox(height: MithaqSpacing.m),

        // Tribe (Optional)
        const _InputLabel(label: 'القبيلة (اختياري)'),
        _buildTextField(
          initialValue: _tribe ?? '',
          hint: 'عتيبه',
          onChanged: (val) => _tribe = val,
        ),
        const SizedBox(height: MithaqSpacing.m),

        // Job
        const _InputLabel(label: 'الوظيفة'),
        _buildTextField(
          initialValue: _job,
          hint: 'طبيب، مهندس، معلم...',
          onChanged: (val) => _job = val,
        ),
      ],
    );
  }

  Widget _buildPhysicalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تساعدنا هذه المواصفات في عرض الملفات الأكثر توافقاً',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: MithaqSpacing.l),

        // Skin Color
        const _InputLabel(label: 'لون البشرة'),
        const Text(
          'اختر الأقرب',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: SkinColor.values.map((color) {
            final isSelected = _skinColor == color;
            Color dotColor;
            switch (color) {
              case SkinColor.white:
                dotColor = const Color(0xFFFFE5D0);
                break;
              case SkinColor.wheat:
                dotColor = const Color(0xFFF3C99F);
                break;
              case SkinColor.brown:
                dotColor = const Color(0xFF8D5524);
                break;
              case SkinColor.dark:
                dotColor = const Color(0xFF3C2006);
                break;
            }
            return GestureDetector(
              onTap: () => setState(() => _skinColor = color),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: MithaqColors.mint, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: MithaqColors.mint.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: MithaqSpacing.xl),

        // Height
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _InputLabel(label: 'الطول (سم)'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: MithaqColors.mint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_height.toInt()} سم',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: MithaqColors.mint,
            inactiveTrackColor: Colors.grey[200],
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: MithaqColors.mint.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _height,
            min: 140,
            max: 210,
            onChanged: (val) => setState(() => _height = val),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '140',
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
            Text(
              '210',
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: MithaqSpacing.xl),

        // BuildType
        const _InputLabel(label: 'البنية'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: BuildType.values.map((type) {
            final isSelected = _buildType == type;
            return GestureDetector(
              onTap: () => setState(() => _buildType = type),
              child: Container(
                width: (MediaQuery.of(context).size.width - 64 - 12) / 2,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isSelected ? MithaqColors.mint : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? MithaqColors.mint
                        : MithaqColors.navy.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    type.label,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MithaqSoftIcon(
          icon: Icons.info_outline,
          padding: MithaqSpacing.m,
        ),
        const SizedBox(height: MithaqSpacing.m),
        Text(
          'هذه الخيارات تعبّر عن رغبة الخاطب وليست صفات شخصية للتابع.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MithaqSpacing.s),
        const Text(
          'يمكنك ترك هذه الخيارات الآن وإضافتها لاحقاً لتحسين نتائج التوافق.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: MithaqSpacing.l),

        // Smoking Preference
        const _InputLabel(label: 'حالة التدخين المفضلة'),
        Wrap(
          spacing: MithaqSpacing.s,
          children: SmokingHabit.values.map((h) {
            final isSelected = _smokingPreference == h;
            return ChoiceChip(
              label: Text(h.label),
              selected: isSelected,
              onSelected: (val) =>
                  setState(() => _smokingPreference = val ? h : null),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: MithaqSpacing.l),

        // Hijab Preference (Only for Male Dependents looking for wife)
        if (_gender != Gender.female) ...[
          const _InputLabel(label: 'نمط اللباس المفضل لدى الخاطب'),
          Wrap(
            spacing: MithaqSpacing.s,
            children: HijabPreference.values.map((p) {
              final isSelected = _hijabPreference == p;
              return ChoiceChip(
                label: Text(p.label),
                selected: isSelected,
                onSelected: (val) =>
                    setState(() => _hijabPreference = val ? p : null),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],

        if (_gender == Gender.female) ...[
          const SizedBox(height: MithaqSpacing.xl),
          const Divider(),
          const SizedBox(height: MithaqSpacing.l),
          Row(
            children: [
              const MithaqSoftIcon(
                icon: Icons.contact_phone_outlined,
                iconColor: MithaqColors.mint,
                padding: MithaqSpacing.s,
              ),
              const SizedBox(width: MithaqSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفعيل بطاقة الشوفة الشرعية',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'تسهل للخاطب الجاد طلب التواصل الرسمي معك',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _shufaCardActive,
                onChanged: (val) => setState(() => _shufaCardActive = val),
                activeColor: MithaqColors.mint,
              ),
            ],
          ),
          if (_shufaCardActive) ...[
            const SizedBox(height: MithaqSpacing.l),
            const _InputLabel(label: 'اسم ولي الأمر (للعرض في البطاقة)'),
            _buildTextField(
              initialValue: _shufaGuardianName,
              hint: 'الأستاذ محمد بن خالد ال سعود',
              onChanged: (val) => _shufaGuardianName = val,
            ),
            const SizedBox(height: MithaqSpacing.m),
            const _InputLabel(label: 'صلة القرابة'),
            _buildTextField(
              initialValue: _shufaGuardianTitle,
              hint: 'الأب، الأخ، العم...',
              onChanged: (val) => _shufaGuardianTitle = val,
            ),
            const SizedBox(height: MithaqSpacing.m),
            const _InputLabel(label: 'رقم جوال ولي الأمر للمواصل المباشر'),
            _buildTextField(
              initialValue: _shufaGuardianPhone,
              hint: '+966 50 123 4567',
              onChanged: (val) => _shufaGuardianPhone = val,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: MithaqColors.navy.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MithaqColors.mint, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: MithaqSpacing.s,
        top: MithaqSpacing.m,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
