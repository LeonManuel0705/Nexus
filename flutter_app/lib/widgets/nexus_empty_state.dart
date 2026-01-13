import 'package:flutter/material.dart';
import '../theme.dart';

class NexusEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isCompact;
  final Color? iconColor;

  const NexusEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isCompact = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1));

    if (isCompact) {
      return _buildCompact(context, color, isDark);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }

  static Widget noTasks({VoidCallback? onAdd}) {
    return NexusEmptyState(
      icon: Icons.task_alt,
      title: 'Keine Aufgaben',
      message: 'Füge deine erste Aufgabe hinzu',
      actionLabel: onAdd != null ? 'Aufgabe hinzufügen' : null,
      onAction: onAdd,
    );
  }

  static Widget noEvents({VoidCallback? onAdd}) {
    return NexusEmptyState(
      icon: Icons.event,
      title: 'Keine Termine',
      message: 'Erstelle einen neuen Termin',
      actionLabel: onAdd != null ? 'Termin hinzufügen' : null,
      onAction: onAdd,
    );
  }

  static Widget noResults() {
    return const NexusEmptyState(
      icon: Icons.search_off,
      title: 'Keine Ergebnisse',
      message: 'Versuche eine andere Suche',
      isCompact: true,
    );
  }

  static Widget offline() {
    return const NexusEmptyState(
      icon: Icons.cloud_off,
      title: 'Offline',
      message: 'Du bist offline. Einige Funktionen sind eingeschränkt.',
      isCompact: true,
    );
  }

  static Widget error({String? message, VoidCallback? onRetry}) {
    return NexusEmptyState(
      icon: Icons.error_outline,
      title: 'Fehler',
      message: message ?? 'Etwas ist schief gelaufen',
      actionLabel: onRetry != null ? 'Erneut versuchen' : null,
      onAction: onRetry,
      iconColor: NexusTheme.error,
    );
  }

  static Widget loading({String? message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message),
          ],
        ],
      ),
    );
  }
}
