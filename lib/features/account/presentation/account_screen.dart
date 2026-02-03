import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../avatar/presentation/widgets/privacy_avatar.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../seeker/data/profile_repository.dart';
import '../../seeker/domain/profile.dart';
import '../../chat/presentation/widgets/shufa_card_widget.dart';

/// My Account Screen - Full profile view with edit capabilities

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  // Partner preferences state
  RangeValues _ageRange = const RangeValues(22, 35);
  Set<MaritalStatus> _acceptedStatuses = {MaritalStatus.single};
  Set<EducationLevel> _preferredEducation = {};
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isInitialized = false;

  // Edit mode state
  bool _isEditingProfile = false;
  bool _isEditingAbout = false;
  bool _isEditingGuardian = false;
  bool _isEditingAppearance = false;

  // Appearance editing
  final TextEditingController _editHeightController = TextEditingController();
  String? _editSkinColor;
  String? _editBuildType;

  bool _processedAutoOpen = false;

  // Profile editing controllers
  final TextEditingController _editCityController = TextEditingController();
  final TextEditingController _editTribeController = TextEditingController();
  final TextEditingController _editJobController = TextEditingController();
  final TextEditingController _editBioController = TextEditingController();
  EducationLevel? _editEducationLevel;

  // Guardian info editing controllers
  final TextEditingController _editGuardianNameController =
      TextEditingController();
  final TextEditingController _editGuardianPhoneController =
      TextEditingController();
  final TextEditingController _editGuardianRelationshipController =
      TextEditingController();

  // Local override للبيانات المحدثة في Debug Mode
  SeekerProfile? _localProfileOverride;

  @override
  void dispose() {
    _cityController.dispose();
    _notesController.dispose();
    _editHeightController.dispose();
    _editCityController.dispose();
    _editTribeController.dispose();
    _editJobController.dispose();
    _editBioController.dispose();
    _editGuardianNameController.dispose();
    _editGuardianPhoneController.dispose();
    _editGuardianRelationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final profileAsync = ref.watch(myProfileProvider);

    // دالة مساعدة لتحديث الحالة المحلية
    void updateLocalState(SeekerProfile profile) {
      final prefs = profile.partnerPreferences;
      if (prefs != null) {
        setState(() {
          _ageRange = RangeValues(
            (prefs.minAge ?? 18).toDouble(),
            (prefs.maxAge ?? 60).toDouble(),
          );
          _acceptedStatuses =
              prefs.acceptedMaritalStatus ?? {MaritalStatus.single};
          _preferredEducation = prefs.preferredEducation ?? {};
          _cityController.text = prefs.preferredCities?.join(', ') ?? '';
          _notesController.text = prefs.notes ?? '';
          _isInitialized = true;
          // تحديث _localProfileOverride ليطابق الـ Global Provider
          _localProfileOverride = profile;
        });
      }
    }

    // الاستماع للتغييرات في Provider الأصلي
    ref.listen<AsyncValue<SeekerProfile?>>(myProfileProvider, (previous, next) {
      if (next.hasValue && next.value != null && !_isInitialized) {
        updateLocalState(next.value!);
      }
    });

    // Auto-open editing based on query params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_processedAutoOpen && mounted) {
        final state = GoRouterState.of(context);
        if (state.uri.queryParameters['action'] == 'edit_appearance') {
          final profile = ref.read(myProfileProvider).value;
          if (profile != null) {
            final displayProfile = profile;

            // Helper lists for validation
            const skinColors = ['بيضاء', 'حنطية', 'سمراء', 'داكنة'];
            const buildTypes = ['نحيف', 'متوسط', 'رياضي', 'ممتلئ'];

            setState(() {
              _editHeightController.text = (displayProfile.height ?? '')
                  .toString();

              _editSkinColor = displayProfile.skinColor;
              if (!skinColors.contains(_editSkinColor)) _editSkinColor = null;

              _editBuildType = displayProfile.build; // or buildType
              if (!buildTypes.contains(_editBuildType)) _editBuildType = null;

              _isEditingAppearance = true;
              _processedAutoOpen = true;
            });
          }
        }
      }
    });

    // تهيئة أولية إذا كان الـ Provider محمل مسبقاً
    if (!_isInitialized) {
      if (profileAsync.hasValue && profileAsync.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          updateLocalState(profileAsync.value!);
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(err.toString()),
        data: (profile) {
          if (profile == null) {
            return _buildMissingProfileState();
          }
          return _buildProfileView(profile, session);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: MithaqSpacing.m),
          const Text('حدث خطأ في تحميل بياناتك'),
          const SizedBox(height: MithaqSpacing.s),
          TextButton(
            onPressed: () => ref.invalidate(myProfileProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingProfileState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: MithaqSpacing.m),
          const Text('لم تكمل ملفك الشخصي بعد'),
          const SizedBox(height: MithaqSpacing.l),
          ElevatedButton(
            onPressed: () => context.push('/seeker/onboarding'),
            child: const Text('إكمال الملف الشخصي'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(SeekerProfile profile, AppSession session) {
    return CustomScrollView(
      slivers: [
        // Profile Header
        SliverToBoxAdapter(child: _buildProfileHeader(profile)),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(MithaqSpacing.m),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // AI Personality Analysis Banner
              _buildPersonalityAnalysisBanner(),
              const SizedBox(height: MithaqSpacing.m),

              // Subscription Banner
              _buildSubscriptionBanner(),
              const SizedBox(height: MithaqSpacing.xl),

              // Personal Info Section
              _buildSectionTitle('المعلومات الشخصية', Icons.person_outline),
              const SizedBox(height: MithaqSpacing.s),
              _buildPersonalInfoCard(profile),
              const SizedBox(height: MithaqSpacing.xl),

              // Appearance Info Section
              _buildAppearanceCard(profile),
              const SizedBox(height: MithaqSpacing.xl),

              if (profile.shufaCardActive) ...[
                _buildSectionTitle(
                  'بطاقة ولي الأمر',
                  Icons.verified_user_outlined,
                ),
                const SizedBox(height: MithaqSpacing.s),
                Consumer(
                  builder: (context, ref, child) {
                    final infoAsync = ref.watch(
                      guardianContactInfoProvider(profile.profileId),
                    );
                    return infoAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('خطأ في تحميل بيانات الولي'),
                      data: (info) => ShufaCardWidget(
                        guardianName: info?['shufa_card_guardian_name'] ?? '',
                        guardianTitle: info?['shufa_card_guardian_title'] ?? '',
                        contactPhone: info?['shufa_card_guardian_phone'] ?? '',
                        isVerified: profile.shufaCardIsVerified,
                      ),
                    );
                  },
                ),
                const SizedBox(height: MithaqSpacing.xl),
              ],

              // بطاقة معلومات الولي للإناث (فقط لصاحب الحساب)
              if (profile.gender == Gender.female) ...[
                _buildSectionTitle('معلومات ولي الأمر', Icons.family_restroom),
                const SizedBox(height: MithaqSpacing.s),

                // شرح سبب وجود البطاقة
                Container(
                  padding: const EdgeInsets.all(MithaqSpacing.m),
                  margin: const EdgeInsets.only(bottom: MithaqSpacing.m),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(MithaqRadius.m),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: MithaqSpacing.s),
                      Expanded(
                        child: Text(
                          'نحتاج بيانات ولي الأمر لضمان التواصل الشرعي والآمن بهدف الخطبة الرسمية. هذه المعلومات مخفية تماماً عن الآخرين وتستخدم فقط عند الحاجة للتواصل مع ولي أمرك.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildGuardianInfoCard(profile),
                const SizedBox(height: MithaqSpacing.xl),
              ],

              // About Section
              _buildSectionTitle('نبذة عني', Icons.article_outlined),
              const SizedBox(height: MithaqSpacing.s),
              _buildAboutCard(profile),
              const SizedBox(height: MithaqSpacing.xl),

              // Partner Preferences Section
              _buildSectionTitle(
                'رغباتي في شريك العمر',
                Icons.favorite_outline,
              ),
              const SizedBox(height: MithaqSpacing.s),
              _buildPartnerPreferencesCard(),
              const SizedBox(height: MithaqSpacing.xl),

              // Privacy Settings
              _buildSectionTitle('إعدادات الخصوصية', Icons.shield_outlined),
              const SizedBox(height: MithaqSpacing.s),
              _buildPrivacyCard(profile),
              const SizedBox(height: MithaqSpacing.xl),

              // Account Actions
              _buildSectionTitle('إجراءات الحساب', Icons.settings_outlined),
              const SizedBox(height: MithaqSpacing.s),
              _buildAccountActionsCard(session),
              const SizedBox(height: MithaqSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(SeekerProfile profile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MithaqColors.navy, Color(0xFF1A3A5C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(MithaqSpacing.xl),
          child: Column(
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'حسابي',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: MithaqTypography.titleLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isEditingProfile) ...[
                    // أزرار الحفظ والإلغاء في وضع التعديل
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'إلغاء',
                      onPressed: _cancelProfileEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'حفظ',
                      onPressed: _saveProfileChanges,
                    ),
                  ] else
                    // زر التعديل في الوضع العادي
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      onPressed: _showEditProfileSheet,
                    ),
                ],
              ),
              const SizedBox(height: MithaqSpacing.xl),

              // Avatar
              PrivacyAvatar(
                gender: profile.gender,
                size: 100,
                context: AvatarContext.detail,
                style: AvatarStyle.silhouette,
              ),
              const SizedBox(height: MithaqSpacing.m),

              // Name
              Text(
                profile.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: MithaqTypography.titleMedium,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MithaqSpacing.xs),

              // Location & Age
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white60,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile.city,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: MithaqSpacing.m),
                  Icon(
                    Icons.cake_outlined,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.age} سنة',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MithaqSpacing.m),

              // Profile ID Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MithaqSpacing.m,
                  vertical: MithaqSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(MithaqRadius.l),
                ),
                child: Text(
                  'معرف: ${profile.profilePublicId.isNotEmpty ? profile.profilePublicId : profile.profileId.substring(0, 8)}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalityAnalysisBanner() {
    return InkWell(
      onTap: () => context.push('/seeker/personality-test'),
      borderRadius: BorderRadius.circular(MithaqRadius.l),
      child: Container(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(MithaqRadius.l),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Brain icon with glow
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: MithaqSpacing.m),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تحليل الشخصية بالذكاء الاصطناعي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MithaqTypography.titleSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يساعدك على إيجاد شريكك بشكل أسرع',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Start button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MithaqSpacing.m,
                vertical: MithaqSpacing.s,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(MithaqRadius.m),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF667EEA),
                    size: 20,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ابدأ الآن',
                    style: TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: textColor, size: 20),
        const SizedBox(width: MithaqSpacing.s),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: MithaqTypography.titleSmall,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuardianInfoCard(SeekerProfile profile) {
    // استخدام البيانات المحدثة محلياً إذا كانت موجودة
    final displayProfile = _localProfileOverride ?? profile;

    return MithaqCard(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Column(
        children: [
          // ملاحظة: هذه المعلومات خاصة وغير مرئية للآخرين
          Container(
            padding: const EdgeInsets.all(MithaqSpacing.s),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MithaqRadius.s),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_off,
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: MithaqSpacing.xs),
                Expanded(
                  child: Text(
                    'هذه المعلومات مخفية عن الآخرين وتظهر لك فقط',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // زر التعديل/الحفظ
                IconButton(
                  icon: Icon(
                    _isEditingGuardian ? Icons.check : Icons.edit,
                    size: 18,
                    color: _isEditingGuardian ? Colors.green : Colors.blue,
                  ),
                  onPressed: () {
                    if (_isEditingGuardian) {
                      _saveGuardianChanges();
                    } else {
                      setState(() {
                        _editGuardianNameController.text =
                            displayProfile.shufaCardGuardianName ?? '';
                        _editGuardianPhoneController.text =
                            displayProfile.shufaCardGuardianPhone ?? '';
                        _editGuardianRelationshipController.text =
                            displayProfile.relationship ?? '';
                        _isEditingGuardian = true;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: MithaqSpacing.m),

          // عرض بيانات الولي المسجل (إذا كان المستخدم الحالي ولي الأمر)
          if (ref.read(sessionProvider).role == UserRole.guardian) ...[
            _infoRow(
              'ولي الأمر المسجل',
              (ref.read(sessionProvider).fullName ?? '').isEmpty
                  ? 'غير محدد'
                  : ref.read(sessionProvider).fullName!,
              Icons.admin_panel_settings_outlined,
            ),
            const Divider(height: MithaqSpacing.l),
            _infoRow(
              'سبب التواجد',
              'إدارة ملف ${displayProfile.name} ومتابعة الطلبات', // نص توضيحي
              Icons.info_outline,
            ),
            const Divider(height: MithaqSpacing.l),
          ],

          // اسم ولي الأمر - editable
          _isEditingGuardian
              ? TextField(
                  controller: _editGuardianNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم ولي الأمر',
                    border: OutlineInputBorder(),
                  ),
                )
              : _infoRow(
                  'اسم ولي الأمر',
                  displayProfile.shufaCardGuardianName ?? 'غير محدد',
                  Icons.person,
                ),

          const Divider(height: MithaqSpacing.l),

          // رقم الجوال - editable
          _isEditingGuardian
              ? TextField(
                  controller: _editGuardianPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    border: OutlineInputBorder(),
                  ),
                )
              : _infoRow(
                  'رقم الجوال',
                  displayProfile.shufaCardGuardianPhone ?? 'غير محدد',
                  Icons.phone,
                ),

          const Divider(height: MithaqSpacing.l),

          // العلاقة - editable
          _isEditingGuardian
              ? TextField(
                  controller: _editGuardianRelationshipController,
                  decoration: const InputDecoration(
                    labelText: 'العلاقة',
                    hintText: 'مثال: أب، أخ، عم',
                    border: OutlineInputBorder(),
                  ),
                )
              : _infoRow(
                  'العلاقة',
                  displayProfile.relationship ?? 'غير محدد',
                  Icons.family_restroom,
                ),
        ],
      ),
    );
  }

  void _saveGuardianChanges() async {
    final profile = _localProfileOverride ?? ref.read(myProfileProvider).value;
    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      shufaCardGuardianName: _editGuardianNameController.text.isEmpty
          ? null
          : _editGuardianNameController.text,
      shufaCardGuardianPhone: _editGuardianPhoneController.text.isEmpty
          ? null
          : _editGuardianPhoneController.text,
      relationship: _editGuardianRelationshipController.text.isEmpty
          ? null
          : _editGuardianRelationshipController.text,
    );

    try {
      await ref.read(profileRepositoryProvider).addProfile(updatedProfile);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
      }
      return;
    }

    setState(() {
      _isEditingGuardian = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حفظ بيانات ولي الأمر')),
      );
    }
  }

  Widget _buildPersonalInfoCard(SeekerProfile profile) {
    return MithaqCard(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Column(
        children: [
          _infoRow(
            'الحالة الاجتماعية',
            profile.maritalStatus.label,
            Icons.family_restroom,
          ),
          const Divider(height: MithaqSpacing.l),

          // المهنة - editable
          _isEditingProfile
              ? TextField(
                  controller: _editJobController,
                  decoration: const InputDecoration(
                    labelText: 'المهنة',
                    border: OutlineInputBorder(),
                  ),
                )
              : _infoRow('المهنة', profile.job, Icons.work_outline),

          const Divider(height: MithaqSpacing.l),

          // المستوى التعليمي - editable
          _isEditingProfile
              ? DropdownButtonFormField<EducationLevel>(
                  value: _editEducationLevel,
                  decoration: const InputDecoration(
                    labelText: 'المستوى التعليمي',
                    border: OutlineInputBorder(),
                  ),
                  items: EducationLevel.values
                      .map(
                        (level) => DropdownMenuItem(
                          value: level,
                          child: Text(level.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _editEducationLevel = value);
                  },
                )
              : _infoRow(
                  'المستوى التعليمي',
                  profile.educationLevel?.label ?? 'غير محدد',
                  Icons.school_outlined,
                ),

          const Divider(height: MithaqSpacing.l),

          // القبيلة - editable
          _isEditingProfile
              ? TextField(
                  controller: _editTribeController,
                  decoration: const InputDecoration(
                    labelText: 'القبيلة (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                )
              : (profile.tribe != null && profile.tribe!.isNotEmpty)
              ? _infoRow('القبيلة', profile.tribe!, Icons.groups_outlined)
              : const SizedBox.shrink(),

          if (!_isEditingProfile ||
              (profile.tribe != null && profile.tribe!.isNotEmpty))
            const Divider(height: MithaqSpacing.l),

          _infoRow(
            'الجنس',
            profile.gender == Gender.male ? 'ذكر' : 'أنثى',
            Icons.person_outline,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: primaryColor.withValues(alpha: 0.5), size: 20),
        const SizedBox(width: MithaqSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'غير محدد' : value,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceCard(SeekerProfile profile) {
    final displayProfile = _localProfileOverride ?? profile;

    // Helper map for translation if needed, simplified for now
    const skinColors = ['بيضاء', 'حنطية', 'سمراء', 'داكنة'];
    const buildTypes = ['نحيف', 'متوسط', 'رياضي', 'ممتلئ'];

    return MithaqCard(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // العنوان مع أيقونة
              Row(
                children: [
                  Icon(
                    Icons.accessibility,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: MithaqSpacing.s),
                  Text(
                    'المواصفات الشكلية',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: MithaqTypography.titleSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isEditingAppearance ? Icons.check : Icons.edit,
                  color: _isEditingAppearance ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  if (_isEditingAppearance) {
                    _saveAppearanceChanges();
                  } else {
                    setState(() {
                      _editHeightController.text = (displayProfile.height ?? '')
                          .toString();

                      // Match closest value or default
                      _editSkinColor = displayProfile.skinColor;
                      if (!skinColors.contains(_editSkinColor)) {
                        _editSkinColor = null;
                      }

                      _editBuildType = displayProfile.build;
                      if (!buildTypes.contains(_editBuildType)) {
                        _editBuildType = null;
                      }

                      _isEditingAppearance = true;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: MithaqSpacing.s),

          // الطول
          _isEditingAppearance
              ? TextField(
                  controller: _editHeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الطول (سم)',
                    border: OutlineInputBorder(),
                  ),
                )
              : _infoRow(
                  'الطول',
                  displayProfile.height != null
                      ? '${displayProfile.height} سم'
                      : 'غير محدد',
                  Icons.height,
                ),

          const Divider(height: MithaqSpacing.l),

          // لون البشرة
          _isEditingAppearance
              ? DropdownButtonFormField<String>(
                  value: _editSkinColor,
                  decoration: const InputDecoration(
                    labelText: 'لون البشرة',
                    border: OutlineInputBorder(),
                  ),
                  items: skinColors
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _editSkinColor = v),
                )
              : _infoRow(
                  'لون البشرة',
                  displayProfile.skinColor ?? 'غير محدد',
                  Icons.face,
                ),

          const Divider(height: MithaqSpacing.l),

          // بنية الجسم
          _isEditingAppearance
              ? DropdownButtonFormField<String>(
                  value: _editBuildType,
                  decoration: const InputDecoration(
                    labelText: 'بنية الجسم',
                    border: OutlineInputBorder(),
                  ),
                  items: buildTypes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _editBuildType = v),
                )
              : _infoRow(
                  'بنية الجسم',
                  displayProfile.build ?? 'غير محدد',
                  Icons.accessibility_new,
                ),
        ],
      ),
    );
  }

  void _saveAppearanceChanges() async {
    final profile = _localProfileOverride ?? ref.read(myProfileProvider).value;
    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      height: int.tryParse(_editHeightController.text),
      skinColor: _editSkinColor,
      build: _editBuildType,
    );

    try {
      await ref.read(profileRepositoryProvider).addProfile(updatedProfile);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
      }
      return;
    }

    setState(() {
      _isEditingAppearance = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حفظ المواصفات الشكلية')),
      );
    }
  }

  Widget _buildAboutCard(SeekerProfile profile) {
    final displayProfile = _localProfileOverride ?? profile;
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    return MithaqCard(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isEditingAbout
              ? TextField(
                  controller: _editBioController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'نبذة عني',
                    hintText: 'أخبرنا المزيد عن نفسك...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                )
              : Text(
                  (displayProfile.bio != null && displayProfile.bio!.isNotEmpty)
                      ? displayProfile.bio!
                      : 'لم يتم إضافة نبذة بعد. أخبر الآخرين عن شخصيتك وأفكارك...',
                  style: TextStyle(
                    color: primaryColor.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
          const SizedBox(height: MithaqSpacing.m),
          if (_isEditingAbout) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _cancelAboutEdit,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('إلغاء'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(width: MithaqSpacing.s),
                ElevatedButton.icon(
                  onPressed: _saveAboutChanges,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('حفظ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _showEditAboutSheet,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('تعديل النبذة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartnerPreferencesCard() {
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    return MithaqCard(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الفئة العمرية',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} سنة',
                style: const TextStyle(
                  color: MithaqColors.mint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 60,
            divisions: 42,
            activeColor: MithaqColors.mint,
            onChanged: (values) => setState(() => _ageRange = values),
          ),
          const Divider(height: MithaqSpacing.l),

          // Marital Status
          Text(
            'الحالة الاجتماعية المقبولة',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: MithaqSpacing.s),
          Wrap(
            spacing: MithaqSpacing.s,
            runSpacing: MithaqSpacing.s,
            children: MaritalStatus.values
                .where((s) => s != MaritalStatus.married)
                .map(
                  (status) => FilterChip(
                    label: Text(status.label),
                    selected: _acceptedStatuses.contains(status),
                    selectedColor: MithaqColors.mint.withValues(alpha: 0.2),
                    checkmarkColor: MithaqColors.mint,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _acceptedStatuses.add(status);
                        } else {
                          _acceptedStatuses.remove(status);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const Divider(height: MithaqSpacing.l),

          // Education
          Text(
            'المستوى التعليمي المفضل',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: MithaqSpacing.s),
          Wrap(
            spacing: MithaqSpacing.s,
            runSpacing: MithaqSpacing.s,
            children: EducationLevel.values
                .map(
                  (level) => FilterChip(
                    label: Text(level.label),
                    selected: _preferredEducation.contains(level),
                    selectedColor: MithaqColors.mint.withValues(alpha: 0.2),
                    checkmarkColor: MithaqColors.mint,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _preferredEducation.add(level);
                        } else {
                          _preferredEducation.remove(level);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const Divider(height: MithaqSpacing.l),

          // City
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'المدينة المفضلة',
              hintText: 'مثال: الرياض، جدة',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MithaqRadius.m),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: MithaqSpacing.m),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'ملاحظات إضافية',
              hintText: 'أي متطلبات أخرى...',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MithaqRadius.m),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: MithaqSpacing.m),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePartnerPreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: MithaqColors.mint,
                foregroundColor: Colors.white,
              ),
              child: const Text('حفظ الرغبات'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(SeekerProfile profile) {
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    return MithaqCard(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.visibility_outlined, color: primaryColor),
            title: const Text('إظهار الاسم'),
            subtitle: Text(_getVisibilityLabel(profile.nameVisibility)),
            trailing: const Icon(Icons.chevron_left),
            onTap: _showNameVisibilitySheet,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard(AppSession session) {
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    return MithaqCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              session.isPaused
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
              color: primaryColor,
            ),
            title: Text(
              session.isPaused ? 'إلغاء تجميد الحساب' : 'تجميد الحساب مؤقتاً',
            ),
            subtitle: Text(
              session.isPaused ? 'حسابك مخفي حالياً' : 'إخفاء ملفك من البحث',
            ),
            trailing: Switch(
              value: session.isPaused,
              activeTrackColor: MithaqColors.mint,
              onChanged: (val) => _togglePause(val),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'حذف الحساب نهائياً',
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_left, color: Colors.red),
            onTap: () => context.push('/seeker/account/delete'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.orange),
            title: const Text('تسجيل الخروج'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'خروج',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(sessionProvider.notifier).setAuthSignedOut();
                if (mounted) {
                  context.go('/');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'hidden':
        return 'مخفي';
      case 'first':
        return 'الاسم الأول فقط';
      case 'full_subscribers_only':
        return 'الاسم الكامل (للمشتركين)';
      default:
        return 'مخفي';
    }
  }

  void _showEditProfileSheet() {
    final profile = ref.read(myProfileProvider).value;
    if (profile == null) return;

    // Initialize controllers with current values
    _editCityController.text = profile.city;
    _editTribeController.text = profile.tribe ?? '';
    _editJobController.text = profile.job;
    _editEducationLevel = profile.educationLevel;

    setState(() {
      _isEditingProfile = true;
    });
  }

  void _saveProfileChanges() async {
    final profile = ref.read(myProfileProvider).value;
    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      city: _editCityController.text,
      tribe: _editTribeController.text.isEmpty
          ? null
          : _editTribeController.text,
      job: _editJobController.text,
      educationLevel: _editEducationLevel,
    );

    try {
      // الوضع العادي: حفظ على السيرفر
      await ref.read(profileRepositoryProvider).addProfile(updatedProfile);

      // تحديث الـ provider ليُظهر البيانات الجديدة
      ref.invalidate(myProfileProvider);

      setState(() {
        _isEditingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ التغييرات بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
      }
    }
  }

  void _cancelProfileEdit() {
    setState(() {
      _isEditingProfile = false;
    });
  }

  void _showEditAboutSheet() {
    final profile = _localProfileOverride ?? ref.read(myProfileProvider).value;
    if (profile == null) return;

    _editBioController.text = profile.bio ?? '';

    setState(() {
      _isEditingAbout = true;
    });
  }

  void _saveAboutChanges() async {
    final profile = _localProfileOverride ?? ref.read(myProfileProvider).value;
    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      bio: _editBioController.text.isEmpty ? null : _editBioController.text,
    );

    try {
      await ref.read(profileRepositoryProvider).addProfile(updatedProfile);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
      }
      return;
    }

    setState(() {
      _isEditingAbout = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تم حفظ النبذة')));
    }
  }

  void _cancelAboutEdit() {
    setState(() {
      _isEditingAbout = false;
    });
  }

  void _showNameVisibilitySheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إظهار الاسم',
              style: TextStyle(
                fontSize: MithaqTypography.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),
            ListTile(
              title: const Text('مخفي'),
              subtitle: const Text('لن يظهر اسمك لأي شخص'),
              leading: const Icon(Icons.visibility_off),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إخفاء الاسم ✓')),
                );
              },
            ),
            ListTile(
              title: const Text('الاسم الأول فقط'),
              subtitle: const Text('سيظهر اسمك الأول فقط'),
              leading: const Icon(Icons.person),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سيظهر الاسم الأول فقط ✓')),
                );
              },
            ),
            ListTile(
              title: const Text('الاسم الكامل (للمشتركين)'),
              subtitle: const Text('يظهر للمشتركين فقط'),
              leading: const Icon(Icons.badge),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيظهر الاسم الكامل للمشتركين ✓'),
                  ),
                );
              },
            ),
            const SizedBox(height: MithaqSpacing.l),
          ],
        ),
      ),
    );
  }

  Future<void> _savePartnerPreferences() async {
    final profile = _localProfileOverride ?? ref.read(myProfileProvider).value;
    if (profile == null) return;

    final updatedPrefs = PartnerPreferences(
      minAge: _ageRange.start.toInt(),
      maxAge: _ageRange.end.toInt(),
      acceptedMaritalStatus: _acceptedStatuses,
      preferredEducation: _preferredEducation,
      preferredCities: _cityController.text
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map((e) => e.trim())
          .toList(),
      notes: _notesController.text,
    );

    try {
      await ref
          .read(profileRepositoryProvider)
          .savePreferences(profile.profileId, updatedPrefs);
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ فشل الحفظ: $e')));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ رغباتك في شريك العمر'),
          backgroundColor: MithaqColors.mint,
        ),
      );
    }
  }

  void _togglePause(bool pause) async {
    await ref.read(sessionProvider.notifier).togglePaused();
  }

  Widget _buildSubscriptionBanner() {
    return GestureDetector(
      onTap: () => context.push('/subscription'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: MithaqSpacing.m,
          vertical: MithaqSpacing.m,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2B56), Color(0xFF2A3A63)],
          ),
          borderRadius: BorderRadius.circular(MithaqRadius.m),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2B56).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(MithaqSpacing.s),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: MithaqSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اشترك في باقات ميثاق',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'احصل على مميزات حصرية وزد فرصك',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
