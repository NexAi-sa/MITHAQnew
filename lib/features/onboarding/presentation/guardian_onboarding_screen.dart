import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/design_system.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../seeker/domain/profile.dart';
import '../../seeker/data/profile_repository.dart';

/// Premium Guardian Onboarding Screen
/// Calm, trustworthy experience for guardians
class GuardianOnboardingScreen extends ConsumerStatefulWidget {
  const GuardianOnboardingScreen({super.key});

  @override
  ConsumerState<GuardianOnboardingScreen> createState() =>
      _GuardianOnboardingScreenState();
}

class _GuardianOnboardingScreenState
    extends ConsumerState<GuardianOnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late final TextEditingController _nameController;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _dependentNameController =
      TextEditingController();
  bool _isCompleting = false;

  // Animation
  late AnimationController _stepController;
  late Animation<double> _stepFade;
  late Animation<Offset> _stepSlide;

  @override
  void initState() {
    super.initState();
    // Always start from step 0 for guardian onboarding
    _currentStep = 0;

    _nameController = TextEditingController(
      text: ref.read(sessionProvider).fullName,
    );
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

    _stepController.forward();
  }

  @override
  void dispose() {
    _stepController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _dependentNameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 1) {
      // Validate Step 1 (Guardian Info)
      if (_currentStep == 0) {
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى إدخال اسمك الكريم للمتابعة'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      _stepController.reset();
      setState(() => _currentStep++);
      _stepController.forward();
    } else {
      _complete();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _stepController.reset();
      setState(() => _currentStep--);
      _stepController.forward();
    }
  }

  Future<void> _complete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    final notifier = ref.read(sessionProvider.notifier);
    final session = ref.read(sessionProvider);

    try {
      // 1. Update Guardian Name in Session/DB
      if (_nameController.text.isNotEmpty && session.userId != null) {
        await notifier.setAuthSignedIn(
          session.userId!,
          name: _nameController.text,
        );
      }

      // 2. Create Initial Dependent Profile if name provided
      if (_dependentNameController.text.isNotEmpty && session.userId != null) {
        final repository = ref.read(profileRepositoryProvider);
        final newDependent = SeekerProfile(
          profileId: 'new',
          userId: session.userId!,
          name: _dependentNameController.text,
          city: _cityController.text.isNotEmpty
              ? _cityController.text
              : 'الرياض',
          gender: Gender.female, // Default, wizard will refine
          maritalStatus: MaritalStatus.single,
          job: '',
          isManagedByGuardian: true,
          guardianUserId: session.userId,
          profileOwnerRole: ProfileOwnerRole.seekerDependent,
          dob: DateTime(2000, 1, 1),
        );
        await repository.addProfile(newDependent);
        ref.invalidate(guardianDependentsProvider);
      }

      // 3. Mark Onboarding as Completed
      await notifier.setOnboardingStatus(OnboardingStatus.completed);
      await notifier.setProfileStatus(ProfileStatus.ready);

      // 4. Force session refresh to ensure router picks up changes
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await _showGratitudeDialog();
        if (mounted) {
          // Use pushReplacement to avoid back stack issues
          context.go('/guardian/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        title: Text(
          _getStepTitle(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress indicator
              _buildProgressBar(),

              const SizedBox(height: 32),

              // Step content with animation
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

              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'بيانات الولي';
      case 1:
        return 'إضافة المستفيد';
      default:
        return '';
    }
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
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
          'الخطوة ${_currentStep + 1} من 2',
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
                    _currentStep == 1 ? 'إتمام التسجيل ✨' : 'التالي',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      default:
        return const SizedBox();
    }
  }

  // Step 1: Guardian Info
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MithaqColors.mint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MithaqColors.mint.withValues(alpha: 0.35),
                  ),
                  child: const Center(
                    child: Text('🤝', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أهلاً بك كولي أمر',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نقدّر ثقتك ومسؤوليتك',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          if (true) ...[
            _buildSectionHeader(
              title: 'اسمك',
              subtitle: 'مطلوب - للتعريف عند التواصل',
              isOptional: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              hint: 'الاسم الكريم',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 24),

          _buildSectionHeader(
            title: 'مدينة الإقامة',
            subtitle: 'لعرض ملفات قريبة منكم',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cityController,
            hint: 'مثال: الرياض، جدة...',
            icon: Icons.location_city_rounded,
          ),

          const SizedBox(height: 16),
          _buildPrivacyHint('معلوماتك محفوظة ولن تظهر للآخرين'),
        ],
      ),
    );
  }

  // Step 2: Add Dependent
  Widget _buildStep2() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: isLight ? 0.1 : 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: isLight ? Colors.orange[700] : Colors.orange[300],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'أضف اسم الشخص الذي تمثّله (ابن/ابنة/أخ/أخت)',
                    style: TextStyle(
                      color: isLight ? Colors.orange[800] : Colors.orange[100],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _buildSectionHeader(
            title: 'اسم المستفيد',
            subtitle: 'الشخص الذي تبحث له عن شريك',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dependentNameController,
            hint: 'مثلاً: ابنتي نورة، ابني محمد...',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 24),

          // Reassurance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MithaqColors.mint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: MithaqColors.mint,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'يمكنك إضافة المزيد وتكملة البيانات لاحقاً من لوحة التحكم',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildPrivacyHint('ستظهر فقط المعلومات التي توافق على مشاركتها'),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    bool isOptional = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: isLight ? 0.15 : 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'اختياري',
                  style: TextStyle(
                    fontSize: 10,
                    color: isLight ? Colors.grey[700] : Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPrivacyHint(String text) {
    return Row(
      children: [
        Icon(Icons.shield_outlined, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

/// Gratitude Dialog for Guardian
class _GratitudeDialog extends StatefulWidget {
  final VoidCallback onContinue;

  const _GratitudeDialog({required this.onContinue});

  @override
  State<_GratitudeDialog> createState() => _GratitudeDialogState();
}

class _GratitudeDialogState extends State<_GratitudeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MithaqColors.mint.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: MithaqColors.mint,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'جزاك الله خيراً 💚',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'نقدّر مسؤوليتك وحرصك\nعلى من تحت ولايتك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ابدأ الآن'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
