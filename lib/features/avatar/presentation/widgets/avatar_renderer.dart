import 'package:flutter/material.dart';
import '../../domain/avatar_config.dart';
import '../../../../core/theme/design_system.dart';

class AvatarRenderer extends StatelessWidget {
  final AvatarConfig config;
  final double size;

  const AvatarRenderer({super.key, required this.config, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MithaqColors.pink.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _AvatarPainter(config: config),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final AvatarConfig config;

  _AvatarPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = size.width * 0.35;

    final Paint skinPaint = Paint()..color = _getSkinColor(config.skinTone);
    final Paint featurePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Head Shape
    _drawHead(
      canvas,
      center,
      size.height * 0.45,
      radius,
      config.faceShape,
      skinPaint,
    );

    // Style elements (Hair/Hijab)
    _drawHeadStyle(
      canvas,
      center,
      size.height * 0.45,
      radius,
      config.headStyle,
      config.gender,
    );

    // Minimalistic Features (Eyes)
    canvas.drawCircle(
      Offset(center - radius * 0.3, size.height * 0.45),
      radius * 0.08,
      featurePaint,
    );
    canvas.drawCircle(
      Offset(center + radius * 0.3, size.height * 0.45),
      radius * 0.08,
      featurePaint,
    );
  }

  void _drawHead(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    FaceShape shape,
    Paint paint,
  ) {
    switch (shape) {
      case FaceShape.oval:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: r * 2,
            height: r * 2.4,
          ),
          paint,
        );
      case FaceShape.round:
        canvas.drawCircle(Offset(cx, cy), r * 1.1, paint);
      case FaceShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: r * 2,
              height: r * 2.2,
            ),
            Radius.circular(r * 0.4),
          ),
          paint,
        );
    }
  }

  void _drawHeadStyle(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    HeadStyle style,
    Gender gender,
  ) {
    final Paint hairPaint = Paint()..color = const Color(0xFF333333);
    final Paint hijabPaint = Paint()
      ..color = MithaqColors.navy.withValues(alpha: 0.8);

    if (style == HeadStyle.hijab) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy - r * 0.2),
          width: r * 2.4,
          height: r * 2.8,
        ),
        hijabPaint,
      );
      // Face opening
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + r * 0.1),
          width: r * 1.6,
          height: r * 2.0,
        ),
        Paint()..color = _getSkinColor(config.skinTone),
      );
    } else if (style == HeadStyle.shortHair) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: r * 2.1,
          height: r * 2.5,
        ),
        3.14,
        3.14,
        true,
        hairPaint,
      );
    } else if (style == HeadStyle.longHair) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy + r * 0.5),
            width: r * 2.3,
            height: r * 2.8,
          ),
          Radius.circular(r),
        ),
        hairPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: r * 2.1,
          height: r * 2.5,
        ),
        3.14,
        3.14,
        true,
        hairPaint,
      );
    } else if (style == HeadStyle.beard) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy + r * 0.3),
          width: r * 1.9,
          height: r * 1.5,
        ),
        0,
        3.14,
        true,
        hairPaint,
      );
    }
  }

  Color _getSkinColor(SkinTone tone) {
    switch (tone) {
      case SkinTone.light:
        return const Color(0xFFFFDBAC);
      case SkinTone.medium:
        return const Color(0xFFF1C27D);
      case SkinTone.tan:
        return const Color(0xFFE0AC69);
      case SkinTone.mediumDeep:
        return const Color(0xFF8D5524);
      case SkinTone.deep:
        return const Color(0xFF5D3117);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
