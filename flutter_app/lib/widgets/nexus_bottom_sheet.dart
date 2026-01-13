import 'package:flutter/material.dart';
import '../theme.dart';

class NexusBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final bool showHandle;
  final bool showCloseButton;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  const NexusBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.showHandle = true,
    this.showCloseButton = true,
    this.initialChildSize = 0.6,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.9,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool showHandle = true,
    bool showCloseButton = true,
    double initialChildSize = 0.6,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool isScrollControlled = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => NexusBottomSheet(
        title: title,
        actions: actions,
        showHandle: showHandle,
        showCloseButton: showCloseButton,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkSurface : NexusTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            if (showHandle) _buildHandle(),
            if (title != null || showCloseButton) _buildHeader(context, isDark),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: child,
              ),
            ),
            if (actions != null) _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        showHandle ? 0 : 16,
        showCloseButton ? 8 : 16,
        8,
      ),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (showCloseButton)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: actions!.map((action) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: action,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NexusActionSheet extends StatelessWidget {
  final String? title;
  final List<NexusActionItem> actions;

  const NexusActionSheet({
    super.key,
    this.title,
    required this.actions,
  });

  static Future<void> show({
    required BuildContext context,
    String? title,
    required List<NexusActionItem> actions,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => NexusActionSheet(
        title: title,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? NexusTheme.darkSurface : NexusTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...actions.map((action) => _buildActionTile(context, action, isDark)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, NexusActionItem action, bool isDark) {
    final color = action.isDestructive ? NexusTheme.error : action.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? NexusTheme.primary).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            action.icon,
            color: color ?? NexusTheme.primary,
          ),
        ),
        title: Text(
          action.label,
          style: TextStyle(
            color: action.isDestructive ? NexusTheme.error : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: action.subtitle != null ? Text(action.subtitle!) : null,
        onTap: () {
          Navigator.pop(context);
          action.onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
      ),
    );
  }
}

class NexusActionItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;

  const NexusActionItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.color,
    this.isDestructive = false,
  });
}
