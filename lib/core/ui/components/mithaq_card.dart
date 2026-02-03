import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_system.dart';
import '../design_tokens.dart';

/// A polished, interactive card component with subtle press animation
/// and optional haptic feedback for a premium feel.
class MithaqCard extends StatefulWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final bool enableHaptics;

  const MithaqCard({
    super.key,
    this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.color,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.enableHaptics = true,
  });

  @override
  State<MithaqCard> createState() => _MithaqCardState();
}

class _MithaqCardState extends State<MithaqCard>
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
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(MithaqSpacing.m),
      decoration: BoxDecoration(
        color: widget.color ?? Theme.of(context).cardColor,
        borderRadius: widget.borderRadius ?? MithaqRadius.large,
        border:
            widget.border ??
            Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? MithaqColors.navy.withValues(alpha: 0.08)
                  : MithaqColors.outlineDark,
              width: 1,
            ),
        boxShadow:
            widget.boxShadow ??
            (Theme.of(context).brightness == Brightness.light
                ? MithaqShadows.soft
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ]),
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: cardContent,
      ),
    );
  }
}
