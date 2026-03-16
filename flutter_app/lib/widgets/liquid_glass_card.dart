import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

/// Liquid Glass style card — visible refraction, specular highlights,
/// edge lighting, and depth. Distinct from standard glassmorphism.
class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final Color? tint;
  final bool enableTapScale;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 24,
    this.tint,
    this.enableTapScale = true,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
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
    final hasTap = widget.onTap != null || widget.onLongPress != null;
    final shouldAnimate = widget.enableTapScale && hasTap;

    // Outer glow shadow for the "floating glass" look
    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          // Colored ambient glow
          BoxShadow(
            color: (widget.tint ?? const Color(0xFF6366F1)).withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
          // Dark depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: shouldUseBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: CustomPaint(
                  painter: _LiquidGlassPainter(
                    isDark: isDark,
                    borderRadius: widget.borderRadius,
                    tint: widget.tint,
                  ),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ),
              )
            : CustomPaint(
                painter: _LiquidGlassPainter(
                  isDark: isDark,
                  borderRadius: widget.borderRadius,
                  tint: widget.tint,
                ),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
      ),
    );

    if (hasTap) {
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

class _LiquidGlassPainter extends CustomPainter {
  final bool isDark;
  final double borderRadius;
  final Color? tint;

  _LiquidGlassPainter({
    required this.isDark,
    required this.borderRadius,
    this.tint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1) Base fill — elevated surface with slight color
    final baseFill = Paint()
      ..color = isDark
          ? (tint ?? const Color(0xFF1e1e2e)).withValues(alpha: 0.7)
          : (tint ?? const Color(0xFFf8f8ff)).withValues(alpha: 0.65);
    canvas.drawRRect(rrect, baseFill);

    // 2) Gradient overlay — the "liquid" refraction look
    //    Top-left is lighter (light entering), bottom-right is darker (shadow side)
    final liquidGradient = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1.0, -1.0),
        end: const Alignment(1.0, 1.0),
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.03),
              ]
            : [
                Colors.white.withValues(alpha: 0.8),
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.2),
              ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, liquidGradient);

    // 3) Specular highlight — bright spot top-left, like light hitting curved glass
    canvas.save();
    canvas.clipRRect(rrect);
    final specular = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, -0.8),
        radius: 1.0,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.06),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.2),
                Colors.transparent,
              ],
        stops: const [0.0, 0.35, 0.8],
      ).createShader(rect);
    canvas.drawRect(rect, specular);

    // 4) Secondary specular — subtle bottom-right reflection (caustic)
    final caustic = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.9),
        radius: 0.8,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.06),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.15),
                Colors.transparent,
              ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, caustic);
    canvas.restore();

    // 5) Edge highlight border — gradient stroke, bright top-left to dim bottom-right
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.40),
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.20),
              ]
            : [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.4),
              ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, borderPaint);

    // 6) Inner border line — very subtle secondary edge for glass thickness
    final innerRRect = RRect.fromRectAndRadius(
      rect.deflate(1.5),
      Radius.circular(borderRadius - 1.5),
    );
    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.12),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.06),
              ]
            : [
                Colors.white.withValues(alpha: 0.6),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.2),
              ],
      ).createShader(rect);
    canvas.drawRRect(innerRRect, innerBorder);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) {
    return isDark != oldDelegate.isDark ||
        borderRadius != oldDelegate.borderRadius ||
        tint != oldDelegate.tint;
  }
}
