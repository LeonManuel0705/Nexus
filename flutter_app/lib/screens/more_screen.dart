import 'package:flutter/material.dart';
import '../theme.dart';
import 'training_screen.dart';
import 'pomodoro_screen.dart';
import 'projects_screen.dart';
import 'knowledge_screen.dart';
import 'email_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'mousepad_screen.dart';
import 'bookmarks_screen.dart';
import 'notes_screen.dart';
import 'assistant_screen.dart';
import 'iserv_screen.dart';
import 'vbb_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Mehr',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Alle Funktionen auf einen Blick',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        Text(
          'Produktivität',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.timer,
              label: 'Pomodoro',
              description: 'Fokus-Timer',
              color: NexusTheme.pomodoroColor,
              onTap: () => _navigateTo(context, const PomodoroScreen(), 'Pomodoro'),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.folder_special,
              label: 'Projekte',
              description: 'Projektmanagement',
              color: NexusTheme.projectsColor,
              onTap: () => _navigateTo(context, const ProjectsScreen(), 'Projekte'),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.auto_stories,
              label: 'Wissen',
              description: 'Wissensbasis',
              color: NexusTheme.knowledgeColor,
              onTap: () => _navigateTo(context, const KnowledgeScreen(), 'Wissen'),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.rate_review,
              label: 'Review',
              description: 'Tages-Reflexion',
              color: NexusTheme.reviewColor,
              onTap: () => _navigateTo(context, const ReviewScreen(), 'Review'),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          'Tools',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.draw,
              label: 'Zeichnen',
              description: 'Mousepad',
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MousepadScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.bookmark,
              label: 'Lesezeichen',
              description: 'Links speichern',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarksScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.sticky_note_2,
              label: 'Notizen',
              description: 'Schnelle Notizen',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.smart_toy,
              label: 'Assistent',
              description: 'KI-Hilfe offline',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssistantScreen()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          'Schule & Bildung',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        _buildLargeFeatureCard(
          context,
          icon: Icons.school,
          label: 'IServ',
          description: 'Schulplattform & Aufgaben',
          color: const Color(0xFF059669),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IServScreen()),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Transport',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        _buildLargeFeatureCard(
          context,
          icon: Icons.directions_transit,
          label: 'VBB Fahrinfo',
          description: 'Öffentlicher Nahverkehr Berlin',
          color: const Color(0xFFDC2626),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VbbScreen()),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Fitness & Gesundheit',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        _buildLargeFeatureCard(
          context,
          icon: Icons.fitness_center,
          label: 'Training',
          description: 'Workouts & Trainingsplan',
          color: NexusTheme.trainingColor,
          onTap: () => _navigateTo(context, const TrainingScreen(), 'Training'),
        ),

        const SizedBox(height: 24),

        Text(
          'Kommunikation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        _buildLargeFeatureCard(
          context,
          icon: Icons.email,
          label: 'E-Mail',
          description: 'Schnellzugriff auf E-Mail-Konten',
          color: NexusTheme.emailColor,
          onTap: () => _navigateTo(context, const EmailScreen(), 'E-Mail'),
        ),

        const SizedBox(height: 24),

        Text(
          'Einstellungen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NexusTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings, color: NexusTheme.primaryColor),
                ),
                title: const Text('Einstellungen'),
                subtitle: const Text('App-Konfiguration'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _navigateTo(context, const SettingsScreen(), 'Einstellungen'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NexusTheme.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: NexusTheme.info),
                ),
                title: const Text('Über Nexus'),
                subtitle: const Text('Version 0.1 closed beta'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark
                    ? NexusTheme.darkTextMuted
                    : NexusTheme.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: SafeArea(child: screen),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: NexusTheme.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Nexus'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Personal Productivity Hub'),
            const SizedBox(height: 16),
            _buildInfoRow('Version', '0.1 closed beta'),
            _buildInfoRow('Entwickler', 'Leon Manuel Töpper'),
            _buildInfoRow('Plattform', 'Flutter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
