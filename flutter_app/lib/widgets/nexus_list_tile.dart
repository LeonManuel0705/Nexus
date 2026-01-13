import 'package:flutter/material.dart';
import '../theme.dart';

class NexusListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Color? swipeLeftColor;
  final Color? swipeRightColor;
  final IconData? swipeLeftIcon;
  final IconData? swipeRightIcon;
  final String? swipeLeftLabel;
  final String? swipeRightLabel;
  final bool isSelected;
  final EdgeInsetsGeometry? contentPadding;

  const NexusListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeLeftColor,
    this.swipeRightColor,
    this.swipeLeftIcon,
    this.swipeRightIcon,
    this.swipeLeftLabel,
    this.swipeRightLabel,
    this.isSelected = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget listTile = Container(
      decoration: BoxDecoration(
        color: isSelected
            ? NexusTheme.primary.withOpacity(0.1)
            : (isDark ? NexusTheme.darkCard : NexusTheme.lightCard),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: NexusTheme.primary.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (onSwipeLeft != null || onSwipeRight != null) {
      listTile = Dismissible(
        key: Key(title),
        background: onSwipeRight != null
            ? _buildSwipeBackground(
                alignment: Alignment.centerLeft,
                color: swipeRightColor ?? NexusTheme.success,
                icon: swipeRightIcon ?? Icons.check,
                label: swipeRightLabel,
              )
            : null,
        secondaryBackground: onSwipeLeft != null
            ? _buildSwipeBackground(
                alignment: Alignment.centerRight,
                color: swipeLeftColor ?? NexusTheme.error,
                icon: swipeLeftIcon ?? Icons.delete,
                label: swipeLeftLabel,
              )
            : null,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd && onSwipeRight != null) {
            onSwipeRight!();
            return false;
          } else if (direction == DismissDirection.endToStart && onSwipeLeft != null) {
            onSwipeLeft!();
            return false;
          }
          return false;
        },
        child: listTile,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: listTile,
    );
  }

  Widget _buildSwipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    String? label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: color),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ] else ...[
            if (label != null) ...[
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
            ],
            Icon(icon, color: color),
          ],
        ],
      ),
    );
  }
}

class NexusCheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color? activeColor;

  const NexusCheckboxTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            decoration: value ? TextDecoration.lineThrough : null,
            color: value
                ? (isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)
                : null,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? NexusTheme.primary,
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
