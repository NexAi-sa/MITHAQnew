import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/integrations/backend/backend_exceptions.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../seeker/domain/profile.dart';
import '../../seeker/data/profile_repository.dart';
import '../../../core/ui/design_tokens.dart';

/// Premium Seeker Onboarding Screen
/// Calm, trustworthy, privacy-focused registration experience
class SeekerOnboardingScreen extends ConsumerStatefulWidget {
  const SeekerOnboardingScreen({super.key});

  @override
  ConsumerState<SeekerOnboardingScreen> createState() =>
      _SeekerOnboardingScreenState();
}

class _SeekerOnboardingScreenState extends ConsumerState<SeekerOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late int _currentStep;
  Gender? _gender; // Now nullable - user must select
  DateTime? _birthDate;
  late final TextEditingController _nameController;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _tribeController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  EducationLevel? _educationLevel;
  MaritalStatus? _maritalStatus;
  bool _isCompleting = false;

  // Step 4 data (Physical & Preferences)
  SkinColor? _skinColor;
  double _height = 165;
  BuildType? _buildType;

  // Animation
  late AnimationController _stepController;
  late Animation<double> _stepFade;
  late Animation<Offset> _stepSlide;

  List<MaritalStatus> get _maritalOptions {
    final options = [
      MaritalStatus.single,
      MaritalStatus.divorced,
      MaritalStatus.widowed,
    ];
    if (_gender == Gender.male) {
      options.add(MaritalStatus.polygamySeekingSecond);
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    _currentStep = session.onboardingStep;

    // Initialize gender from session if available
    if (session.gender != SessionGender.unknown) {
      _gender = session.gender == SessionGender.male
          ? Gender.male
          : Gender.female;
      print('ℹ️ Gender loaded from session: $_gender');
    }

    _stepController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _stepFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _stepController, curve: Curves.easeOut));

    _stepSlide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _stepController, curve: Curves.easeOutCubic),
        );

    _nameController = TextEditingController(text: session.fullName);

    _stepController.forward();
  }

  @override
  void dispose() {
    _stepController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _tribeController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  void _next() {
    // Validate step 1 - require gender selection
    print('🔍 Validation - Current gender: $_gender');
    if (_currentStep == 0 && _gender == null) {
      print('❌ Gender not selected!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الجنس'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    print('✅ Validation passed!');

    if (_currentStep < 3) {
      _stepController.reset();
      setState(() => _currentStep++);
      ref.read(sessionProvider.notifier).setOnboardingStep(_currentStep);
      _stepController.forward();
    } else {
      _complete(isFinished: true);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _stepController.reset();
      setState(() => _currentStep--);
      ref.read(sessionProvider.notifier).setOnboardingStep(_currentStep);
      _stepController.forward();
    }
  }

  // دالة الإكمال المحدثة بوضع المحاكاة لتجنب التعليق
  Future<void> _complete({bool isFinished = false}) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final session = ref.read(sessionProvider);
      final userId = session.userId;
      if (userId == null) {
        throw Exception('لم يتم العثور على معرف المستخدم');
      }

      final notifier = ref.read(sessionProvider.notifier);

      // 1. Build profile object
      final newProfile = SeekerProfile(
        profileId: 'PROF-$userId',
        userId: userId,
        name: _nameController.text,
        city: _cityController.text,
        maritalStatus: _maritalStatus ?? MaritalStatus.single,
        gender: _gender!,
        job: _jobController.text,
        isManagedByGuardian: false,
        dob: _birthDate ?? DateTime(2000, 1, 1),
        skinColor: _skinColor?.name,
        height: _height.toInt(),
        build: _buildType?.name,
      );

      // 2. CRITICAL: Save to server FIRST - no silent failure!
      // We MUST wait for actual server success before proceeding
      final savedProfile = await ref
          .read(profileRepositoryProvider)
          .addProfile(newProfile)
          .timeout(
            const Duration(
              seconds: 15,
            ), // Increased timeout for network reliability
            onTimeout: () {
              throw Exception(
                'انتهت مهلة الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى',
              );
            },
          );

      // 3. Only after successful save: Update local session state
      await notifier.setProfileData(
        profileId: savedProfile.profileId,
        gender: _gender == Gender.male
            ? SessionGender.male
            : SessionGender.female,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        tribe: _tribeController.text.isNotEmpty ? _tribeController.text : null,
        height: _height.toInt(),
        build: _buildType?.name,
        skinColor: _skinColor?.name,
      );

      if (_nameController.text.isNotEmpty) {
        await notifier.setAuthSignedIn(userId, name: _nameController.text);
      }

      // 4. Update onboarding status ONLY after successful save
      if (isFinished) {
        final isReady =
            _birthDate != null &&
            _cityController.text.isNotEmpty &&
            _educationLevel != null &&
            _maritalStatus != null &&
            _skinColor != null &&
            _buildType != null;

        await notifier.setOnboardingStatus(OnboardingStatus.completed);
        await notifier.setProfileStatus(
          isReady ? ProfileStatus.ready : ProfileStatus.draft,
        );
      } else {
        await notifier.setOnboardingStatus(OnboardingStatus.inProgress);
        await notifier.setProfileStatus(ProfileStatus.draft);
      }

      // 5. Invalidate providers to ensure fresh data
      ref.invalidate(myProfileProvider);
      ref.invalidate(discoveryProfilesProvider);

      // 6. Navigate only after everything succeeds
      if (mounted) {
        if (isFinished) {
          await _showGratitudeDialog();
          if (mounted) context.go('/seeker/home');
        } else {
          // Complete Later: Sign out for safety
          await notifier.setAuthSignedOut();
          if (mounted) context.go('/auth');
        }
      }
    } catch (e) {
      // Parse error and show clear Arabic message
      String errorMessage;

      if (e is BackendException) {
        // Use the exception's message directly (now properly formatted in Arabic)
        errorMessage = e.message;
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage =
            'انتهت مهلة الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى';
      } else {
        // Generic error
        errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
      }

      // Show clear error message to user so they can retry
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _complete(isFinished: isFinished),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _showGratitudeDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _GratitudeDialog(onContinue: () => Navigator.of(context).pop()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: _back,
              )
            : null,
        title: _buildStepIndicator(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildProgressBar(),
              const SizedBox(height: 32),
              Expanded(
                child: FadeTransition(
                  opacity: _stepFade,
                  child: SlideTransition(
                    position: _stepSlide,
                    child: _buildStep(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Text(
      _getStepTitle(),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'المعلومات الأساسية';
      case 1:
        return 'مكان الإقامة';
      case 2:
        return 'التفاصيل الإضافية';
      case 3:
        return 'المواصفات الشكلية';
      default:
        return '';
    }
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isActive = index <= _currentStep;
            final isCurrent = index == _currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? MithaqColors.mint
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'الخطوة ${_currentStep + 1} من 4',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isCompleting ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isCompleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _currentStep == 3 ? 'إتمام التسجيل ✨' : 'التالي',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (_currentStep < 3)
          TextButton(
            onPressed: () => _complete(isFinished: false),
            child: Text(
              'أكمل لاحقاً',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'الاسم الكريم',
            subtitle: 'الاسم الذي سيُعرف به ملفك',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            hint: 'اسمك الثلاثي أو اللقب',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'الجنس',
            subtitle: 'لعرض الملفات المناسبة لك',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  icon: Icons.male_rounded,
                  label: 'ذكر',
                  isSelected: _gender == Gender.male,
                  onTap: () {
                    print('🔵 Male button tapped!');
                    setState(() {
                      _gender = Gender.male;
                      print('✅ Gender updated to: $_gender');
                    });
                    ref
                        .read(sessionProvider.notifier)
                        .setGender(SessionGender.male);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderCard(
                  icon: Icons.female_rounded,
                  label: 'أنثى',
                  isSelected: _gender == Gender.female,
                  onTap: () {
                    print('🟣 Female button tapped!');
                    setState(() {
                      _gender = Gender.female;
                      print('✅ Gender updated to: $_gender');
                    });
                    ref
                        .read(sessionProvider.notifier)
                        .setGender(SessionGender.female);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
            title: 'تاريخ الميلاد',
            subtitle: 'لحساب العمر بدقة',
          ),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 12),
          _buildPrivacyHint('لن يظهر تاريخ ميلادك، فقط عمرك'),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'مدينة الإقامة',
            subtitle: 'للتوصية بملفات قريبة منك',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cityController,
            hint: 'مثال: الرياض، جدة، الدمام...',
            icon: Icons.location_city_rounded,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
            title: 'القبيلة',
            subtitle: 'اختياري - يمكنك تخطيه',
            isOptional: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _tribeController,
            hint: 'اسم القبيلة (اختياري)',
            icon: Icons.people_outline_rounded,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
            title: 'المهنة / العمل',
            subtitle: 'يساعد الآخرين في فهم طبيعة حياتك',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _jobController,
            hint: 'مثال: مهندس، معلم، رائد أعمال...',
            icon: Icons.work_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: 'المستوى التعليمي', subtitle: null),
          const SizedBox(height: 16),
          _buildChipSelector<EducationLevel>(
            options: EducationLevel.values,
            selected: _educationLevel,
            labelBuilder: (e) => e.label,
            onSelected: (e) => setState(() => _educationLevel = e),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(title: 'الحالة الاجتماعية', subtitle: null),
          const SizedBox(height: 16),
          _buildChipSelector<MaritalStatus>(
            options: _maritalOptions,
            selected: _maritalStatus,
            labelBuilder: (s) => s.label,
            onSelected: (s) => setState(() => _maritalStatus = s),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'المواصفات الشكلية',
            subtitle: 'تساعدنا في تحسين نتائج المطابقة',
          ),
          const SizedBox(height: 24),
          Text(
            'لون البشرة',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
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
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('🎨 Skin color tapped: ${color.name}');
                  setState(() => _skinColor = color);
                  // ⚠️ لا نحفظ في الـ session الآن! فقط local state
                  // سنحفظ كل شيء عند الإتمام النهائي
                  print('✅ Skin color updated to: ${color.name}');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 60 : 50,
                  height: isSelected ? 60 : 50,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: MithaqColors.mint, width: 4)
                        : Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 2,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: MithaqColors.mint.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الطول (سم)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
          Slider(
            value: _height,
            min: 140,
            max: 210,
            onChanged: (val) {
              setState(() => _height = val);
              // ⚠️ لا نحفظ في الـ session الآن! سنحفظ عند الإتمام
            },
          ),
          const SizedBox(height: 32),
          Text(
            'البنية',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: BuildType.values.map((type) {
              final isSelected = _buildType == type;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  print('💪 Build type tapped: ${type.name}');
                  setState(() => _buildType = type);
                  // ⚠️ لا نحفظ في الـ session الآن! سنحفظ عند الإتمام
                  print('✅ Build type updated to: ${type.name}');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MithaqColors.mint
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(MithaqRadius.m),
                    border: Border.all(
                      color: isSelected
                          ? MithaqColors.mint
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      Text(
                        type.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // المساعدات البرمجية (Widgets)
  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (isOptional) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'اختياري',
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
      ],
    );
  }

  Widget _buildGenderCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? MithaqColors.mint.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.08),
            border: Border.all(
              color: isSelected
                  ? MithaqColors.mint
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? MithaqColors.mint : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1960),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _birthDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _birthDate != null
                ? MithaqColors.mint
                : Colors.grey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded),
            const SizedBox(width: 12),
            Text(
              _birthDate == null
                  ? 'اختر تاريخ الميلاد'
                  : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildChipSelector<T>({
    required List<T> options,
    required T? selected,
    required String Function(T) labelBuilder,
    required void Function(T) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? MithaqColors.mint.withValues(alpha: 0.25)
                  : Colors.grey.withValues(alpha: 0.12),
            ),
            child: Text(labelBuilder(option)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyHint(String text) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 14),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _GratitudeDialog extends StatefulWidget {
  final VoidCallback onContinue;
  const _GratitudeDialog({required this.onContinue});
  @override
  State<_GratitudeDialog> createState() => _GratitudeDialogState();
}

class _GratitudeDialogState extends State<_GratitudeDialog>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: MithaqColors.mint),
            const SizedBox(height: 24),
            const Text(
              'شكراً لانضمامك! 💚',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'نسأل الله أن ييسّر لك النصف الآخر الصالح',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onContinue,
              child: const Text('ابدأ الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
