import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_system.dart';
import '../design_tokens.dart';

/// A soft-styled icon container for visual emphasis.
class MithaqSoftIcon extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double padding;

  const MithaqSoftIcon({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = MithaqIconSize.m,
    this.padding = MithaqSpacing.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? MithaqColors.mint.withValues(alpha: 0.15),
        borderRadius: MithaqRadius.medium,
      ),
      child: Icon(icon, color: iconColor ?? MithaqColors.navy, size: size),
    );
  }
}

/// A polished icon button with subtle press animation and haptic feedback.
class MithaqIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const MithaqIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 24,
  });

  @override
  State<MithaqIconButton> createState() => _MithaqIconButtonState();
}

class _MithaqIconButtonState extends State<MithaqIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MithaqDurations.fast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(MithaqSpacing.s),
          decoration: BoxDecoration(
            color:
                widget.backgroundColor ??
                MithaqColors.navy.withValues(alpha: 0.06),
            borderRadius: MithaqRadius.medium,
            border: Border.all(
              color: MithaqColors.navy.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.color ?? MithaqColors.navy,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
