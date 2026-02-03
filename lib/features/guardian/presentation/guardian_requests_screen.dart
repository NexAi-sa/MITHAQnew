import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_system.dart';
import '../../avatar/domain/avatar_config.dart';
import '../../avatar/presentation/widgets/avatar_renderer.dart';
import '../../seeker/data/profile_repository.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_models.dart';
import '../../../core/session/session_provider.dart';

class SuitorRequest {
  final String id; // Session ID
  final String publicId;
  final String age;
  final String city;
  final String job;
  final String company;
  final String compatibility;
  final bool isVerified;
  final String? imageUrl;
  final ChatStage stage;

  final String suitorProfileId;

  SuitorRequest({
    required this.id,
    required this.publicId,
    required this.age,
    required this.city,
    required this.job,
    required this.company,
    required this.compatibility,
    this.isVerified = false,
    this.imageUrl,
    required this.stage,
    required this.suitorProfileId,
  });
}

class GuardianRequestsScreen extends ConsumerStatefulWidget {
  const GuardianRequestsScreen({super.key});

  @override
  ConsumerState<GuardianRequestsScreen> createState() =>
      _GuardianRequestsScreenState();
}

class _GuardianRequestsScreenState extends ConsumerState<GuardianRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Future<void> _handleAccept(SuitorRequest request) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .updateStage(request.id, ChatStage.activeCommunication);
      ref.invalidate(suitorRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول التواصل وتفعيل المحادثة آلياً'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء قبول الطلب')),
        );
      }
    }
  }

  Future<void> _handleDecline(SuitorRequest request) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .updateStage(request.id, ChatStage.closed);
      ref.invalidate(suitorRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الاعتذار عن الطلب')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تنفيذ الطلب')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D172E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            ref
                .watch(suitorRequestsProvider)
                .when(
                  data: (all) => _buildTabBar(all),
                  loading: () => const SizedBox(height: 48),
                  error: (_, __) => const SizedBox(height: 48),
                ),
            Expanded(
              child: ref
                  .watch(suitorRequestsProvider)
                  .when(
                    data: (allRequests) {
                      final newReqs = allRequests
                          .where((r) => r.stage == ChatStage.requestSent)
                          .toList();
                      final reviewReqs = allRequests
                          .where((r) => r.stage == ChatStage.initialApproval)
                          .toList();
                      final acceptedReqs = allRequests
                          .where(
                            (r) =>
                                r.stage == ChatStage.activeCommunication ||
                                r.stage == ChatStage.shufaRequested,
                          )
                          .toList();
                      final previousReqs = allRequests
                          .where((r) => r.stage == ChatStage.closed)
                          .toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestsList(
                            newReqs,
                            'لا توجد طلبات جديدة حالياً',
                          ),
                          _buildRequestsList(
                            reviewReqs,
                            'لا توجد طلبات قيد المراجعة',
                          ),
                          _buildRequestsList(
                            acceptedReqs,
                            'لا توجد محادثات نشطة حالياً',
                          ),
                          _buildRequestsList(
                            previousReqs,
                            'لا يوجد محادثات مؤرشفة',
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: MithaqColors.mint,
                      ),
                    ),
                    error: (e, _) =>
                        _buildEmptyState('حدث خطأ في تحميل الطلبات'),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleIcon(Icons.notifications_none_rounded),
          const Text(
            'مركز التواصل',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildCircleIcon(Icons.tune_rounded),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildTabBar(List<SuitorRequest> allRequests) {
    final newCount = allRequests
        .where((r) => r.stage == ChatStage.requestSent)
        .length;
    final reviewCount = allRequests
        .where((r) => r.stage == ChatStage.initialApproval)
        .length;

    return TabBar(
      controller: _tabController,
      dividerColor: Colors.transparent,
      indicatorColor: MithaqColors.mint,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: MithaqColors.mint,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 13,
      ),
      isScrollable: false,
      tabs: [
        Tab(text: 'الجديدة${newCount > 0 ? " ($newCount)" : ""}'),
        Tab(text: 'قيد المراجعة${reviewCount > 0 ? " ($reviewCount)" : ""}'),
        const Tab(text: 'المحادثات'),
        const Tab(text: 'الأرشيف'),
      ],
    );
  }

  Widget _buildRequestsList(List<SuitorRequest> requests, String emptyMessage) {
    if (requests.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index]);
      },
    );
  }

  Widget _buildRequestCard(SuitorRequest request) {
    return InkWell(
      onTap: () => context.push('/profile/${request.suitorProfileId}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2B56).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (request.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.verified,
                                color: Color(0xFF4A90E2),
                                size: 18,
                              ),
                            ),
                          Text(
                            'معرف الملف: #${request.publicId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'العمر: ${request.age} • ${request.city}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      if (request.stage == ChatStage.shufaRequested) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: MithaqColors.mint.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: MithaqColors.mint.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: MithaqColors.mint,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'تم طلب الشوفة',
                                style: TextStyle(
                                  color: MithaqColors.mint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${request.job}- ${request.company}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: const AvatarRenderer(
                          config: AvatarConfig(
                            gender:
                                Gender.male, // Suitors are male in this context
                          ),
                          size: 90,
                        ),
                      ),
                    ),
                    Container(
                      transform: Matrix4.translationValues(0, 10, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MithaqColors.mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${request.compatibility} توافق',
                        style: const TextStyle(
                          color: MithaqColors.navy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'بدء المحادثة',
                    MithaqColors.mint,
                    MithaqColors.navy,
                    Icons.chat_bubble_outline_rounded,
                    onTap: () => _handleAccept(request),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'اعتذار',
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white,
                    Icons.close_rounded,
                    onTap: () => _handleDecline(request),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color bgColor,
    Color textColor,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

final suitorRequestsProvider = FutureProvider<List<SuitorRequest>>((ref) async {
  final session = ref.watch(sessionProvider);
  final userId = session.userId;
  if (userId == null) return [];

  final profileRepo = ref.watch(profileRepositoryProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  try {
    // 1. Get managed dependents
    final dependents = await profileRepo.getProfilesByUserId(userId);
    final depIds = dependents.map((d) => d.profileId).toList();

    if (depIds.isEmpty) return [];

    // 2. Get inbound chat sessions (requests)
    final sessions = await chatRepo.getInboundSessions(depIds);

    final List<SuitorRequest> suitorRequests = [];

    for (final s in sessions) {
      final suitorProfile = await profileRepo.getProfileById(s.seekerProfileId);

      if (suitorProfile != null) {
        suitorRequests.add(
          SuitorRequest(
            id: s.id,
            publicId: suitorProfile.profilePublicId.isNotEmpty
                ? suitorProfile.profilePublicId
                : (suitorProfile.profileId.length > 8
                      ? suitorProfile.profileId.substring(0, 8)
                      : suitorProfile.profileId),
            age: suitorProfile.age.toString(),
            city: suitorProfile.city,
            job: suitorProfile.job,
            company: suitorProfile.tribe ?? 'جهة غير محددة',
            compatibility: '85%',
            isVerified: true,
            stage: s.stage,
            suitorProfileId: suitorProfile.profileId,
          ),
        );
      }
    }

    return suitorRequests;
  } catch (e) {
    print('Error in suitorRequestsProvider: $e');
    return []; // Return empty list on error
  }
});
