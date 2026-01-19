import 'dart:ui';
import 'package:flutter/material.dart';

class NexusBackground extends StatefulWidget {
  final Widget child;

  const NexusBackground({super.key, required this.child});

  @override
  State<NexusBackground> createState() => _NexusBackgroundState();
}

class _NexusBackgroundState extends State<NexusBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  static const Color _accent1 = Color(0xFF667EEA);
  static const Color _accent2 = Color(0xFF764BA2);
  static const Color _accent3 = Color(0xFFF093FB);

  static const Color _darkBg = Color(0xFF0F0F1A);
  static const Color _lightBg = Color(0xFFFAFBFC);

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _controller2 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _controller2.value = 0.35;
    _controller2.repeat();

    _controller3 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _controller3.value = 0.70;
    _controller3.repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  Offset _getTranslation(double t) {
    if (t < 0.25) {
      final progress = t / 0.25;
      return Offset(30 * progress, -30 * progress);
    } else if (t < 0.5) {
      final progress = (t - 0.25) / 0.25;
      return Offset(30 - 50 * progress, -30 + 50 * progress);
    } else if (t < 0.75) {
      final progress = (t - 0.5) / 0.25;
      return Offset(-20 - 10 * progress, 20 - 40 * progress);
    } else {
      final progress = (t - 0.75) / 0.25;
      return Offset(-30 + 30 * progress, -20 + 20 * progress);
    }
  }

  double _getScale(double t) {
    if (t < 0.25) {
      return 1.0 + 0.05 * (t / 0.25);
    } else if (t < 0.5) {
      return 1.05 - 0.10 * ((t - 0.25) / 0.25);
    } else if (t < 0.75) {
      return 0.95 + 0.07 * ((t - 0.5) / 0.25);
    } else {
      return 1.02 - 0.02 * ((t - 0.75) / 0.25);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orbOpacity = isDark ? 0.25 : 0.4;

    return Stack(
      children: [
        Container(color: isDark ? _darkBg : _lightBg),

        AnimatedBuilder(
          animation: Listenable.merge([_controller1, _controller2, _controller3]),
          builder: (context, child) {
            return CustomPaint(
              painter: _OrbsPainter(
                orbs: [
                  _OrbData(
                    size: 600,
                    baseOffset: const Offset(100, -200),
                    anchorTopRight: true,
                    colors: [_accent1, _accent2],
                    translation: _getTranslation(_controller1.value),
                    scale: _getScale(_controller1.value),
                  ),
                  _OrbData(
                    size: 500,
                    baseOffset: const Offset(-100, 150),
                    anchorBottomLeft: true,
                    colors: [_accent2, _accent3],
                    translation: _getTranslation(_controller2.value),
                    scale: _getScale(_controller2.value),
                  ),
                  _OrbData(
                    size: 400,
                    baseOffset: Offset.zero,
                    anchorCenter: true,
                    colors: [_accent3, _accent1],
                    translation: _getTranslation(_controller3.value),
                    scale: _getScale(_controller3.value),
                  ),
                ],
                opacity: orbOpacity,
                blurSigma: 40,
              ),
              size: Size.infinite,
            );
          },
        ),

        widget.child,
      ],
    );
  }
}

class _OrbData {
  final double size;
  final Offset baseOffset;
  final bool anchorTopRight;
  final bool anchorBottomLeft;
  final bool anchorCenter;
  final List<Color> colors;
  final Offset translation;
  final double scale;

  _OrbData({
    required this.size,
    required this.baseOffset,
    this.anchorTopRight = false,
    this.anchorBottomLeft = false,
    this.anchorCenter = false,
    required this.colors,
    required this.translation,
    required this.scale,
  });
}

class _OrbsPainter extends CustomPainter {
  final List<_OrbData> orbs;
  final double opacity;
  final double blurSigma;

  _OrbsPainter({
    required this.orbs,
    required this.opacity,
    required this.blurSigma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final scaledSize = orb.size * orb.scale;
      final radius = scaledSize / 2;

      Offset center;
      if (orb.anchorTopRight) {
        center = Offset(
          size.width + orb.baseOffset.dx + orb.translation.dx,
          orb.baseOffset.dy + radius + orb.translation.dy,
        );
      } else if (orb.anchorBottomLeft) {
        center = Offset(
          orb.baseOffset.dx + radius + orb.translation.dx,
          size.height + orb.baseOffset.dy + orb.translation.dy,
        );
      } else if (orb.anchorCenter) {
        center = Offset(
          size.width / 2 + orb.translation.dx,
          size.height / 2 + orb.translation.dy,
        );
      } else {
        center = orb.baseOffset + orb.translation;
      }

      final gradient = RadialGradient(
        colors: [
          orb.colors[0].withOpacity(opacity),
          orb.colors[1].withOpacity(opacity * 0.6),
          orb.colors[1].withOpacity(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbsPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.blurSigma != blurSigma ||
        !_orbsEqual(oldDelegate.orbs, orbs);
  }

  bool _orbsEqual(List<_OrbData> a, List<_OrbData> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].translation != b[i].translation || a[i].scale != b[i].scale) {
        return false;
      }
    }
    return true;
  }
}
