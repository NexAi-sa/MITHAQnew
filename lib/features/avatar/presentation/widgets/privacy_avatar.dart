import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/avatar_config.dart';

/// Context for avatar display - affects blur intensity
enum AvatarContext {
  /// Discover/Home grid - maximum privacy (highest blur)
  grid,

  /// Profile detail view - reduced blur (still privacy-preserving)
  detail,

  /// Chat/Messaging context - medium blur
  chat,
}

/// Style of avatar display
enum AvatarStyle {
  /// Silhouette with geometric pattern background
  silhouette,

  /// Blurred photo (when available)
  blurredPhoto,

  /// Abstract gradient (fallback)
  abstractGradient,
}

/// A premium privacy-preserving avatar widget with gradient ring.
/// Matches the reference design with dark theme styling.
class PrivacyAvatar extends StatelessWidget {
  final String? photoUrl;
  final Gender gender;
  final double size;
  final AvatarContext context;
  final AvatarStyle style;

  const PrivacyAvatar({
    super.key,
    this.photoUrl,
    required this.gender,
    this.size = 100,
    this.context = AvatarContext.grid,
    this.style = AvatarStyle.silhouette,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GradientRingPainter(gender: gender, ringWidth: size * 0.04),
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: ClipOval(child: _buildAvatarContent()),
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    // If we have a photo URL and style is blurredPhoto, show blurred image
    if (photoUrl != null &&
        photoUrl!.isNotEmpty &&
        style == AvatarStyle.blurredPhoto) {
      return _buildBlurredPhoto();
    }

    // Otherwise show silhouette or abstract gradient
    if (style == AvatarStyle.silhouette) {
      return _buildSilhouette();
    }

    return _buildAbstractGradient();
  }

  /// Builds the silhouette avatar (like reference image)
  Widget _buildSilhouette() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MithaqColors.navy.withValues(alpha: 0.9),
            MithaqColors.navy,
            const Color(0xFF0D1628),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Geometric pattern background
          CustomPaint(painter: _GeometricPatternPainter(gender: gender)),
          // Silhouette
          Center(
            child: CustomPaint(
              size: Size(size * 0.6, size * 0.7),
              painter: _SilhouettePainter(gender: gender),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the blurred photo layer
  Widget _buildBlurredPhoto() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred image
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: _getBlurIntensity(),
            sigmaY: _getBlurIntensity(),
            tileMode: TileMode.clamp,
          ),
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildSilhouette(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildSilhouette();
            },
          ),
        ),
        // Warm gradient overlay for blurred photos
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                MithaqColors.pink.withValues(alpha: 0.2),
                MithaqColors.navy.withValues(alpha: 0.3),
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  /// Abstract gradient fallback
  Widget _buildAbstractGradient() {
    final colors = gender == Gender.female
        ? [
            MithaqColors.navy,
            MithaqColors.pink.withValues(alpha: 0.4),
            const Color(0xFFE8B4B8).withValues(alpha: 0.3),
          ]
        : [
            MithaqColors.navy,
            MithaqColors.mint.withValues(alpha: 0.4),
            const Color(0xFF4ECDC4).withValues(alpha: 0.3),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.3, -0.3),
          radius: 1.2,
          colors: colors,
        ),
      ),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: CustomPaint(painter: _AbstractPatternPainter(gender: gender)),
      ),
    );
  }

  /// Get blur intensity based on gender and context
  double _getBlurIntensity() {
    double baseBlur = gender == Gender.female ? 22.0 : 16.0;

    switch (context) {
      case AvatarContext.grid:
        return baseBlur * 1.1;
      case AvatarContext.detail:
        return baseBlur * 0.7;
      case AvatarContext.chat:
        return baseBlur * 0.85;
    }
  }
}

/// Painter for the gradient ring around avatar
class _GradientRingPainter extends CustomPainter {
  final Gender gender;
  final double ringWidth;

  _GradientRingPainter({required this.gender, required this.ringWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (ringWidth / 2);

    // Define gradient colors based on gender
    final colors = gender == Gender.female
        ? [
            MithaqColors.pink,
            MithaqColors.pink.withValues(alpha: 0.7),
            const Color(0xFFE8B4B8),
            MithaqColors.pink.withValues(alpha: 0.5),
          ]
        : [
            MithaqColors.mint,
            const Color(0xFF4ECDC4),
            MithaqColors.mint.withValues(alpha: 0.7),
            const Color(0xFF45B7AA),
          ];

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: colors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth;

    canvas.drawCircle(center, radius, paint);

    // Add subtle glow
    final glowPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for silhouette shape
class _SilhouettePainter extends CustomPainter {
  final Gender gender;

  _SilhouettePainter({required this.gender});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A1525).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    // Head
    final headRadius = size.width * 0.35;
    final headCenterY = size.height * 0.25;
    canvas.drawCircle(Offset(centerX, headCenterY), headRadius, paint);

    // Shoulders/Body
    final path = Path();
    final shoulderY = headCenterY + headRadius + size.height * 0.05;
    final bodyWidth = size.width * 0.9;

    path.moveTo(centerX - bodyWidth / 2, size.height);
    path.quadraticBezierTo(
      centerX - bodyWidth / 2,
      shoulderY,
      centerX,
      shoulderY,
    );
    path.quadraticBezierTo(
      centerX + bodyWidth / 2,
      shoulderY,
      centerX + bodyWidth / 2,
      size.height,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for geometric pattern background
class _GeometricPatternPainter extends CustomPainter {
  final Gender gender;

  _GeometricPatternPainter({required this.gender});

  @override
  void paint(Canvas canvas, Size size) {
    final patternColor = gender == Gender.female
        ? MithaqColors.pink.withValues(alpha: 0.08)
        : MithaqColors.mint.withValues(alpha: 0.08);

    final paint = Paint()
      ..color = patternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw Islamic geometric pattern (simplified)
    final spacing = size.width / 6;
    for (var i = 0; i < 8; i++) {
      for (var j = 0; j < 8; j++) {
        final x = i * spacing;
        final y = j * spacing;

        // Draw diamond shapes
        final path = Path()
          ..moveTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..lineTo(x, y + spacing / 2)
          ..close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for abstract background pattern
class _AbstractPatternPainter extends CustomPainter {
  final Gender gender;

  _AbstractPatternPainter({required this.gender});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (gender == Gender.female) {
      paint.color = MithaqColors.pink.withValues(alpha: 0.4);
      canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.3),
        size.width * 0.5,
        paint,
      );
      paint.color = MithaqColors.navy.withValues(alpha: 0.3);
      canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.7),
        size.width * 0.4,
        paint,
      );
    } else {
      paint.color = MithaqColors.mint.withValues(alpha: 0.35);
      canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.4),
        size.width * 0.45,
        paint,
      );
      paint.color = MithaqColors.navy.withValues(alpha: 0.35);
      canvas.drawCircle(
        Offset(size.width * 0.35, size.height * 0.65),
        size.width * 0.35,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
