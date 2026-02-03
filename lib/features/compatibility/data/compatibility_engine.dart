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

    return CompatibilityResult(
      targetProfileId: targetProfileId,
      basic: _calculateBasic(currentUser, targetProfile),
      style: _calculateStyle(currentUser, targetProfile),
      psychological: _calculatePsychological(currentUser, targetProfile),
      calculatedAt: DateTime.now(),
    );
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
    // Psychological compatibility requires advisor insights or mini check-ins
    // For now, mark as incomplete if no data available
    // Parameters user and target would be used in a real implementation
    // to check advisor repository and check-in data

    // Mock: In a real app, we'd check advisor repository and check-in data
    // For now, always return incomplete since we have no psychological data
    return const AxisScore(
      axis: CompatibilityAxis.psychological,
      score: 0,
      isComplete: false,
      positiveReasons: [],
      discussionPoints: ['لم يتوفر بيانات كافية للتقييم النفسي'],
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
