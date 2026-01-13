import 'package:flutter/material.dart';
import '../theme.dart';

class NexusDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final VoidCallback onClose;

  const NexusDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark
          ? const Color(0xFF12121F)
          : Colors.white,
      child: SafeArea(
        child: Column(
          children: [

            _buildHeader(context, isDark),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NavItem(
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard,
                      label: 'Dashboard',
                      isSelected: currentIndex == 0,
                      onTap: () => _navigate(context, 0),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(label: 'ALLTAG'),

                    _NavItem(
                      icon: Icons.task_alt_outlined,
                      selectedIcon: Icons.task_alt,
                      label: 'Aufgaben',
                      isSelected: currentIndex == 1,
                      onTap: () => _navigate(context, 1),
                    ),
                    _NavItem(
                      icon: Icons.timer_outlined,
                      selectedIcon: Icons.timer,
                      label: 'Pomodoro',
                      isSelected: currentIndex == 5,
                      onTap: () => _navigate(context, 5),
                    ),
                    _NavItem(
                      icon: Icons.calendar_today_outlined,
                      selectedIcon: Icons.calendar_today,
                      label: 'Kalender',
                      isSelected: currentIndex == 2,
                      onTap: () => _navigate(context, 2),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(label: 'BEREICHE'),

                    _NavItem(
                      icon: Icons.school_outlined,
                      selectedIcon: Icons.school,
                      label: 'Schule',
                      isSelected: currentIndex == 3,
                      onTap: () => _navigate(context, 3),
                    ),
                    _NavItem(
                      icon: Icons.fitness_center_outlined,
                      selectedIcon: Icons.fitness_center,
                      label: 'Training',
                      isSelected: currentIndex == 6,
                      onTap: () => _navigate(context, 6),
                    ),
                    _NavItem(
                      icon: Icons.folder_outlined,
                      selectedIcon: Icons.folder,
                      label: 'Projekte',
                      isSelected: currentIndex == 7,
                      onTap: () => _navigate(context, 7),
                    ),
                    _NavItem(
                      icon: Icons.menu_book_outlined,
                      selectedIcon: Icons.menu_book,
                      label: 'Wissen',
                      isSelected: currentIndex == 8,
                      onTap: () => _navigate(context, 8),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(label: 'SYSTEM'),

                    _NavItem(
                      icon: Icons.email_outlined,
                      selectedIcon: Icons.email,
                      label: 'E-Mail',
                      isSelected: currentIndex == 9,
                      onTap: () => _navigate(context, 9),
                    ),
                    _NavItem(
                      icon: Icons.show_chart_outlined,
                      selectedIcon: Icons.show_chart,
                      label: 'Review',
                      isSelected: currentIndex == 10,
                      onTap: () => _navigate(context, 10),
                    ),
                    _NavItem(
                      icon: Icons.brush_outlined,
                      selectedIcon: Icons.brush,
                      label: 'Mousepad',
                      isSelected: currentIndex == 11,
                      onTap: () => _navigate(context, 11),
                    ),
                    _NavItem(
                      icon: Icons.chat_outlined,
                      selectedIcon: Icons.chat,
                      label: 'Assistent',
                      isSelected: currentIndex == 12,
                      onTap: () => _navigate(context, 12),
                    ),
                    _NavItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Einstellungen',
                      isSelected: currentIndex == 13,
                      onTap: () => _navigate(context, 13),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            _buildFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          // Nexus logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/nexus-logo.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Gradient text "Nexus"
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: NexusTheme.primaryGradient,
                ).createShader(bounds),
                child: const Text(
                  'Nexus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NexusTheme.primaryColor.withOpacity(0.2),
                      NexusTheme.secondaryColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '0.1 closed beta',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : NexusTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© Made with ',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: NexusTheme.primaryGradient,
                ).createShader(bounds),
                child: const Icon(
                  Icons.favorite,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              Text(
                ' by Leon Töpper :-)',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);
    onNavigate(index);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(

              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: NexusTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : NexusTheme.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
