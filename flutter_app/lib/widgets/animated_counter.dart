import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String? suffix;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.suffix,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        final display = decimals > 0
            ? animValue.toStringAsFixed(decimals)
            : animValue.round().toString();
        return Text(
          suffix != null ? '$display$suffix' : display,
          style: style ?? Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        );
      },
    );
  }
}
