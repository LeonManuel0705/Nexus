import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_provider.dart';
import 'providers/drawing_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/assistant_provider.dart';
import 'providers/iserv_provider.dart';
import 'providers/email_provider.dart';
import 'providers/vbb_provider.dart';
import 'providers/sync_provider.dart';
import 'services/connectivity_service.dart';
import 'services/sync_manager.dart';
import 'services/offline_queue.dart';
import 'services/background_service.dart';
import 'services/database_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/tasks_screen.dart' show TasksScreen, showAddTaskDialog;
import 'screens/calendar_screen.dart' show CalendarScreen, showAddEventDialog;
import 'screens/school_screen.dart' show SchoolScreen, showAddLessonDialog;
import 'screens/more_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/training_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/knowledge_screen.dart';
import 'screens/email_screen.dart';
import 'screens/review_screen.dart';
import 'screens/mousepad_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';
import 'widgets/quick_note_fab.dart';
import 'widgets/connection_indicator.dart';
import 'widgets/nexus_drawer.dart';
import 'widgets/nexus_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await initializeDateFormatting('de_DE', null);

  await ConnectivityService().initialize();
  await SyncManager().initialize();
  await OfflineQueue().initialize();
  await BackgroundService().initialize();
  await BackgroundService().registerTasks();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => DrawingProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
        ChangeNotifierProvider(create: (_) => IServProvider()),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
        ChangeNotifierProvider(create: (_) => VbbProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {

          final isDark = provider.themeMode == ThemeMode.dark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FA),
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ));

          return MaterialApp(
            title: 'Nexus',
            debugShowCheckedModeBanner: false,
            theme: NexusTheme.lightTheme,
            darkTheme: NexusTheme.darkTheme,
            themeMode: provider.themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  bool _hasCheckedFirstLaunch = false;

  static const _bundeslaender = [
    'Baden-Württemberg',
    'Bayern',
    'Berlin',
    'Brandenburg',
    'Bremen',
    'Hamburg',
    'Hessen',
    'Mecklenburg-Vorpommern',
    'Niedersachsen',
    'Nordrhein-Westfalen',
    'Rheinland-Pfalz',
    'Saarland',
    'Sachsen',
    'Sachsen-Anhalt',
    'Schleswig-Holstein',
    'Thüringen',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLaunch());
  }

  Future<void> _checkFirstLaunch() async {
    if (_hasCheckedFirstLaunch) return;
    _hasCheckedFirstLaunch = true;

    final prefs = await SharedPreferences.getInstance();
    final hasSelectedBundesland = prefs.containsKey('user_bundesland');

    if (!hasSelectedBundesland && mounted) {
      _showBundeslandDialog();
    }
  }

  Future<void> _showBundeslandDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BundeslandSelectionDialog(bundeslaender: _bundeslaender),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_bundesland', result);
    }
  }

  final List<Widget> _allScreens = const [
    DashboardScreen(),
    TasksScreen(),
    CalendarScreen(),
    SchoolScreen(),
    MoreScreen(),
    PomodoroScreen(),
    TrainingScreen(),
    ProjectsScreen(),
    KnowledgeScreen(),
    EmailScreen(),
    ReviewScreen(),
    MousepadScreen(),
    AssistantScreen(),
    SettingsScreen(),
  ];

  void _navigateToScreen(int screenIndex) {
    setState(() {
      _currentIndex = screenIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NexusBackground(
      child: ConnectionIndicator(
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: NexusDrawer(
            currentIndex: _currentIndex,
            onNavigate: _navigateToScreen,
            onClose: () => Navigator.pop(context),
          ),
          body: SafeArea(
            child: Column(
              children: [

                _buildAppBar(context, isDark),

                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _allScreens,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFab(),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [

          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            icon: Icon(
              Icons.menu,
              color: isDark ? Colors.white : NexusTheme.lightText,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: () => _navigateToScreen(0),
            child: Row(
              children: [

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/nexus-logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: NexusTheme.primaryGradient,
                  ).createShader(bounds),
                  child: const Text(
                    'Nexus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getScreenTitle(_currentIndex),
              style: TextStyle(
                color: isDark ? Colors.white70 : NexusTheme.lightTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Aufgaben';
      case 2: return 'Kalender';
      case 3: return 'Schule';
      case 4: return 'Mehr';
      case 5: return 'Pomodoro';
      case 6: return 'Training';
      case 7: return 'Projekte';
      case 8: return 'Wissen';
      case 9: return 'E-Mail';
      case 10: return 'Review';
      case 11: return 'Mousepad';
      case 12: return 'Assistent';
      case 13: return 'Einstellungen';
      default: return '';
    }
  }

  Widget _buildFab() {
    return const QuickNoteFab();
  }
}

class _BundeslandSelectionDialog extends StatefulWidget {
  final List<String> bundeslaender;

  const _BundeslandSelectionDialog({required this.bundeslaender});

  @override
  State<_BundeslandSelectionDialog> createState() => _BundeslandSelectionDialogState();
}

class _BundeslandSelectionDialogState extends State<_BundeslandSelectionDialog> {
  String? _selectedBundesland;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: NexusTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Willkommen bei Nexus!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'In welchem Bundesland wohnst du?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wird für Ferien und Feiertage verwendet.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.bundeslaender.length,
          itemBuilder: (context, index) {
            final bundesland = widget.bundeslaender[index];
            final isSelected = _selectedBundesland == bundesland;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? NexusTheme.primaryColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? NexusTheme.primaryColor
                      : Colors.transparent,
                ),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  bundesland,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? NexusTheme.primaryColor : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: NexusTheme.primaryColor, size: 20)
                    : null,
                onTap: () => setState(() => _selectedBundesland = bundesland),
              ),
            );
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _selectedBundesland != null
              ? () => Navigator.pop(context, _selectedBundesland)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: NexusTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          child: const Text('Weiter'),
        ),
      ],
    );
  }
}
