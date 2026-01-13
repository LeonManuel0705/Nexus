import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

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

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _controller2 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _controller3 = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [

        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FA),
          ),
        ),

        AnimatedBuilder(
          animation: Listenable.merge([_controller1, _controller2, _controller3]),
          builder: (context, child) {
            return Stack(
              children: [

                Positioned(
                  top: -150 + 50 * math.sin(_controller1.value * 2 * math.pi),
                  right: -50 + 30 * math.cos(_controller1.value * 2 * math.pi),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          NexusTheme.primaryColor.withOpacity(isDark ? 0.25 : 0.35),
                          NexusTheme.secondaryColor.withOpacity(isDark ? 0.2 : 0.3),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: -100 + 40 * math.sin(_controller2.value * 2 * math.pi + math.pi / 2),
                  left: -80 + 35 * math.cos(_controller2.value * 2 * math.pi),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          NexusTheme.secondaryColor.withOpacity(isDark ? 0.2 : 0.3),
                          NexusTheme.accentColor.withOpacity(isDark ? 0.15 : 0.25),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4 +
                      30 * math.sin(_controller3.value * 2 * math.pi + math.pi),
                  left: MediaQuery.of(context).size.width * 0.3 +
                      25 * math.cos(_controller3.value * 2 * math.pi + math.pi / 4),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          NexusTheme.accentColor.withOpacity(isDark ? 0.15 : 0.25),
                          NexusTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FA))
                .withOpacity(0.3),
          ),
        ),

        widget.child,
      ],
    );
  }
}
