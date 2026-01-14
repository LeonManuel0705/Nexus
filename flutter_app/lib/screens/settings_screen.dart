import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../providers/iserv_provider.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _abWeeksEnabled = true;
  String? _weatherCity;
  double? _weatherLat;
  double? _weatherLon;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _abWeeksEnabled = prefs.getBool('ab_weeks_enabled') ?? true;
      _weatherCity = prefs.getString('weather_city');
      _weatherLat = prefs.getDouble('weather_lat');
      _weatherLon = prefs.getDouble('weather_lon');
    });
  }

  Future<void> _saveAbWeeksSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ab_weeks_enabled', value);
    setState(() => _abWeeksEnabled = value);
  }

  Future<void> _saveWeatherLocation(String city, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_city', city);
    await prefs.setDouble('weather_lat', lat);
    await prefs.setDouble('weather_lon', lon);
    setState(() {
      _weatherCity = city;
      _weatherLat = lat;
      _weatherLon = lon;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NexusTheme.primaryColor.withOpacity(0.15),
                    NexusTheme.secondaryColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [NexusTheme.primaryColor, NexusTheme.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Einstellungen',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Konfiguriere deinen Nexus Hub',
                          style: TextStyle(
                            color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildSectionTitle(context, 'Erscheinungsbild', Icons.palette),
            _buildCard(
              isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: provider.themeMode == ThemeMode.dark ? 'Aktiviert' : 'Deaktiviert',
                  value: provider.themeMode == ThemeMode.dark,
                  onChanged: (_) => provider.toggleTheme(),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Stundenplan', Icons.school),
            _buildCard(
              isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.swap_horiz,
                  title: 'A/B-Wochen',
                  subtitle: _abWeeksEnabled
                      ? 'Wechselnde Stundenpläne aktiv'
                      : 'Manche Schulen haben wechselnde A/B-Wochen',
                  value: _abWeeksEnabled,
                  onChanged: _saveAbWeeksSetting,
                  isDark: isDark,
                ),
                if (_abWeeksEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NexusTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: NexusTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Du kannst im Schul-Tab zwischen A und B-Woche wechseln.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? NexusTheme.darkTextSecondary : NexusTheme.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Wetter', Icons.wb_sunny),
            _buildCard(
              isDark,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NexusTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_on, color: NexusTheme.warning, size: 20),
                  ),
                  title: const Text('Standort'),
                  subtitle: Text(_weatherCity ?? 'Nicht festgelegt'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _showLocationDialog(context),
                        child: const Text('Ändern'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _autoDetectLocation(context),
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Auto-erkennen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'IServ-Konto', Icons.school),
            Consumer<IServProvider>(
              builder: (context, iservProvider, child) {
                return _buildCard(
                  isDark,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iservProvider.isConnected
                              ? NexusTheme.success.withOpacity(0.1)
                              : NexusTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          iservProvider.isConnected ? Icons.check_circle : Icons.link,
                          color: iservProvider.isConnected ? NexusTheme.success : NexusTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(iservProvider.isConnected ? 'Verbunden' : 'Nicht verbunden'),
                      subtitle: Text(iservProvider.isConnected
                          ? 'IServ-Konto aktiv'
                          : 'Verbinde dein Schulkonto'),
                      trailing: iservProvider.isConnected
                          ? TextButton(
                              onPressed: () => _confirmDisconnectIServ(context, iservProvider),
                              style: TextButton.styleFrom(foregroundColor: NexusTheme.danger),
                              child: const Text('Trennen'),
                            )
                          : FilledButton(
                              onPressed: () => _showIServLoginDialog(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: NexusTheme.primaryColor,
                              ),
                              child: const Text('Verbinden'),
                            ),
                    ),
                    if (iservProvider.isConnected)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFeatureChip('Stundenplan', Icons.calendar_today),
                            _buildFeatureChip('E-Mail', Icons.email),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Google-Konten', Icons.account_circle),
            _buildCard(
              isDark,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_circle, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Verbundene Konten'),
                  subtitle: const Text('Für Kalender & E-Mail'),
                  trailing: FilledButton.icon(
                    onPressed: () => _showGoogleConnectInfo(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Verbinden'),
                    style: FilledButton.styleFrom(
                      backgroundColor: NexusTheme.primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Google-Konten werden bald unterstützt',
                            style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Daten', Icons.storage),
            _buildCard(
              isDark,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NexusTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.task_alt, color: NexusTheme.primaryColor, size: 20),
                  ),
                  title: const Text('Aufgaben'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: NexusTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.tasks.length}',
                      style: TextStyle(
                        color: NexusTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NexusTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.event, color: NexusTheme.secondaryColor, size: 20),
                  ),
                  title: const Text('Termine'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: NexusTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.events.length}',
                      style: TextStyle(
                        color: NexusTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NexusTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.school, color: NexusTheme.accentColor, size: 20),
                  ),
                  title: const Text('Stundenplan-Einträge'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: NexusTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.lessons.length}',
                      style: TextStyle(
                        color: NexusTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Gefahrenzone', Icons.warning, isWarning: true),
            Container(
              decoration: BoxDecoration(
                color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NexusTheme.danger.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NexusTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete_sweep, color: NexusTheme.warning, size: 20),
                    ),
                    title: const Text('Erledigte Aufgaben löschen'),
                    subtitle: const Text('Entfernt alle abgeschlossenen Aufgaben'),
                    onTap: () => _showDeleteCompletedDialog(context, provider),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NexusTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete_forever, color: NexusTheme.danger, size: 20),
                    ),
                    title: const Text('Alle Daten löschen'),
                    subtitle: const Text('Setzt die App auf Werkseinstellungen zurück'),
                    onTap: () => _showResetDialog(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(context, 'Über Nexus', Icons.info),
            _buildCard(
              isDark,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: NexusTheme.primaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hub, color: Colors.white, size: 20),
                  ),
                  title: const Text('Version'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          NexusTheme.primaryColor.withOpacity(0.2),
                          NexusTheme.secondaryColor.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '0.1 beta',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person, color: Colors.purple, size: 20),
                  ),
                  title: const Text('Entwickler'),
                  trailing: const Text('Leon Manuel Töpper'),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: NexusTheme.primaryGradient,
                        ).createShader(bounds),
                        child: const Text(
                          'Nexus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dein persönliches Organisations-Hub',
                        style: TextStyle(
                          color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zentralisiert. Zuverlässig. Effizient.',
                        style: TextStyle(
                          color: isDark ? NexusTheme.darkTextSecondary : NexusTheme.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isWarning ? NexusTheme.danger : NexusTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isWarning ? NexusTheme.danger : NexusTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NexusTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: NexusTheme.primaryColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: NexusTheme.primaryColor,
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NexusTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NexusTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: NexusTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    final controller = TextEditingController(text: _weatherCity ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standort festlegen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Stadt',
            hintText: 'z.B. Berlin',
            prefixIcon: Icon(Icons.location_city),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final city = controller.text.trim();
              if (city.isEmpty) return;

              await _saveWeatherLocation(city, 52.52, 13.41);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Standort gesetzt: $city')),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoDetectLocation(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Standort-Erkennung wird bald unterstützt')),
    );
  }

  void _showIServLoginDialog(BuildContext context) {
    final urlController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mit IServ verbinden'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'IServ-URL',
                    hintText: 'z.B. gymnasium-berlin.de',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Benutzername',
                    hintText: 'z.B. max.mustermann',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NexusTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: NexusTheme.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: TextStyle(color: NexusTheme.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (urlController.text.trim().isEmpty ||
                          usernameController.text.trim().isEmpty ||
                          passwordController.text.isEmpty) {
                        setDialogState(() => error = 'Bitte alle Felder ausfüllen');
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                        error = null;
                      });

                      try {
                        final provider = context.read<IServProvider>();
                        final result = await provider.connect(
                          username: usernameController.text.trim(),
                          password: passwordController.text,
                          iservUrl: urlController.text.trim(),
                        );

                        if (context.mounted) {
                          if (result['success'] == true) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('IServ erfolgreich verbunden')),
                            );
                          } else {
                            setDialogState(() {
                              error = result['error'] ?? 'Anmeldung fehlgeschlagen';
                              isLoading = false;
                            });
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          error = 'Verbindungsfehler: ${e.toString()}';
                          isLoading = false;
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verbinden'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDisconnectIServ(BuildContext context, IServProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IServ trennen?'),
        content: const Text('Möchtest du die Verbindung zu IServ wirklich trennen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NexusTheme.danger),
            onPressed: () {
              provider.disconnect();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('IServ getrennt')),
              );
            },
            child: const Text('Trennen'),
          ),
        ],
      ),
    );
  }

  void _showGoogleConnectInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google-Konten werden bald unterstützt')),
    );
  }

  void _showDeleteCompletedDialog(BuildContext context, AppProvider provider) {
    final completedTasks = provider.tasks.where((t) => t.completed).toList();

    if (completedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine erledigten Aufgaben vorhanden')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erledigte Aufgaben löschen?'),
        content: Text('Möchtest du ${completedTasks.length} erledigte Aufgaben endgültig löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NexusTheme.warning),
            onPressed: () async {
              Navigator.pop(context);
              for (final task in completedTasks) {
                await provider.deleteTask(task.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${completedTasks.length} Aufgaben gelöscht')),
                );
              }
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Daten löschen?'),
        content: const Text(
          'Dies kann nicht rückgängig gemacht werden. '
          'Alle Aufgaben, Termine und Stundenplan-Einträge werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NexusTheme.danger),
            onPressed: () async {
              Navigator.pop(context);

              for (final task in List.from(provider.tasks)) {
                await provider.deleteTask(task.id);
              }
              for (final event in List.from(provider.events)) {
                await provider.deleteEvent(event.id);
              }
              for (final lesson in List.from(provider.lessons)) {
                await provider.deleteLesson(lesson.id);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alle Daten wurden gelöscht')),
                );
              }
            },
            child: const Text('Alle Daten löschen'),
          ),
        ],
      ),
    );
  }
}
