import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_emoji_hint.dart';
import '../../../core/ui/components/mithaq_soft_icon.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../../avatar/presentation/widgets/privacy_avatar.dart';
import '../domain/profile.dart';
import '../data/profile_repository.dart'; // Contains guardianContactInfoProvider
import '../../compatibility/data/compatibility_engine.dart';
import '../../compatibility/presentation/compatibility_indicators_card.dart';
import '../../compatibility/presentation/compatibility_explainer_sheet.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../chat/data/chat_repository.dart'
    hide
        guardianContactInfoProvider,
        shufaCardUnlockedProvider; // Hide duplicates
import '../../chat/domain/chat_models.dart';
import '../../advisor/presentation/advisor_entry_card.dart';
import '../../chat/presentation/widgets/shufa_card_widget.dart';

// IAP Imports
import '../../subscription/data/subscription_service.dart';
import '../../subscription/domain/product_ids.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  final String profileId;
  const ProfileDetailsScreen({super.key, required this.profileId});

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(singleProfileProvider(widget.profileId));
    final session = ref.watch(sessionProvider);
    final chatSessionAsync = ref.watch(chatSessionProvider(widget.profileId));

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('الملف غير موجود')));
        }

        // Debug logging
        debugPrint(
          '📋 Profile loaded: ${profile.name}, age: ${profile.age}, city: ${profile.city}',
        );
        debugPrint(
          '📋 Profile ID: ${profile.profileId}, User ID: ${profile.userId}',
        );
        debugPrint(
          '📋 Session User ID: ${session.userId}, Profile Status: ${session.profileStatus}',
        );

        final profileStatus = session.profileStatus;

        if (profileStatus == ProfileStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Only show onboarding prompt if viewing own profile and it's missing
        // Allow viewing other profiles regardless of own profile status
        final isViewingOwnProfile = profile.userId == session.userId;
        if (profileStatus == ProfileStatus.missing && isViewingOwnProfile) {
          return _buildOnboardingPrompt(context);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, profile),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(MithaqSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileInfo(profileStatus, profile),
                      const SizedBox(height: MithaqSpacing.xl),
                      if (profile.userId != session.userId) ...[
                        _buildCompatibilitySection(profile),
                        const SizedBox(height: MithaqSpacing.xl),
                        MithaqEmojiHint(
                          emoji: '🛡️',
                          text: profile.isManagedByGuardian
                              ? 'هذا الحساب بإدارة ولي الأمر. يتم التواصل الأول دائماً عبر الولي حفاظاً على الخصوصية والجدية.'
                              : 'بروتوكول التواصل المرحلي يهدف إلى الوضوح، وليس إلى التقييد.',
                        ),
                      ],
                      if (profile.shufaCardActive) ...[
                        const SizedBox(height: MithaqSpacing.l),
                        _buildShufaSection(context, ref, session, profile),
                      ],
                      if (profile.userId != session.userId) ...[
                        const SizedBox(height: MithaqSpacing.l),
                        AdvisorProfileButton(profileId: profile.profileId),
                        const SizedBox(height: MithaqSpacing.l),
                        _buildSafetyActions(context, profile),
                      ],
                      const SizedBox(height: MithaqSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: chatSessionAsync.when(
            data: (chatSession) =>
                _buildBottomBar(context, profile, chatSession),
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _buildBottomBar(context, profile, null),
          ),
        );
      },
    );
  }

  Widget _buildOnboardingPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MithaqSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: Theme.of(context).brightness == Brightness.light
                    ? MithaqColors.navy
                    : MithaqColors.textPrimaryDark,
              ),
              const SizedBox(height: MithaqSpacing.m),
              Text(
                'أبهرهم بحضورك!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: MithaqSpacing.s),
              const Text(
                'إنشاء ملفك الشخصي يساعدنا في إيجاد الشريك الأكثر توافقاً معك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: MithaqSpacing.l),
              ElevatedButton(
                onPressed: () => context.push('/seeker/onboarding'),
                child: const Text('بدء رحلة التوافق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, SeekerProfile profile) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MithaqIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: PrivacyAvatar(
              photoUrl: null, // Will use abstract gradient
              gender: profile.gender,
              size: 160,
              context: AvatarContext.detail,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(ProfileStatus profileStatus, SeekerProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profileStatus == ProfileStatus.draft) _buildDraftBanner(),
        _buildProfileHeader(profile),
        const SizedBox(height: MithaqSpacing.xl),
        Text(
          profile.gender == Gender.male ? 'عن السيد' : 'عن الآنسة',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: MithaqTypography.titleSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MithaqSpacing.m),
        _buildAboutCard(profile),
      ],
    );
  }

  Widget _buildDraftBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: MithaqSpacing.l),
      padding: const EdgeInsets.all(MithaqSpacing.m),
      decoration: BoxDecoration(
        color: MithaqColors.mint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MithaqRadius.s),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: MithaqColors.navy),
          const SizedBox(width: 12),
          const Expanded(child: Text('هذا الملف غير مكتمل (مسودة).')),
          TextButton(onPressed: () {}, child: const Text('أكمل')),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(SeekerProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.name,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? MithaqColors.navy
                    : MithaqColors.textPrimaryDark,
                fontSize: MithaqTypography.displaySmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (profile.isManagedByGuardian) _buildGuardianTag(),
            Text(
              '${profile.age != null ? "${profile.age} سنة" : "العمر غير محدد"} • ${profile.city}',
              style: TextStyle(
                color:
                    (Theme.of(context).brightness == Brightness.light
                            ? MithaqColors.navy
                            : MithaqColors.textPrimaryDark)
                        .withValues(alpha: 0.6),
                fontSize: MithaqTypography.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            // Profile ID Badge with Copy
            GestureDetector(
              onTap: () {
                final id = profile.profilePublicId.isNotEmpty
                    ? profile.profilePublicId
                    : profile.profileId.substring(0, 8);
                Clipboard.setData(ClipboardData(text: id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ معرف المستخدم'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: MithaqColors.navy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MithaqColors.navy.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'المعرف: ${profile.profilePublicId.isNotEmpty ? profile.profilePublicId : profile.profileId.substring(0, 8)}',
                      style: const TextStyle(
                        color: MithaqColors.navy,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.copy_rounded,
                      size: 12,
                      color: MithaqColors.navy,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const MithaqSoftIcon(
          icon: Icons.verified,
          iconColor: MithaqColors.mint,
          backgroundColor: Colors.transparent,
          size: MithaqIconSize.l,
        ),
      ],
    );
  }

  Widget _buildGuardianTag() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: MithaqColors.navy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'بإدارة ولي الأمر',
        style: TextStyle(
          color: MithaqColors.navy,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAboutCard(SeekerProfile profile) {
    return MithaqCard(
      child: Column(
        children: [
          _infoTile(Icons.work_outline, 'المهنة', profile.job),
          const Divider(),
          _infoTile(
            Icons.group_outlined,
            'القبيلة',
            (profile.tribe?.isEmpty ?? true) ? 'غير مذكور' : profile.tribe!,
          ),
          const Divider(),
          _infoTile(
            Icons.school_outlined,
            'التعليم',
            profile.educationLevel?.label ?? 'غير مكتمل',
          ),
          const Divider(),
          _infoTile(
            Icons.favorite_outline,
            'الحالة الاجتماعية',
            profile.maritalStatus.label,
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilitySection(SeekerProfile profile) {
    return Consumer(
      builder: (context, ref, child) {
        final compatAsync = ref.watch(
          compatibilityResultProvider(profile.profileId),
        );
        return compatAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
          data: (compatResult) => CompatibilityIndicatorsCard(
            result: compatResult,
            onExplainTap: () =>
                _showCompatibilityExplainer(context, compatResult),
          ),
        );
      },
    );
  }

  void _showCompatibilityExplainer(BuildContext context, dynamic result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompatibilityExplainerSheet(result: result),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    SeekerProfile profile,
    ChatSession? chatSession,
  ) {
    final session = ref.watch(sessionProvider);
    final isMyProfile = profile.userId == session.userId;

    if (isMyProfile) {
      return Container(
        padding: const EdgeInsets.all(MithaqSpacing.m),
        child: ElevatedButton(
          onPressed: () => context.push(
            session.role == UserRole.seeker
                ? '/seeker/account'
                : '/guardian/dashboard',
          ), // Placeholder for edit
          style: ElevatedButton.styleFrom(
            backgroundColor: MithaqColors.mint,
            foregroundColor: MithaqColors.navy,
            padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
          ),
          child: const Text('تعديل الملف الشخصي'),
        ),
      );
    }

    String label = profile.isManagedByGuardian
        ? 'طلب تواصل مع الولي'
        : 'طلب تواصل';
    bool isDisabled = false;
    String? subtext;

    if (chatSession != null) {
      if (chatSession.stage == ChatStage.requestSent) {
        label = 'طلب تواصل مسبق';
        isDisabled = true;
      } else {
        label = 'فتح المحادثة';
      }
    } else {
      subtext =
          'سيتم إرسال طلبك، وعند الموافقة يبدأ التواصل وفق بروتوكول التواصل المرحلي.';
    }

    return Container(
      padding: const EdgeInsets.all(MithaqSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtext != null)
            Padding(
              padding: const EdgeInsets.only(bottom: MithaqSpacing.s),
              child: Text(
                subtext,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDisabled
                  ? null
                  : () => chatSession != null
                        ? context.push('/chat/${profile.profileId}')
                        : _handleContactRequest(context, profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
                shape: RoundedRectangleBorder(
                  borderRadius: MithaqRadius.medium,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: MithaqTypography.bodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleContactRequest(
    BuildContext context,
    SeekerProfile profile,
  ) async {
    final currentUserSession = ref.read(sessionProvider);
    // Use profileId for seekers (not userId!) or activeDependentId for guardians
    final activeId = currentUserSession.role == UserRole.seeker
        ? currentUserSession.profileId
        : currentUserSession.activeDependentId;

    debugPrint('🔗 Contact Request - Role: ${currentUserSession.role}');
    debugPrint('🔗 Contact Request - userId: ${currentUserSession.userId}');
    debugPrint(
      '🔗 Contact Request - profileId: ${currentUserSession.profileId}',
    );
    debugPrint('🔗 Contact Request - activeId (used): $activeId');

    if (activeId == null) {
      debugPrint('🔗 ❌ activeId is null! Cannot create chat session.');
      return;
    }

    // Contact Paywall: Check subscription
    if (!currentUserSession.hasActiveSubscription) {
      final pay = await showModalBottomSheet<bool>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(MithaqSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تواصل جاد وآمن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: MithaqSpacing.l),
              const Text(
                'إرسال طلبات التواصل متاح لمشتركي الباقة الأساسية بلس لضمان الجدية والستر في البحث.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MithaqSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('استعراض الباقات'),
                ),
              ),
            ],
          ),
        ),
      );
      if (pay != true) return;
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(MithaqSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الخطوة التالية',
                style: TextStyle(
                  fontSize: MithaqTypography.titleSmall,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: MithaqSpacing.m),
              const Text(
                'سيتم إرسال طلبك، وعند الموافقة يبدأ التواصل وفق بروتوكول التواصل المرحلي.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MithaqSpacing.s),
              const Text(
                'يمكنك التراجع في أي وقت.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: MithaqSpacing.l),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(chatRepositoryProvider)
                      .createSession(activeId, profile.profileId);
                  ref.invalidate(chatSessionProvider(profile.profileId));
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.push('/chat/${profile.profileId}');
                  }
                },
                child: const Text('متابعة'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSafetyActions(BuildContext context, SeekerProfile profile) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: MithaqSpacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _safetyActionButton(
              icon: Icons.report_problem_outlined,
              label: 'إبلاغ',
              onTap: () => _showReportSheet(context, profile),
            ),
            const SizedBox(width: MithaqSpacing.l),
            _safetyActionButton(
              icon: Icons.block,
              label: 'حجب',
              onTap: () => _showBlockConfirmation(context, profile),
            ),
          ],
        ),
      ],
    );
  }

  Widget _safetyActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context, SeekerProfile profile) {}

  void _showBlockConfirmation(BuildContext context, SeekerProfile profile) {}

  Widget _buildShufaSection(
    BuildContext context,
    WidgetRef ref,
    AppSession session,
    SeekerProfile profile,
  ) {
    final activeId = session.role == UserRole.seeker
        ? session.userId
        : session.activeDependentId;

    if (activeId == null || profile.userId == session.userId) {
      return ShufaCardWidget(
        guardianName: profile.shufaCardGuardianName ?? '',
        guardianTitle: profile.shufaCardGuardianTitle ?? '',
        contactPhone: profile.shufaCardGuardianPhone ?? '',
        isVerified: profile.shufaCardIsVerified,
      );
    }

    final unlockAsync = ref.watch(
      shufaCardUnlockedProvider((activeId, profile.profileId)),
    );

    return unlockAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (isUnlocked) {
        if (isUnlocked) {
          final privateInfoAsync = ref.watch(
            guardianContactInfoProvider(profile.profileId),
          );

          return privateInfoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('خطأ في تحميل البيانات'),
            data: (info) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: ShufaCardWidget(
                guardianName: info?['shufa_card_guardian_name'] ?? '',
                guardianTitle: info?['shufa_card_guardian_title'] ?? '',
                contactPhone: info?['shufa_card_guardian_phone'] ?? '',
                isVerified: profile.shufaCardIsVerified,
              ),
            ),
          );
        }

        return MithaqCard(
          color: MithaqColors.mint.withValues(alpha: 0.05),
          border: Border.all(color: MithaqColors.mint.withValues(alpha: 0.3)),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline, color: MithaqColors.mint, size: 20),
                  SizedBox(width: MithaqSpacing.s),
                  Text(
                    'بطاقة الشوفة الشرعية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: MithaqColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MithaqSpacing.m),
              const Text(
                'بإمكانك طلب معلومات التواصل مع الولي رسمياً بعد التأكد من الجدية والتوافق الأولي.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: MithaqSpacing.m),
              ElevatedButton.icon(
                onPressed: () => _handleShufaRequest(
                  context,
                  ref,
                  activeId,
                  profile.profileId,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('طلب معلومات الولي (رسمي)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.mint,
                  foregroundColor: MithaqColors.navy,
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleShufaRequest(
    BuildContext context,
    WidgetRef ref,
    String activeId,
    String targetId,
  ) async {
    // 1. Fetch Product Logic
    final subService = ref.read(subscriptionServiceProvider);

    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final product = await subService.getProduct(MithaqProductIds.revealContact);
    if (context.mounted) Navigator.pop(context); // Pop Loading

    if (product == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'عذراً، خدمة الشراء غير متوفرة حالياً. يرجى المحاولة لاحقاً.',
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // 2. Show Confirmation
    final shouldPurchase = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(MithaqSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'طلب بيانات الولي (رسمي)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: MithaqSpacing.m),
            Text(
              'يتطلب طلب معلومات التواصل الرسمية دفع "رسوم إثبات الجدية" بقيمة ${product.priceString}، تظهر البيانات مباشرة بعد الدفع.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: MithaqSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MithaqColors.mint,
                  foregroundColor: MithaqColors.navy,
                ),
                child: Text('دفع رسوم الجدية (${product.priceString})'),
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );

    if (shouldPurchase == true) {
      // 3. Perform Purchase
      final success = await subService.purchaseProduct(product);

      if (success) {
        // 4. Unlock Content via Backend RPC
        await ref
            .read(profileRepositoryProvider)
            .unlockGuardianContact(targetId);

        // Refresh Providers
        // We use the providers from profile_repository (imported above)
        ref.invalidate(shufaCardUnlockedProvider((activeId, targetId)));
        ref.invalidate(guardianContactInfoProvider(targetId));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم الدفع بنجاح! تم كشف بيانات التواصل.'),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء عملية الشراء أو فشلها.')),
          );
        }
      }
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.s),
      child: Row(
        children: [
          MithaqSoftIcon(icon: icon, size: MithaqIconSize.s),
          const SizedBox(width: MithaqSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: MithaqTypography.bodySmall,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: MithaqTypography.bodyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
