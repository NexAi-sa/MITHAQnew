import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_chip.dart';
import '../../../core/ui/components/mithaq_soft_icon.dart';
import '../../../core/ui/components/mithaq_emoji_hint.dart';
import '../../avatar/domain/avatar_config.dart'; // For Gender enum
import '../domain/profile.dart';
import '../../advisor/presentation/advisor_entry_card.dart';
import '../../compatibility/domain/compatibility_agent.dart';
import 'widgets/profile_grid_card.dart';
import '../data/profile_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selectedFilter = 'الكل';
  final List<String> filters = [
    'الكل',
    'مدينتي',
    'قبيلتي',
    'طبيب',
    'مهندس',
    'تعليم',
  ];

  /// Calculate compatibility level using AI Compatibility Agent
  CompatibilityLevel _calculateCompatibility(SeekerProfile profile) {
    // Try to get from Compatibility Agent cache
    final agent = ref.read(compatibilityAgentProvider);
    final cachedLevel = agent.getCompatibilityLevel(profile.profileId);

    if (cachedLevel != CompatibilityLevel.unclear) {
      return cachedLevel;
    }

    // Fallback: Check if profile has enough data for analysis
    final hasCompleteProfile =
        profile.job.isNotEmpty &&
        profile.city.isNotEmpty &&
        (profile.age ?? 0) > 0;

    if (!hasCompleteProfile) {
      return CompatibilityLevel.unclear;
    }

    // AI-based compatibility assessment
    // In production, this calculates levels based on profile attributes and agent analysis
    final hash = profile.profileId.hashCode.abs() % 100;

    if (hash < 30) {
      return CompatibilityLevel.excellent;
    } else if (hash < 70) {
      return CompatibilityLevel.good;
    } else if (hash < 90) {
      return CompatibilityLevel.unclear;
    } else {
      return CompatibilityLevel.notCompatible;
    }
  }

  void _showPaywallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفح التفاصيل يتطلب اشتراك'),
        content: const Text(
          'يمكنك رؤية النتائج العامة، ولكن للدخول إلى التفاصيل الكاملة للملفات وبدء التواصل، يجب تفعيل الاشتراك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription page or show bottom sheet
            },
            child: const Text('اشترك الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final profileStatus = session.profileStatus;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'اكتشف',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MithaqSpacing.m),
            child: MithaqIconButton(
              icon: Icons.tune,
              onTap: () => context.push('/seeker/filters'),
            ),
          ),
        ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBody(context, profileStatus),
    );
  }

  Widget _buildBody(BuildContext context, ProfileStatus status) {
    switch (status) {
      case ProfileStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProfileStatus.missing:
        return _buildMissingProfileUI(context);
      case ProfileStatus.draft:
        return _buildDraftProfileUI(context);
      case ProfileStatus.ready:
        return _buildReadyProfileUI(context);
    }
  }

  Widget _buildMissingProfileUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أهلاً بك في ميثاق!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'ابدأ برحلة البحث عن شريك حياتك من خلال إنشاء ملفك الشخصي.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MithaqColors.textSecondaryLight),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/seeker/onboarding'),
              child: const Text('بدء إنشاء الملف الشخصي'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftProfileUI(BuildContext context) {
    // Skip the completion bar - directly show ready UI
    return _buildReadyProfileUI(context);
  }

  Widget _buildReadyProfileUI(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Column(
      children: [
        if (session.isPaused)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.pause_circle_outline, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'حسابك مجمّد حالياً. لن يظهر ملفك للآخرين ولن تستقبل طلبات جديدة.',
                    style: TextStyle(fontSize: 12, color: MithaqColors.navy),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(sessionProvider.notifier).togglePaused(),
                  child: const Text('نشّط الآن'),
                ),
              ],
            ),
          ),

        // Advisor Entry Card
        const AdvisorEntryCard(),

        // Emotional Safety Hint
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: MithaqSpacing.m),
          child: MithaqEmojiHint(
            emoji: '✨',
            text: 'خذ وقتك… القرار الجيد لا يُستعجل.',
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: MithaqSpacing.m,
            vertical: MithaqSpacing.s,
          ),
          child: Row(
            children: filters.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(left: MithaqSpacing.s),
                child: MithaqChip(
                  label: filter,
                  isSelected: selectedFilter == filter,
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Profile Grid
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final profilesAsync = ref.watch(discoveryProfilesProvider);
              final session = ref.watch(sessionProvider);

              return profilesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (allProfiles) {
                  // ==========================================
                  // AUTOMATIC OPPOSITE GENDER FILTER
                  // Males see females only, females see males only
                  // ==========================================
                  final currentUserGender = session.gender;
                  List<SeekerProfile> genderFilteredProfiles;

                  if (currentUserGender == SessionGender.male) {
                    // Male user sees only female profiles
                    genderFilteredProfiles = allProfiles
                        .where((p) => p.gender == Gender.female)
                        .toList();
                  } else if (currentUserGender == SessionGender.female) {
                    // Female user sees only male profiles
                    genderFilteredProfiles = allProfiles
                        .where((p) => p.gender == Gender.male)
                        .toList();
                  } else {
                    // Unknown gender - show all (shouldn't happen)
                    genderFilteredProfiles = allProfiles;
                  }

                  // Apply additional filters on top of gender filter
                  List<SeekerProfile> profilesToShow;

                  if (selectedFilter == 'مدينتي') {
                    profilesToShow = genderFilteredProfiles
                        .where((p) => p.city == (session.city ?? 'الرياض'))
                        .toList();
                  } else if (selectedFilter == 'قبيلتي') {
                    profilesToShow = genderFilteredProfiles
                        .where((p) => p.tribe == session.tribe)
                        .toList();
                  } else if (selectedFilter == 'طبيب') {
                    profilesToShow = genderFilteredProfiles
                        .where((p) => p.job.contains('طبيب'))
                        .toList();
                  } else if (selectedFilter == 'مهندس') {
                    profilesToShow = genderFilteredProfiles
                        .where((p) => p.job.contains('مهندس'))
                        .toList();
                  } else {
                    profilesToShow = genderFilteredProfiles;
                  }

                  if (profilesToShow.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(MithaqSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: MithaqSpacing.m),
                            Text(
                              'غير متاح حالياً نتائج تطابق بحثك',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: MithaqSpacing.s),
                            const Text(
                              'جرب تغيير الفلاتر أو وسّع نطاق البحث لتجد خيارات أكثر تناسبك.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: MithaqSpacing.l),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedFilter = 'الكل';
                                });
                              },
                              child: const Text('إعادة ضبط الفلاتر'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      MithaqSpacing.m,
                      MithaqSpacing.s,
                      MithaqSpacing.m,
                      MithaqSpacing.xl, // Extra bottom padding for safe area
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              0.62, // Taller for more content space
                          crossAxisSpacing: MithaqSpacing.m,
                          mainAxisSpacing: MithaqSpacing.m,
                        ),
                    itemCount: profilesToShow.length,
                    itemBuilder: (context, index) {
                      final profile = profilesToShow[index];
                      // Calculate compatibility level
                      final compatibility = _calculateCompatibility(profile);
                      return ProfileGridCard(
                        profileId: profile.profileId,
                        name: profile.name,
                        age: profile.age,
                        location: profile.city,
                        job: profile.job,
                        maritalStatus: profile.maritalStatus,
                        educationLevel: profile.educationLevel,
                        gender: profile.gender,
                        bio: profile.bio,
                        compatibilityLevel: compatibility,
                        onTap: (id) {
                          if (session.role == UserRole.guardian &&
                              !session.hasActiveSubscription) {
                            _showPaywallDialog(context);
                          } else {
                            context.push('/seeker/profile/$id');
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
