import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/compatibility_model.dart';
import '../../seeker/domain/profile.dart';
import '../../seeker/data/profile_repository.dart';
import '../../../core/session/session_provider.dart';

/// Mock compatibility calculation engine
class CompatibilityEngine {
  final ProfileRepository _profileRepo;

  CompatibilityEngine(this._profileRepo);

  /// Calculate compatibility between current user and target profile
  Future<CompatibilityResult> calculate({
    required SeekerProfile currentUser,
    required String targetProfileId,
  }) async {
    final targetProfile = await _profileRepo.getProfileById(targetProfileId);
    if (targetProfile == null) {
      return _emptyResult(targetProfileId);
    }

    final basicScore = _calculateBasic(currentUser, targetProfile);
    final styleScore = _calculateStyle(currentUser, targetProfile);
    final psychologicalScore = _calculatePsychological(
      currentUser,
      targetProfile,
    );

    final tags = _generateCompatibilityTags(
      currentUser,
      targetProfile,
      basicScore,
      psychologicalScore,
    );
    final report = _generateHybridReport(
      currentUser,
      targetProfile,
      tags,
      psychologicalScore,
    );

    return CompatibilityResult(
      targetProfileId: targetProfileId,
      basic: basicScore,
      style: styleScore,
      psychological: psychologicalScore,
      calculatedAt: DateTime.now(),
      compatibilityTags: tags,
      hybridReportText: report,
    );
  }

  List<String> _generateCompatibilityTags(
    SeekerProfile user,
    SeekerProfile target,
    AxisScore basic,
    AxisScore psych,
  ) {
    final tags = <String>[];

    // 1. Geography
    if (user.city == target.city) tags.add('نفس المدينة');

    // 2. Personality Alignment
    if (user.personalityType != null &&
        user.personalityType == target.personalityType) {
      tags.add('توافق في نمط ${user.personalityType}');
    }

    // 3. Priorities
    final userPriorities =
        (user.personalityData?['priorities'] as List?)?.cast<String>() ?? [];
    final targetPriorities =
        (target.personalityData?['priorities'] as List?)?.cast<String>() ?? [];
    if (userPriorities.isNotEmpty &&
        targetPriorities.isNotEmpty &&
        userPriorities.first == targetPriorities.first) {
      tags.add('اشتراك في أولوية ${userPriorities.first}');
    }

    // 4. Age
    if (user.age != null &&
        target.age != null &&
        (user.age! - target.age!).abs() <= 3) {
      tags.add('تقارب في العمر');
    }

    return tags.take(3).toList();
  }

  String? _generateHybridReport(
    SeekerProfile user,
    SeekerProfile target,
    List<String> tags,
    AxisScore psych,
  ) {
    if (!psych.isComplete) return null;

    String reason = 'تقارب جميل في الرؤى';

    if (user.personalityType != null &&
        user.personalityType == target.personalityType) {
      reason = 'اشتراككما في رؤية "${user.personalityType}"';
    } else if (tags.contains('نفس المدينة')) {
      reason = 'تواجدكما في نفس المدينة وتقارب أهدافكما';
    }

    return 'مرحباً.. قبل أن تبدآ، يخبركما ميثاق أن $reason هو ما جعل التوافق بينكما متميزاً. ننصحكما بالحديث عن تطلعاتكما المستقبلية لبناء حياة مستقرة!';
  }

  AxisScore _calculateBasic(SeekerProfile user, SeekerProfile target) {
    int score = 0;
    final positives = <String>[];
    final discussions = <String>[];

    // Age alignment (prefer within 5 years)
    final userAge = user.age;
    final targetAge = target.age;
    if (userAge != null && targetAge != null) {
      final ageDiff = (userAge - targetAge).abs();
      if (ageDiff <= 3) {
        score += 30;
        positives.add('فارق العمر مناسب');
      } else if (ageDiff <= 7) {
        score += 20;
        positives.add('فارق العمر مقبول');
      } else {
        score += 10;
        discussions.add('فارق العمر يحتاج حوار');
      }
    } else {
      score += 15;
      discussions.add('العمر غير متوفر للمقارنة');
    }

    // City alignment
    if (user.city == target.city) {
      score += 30;
      positives.add('نفس المدينة - تسهيل التواصل');
    } else {
      score += 15;
      discussions.add('المدينة مختلفة - ناقش خطط السكن');
    }

    // Marital status compatibility
    if (user.maritalStatus == target.maritalStatus) {
      score += 25;
      positives.add('توافق في الحالة الاجتماعية');
    } else {
      score += 15;
    }

    // Education level proximity
    if (user.educationLevel == target.educationLevel) {
      score += 15;
      positives.add('مستوى تعليمي متقارب');
    } else {
      score += 10;
    }

    return AxisScore(
      axis: CompatibilityAxis.basic,
      score: score.clamp(0, 100),
      positiveReasons: positives.take(2).toList(),
      discussionPoints: discussions.take(2).toList(),
    );
  }

  AxisScore _calculateStyle(SeekerProfile user, SeekerProfile target) {
    int score = 50; // Base score
    final positives = <String>[];
    final discussions = <String>[];

    // Smoking alignment (if preferences exist)
    final userPref = user.suitorPreferences;
    final targetPref = target.suitorPreferences;

    if (userPref?.smoking != null && targetPref?.smoking != null) {
      if (userPref!.smoking == targetPref!.smoking) {
        score += 25;
        positives.add('توافق في موضوع التدخين');
      } else if (userPref.smoking == SmokingHabit.no &&
          targetPref.smoking == SmokingHabit.yes) {
        score -= 10;
        discussions.add('تنبيه ودي: يوجد فرق في موضوع التدخين');
      } else {
        score += 10;
      }
    } else {
      // No data on smoking - neutral
      score += 15;
    }

    // Hijab preference alignment
    if (userPref?.hijab != null && targetPref?.hijab != null) {
      if (userPref!.hijab == targetPref!.hijab) {
        score += 25;
        positives.add('توافق في نمط اللباس المفضل');
      } else {
        score += 10;
      }
    } else {
      score += 15;
    }

    return AxisScore(
      axis: CompatibilityAxis.style,
      score: score.clamp(0, 100),
      positiveReasons: positives.take(2).toList(),
      discussionPoints: discussions.take(2).toList(),
    );
  }

  AxisScore _calculatePsychological(SeekerProfile user, SeekerProfile target) {
    if (user.personalityType == null || target.personalityType == null) {
      return const AxisScore(
        axis: CompatibilityAxis.psychological,
        score: 0,
        isComplete: false,
        positiveReasons: [],
        discussionPoints: [
          'أكمل "اختبار العمى عن المثالية" لتفعيل التوافق النفسي',
        ],
      );
    }

    int score = 50;
    final positives = <String>[];
    final discussions = <String>[];

    // 1. Home Type Alignment
    if (user.personalityType == target.personalityType) {
      score += 30;
      positives.add('توافق تام في نمط الحياة (${user.personalityType})');
    } else {
      // Check for clashing types (e.g., Castle vs Camping)
      if ((user.personalityType == 'صاحب الحصن المنيع' &&
              target.personalityType == 'روح المغامرة الحرّة') ||
          (target.personalityType == 'صاحب الحصن المنيع' &&
              user.personalityType == 'روح المغامرة الحرّة')) {
        score -= 20;
        discussions.add('اختلاف في الرؤية للخصوصية مقابل الانفتاح');
      } else {
        score += 10;
        discussions.add('تنوع جميل في الطباع');
      }
    }

    // 2. Silence Interpretation Analysis
    final userSilence = user.personalityData?['silence'];
    final targetSilence = target.personalityData?['silence'];

    if (userSilence != null && targetSilence != null) {
      if (userSilence == targetSilence) {
        score += 20;
        positives.add('تفسير مشترك للمواقف الصامتة');
      } else if (userSilence == 'apathy' || targetSilence == 'apathy') {
        // One needs affirmation, one provides stability
        score += 15;
        positives.add('علاقة تكاملية: أمان وتفهم متبادل');
      }
    }

    // 3. Priorities Check
    final userPriorities =
        (user.personalityData?['priorities'] as List?)?.cast<String>() ?? [];
    final targetPriorities =
        (target.personalityData?['priorities'] as List?)?.cast<String>() ?? [];

    final commonPriorities = userPriorities
        .where((p) => targetPriorities.contains(p))
        .toList();
    if (commonPriorities.isNotEmpty) {
      score += 10 * commonPriorities.length;
      positives.add('اشتراك في قيم: ${commonPriorities.join("، ")}');
    }

    return AxisScore(
      axis: CompatibilityAxis.psychological,
      score: score.clamp(0, 100),
      isComplete: true,
      positiveReasons: positives.take(2).toList(),
      discussionPoints: discussions.take(2).toList(),
    );
  }

  CompatibilityResult _emptyResult(String targetProfileId) {
    return CompatibilityResult(
      targetProfileId: targetProfileId,
      basic: const AxisScore(
        axis: CompatibilityAxis.basic,
        score: 0,
        isComplete: false,
      ),
      style: const AxisScore(
        axis: CompatibilityAxis.style,
        score: 0,
        isComplete: false,
      ),
      psychological: const AxisScore(
        axis: CompatibilityAxis.psychological,
        score: 0,
        isComplete: false,
      ),
      calculatedAt: DateTime.now(),
    );
  }
}

/// Provider for compatibility engine
final compatibilityEngineProvider = Provider<CompatibilityEngine>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return CompatibilityEngine(profileRepo);
});

final compatibilityResultProvider =
    FutureProvider.family<CompatibilityResult, String>((ref, targetId) async {
      final engine = ref.watch(compatibilityEngineProvider);
      final session = ref.watch(sessionProvider);
      final repo = ref.watch(profileRepositoryProvider);

      // In a real app, we'd fetch the current user's profile
      // For demo/MVP, if session.userId is null, we might not have a profile.
      // We'll try to find a profile owned by the current user.
      final userId = session.userId;
      if (userId == null) {
        return engine._emptyResult(targetId);
      }

      final userProfiles = await repo.getProfilesByUserId(userId);
      if (userProfiles.isEmpty) {
        return engine._emptyResult(targetId);
      }

      return engine.calculate(
        currentUser: userProfiles.first,
        targetProfileId: targetId,
      );
    });
