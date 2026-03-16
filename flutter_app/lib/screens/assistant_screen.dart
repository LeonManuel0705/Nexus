import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_fade_in.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageFadeIn(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: NexusTheme.gradientText('Assistent', fontSize: 36),
          ),
          const SizedBox(height: 4),

          // "In Development" wall
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NexusTheme.primaryColor.withValues(alpha: 0.15),
                            NexusTheme.secondary.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        size: 48,
                        color: NexusTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'In Entwicklung',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Der KI-Assistent wird aktuell überarbeitet und ist bald mit neuen Funktionen verfügbar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Diese Funktion ist noch nicht verfügbar.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
