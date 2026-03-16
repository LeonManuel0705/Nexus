import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final double blurSigma;
  final Color? tint;
  final bool hasBorder;
  final bool hasShadow;
  final bool enableTapScale;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 24,
    this.blurSigma = 12,
    this.tint,
    this.hasBorder = true,
    this.hasShadow = true,
    this.enableTapScale = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTapHandler = widget.onTap != null || widget.onLongPress != null;
    final shouldAnimate = widget.enableTapScale && hasTapHandler;

    final cardDecoration = BoxDecoration(
      color: isDark
          ? (widget.tint ?? Colors.black).withValues(alpha: shouldUseBlur ? 0.40 : 0.60)
          : (widget.tint ?? Colors.white).withValues(alpha: shouldUseBlur ? 0.40 : 0.60),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: widget.hasBorder
          ? Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.20),
              width: 1,
            )
          : null,
      boxShadow: widget.hasShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: shouldUseBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(16),
                decoration: cardDecoration,
                child: widget.child,
              ),
            )
          : Container(
              padding: widget.padding ?? const EdgeInsets.all(16),
              decoration: cardDecoration,
              child: widget.child,
            ),
    );

    if (hasTapHandler) {
      if (shouldAnimate) {
        content = AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onTapDown: (_) => _scaleController.forward(),
              onTapUp: (_) => _scaleController.reverse(),
              onTapCancel: () => _scaleController.reverse(),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: content,
            ),
          ),
        );
      } else {
        content = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: content,
          ),
        );
      }
    }

    return Container(margin: widget.margin, child: content);
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? tint;
  final BoxBorder? border;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.blurSigma = 12,
    this.tint,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerDecoration = BoxDecoration(
      color: gradient == null
          ? (isDark
              ? (tint ?? Colors.black).withValues(alpha: shouldUseBlur ? 0.40 : 0.60)
              : (tint ?? Colors.white).withValues(alpha: shouldUseBlur ? 0.40 : 0.60))
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ??
          Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
    );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: shouldUseBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  padding: padding,
                  decoration: containerDecoration,
                  child: child,
                ),
              )
            : Container(
                padding: padding,
                decoration: containerDecoration,
                child: child,
              ),
      ),
    );
  }
}
