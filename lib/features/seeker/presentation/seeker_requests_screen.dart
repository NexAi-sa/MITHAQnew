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

class SeekerRequest {
  final String id; // Session ID
  final String publicId;
  final String age;
  final String city;
  final String job;
  final String compatibility;
  final bool isVerified;
  final ChatStage stage;
  final bool isIncoming;
  final String otherProfileId;

  SeekerRequest({
    required this.id,
    required this.publicId,
    required this.age,
    required this.city,
    required this.job,
    required this.compatibility,
    this.isVerified = false,
    required this.stage,
    required this.isIncoming,
    required this.otherProfileId,
  });
}

class SeekerRequestsScreen extends ConsumerStatefulWidget {
  const SeekerRequestsScreen({super.key});

  @override
  ConsumerState<SeekerRequestsScreen> createState() =>
      _SeekerRequestsScreenState();
}

class _SeekerRequestsScreenState extends ConsumerState<SeekerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  Future<void> _handleAccept(SeekerRequest request) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .updateStage(request.id, ChatStage.activeCommunication);
      ref.invalidate(seekerAllRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الاهتمام والمحادثة متاحة الآن'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في تنفيذ العملية')),
        );
      }
    }
  }

  Future<void> _handleDecline(SeekerRequest request) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .updateStage(request.id, ChatStage.closed);
      ref.invalidate(seekerAllRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الاعتذار عن الطلب')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في تنفيذ العملية')),
        );
      }
    }
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
                .watch(seekerAllRequestsProvider)
                .when(
                  data: (all) => _buildTabBar(all),
                  loading: () => const SizedBox(height: 48),
                  error: (_, __) => const SizedBox(height: 48),
                ),
            Expanded(
              child: ref
                  .watch(seekerAllRequestsProvider)
                  .when(
                    data: (allRequests) {
                      final incoming = allRequests
                          .where(
                            (r) =>
                                r.isIncoming &&
                                r.stage == ChatStage.requestSent,
                          )
                          .toList();
                      final sent = allRequests
                          .where(
                            (r) =>
                                !r.isIncoming &&
                                (r.stage == ChatStage.requestSent ||
                                    r.stage == ChatStage.initialApproval),
                          )
                          .toList();
                      final active = allRequests
                          .where(
                            (r) => r.stage == ChatStage.activeCommunication,
                          )
                          .toList();
                      final previous = allRequests
                          .where((r) => r.stage == ChatStage.closed)
                          .toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestsList(
                            incoming,
                            'لا توجد طلبات واردة حالياً',
                          ),
                          _buildRequestsList(
                            sent,
                            'لم ترسل أي طلبات اهتمام بعد',
                          ),
                          _buildRequestsList(
                            active,
                            'لا توجد محادثات نشطة حالياً',
                          ),
                          _buildRequestsList(previous, 'لا توجد طلبات سابقة'),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: MithaqColors.mint,
                      ),
                    ),
                    error: (e, _) =>
                        _buildEmptyState('حدث خطأ في تحميل البيانات'),
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
          _buildCircleIcon(Icons.history_rounded),
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

  Widget _buildTabBar(List<SeekerRequest> allRequests) {
    final incomingCount = allRequests
        .where((r) => r.isIncoming && r.stage == ChatStage.requestSent)
        .length;
    final activeCount = allRequests
        .where((r) => r.stage == ChatStage.activeCommunication)
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
        Tab(text: 'وارد${incomingCount > 0 ? " ($incomingCount)" : ""}'),
        const Tab(text: 'مرسل'),
        Tab(text: 'محادثات${activeCount > 0 ? " ($activeCount)" : ""}'),
        const Tab(text: 'الأرشيف'),
      ],
    );
  }

  Widget _buildRequestsList(List<SeekerRequest> requests, String emptyMessage) {
    if (requests.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildRequestCard(requests[index]),
    );
  }

  Widget _buildRequestCard(SeekerRequest request) {
    return InkWell(
      onTap: () => context.push('/profile/${request.otherProfileId}'),
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
                      Text(
                        'معرف الملف: #${request.publicId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'العمر: ${request.age} • ${request.city}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.job,
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
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: AvatarRenderer(
                        config: AvatarConfig(
                          gender: request.isIncoming
                              ? Gender.male
                              : Gender
                                    .female, // Logic depends on who we are viewing
                        ),
                        size: 70,
                      ),
                    ),
                    Container(
                      transform: Matrix4.translationValues(0, 8, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: MithaqColors.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${request.compatibility} توافق',
                        style: const TextStyle(
                          color: MithaqColors.navy,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionArea(request),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(SeekerRequest request) {
    if (request.stage == ChatStage.activeCommunication) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/chat/${request.otherProfileId}'),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('دخول المحادثة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: MithaqColors.mint,
            foregroundColor: MithaqColors.navy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    if (request.isIncoming) {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'قبول',
              MithaqColors.mint,
              MithaqColors.navy,
              Icons.check,
              onTap: () => _handleAccept(request),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildButton(
              'اعتذار',
              Colors.white.withValues(alpha: 0.1),
              Colors.white,
              Icons.close,
              onTap: () => _handleDecline(request),
            ),
          ),
        ],
      );
    }

    // Status for sent request
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          request.stage == ChatStage.requestSent
              ? 'انتظار قبول الطرف الآخر'
              : 'بانتظار موافقة ولي الأمر',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String label,
    Color bg,
    Color text,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: text, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: text, fontWeight: FontWeight.bold),
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
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}

final seekerAllRequestsProvider = FutureProvider<List<SeekerRequest>>((
  ref,
) async {
  final session = ref.watch(sessionProvider);
  final myProfileId = session.profileId ?? session.userId;
  if (myProfileId == null) return [];

  final chatRepo = ref.watch(chatRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);

  try {
    // Get all sessions where I am either seeker or target
    final allSessions = await chatRepo.getSessionsForProfile(myProfileId);

    final List<SeekerRequest> requests = [];

    for (final s in allSessions) {
      final isIncoming = s.targetProfileId == myProfileId;
      final otherProfileId = isIncoming ? s.seekerProfileId : s.targetProfileId;

      final otherProfile = await profileRepo.getProfileById(otherProfileId);
      if (otherProfile != null) {
        requests.add(
          SeekerRequest(
            id: s.id,
            publicId: otherProfile.profilePublicId.isEmpty
                ? (otherProfile.profileId.length > 4
                      ? 'MITH-${otherProfile.profileId.substring(0, 4)}'
                      : 'MITH-${otherProfile.profileId}')
                : otherProfile.profilePublicId,
            age: '${otherProfile.age} سنة',
            city: otherProfile.city,
            job: otherProfile.job,
            compatibility: '٨٩٪',
            isVerified: true,
            stage: s.stage,
            isIncoming: isIncoming,
            otherProfileId: otherProfileId,
          ),
        );
      }
    }

    return requests;
  } catch (e) {
    print('Error in seekerAllRequestsProvider: $e');
    return [];
  }
});
