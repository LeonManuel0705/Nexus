import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'services/background_service.dart' if (dart.library.html) 'services/background_service_web.dart';
import 'services/database_service.dart' if (dart.library.html) 'services/database_service_web.dart';
import 'services/holiday_service.dart';
import 'services/update_service.dart';
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
import 'screens/notes_screen.dart';
import 'screens/mousepad_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';
import 'widgets/quick_note_fab.dart';
import 'widgets/connection_indicator.dart';
import 'widgets/nexus_drawer.dart';
import 'widgets/nexus_background.dart';
import 'utils/responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
  } catch (e) {
  }

  try {
    await initializeDateFormatting('de_DE', null);
  } catch (e) {
  }

  if (!kIsWeb) {
    try {
      await ConnectivityService().initialize();
    } catch (e) {
    }

    try {
      await SyncManager().initialize();
    } catch (e) {
    }

    try {
      await OfflineQueue().initialize();
    } catch (e) {
    }

    await BackgroundService().initialize();
    await BackgroundService().registerTasks();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

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
        ChangeNotifierProvider(create: (_) => IServProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
        ChangeNotifierProvider(create: (_) => VbbProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {

          final isDark = provider.themeMode == ThemeMode.dark;
          if (!kIsWeb) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FA),
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ));
          }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    // Small delay to let the UI settle
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      UpdateService.showUpdateDialog(context, updateInfo);
    }
  }

  Future<void> _checkFirstLaunch() async {
    if (_hasCheckedFirstLaunch) return;
    _hasCheckedFirstLaunch = true;

    final prefs = await SharedPreferences.getInstance();
    final hasSelectedBundesland = prefs.containsKey('user_bundesland');

    if (!hasSelectedBundesland && mounted) {
      await _showBundeslandDialog();
    } else if (hasSelectedBundesland) {
      _importHolidaysIfNeeded();
    }
  }

  Future<void> _importHolidaysIfNeeded() async {
    try {
      print('main.dart: Checking if holidays need to be imported...');
      final holidayService = HolidayService();
      final hasHolidays = await holidayService.hasImportedHolidays();
      print('main.dart: hasImportedHolidays() returned: $hasHolidays');

      if (!hasHolidays) {
        print('main.dart: Starting holiday import...');
        final events = await holidayService.importHolidays();
        print('main.dart: Holiday import complete, got ${events.length} events');

        if (mounted) {
          print('main.dart: Refreshing AppProvider to load new events...');
          context.read<AppProvider>().refresh();
        }
      } else {
        print('main.dart: Holidays already imported, skipping');
      }
    } catch (e, stackTrace) {
      print('main.dart: ERROR during holiday import: $e');
      print('main.dart: Stack trace: $stackTrace');
    }
  }

  Future<void> _showBundeslandDialog() async {
    final result = await showDialog<WelcomeSetupResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WelcomeSetupDialog(bundeslaender: _bundeslaender),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_bundesland', result.bundesland);
      await prefs.setInt('graduation_year', result.graduationYear);

      if (mounted) {
        _importHolidaysAfterSelection();
      }
    }
  }

  Future<void> _importHolidaysAfterSelection() async {
    try {
      print('main.dart: User selected Bundesland, starting holiday import...');
      final holidayService = HolidayService();
      final events = await holidayService.importHolidays();
      print('main.dart: Holiday import after selection complete, got ${events.length} events');

      if (mounted) {
        print('main.dart: Refreshing AppProvider...');
        context.read<AppProvider>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${events.length} Feiertage und Ferien wurden importiert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('main.dart: ERROR importing holidays after selection: $e');
      print('main.dart: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Importieren der Feiertage: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  final List<Widget> _allScreens = const [
    DashboardScreen(),      // 0
    TasksScreen(),          // 1
    CalendarScreen(),       // 2
    SchoolScreen(),         // 3
    MoreScreen(),           // 4
    PomodoroScreen(),       // 5
    TrainingScreen(),       // 6
    ProjectsScreen(),       // 7
    KnowledgeScreen(),      // 8
    EmailScreen(),          // 9
    ReviewScreen(),         // 10
    MousepadScreen(),       // 11
    AssistantScreen(),      // 12
    SettingsScreen(),       // 13
    NotesScreen(),          // 14
  ];

  void _navigateToScreen(int screenIndex) {
    setState(() {
      _currentIndex = screenIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = Responsive.useTabletLayout(context);

    if (isTablet) {
      return _buildTabletLayout(context, isDark);
    } else {
      return _buildPhoneLayout(context, isDark);
    }
  }

  Widget _buildPhoneLayout(BuildContext context, bool isDark) {
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

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    final sidebarWidth = Responsive.getSidebarWidth(context);

    return NexusBackground(
      child: ConnectionIndicator(
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Row(
              children: [
                _buildTabletSidebar(context, isDark, sidebarWidth),
                Expanded(
                  child: Column(
                    children: [
                      _buildTabletAppBar(context, isDark),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _allScreens,
                        ),
                      ),
                    ],
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

  Widget _buildTabletSidebar(BuildContext context, bool isDark, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF12121F).withOpacity(0.95),
                  const Color(0xFF1A1A2E).withOpacity(0.9),
                  const Color(0xFF16162A).withOpacity(0.95),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  const Color(0xFFF8F9FC).withOpacity(0.9),
                  Colors.white.withOpacity(0.95),
                ],
        ),
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: NexusTheme.primaryColor.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: NexusTheme.primaryGradient,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF12121F) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/nexus-logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NexusTheme.primaryColor.withOpacity(0.2),
                            NexusTheme.secondaryColor.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '0.2 closed beta',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : NexusTheme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarSection('Übersicht', [
                  _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
                  _buildSidebarItem(1, Icons.task_alt_outlined, 'Aufgaben'),
                  _buildSidebarItem(2, Icons.calendar_today_outlined, 'Kalender'),
                ]),
                _buildSidebarSection('Schule', [
                  _buildSidebarItem(3, Icons.school_outlined, 'Stundenplan'),
                  _buildSidebarItem(5, Icons.timer_outlined, 'Pomodoro'),
                  _buildSidebarItem(10, Icons.repeat_outlined, 'Review'),
                ]),
                _buildSidebarSection('Aktivitäten', [
                  _buildSidebarItem(6, Icons.fitness_center_outlined, 'Training'),
                  _buildSidebarItem(7, Icons.folder_outlined, 'Projekte'),
                  _buildSidebarItem(8, Icons.lightbulb_outlined, 'Wissen'),
                ]),
                _buildSidebarSection('Tools', [
                  _buildSidebarItem(14, Icons.note_outlined, 'Notizen'),
                  _buildSidebarItem(9, Icons.email_outlined, 'E-Mail'),
                  _buildSidebarItem(12, Icons.smart_toy_outlined, 'Assistent'),
                  _buildSidebarItem(11, Icons.draw_outlined, 'Zeichnen'),
                ]),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildSidebarItem(13, Icons.settings_outlined, 'Einstellungen'),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '© Made with ',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: NexusTheme.primaryGradient,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.favorite,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' by Leon',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    NexusTheme.primaryColor.withOpacity(0.25),
                    NexusTheme.secondaryColor.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: NexusTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              )
            : null,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _navigateToScreen(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  isSelected
                      ? ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: NexusTheme.primaryGradient,
                          ).createShader(bounds),
                          child: Icon(
                            icon,
                            size: 22,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 22,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                  const SizedBox(width: 12),
                  isSelected
                      ? ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: NexusTheme.primaryGradient,
                          ).createShader(bounds),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            _getScreenTitle(_currentIndex),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
        ],
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
      case 11: return 'Zeichnen';
      case 12: return 'Assistent';
      case 13: return 'Einstellungen';
      case 14: return 'Notizen';
      default: return '';
    }
  }

  Widget? _buildFab() {
    const screensWithOwnFab = {6, 7, 8, 9};

    if (screensWithOwnFab.contains(_currentIndex)) {
      return null;
    }

    switch (_currentIndex) {
      case 1: // Tasks
        return FloatingActionButton(
          heroTag: 'fab_tasks',
          onPressed: () => showAddTaskDialog(context),
          backgroundColor: NexusTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 2: // Calendar
        return FloatingActionButton(
          heroTag: 'fab_calendar',
          onPressed: () => showAddEventDialog(context),
          backgroundColor: NexusTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 3: // School
        return FloatingActionButton(
          heroTag: 'fab_school',
          onPressed: () => showAddLessonDialog(context),
          backgroundColor: NexusTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return const QuickNoteFab();
    }
  }
}

/// Result from the welcome setup dialog
class WelcomeSetupResult {
  final String bundesland;
  final int graduationYear;

  WelcomeSetupResult({required this.bundesland, required this.graduationYear});
}

class _WelcomeSetupDialog extends StatefulWidget {
  final List<String> bundeslaender;

  const _WelcomeSetupDialog({required this.bundeslaender});

  @override
  State<_WelcomeSetupDialog> createState() => _WelcomeSetupDialogState();
}

class _WelcomeSetupDialogState extends State<_WelcomeSetupDialog>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String? _selectedBundesland;
  int? _selectedGraduationYear;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const _cardGradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFF30CFD0), Color(0xFF330867)],
    [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
    [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
  ];

  List<int> get _graduationYears {
    final currentYear = DateTime.now().year;
    return List.generate(11, (i) => currentYear + i);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 580),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16162A)]
                  : [Colors.white, const Color(0xFFF8F9FC)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: NexusTheme.primaryColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGradientHeader(isDark),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _currentStep == 0
                      ? _buildBundeslandStep(isDark)
                      : _buildGraduationStep(isDark),
                ),
              ),
              _buildFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: NexusTheme.primaryGradient,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _currentStep == 0 ? Icons.map_outlined : Icons.school_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Willkommen!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentStep == 0
                              ? 'Wo bist du zuhause?'
                              : 'Wie lange noch?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildModernStepPill(0, 'Bundesland'),
                  const SizedBox(width: 8),
                  _buildModernStepPill(1, 'Abschluss'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStepPill(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(isCurrent ? 0.3 : 0.15)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? Colors.white.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
              ),
              child: Center(
                child: _currentStep > step
                    ? Icon(Icons.check, color: NexusTheme.primaryColor, size: 14)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: isActive ? NexusTheme.primaryColor : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundeslandStep(bool isDark) {
    return Padding(
      key: const ValueKey('bundesland'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NexusTheme.primaryColor.withOpacity(0.1),
                  NexusTheme.secondaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: NexusTheme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Wird verwendet um Ferien und Feiertage zu importieren',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.bundeslaender.length,
              itemBuilder: (context, index) {
                final bundesland = widget.bundeslaender[index];
                final isSelected = _selectedBundesland == bundesland;
                final gradientColors = _cardGradients[index % _cardGradients.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedBundesland = bundesland),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    gradientColors[0].withOpacity(0.2),
                                    gradientColors[1].withOpacity(0.1),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? gradientColors[0].withOpacity(0.5)
                                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(colors: gradientColors)
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 22,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black38),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                bundesland,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 15,
                                  color: isSelected
                                      ? (isDark ? Colors.white : gradientColors[0])
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradientColors),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraduationStep(bool isDark) {
    return Padding(
      key: const ValueKey('graduation'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF43E97B).withOpacity(0.15),
                  const Color(0xFF38F9D7).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF43E97B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ferien werden automatisch bis zu diesem Jahr importiert',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _graduationYears.length,
              itemBuilder: (context, index) {
                final year = _graduationYears[index];
                final isSelected = _selectedGraduationYear == year;
                final yearsFromNow = year - DateTime.now().year;
                final label = yearsFromNow == 0
                    ? 'Dieses Jahr'
                    : yearsFromNow == 1
                        ? 'In einem Jahr'
                        : 'In $yearsFromNow Jahren';

                final gradientColors = yearsFromNow <= 2
                    ? [const Color(0xFF43E97B), const Color(0xFF38F9D7)]
                    : yearsFromNow <= 5
                        ? [const Color(0xFF4FACFE), const Color(0xFF00F2FE)]
                        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedGraduationYear = year),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    gradientColors[0].withOpacity(0.2),
                                    gradientColors[1].withOpacity(0.1),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? gradientColors[0].withOpacity(0.5)
                                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(colors: gradientColors)
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 20,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black38),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$year',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black38),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Abschluss $year',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 15,
                                      color: isSelected
                                          ? (isDark ? Colors.white : gradientColors[0])
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradientColors),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Zuruck'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 1 : 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: _canProceed()
                    ? const LinearGradient(colors: NexusTheme.primaryGradient)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _canProceed() ? _handleNext : null,
                icon: Icon(
                  _currentStep == 0 ? Icons.arrow_forward : Icons.check,
                  size: 18,
                ),
                label: Text(_currentStep == 0 ? 'Weiter' : 'Fertig'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed() ? Colors.transparent : null,
                  disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      return _selectedBundesland != null;
    } else {
      return _selectedGraduationYear != null;
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else {
      Navigator.pop(
        context,
        WelcomeSetupResult(
          bundesland: _selectedBundesland!,
          graduationYear: _selectedGraduationYear!,
        ),
      );
    }
  }
}
