import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/ui/design_tokens.dart';
import '../../../avatar/domain/avatar_config.dart';
import '../../../avatar/presentation/widgets/privacy_avatar.dart';
import '../../domain/profile.dart';

/// Compatibility level between profiles based on personality analysis
enum CompatibilityLevel {
  /// Excellent match - both completed tests with high compatibility
  excellent,

  /// Good match - reasonable compatibility
  good,

  /// Not compatible - low compatibility score
  notCompatible,

  /// Unclear - one or both parties haven't completed profile/personality test
  unclear,
}

extension CompatibilityLevelUI on CompatibilityLevel {
  String get label {
    switch (this) {
      case CompatibilityLevel.excellent:
        return 'توافق ممتاز';
      case CompatibilityLevel.good:
        return 'توافق جيد';
      case CompatibilityLevel.notCompatible:
        return 'غير متوافق';
      case CompatibilityLevel.unclear:
        return 'توافق غير واضح';
    }
  }

  Color get color {
    switch (this) {
      case CompatibilityLevel.excellent:
        return const Color(0xFF10B981); // Green
      case CompatibilityLevel.good:
        return const Color(0xFF3B82F6); // Blue
      case CompatibilityLevel.notCompatible:
        return const Color(0xFFEF4444); // Red
      case CompatibilityLevel.unclear:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  IconData get icon {
    switch (this) {
      case CompatibilityLevel.excellent:
        return Icons.verified;
      case CompatibilityLevel.good:
        return Icons.check_circle_outline;
      case CompatibilityLevel.notCompatible:
        return Icons.cancel_outlined;
      case CompatibilityLevel.unclear:
        return Icons.help_outline;
    }
  }
}

/// A premium dark-themed profile card matching the reference design.
/// Features gradient ring avatar, action buttons, and elegant info layout.
class ProfileGridCard extends StatelessWidget {
  final String name;
  final int? age;
  final String location;
  final String job;
  final EducationLevel? educationLevel;
  final MaritalStatus maritalStatus;
  final Gender gender;
  final String profileId;
  final Function(String) onTap;
  final Function(String)? onLike;
  final Function(String)? onAccept;
  final int? compatibilityScore;
  final CompatibilityLevel? compatibilityLevel;
  final String? bio;
  final bool isLiked;
  final bool isAccepted;

  const ProfileGridCard({
    super.key,
    required this.name,
    this.age,
    required this.location,
    required this.job,
    this.educationLevel,
    required this.maritalStatus,
    required this.gender,
    required this.profileId,
    required this.onTap,
    this.bio,
    this.onLike,
    this.onAccept,
    this.compatibilityScore,
    this.compatibilityLevel,
    this.isLiked = false,
    this.isAccepted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(profileId);
      },
      child: AnimatedContainer(
        duration: MithaqDurations.normal,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E2D4D),
              const Color(0xFF162240),
              MithaqColors.navy.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(MithaqRadius.l),
          border: Border.all(
            color: MithaqColors.mint.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Action buttons row
                _buildActionButtons(),

                // Avatar Section
                Expanded(
                  flex: 4,
                  child: Center(
                    child: PrivacyAvatar(
                      photoUrl: null,
                      gender: gender,
                      size: 90,
                      context: AvatarContext.grid,
                      style: AvatarStyle.silhouette,
                    ),
                  ),
                ),

                // Info Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MithaqSpacing.m,
                    0,
                    MithaqSpacing.m,
                    MithaqSpacing.m,
                  ),
                  child: Column(
                    children: [
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: MithaqTypography.bodyLarge,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      // Location with dot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: MithaqColors.mint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              location,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: MithaqTypography.bodySmall,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Information Row (Age & Gender)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            age != null ? '$age سنة' : 'غير محدد',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            gender == Gender.male ? Icons.male : Icons.female,
                            size: 11,
                            color: gender == Gender.male
                                ? Colors.blue.shade300
                                : Colors.pink.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gender == Gender.male ? 'ذكر' : 'أنثى',
                            style: TextStyle(
                              color: gender == Gender.male
                                  ? Colors.blue.shade200
                                  : Colors.pink.shade200,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      if (bio != null && bio!.isNotEmpty) ...[
                        const SizedBox(height: MithaqSpacing.s),
                        Text(
                          bio!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Compatibility Badge (top-left corner)
            if (compatibilityLevel != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: compatibilityLevel!.color.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: compatibilityLevel!.color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        compatibilityLevel!.icon,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        compatibilityLevel!.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(MithaqSpacing.s),
      child: Row(
        children: [
          // Like button
          _ActionButton(
            icon: Icons.favorite,
            isActive: isLiked,
            activeColor: MithaqColors.pink,
            onTap: onLike != null ? () => onLike!(profileId) : null,
          ),
          const SizedBox(width: MithaqSpacing.xs),
          // Accept button
          _ActionButton(
            icon: Icons.check,
            isActive: isAccepted,
            activeColor: MithaqColors.mint,
            onTap: onAccept != null ? () => onAccept!(profileId) : null,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: MithaqDurations.fast,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? activeColor : Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
