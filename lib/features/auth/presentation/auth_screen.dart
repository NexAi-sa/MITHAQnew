import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/integrations/backend/backend_providers.dart';
import '../../../core/integrations/backend/backend_exceptions.dart' as be;
import '../../seeker/data/profile_repository.dart';
import '../../seeker/domain/profile.dart';
import '../../avatar/domain/avatar_config.dart';

/// Premium Authentication Screen
/// Handles Login and Signup with Email, Phone, Password, and Name
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _agreedToEula = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isLogin && !_agreedToEula) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى الموافقة على اتفاقية الاستخدام (EULA) للمتابعة',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final backend = ref.read(backendClientProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      try {
        AppSession result;
        if (_isLogin) {
          result = await backend.signIn(email, password);
        } else {
          result = await backend.signUp(email, password, phoneNumber: phone);
        }

        if (result.userId != null) {
          final notifier = ref.read(sessionProvider.notifier);
          final userId = result.userId!;

          // 1. Set basic auth state
          await notifier.setAuthSignedIn(
            userId,
            name: !_isLogin ? name : null,
            email: email,
            phoneNumber: phone,
          );

          // 2. If Login: Check for existing profiles and additional data to restore session
          if (_isLogin) {
            final repo = ref.read(profileRepositoryProvider);
            final profiles = await repo.getProfilesByUserId(userId);

            if (profiles.isNotEmpty) {
              // Priority 1: Check if user is a Seeker (has a self-owned profile)
              SeekerProfile? selfProfile;
              for (final p in profiles) {
                if (p.userId == userId &&
                    p.profileOwnerRole == ProfileOwnerRole.seekerSelf) {
                  selfProfile = p;
                  break;
                }
              }

              if (selfProfile != null) {
                // Restore Seeker session
                await notifier.setRole(UserRole.seeker);
                await notifier.setProfileData(
                  profileId: selfProfile.profileId,
                  city: selfProfile.city,
                  tribe: selfProfile.tribe,
                  gender: selfProfile.gender == Gender.male
                      ? SessionGender.male
                      : SessionGender.female,
                );
              } else {
                // Must be a Guardian since we have profiles but no self-seeker profile
                bool isGuardian = false;
                for (final p in profiles) {
                  if (p.guardianUserId == userId || p.userId != userId) {
                    isGuardian = true;
                    break;
                  }
                }

                if (isGuardian) {
                  await notifier.setRole(UserRole.guardian);
                } else if (profiles.length == 1 &&
                    profiles.first.userId == userId) {
                  // Actually a seeker but maybe role_context was mislabeled
                  await notifier.setRole(UserRole.seeker);
                }
              }

              await notifier.setOnboardingStatus(OnboardingStatus.completed);
              await notifier.setProfileStatus(ProfileStatus.ready);

              if (mounted) {
                final currentRole = ref.read(sessionProvider).role;
                context.go(
                  currentRole == UserRole.seeker
                      ? '/seeker/home'
                      : '/guardian/home',
                );
              }
              return;
            }

            // Check if user has already started onboarding but has no profile yet
            // This is stored in user_metadata or private tables in a real app
            // For now, if we have a fullName or other data in session, respect it
          }

          // 3. New User or Login with no profile -> Go to Role Selection
          if (!_isLogin) {
            await notifier.setProfileStatus(ProfileStatus.draft);
            if (mounted) context.go('/role-selection');
          } else {
            // Existing user but no profile? Let's double check if they have a role set
            final role = ref.read(sessionProvider).role;
            if (role != UserRole.none) {
              if (mounted) {
                context.go(
                  role == UserRole.seeker ? '/seeker/home' : '/guardian/home',
                );
              }
            } else {
              if (mounted) context.go('/role-selection');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          // Extract and localize error message
          String errorMessage;
          if (e is be.BackendException) {
            final rawMessage = e.message.toLowerCase();

            // Handle common Supabase errors with user-friendly messages
            if (rawMessage.contains('rate limit') ||
                rawMessage.contains('over_email')) {
              errorMessage =
                  'تم تجاوز حد المحاولات. يرجى الانتظار بضع دقائق والمحاولة مرة أخرى';
            } else if (rawMessage.contains('already registered') ||
                rawMessage.contains('already exists')) {
              errorMessage =
                  'البريد الإلكتروني مسجل مسبقاً. جرب تسجيل الدخول بدلاً من ذلك';
            } else if (rawMessage.contains('invalid email')) {
              errorMessage = 'صيغة البريد الإلكتروني غير صحيحة';
            } else if (rawMessage.contains('weak password') ||
                rawMessage.contains('password')) {
              errorMessage = 'كلمة المرور ضعيفة. يجب أن تكون 6 أحرف على الأقل';
            } else if (rawMessage.contains('invalid login') ||
                rawMessage.contains('invalid credentials')) {
              errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
            } else if (rawMessage.contains('network')) {
              errorMessage =
                  'خطأ في الاتصال بالإنترنت. تأكد من اتصالك وحاول مرة أخرى';
            } else {
              errorMessage = e.message;
            }
          } else {
            errorMessage = 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Logo & Intro
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Auth Type Toggle (Subtle Tabs)
                    _buildAuthModeToggle(),

                    const SizedBox(height: 32),

                    // Input Fields
                    _buildLabel('البريد الإلكتروني'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'example@mail.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'يرجى إدخال البريد' : null,
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('رقم الجوال'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: '5xxxxxxxx',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      prefixText: '+966 ',
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'يرجى إدخال الرقم' : null,
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('كلمة المرور'),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '********',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (value) =>
                          (value?.length ?? 0) < 6 ? 'كلمة المرور ضعيفة' : null,
                    ),

                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text(
                            'نسيت كلمة المرور؟',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreedToEula,
                              onChanged: (v) =>
                                  setState(() => _agreedToEula = v ?? false),
                              activeColor: MithaqColors.mint,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _agreedToEula = !_agreedToEula,
                              ),
                              child: const Text(
                                'أوافق على اتفاقية الاستخدام (EULA) وأتعهد بعدم نشر أي محتوى مسيء.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Main Action Button
                    _buildSubmitButton(),

                    const SizedBox(height: 24),

                    // Footer Switch
                    _buildFooterToggle(),

                    const SizedBox(height: 40),

                    // Trust indicator
                    _buildTrustIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MithaqColors.mint.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.handshake_rounded,
            color: MithaqColors.mint,
            size: 28,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'مرحباً بعودتكم' : 'انضم إلينا في ميثاق',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'سجل دخولك لمتابعة رحلة البحث عن المودة'
              : 'ابدأ رحلتك نحو الاستقرار وتكوين أسرة صالحة',
          style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAuthModeToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleTab(
              title: 'تسجيل دخول',
              isSelected: _isLogin,
              onTap: () {
                if (!_isLogin) _toggleAuthMode();
              },
            ),
          ),
          Expanded(
            child: _buildToggleTab(
              title: 'حساب جديد',
              isSelected: !_isLogin,
              onTap: () {
                if (_isLogin) _toggleAuthMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          size: 22,
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.03),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _isLogin ? 'دخول' : 'إنشاء الحساب',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFooterToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'ليس لديك حساب؟ ' : 'لديك حساب بالفعل؟ ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        GestureDetector(
          onTap: _toggleAuthMode,
          child: const Text(
            'اضغط هنا',
            style: TextStyle(
              color: MithaqColors.mint,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          'تشفير بياناتك بخصوصية تامة',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
