import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/iserv_provider.dart';
import '../models/lesson.dart';
import '../services/database_service.dart';
import '../theme.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAWeek = true;
  int _selectedSubTab = 0;
  final DatabaseService _db = DatabaseService();

  final List<String> _subTabs = ['Stundenplan', 'Fächer', 'Hausaufgaben', 'Tests', 'Klausuren', 'Noten', 'IServ'];
  final List<String> _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr'];
  final List<String> _daysFull = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'];

  // State for each section
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _homework = [];
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateCurrentWeek();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      _subjects = await _db.getSubjects();
      _homework = await _db.getHomework();
      // Load tests, exams, grades from database
      await _loadTests();
      await _loadExams();
      await _loadGrades();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTests() async {
    final db = await _db.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tests (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subject_id INTEGER,
        date TEXT,
        notes TEXT,
        grade TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    _tests = await db.rawQuery('''
      SELECT t.*, s.name as subject_name, s.color as subject_color
      FROM tests t
      LEFT JOIN subjects s ON t.subject_id = s.id
      ORDER BY t.date ASC
    ''');
  }

  Future<void> _loadExams() async {
    final db = await _db.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exams (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subject_id INTEGER,
        date TEXT,
        notes TEXT,
        grade TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    _exams = await db.rawQuery('''
      SELECT e.*, s.name as subject_name, s.color as subject_color
      FROM exams e
      LEFT JOIN subjects s ON e.subject_id = s.id
      ORDER BY e.date ASC
    ''');
  }

  Future<void> _loadGrades() async {
    final db = await _db.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS grades (
        id TEXT PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        semester TEXT NOT NULL,
        type TEXT NOT NULL,
        points INTEGER NOT NULL,
        notes TEXT,
        date TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    _grades = await db.rawQuery('''
      SELECT g.*, s.name as subject_name, s.color as subject_color
      FROM grades g
      LEFT JOIN subjects s ON g.subject_id = s.id
      ORDER BY g.date DESC
    ''');
  }

  void _calculateCurrentWeek() {
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    setState(() {
      _isAWeek = weekNumber % 2 == 0;
    });
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirst = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirst + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with A/B week toggle
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NexusTheme.primaryColor.withOpacity(0.15),
                    NexusTheme.secondaryColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schule',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fächer, Hausaufgaben & Klausuren',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // A/B Week toggle
                      GestureDetector(
                        onTap: () => setState(() => _isAWeek = !_isAWeek),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isAWeek
                                  ? [NexusTheme.primaryColor, NexusTheme.secondaryColor]
                                  : [NexusTheme.secondaryColor, NexusTheme.accentColor],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_isAWeek ? NexusTheme.primaryColor : NexusTheme.accentColor).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isAWeek ? 'A' : 'B',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Woche',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sub-tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_subTabs.length, (index) {
                        final isSelected = _selectedSubTab == index;
                        return Padding(
                          padding: EdgeInsets.only(right: index < _subTabs.length - 1 ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSubTab = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? NexusTheme.primaryColor
                                    : (isDark ? NexusTheme.darkCard : NexusTheme.lightCard),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? NexusTheme.primaryColor
                                      : (isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
                                ),
                              ),
                              child: Text(
                                _subTabs[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? NexusTheme.darkTextSecondary : NexusTheme.lightTextSecondary),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSubTabContent(provider, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubTabContent(AppProvider provider, bool isDark) {
    switch (_selectedSubTab) {
      case 0:
        return _buildStundenplanTab(provider, isDark);
      case 1:
        return _buildSubjectsTab(isDark);
      case 2:
        return _buildHomeworkTab(isDark);
      case 3:
        return _buildTestsTab(isDark);
      case 4:
        return _buildExamsTab(isDark);
      case 5:
        return _buildGradesTab(isDark);
      case 6:
        return _buildIServTab(isDark);
      default:
        return _buildStundenplanTab(provider, isDark);
    }
  }

  // ============== STUNDENPLAN TAB ==============
  Widget _buildStundenplanTab(AppProvider provider, bool isDark) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          decoration: BoxDecoration(
            color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Heute'),
              Tab(text: 'Morgen'),
              Tab(text: 'Woche'),
            ],
            labelColor: NexusTheme.primaryColor,
            unselectedLabelColor: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
            indicatorColor: NexusTheme.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDaySchedule(provider, _getTodayWeekday(), 'Heute', isDark),
              _buildDaySchedule(provider, _getTomorrowWeekday(), 'Morgen', isDark),
              _buildWeekOverview(provider, isDark),
            ],
          ),
        ),
      ],
    );
  }

  int _getTodayWeekday() {
    final today = DateTime.now().weekday;
    return today <= 5 ? today : 1;
  }

  int _getTomorrowWeekday() {
    final tomorrow = (DateTime.now().weekday % 7) + 1;
    if (tomorrow > 5) return 1;
    return tomorrow;
  }

  Widget _buildDaySchedule(AppProvider provider, int dayOfWeek, String dayLabel, bool isDark) {
    final now = DateTime.now();
    final isToday = dayLabel == 'Heute';

    final lessonsForDay = provider.lessons
        .where((l) => l.dayOfWeek == dayOfWeek)
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refresh();
        await _loadAllData();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (isToday && lessonsForDay.isNotEmpty) ...[
            _buildCurrentLessonCard(lessonsForDay, now, isDark),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [NexusTheme.primaryColor, NexusTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _daysFull[dayOfWeek - 1],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${lessonsForDay.length} Stunden',
                  style: TextStyle(
                    color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (lessonsForDay.isEmpty)
            _buildEmptyDayState(isDark, dayOfWeek)
          else ...[
            ...lessonsForDay.map((lesson) => _LessonCard(
              lesson: lesson,
              onDelete: () => provider.deleteLesson(lesson.id),
              onEdit: () => _showEditLessonDialog(context, lesson),
              isCurrentLesson: isToday && _isCurrentLesson(lesson, now),
            )),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => showAddLessonDialog(context, dayOfWeek: dayOfWeek),
                icon: const Icon(Icons.add),
                label: const Text('Weitere Stunde hinzufügen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NexusTheme.primaryColor,
                  side: BorderSide(color: NexusTheme.primaryColor.withOpacity(0.5)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCurrentLessonCard(List<Lesson> lessons, DateTime now, bool isDark) {
    Lesson? currentLesson;
    Lesson? nextLesson;

    for (int i = 0; i < lessons.length; i++) {
      if (_isCurrentLesson(lessons[i], now)) {
        currentLesson = lessons[i];
        if (i + 1 < lessons.length) {
          nextLesson = lessons[i + 1];
        }
        break;
      }
    }

    if (currentLesson == null) {
      for (final lesson in lessons) {
        final startParts = lesson.startTime.split(':');
        final lessonStart = DateTime(now.year, now.month, now.day,
            int.parse(startParts[0]), int.parse(startParts[1]));
        if (lessonStart.isAfter(now)) {
          nextLesson = lesson;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: currentLesson != null
              ? [NexusTheme.primaryColor.withOpacity(0.9), NexusTheme.secondaryColor.withOpacity(0.9)]
              : [
                  isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
                  isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: currentLesson == null ? Border.all(
          color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
        ) : null,
        boxShadow: currentLesson != null ? [
          BoxShadow(
            color: NexusTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentLesson != null ? Colors.greenAccent : NexusTheme.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (currentLesson != null ? Colors.greenAccent : NexusTheme.warning).withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentLesson != null ? 'Aktuell' : 'Nächste Stunde',
                style: TextStyle(
                  color: currentLesson != null ? Colors.white70 : (isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentLesson != null) ...[
            Text(
              currentLesson.subject,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${currentLesson.timeRange}${currentLesson.room != null ? ' • Raum ${currentLesson.room}' : ''}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            if (nextLesson != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_forward, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Danach: ${nextLesson.subject}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (nextLesson != null) ...[
            Text(
              nextLesson.subject,
              style: TextStyle(
                color: isDark ? NexusTheme.darkText : NexusTheme.lightText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Beginnt um ${nextLesson.startTime}${nextLesson.room != null ? ' • Raum ${nextLesson.room}' : ''}',
              style: TextStyle(
                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                fontSize: 13,
              ),
            ),
          ] else ...[
            Text(
              'Keine weiteren Stunden heute',
              style: TextStyle(
                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isCurrentLesson(Lesson lesson, DateTime now) {
    final startParts = lesson.startTime.split(':');
    final endParts = lesson.endTime.split(':');

    final lessonStart = DateTime(now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final lessonEnd = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));

    return now.isAfter(lessonStart) && now.isBefore(lessonEnd);
  }

  Widget _buildWeekOverview(AppProvider provider, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [NexusTheme.primaryColor, NexusTheme.secondaryColor],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _isAWeek ? 'A' : 'B',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_isAWeek ? 'A' : 'B'}-Woche',
                  style: TextStyle(
                    color: isDark ? NexusTheme.darkText : NexusTheme.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(5, (dayIndex) {
          final dayOfWeek = dayIndex + 1;
          final lessonsForDay = provider.lessons
              .where((l) => l.dayOfWeek == dayOfWeek)
              .toList()
            ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

          final isToday = DateTime.now().weekday == dayOfWeek;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? NexusTheme.primaryColor.withOpacity(0.5)
                    : (isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isToday
                        ? NexusTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _daysFull[dayIndex],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? NexusTheme.primaryColor
                              : (isDark ? NexusTheme.darkText : NexusTheme.lightText),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: NexusTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Heute',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${lessonsForDay.length} Std.',
                        style: TextStyle(
                          color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (lessonsForDay.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Frei',
                      style: TextStyle(
                        color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: lessonsForDay.map((lesson) {
                        final lessonColor = lesson.color != null
                            ? Color(int.parse(lesson.color!.replaceFirst('#', '0xFF')))
                            : NexusTheme.primaryColor;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: lessonColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: lessonColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: lessonColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${lesson.lessonNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lesson.subject,
                                style: TextStyle(
                                  color: isDark ? NexusTheme.darkText : NexusTheme.lightText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEmptyDayState(bool isDark, int dayOfWeek) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 64,
            color: NexusTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Stunden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? NexusTheme.darkText : NexusTheme.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dieser Tag ist noch leer',
            style: TextStyle(
              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => showAddLessonDialog(context, dayOfWeek: dayOfWeek),
            icon: const Icon(Icons.add),
            label: const Text('Stunde hinzufügen'),
            style: FilledButton.styleFrom(
              backgroundColor: NexusTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============== SUBJECTS TAB ==============
  Widget _buildSubjectsTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _subjects.isEmpty
          ? _buildEmptyState(
              icon: Icons.school,
              title: 'Keine Fächer',
              subtitle: 'Füge deine Schulfächer hinzu',
              buttonText: 'Fach hinzufügen',
              onAdd: () => _showAddSubjectDialog(isDark),
              isDark: isDark,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._subjects.map((subject) => _SubjectCard(
                  subject: subject,
                  onEdit: () => _showEditSubjectDialog(subject, isDark),
                  onDelete: () => _deleteSubject(subject['id']),
                )),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showAddSubjectDialog(bool isDark) {
    _showSubjectDialog(null, isDark);
  }

  void _showEditSubjectDialog(Map<String, dynamic> subject, bool isDark) {
    _showSubjectDialog(subject, isDark);
  }

  void _showSubjectDialog(Map<String, dynamic>? subject, bool isDark) {
    final nameController = TextEditingController(text: subject?['name'] ?? '');
    final shortController = TextEditingController(text: subject?['short_name'] ?? '');
    final teacherController = TextEditingController(text: subject?['teacher'] ?? '');
    final roomController = TextEditingController(text: subject?['room'] ?? '');
    String? selectedColor = subject?['color'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subject != null ? 'Fach bearbeiten' : 'Neues Fach'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Mathematik',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: shortController,
                decoration: const InputDecoration(
                  labelText: 'Kürzel (optional)',
                  hintText: 'z.B. MA',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: teacherController,
                decoration: const InputDecoration(
                  labelText: 'Lehrer (optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Raum (optional)',
                  prefixIcon: Icon(Icons.room),
                ),
              ),
              const SizedBox(height: 16),
              _ColorPicker(
                selectedColor: selectedColor,
                onColorSelected: (color) => selectedColor = color,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              if (subject != null) {
                await _db.updateSubject(
                  subject['id'],
                  name: nameController.text.trim(),
                  shortName: shortController.text.trim(),
                  teacher: teacherController.text.trim(),
                  room: roomController.text.trim(),
                  color: selectedColor,
                );
              } else {
                await _db.insertSubject(
                  name: nameController.text.trim(),
                  shortName: shortController.text.trim().isEmpty ? null : shortController.text.trim(),
                  teacher: teacherController.text.trim().isEmpty ? null : teacherController.text.trim(),
                  room: roomController.text.trim().isEmpty ? null : roomController.text.trim(),
                  color: selectedColor,
                );
              }
              await _loadAllData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fach löschen?'),
        content: const Text('Möchtest du dieses Fach wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NexusTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteSubject(id);
      await _loadAllData();
    }
  }

  // ============== HOMEWORK TAB ==============
  Widget _buildHomeworkTab(bool isDark) {
    final openHomework = _homework.where((h) => h['completed'] != 1).toList();
    final completedHomework = _homework.where((h) => h['completed'] == 1).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _homework.isEmpty
          ? _buildEmptyState(
              icon: Icons.assignment,
              title: 'Keine Hausaufgaben',
              subtitle: 'Füge deine Hausaufgaben hinzu',
              buttonText: 'Hausaufgabe hinzufügen',
              onAdd: () => _showHomeworkDialog(null, isDark),
              isDark: isDark,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (openHomework.isNotEmpty) ...[
                  _SectionHeader(title: 'Offen (${openHomework.length})', isDark: isDark),
                  ...openHomework.map((hw) => _HomeworkCard(
                    homework: hw,
                    onToggle: () => _toggleHomework(hw),
                    onEdit: () => _showHomeworkDialog(hw, isDark),
                    onDelete: () => _deleteHomework(hw['id']),
                  )),
                ],
                if (completedHomework.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Erledigt (${completedHomework.length})', isDark: isDark),
                  ...completedHomework.map((hw) => _HomeworkCard(
                    homework: hw,
                    onToggle: () => _toggleHomework(hw),
                    onEdit: () => _showHomeworkDialog(hw, isDark),
                    onDelete: () => _deleteHomework(hw['id']),
                  )),
                ],
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showHomeworkDialog(Map<String, dynamic>? homework, bool isDark) {
    final titleController = TextEditingController(text: homework?['title'] ?? '');
    final notesController = TextEditingController(text: homework?['notes'] ?? '');
    int? selectedSubjectId = homework?['subject_id'];
    DateTime? dueDate = homework?['due_date'] != null ? DateTime.parse(homework!['due_date']) : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(homework != null ? 'Hausaufgabe bearbeiten' : 'Neue Hausaufgabe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Aufgabe'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Kein Fach')),
                    ..._subjects.map((s) => DropdownMenuItem(
                      value: s['id'] as int,
                      child: Text(s['name'] as String),
                    )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(dueDate != null
                      ? DateFormat('d. MMM yyyy', 'de_DE').format(dueDate!)
                      : 'Fälligkeitsdatum wählen'),
                  trailing: dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setDialogState(() => dueDate = null),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => dueDate = date);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notizen (optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;

                if (homework != null) {
                  await _db.updateHomework(
                    homework['id'],
                    title: titleController.text.trim(),
                    subjectId: selectedSubjectId,
                    notes: notesController.text.trim(),
                    dueDate: dueDate,
                  );
                } else {
                  await _db.insertHomework(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    subjectId: selectedSubjectId,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    dueDate: dueDate,
                  );
                }
                await _loadAllData();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleHomework(Map<String, dynamic> hw) async {
    await _db.toggleHomeworkComplete(hw['id'], hw['completed'] != 1);
    await _loadAllData();
  }

  Future<void> _deleteHomework(String id) async {
    await _db.deleteHomework(id);
    await _loadAllData();
  }

  // ============== TESTS TAB ==============
  Widget _buildTestsTab(bool isDark) {
    final upcoming = _tests.where((t) {
      if (t['date'] == null) return true;
      return DateTime.parse(t['date']).isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).toList();
    final past = _tests.where((t) {
      if (t['date'] == null) return false;
      return DateTime.parse(t['date']).isBefore(DateTime.now().subtract(const Duration(days: 1)));
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _tests.isEmpty
          ? _buildEmptyState(
              icon: Icons.quiz,
              title: 'Keine Tests',
              subtitle: 'Füge anstehende Tests hinzu',
              buttonText: 'Test hinzufügen',
              onAdd: () => _showTestExamDialog(null, isExam: false, isDark: isDark),
              isDark: isDark,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(title: 'Anstehend (${upcoming.length})', isDark: isDark),
                  ...upcoming.map((t) => _TestExamCard(
                    item: t,
                    isExam: false,
                    onEdit: () => _showTestExamDialog(t, isExam: false, isDark: isDark),
                    onDelete: () => _deleteTest(t['id']),
                  )),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Vergangen (${past.length})', isDark: isDark),
                  ...past.map((t) => _TestExamCard(
                    item: t,
                    isExam: false,
                    onEdit: () => _showTestExamDialog(t, isExam: false, isDark: isDark),
                    onDelete: () => _deleteTest(t['id']),
                  )),
                ],
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  // ============== EXAMS TAB ==============
  Widget _buildExamsTab(bool isDark) {
    final upcoming = _exams.where((e) {
      if (e['date'] == null) return true;
      return DateTime.parse(e['date']).isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).toList();
    final past = _exams.where((e) {
      if (e['date'] == null) return false;
      return DateTime.parse(e['date']).isBefore(DateTime.now().subtract(const Duration(days: 1)));
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _exams.isEmpty
          ? _buildEmptyState(
              icon: Icons.edit_note,
              title: 'Keine Klausuren',
              subtitle: 'Füge anstehende Klausuren hinzu',
              buttonText: 'Klausur hinzufügen',
              onAdd: () => _showTestExamDialog(null, isExam: true, isDark: isDark),
              isDark: isDark,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(title: 'Anstehend (${upcoming.length})', isDark: isDark),
                  ...upcoming.map((e) => _TestExamCard(
                    item: e,
                    isExam: true,
                    onEdit: () => _showTestExamDialog(e, isExam: true, isDark: isDark),
                    onDelete: () => _deleteExam(e['id']),
                  )),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Vergangen (${past.length})', isDark: isDark),
                  ...past.map((e) => _TestExamCard(
                    item: e,
                    isExam: true,
                    onEdit: () => _showTestExamDialog(e, isExam: true, isDark: isDark),
                    onDelete: () => _deleteExam(e['id']),
                  )),
                ],
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showTestExamDialog(Map<String, dynamic>? item, {required bool isExam, required bool isDark}) {
    final titleController = TextEditingController(text: item?['title'] ?? '');
    final notesController = TextEditingController(text: item?['notes'] ?? '');
    final gradeController = TextEditingController(text: item?['grade'] ?? '');
    int? selectedSubjectId = item?['subject_id'];
    DateTime? date = item?['date'] != null ? DateTime.parse(item!['date']) : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item != null
              ? '${isExam ? 'Klausur' : 'Test'} bearbeiten'
              : 'Neue${isExam ? ' Klausur' : 'r Test'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: isExam ? 'Thema' : 'Thema'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Kein Fach')),
                    ..._subjects.map((s) => DropdownMenuItem(
                      value: s['id'] as int,
                      child: Text(s['name'] as String),
                    )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(date != null
                      ? DateFormat('d. MMM yyyy', 'de_DE').format(date!)
                      : 'Datum wählen'),
                  trailing: date != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setDialogState(() => date = null),
                        )
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: gradeController,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notizen (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;

                final db = await _db.database;
                final table = isExam ? 'exams' : 'tests';

                if (item != null) {
                  await db.update(table, {
                    'title': titleController.text.trim(),
                    'subject_id': selectedSubjectId,
                    'date': date?.toIso8601String(),
                    'grade': gradeController.text.trim().isEmpty ? null : gradeController.text.trim(),
                    'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  }, where: 'id = ?', whereArgs: [item['id']]);
                } else {
                  await db.insert(table, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': titleController.text.trim(),
                    'subject_id': selectedSubjectId,
                    'date': date?.toIso8601String(),
                    'grade': gradeController.text.trim().isEmpty ? null : gradeController.text.trim(),
                    'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    'created_at': DateTime.now().toIso8601String(),
                  });
                }
                await _loadAllData();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTest(String id) async {
    final db = await _db.database;
    await db.delete('tests', where: 'id = ?', whereArgs: [id]);
    await _loadAllData();
  }

  Future<void> _deleteExam(String id) async {
    final db = await _db.database;
    await db.delete('exams', where: 'id = ?', whereArgs: [id]);
    await _loadAllData();
  }

  // ============== GRADES TAB ==============
  String _selectedSemester = 'Q1';

  Widget _buildGradesTab(bool isDark) {
    final filteredGrades = _selectedSemester == 'all'
        ? _grades
        : _grades.where((g) => g['semester'] == _selectedSemester).toList();

    // Calculate summary
    final klausurGrades = filteredGrades.where((g) => g['type'] == 'Klausur').toList();
    final sonstigeGrades = filteredGrades.where((g) => g['type'] != 'Klausur').toList();

    double? klausurAvg = klausurGrades.isNotEmpty
        ? klausurGrades.map((g) => g['points'] as int).reduce((a, b) => a + b) / klausurGrades.length
        : null;
    double? sonstigeAvg = sonstigeGrades.isNotEmpty
        ? sonstigeGrades.map((g) => g['points'] as int).reduce((a, b) => a + b) / sonstigeGrades.length
        : null;

    // Calculate overall with 1/3 Klausur + 2/3 Sonstige weighting
    double? overallAvg;
    if (klausurAvg != null && sonstigeAvg != null) {
      overallAvg = (klausurAvg * 1 + sonstigeAvg * 2) / 3;
    } else if (klausurAvg != null) {
      overallAvg = klausurAvg;
    } else if (sonstigeAvg != null) {
      overallAvg = sonstigeAvg;
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Semester filter
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Q1', 'Q2', 'Q3', 'Q4', 'all'].map((semester) {
                  final isSelected = _selectedSemester == semester;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSemester = semester),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: semester == 'all' ? 16 : 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [NexusTheme.primaryColor, NexusTheme.secondaryColor])
                              : null,
                          color: isSelected ? null : (isDark ? NexusTheme.darkCard : NexusTheme.lightCard),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : (isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
                          ),
                        ),
                        child: Text(
                          semester == 'all' ? 'Alle' : semester,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? NexusTheme.darkTextSecondary : NexusTheme.lightTextSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Summary card
          if (overallAvg != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Gesamt', overallAvg.toStringAsFixed(1), NexusTheme.primaryColor, isDark),
                  if (klausurAvg != null)
                    _buildSummaryItem('Klausuren (1/3)', klausurAvg.toStringAsFixed(1), NexusTheme.secondaryColor, isDark),
                  if (sonstigeAvg != null)
                    _buildSummaryItem('Sonstige (2/3)', sonstigeAvg.toStringAsFixed(1), NexusTheme.accentColor, isDark),
                ],
              ),
            ),

          // Full grade calculator
          _FullGradeCalculatorCard(isDark: isDark, subjects: _subjects),
          const SizedBox(height: 16),

          // Add grade button
          Row(
            children: [
              _SectionHeader(title: 'Notenübersicht', isDark: isDark),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddGradeDialog(isDark),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Note'),
              ),
            ],
          ),

          if (filteredGrades.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.grade, size: 48, color: NexusTheme.primaryColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Noten eingetragen',
                    style: TextStyle(
                      color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddGradeDialog(isDark),
                    icon: const Icon(Icons.add),
                    label: const Text('Note hinzufügen'),
                    style: FilledButton.styleFrom(backgroundColor: NexusTheme.primaryColor),
                  ),
                ],
              ),
            )
          else
            ..._buildGradesBySubject(filteredGrades, isDark),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAddGradeDialog(bool isDark) {
    int? selectedSubjectId;
    String selectedSemester = _selectedSemester == 'all' ? 'Q1' : _selectedSemester;
    String selectedType = 'Mündlich';
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Neue Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach'),
                  items: _subjects.map((s) => DropdownMenuItem(
                    value: s['id'] as int,
                    child: Row(
                      children: [
                        Text(s['name'] as String),
                        if (s['course_type'] != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: s['course_type'] == 'LK' ? NexusTheme.primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s['course_type'] as String,
                              style: TextStyle(fontSize: 10, color: s['course_type'] == 'LK' ? NexusTheme.primaryColor : Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSemester,
                  decoration: const InputDecoration(labelText: 'Halbjahr'),
                  items: ['Q1', 'Q2', 'Q3', 'Q4'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedSemester = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Art'),
                  items: ['Klausur', 'Mündlich', 'Test', 'Referat', 'Hausarbeit', 'Sonstige']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Punkte (0-15)',
                    hintText: 'z.B. 12',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Gewichtung:', style: TextStyle(fontSize: 12, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)),
                      const SizedBox(height: 4),
                      Text(
                        selectedType == 'Klausur' ? 'Zählt zu Klausuren (1/3)' : 'Zählt zu Sonstige (2/3)',
                        style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? NexusTheme.darkText : NexusTheme.lightText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                if (selectedSubjectId == null || pointsController.text.isEmpty) return;
                final points = int.tryParse(pointsController.text);
                if (points == null || points < 0 || points > 15) return;

                final db = await _db.database;
                await db.insert('grades', {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'subject_id': selectedSubjectId,
                  'semester': selectedSemester,
                  'type': selectedType,
                  'points': points,
                  'date': DateTime.now().toIso8601String(),
                  'created_at': DateTime.now().toIso8601String(),
                });
                await _loadAllData();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGradesBySubject(List<Map<String, dynamic>> grades, bool isDark) {
    final Map<int, List<Map<String, dynamic>>> gradesBySubject = {};
    for (final grade in grades) {
      final subjectId = grade['subject_id'] as int;
      gradesBySubject.putIfAbsent(subjectId, () => []).add(grade);
    }

    return gradesBySubject.entries.map((entry) {
      final subjectGrades = entry.value;
      final subjectName = subjectGrades.first['subject_name'] ?? 'Unbekannt';
      final subjectColor = subjectGrades.first['subject_color'] != null
          ? Color(int.parse((subjectGrades.first['subject_color'] as String).replaceFirst('#', '0xFF')))
          : NexusTheme.primaryColor;
      final courseType = subjectGrades.first['course_type'];

      // Calculate with 1/3 Klausur + 2/3 Sonstige
      final klausuren = subjectGrades.where((g) => g['type'] == 'Klausur').toList();
      final sonstige = subjectGrades.where((g) => g['type'] != 'Klausur').toList();

      double avgPoints;
      if (klausuren.isNotEmpty && sonstige.isNotEmpty) {
        final klausurAvg = klausuren.map((g) => g['points'] as int).reduce((a, b) => a + b) / klausuren.length;
        final sonstigeAvg = sonstige.map((g) => g['points'] as int).reduce((a, b) => a + b) / sonstige.length;
        avgPoints = (klausurAvg * 1 + sonstigeAvg * 2) / 3;
      } else if (klausuren.isNotEmpty) {
        avgPoints = klausuren.map((g) => g['points'] as int).reduce((a, b) => a + b) / klausuren.length;
      } else {
        avgPoints = sonstige.map((g) => g['points'] as int).reduce((a, b) => a + b) / sonstige.length;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
        ),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getGradeColor(avgPoints.round()).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                avgPoints.toStringAsFixed(1),
                style: TextStyle(
                  color: _getGradeColor(avgPoints.round()),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Flexible(child: Text(subjectName as String, overflow: TextOverflow.ellipsis)),
              if (courseType != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: courseType == 'LK'
                        ? NexusTheme.primaryColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    courseType == 'LK' ? 'LK (2x)' : courseType as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: courseType == 'LK' ? NexusTheme.primaryColor : Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text('${subjectGrades.length} Noten • K: ${klausuren.length} • S: ${sonstige.length}'),
          children: subjectGrades.map((g) => ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getGradeColor(g['points'] as int).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${g['points']}',
                  style: TextStyle(
                    color: _getGradeColor(g['points'] as int),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            title: Text(g['type'] as String),
            subtitle: Text('${g['semester']} • ${g['type'] == 'Klausur' ? '1/3' : '2/3'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteGrade(g['id']),
            ),
          )).toList(),
        ),
      );
    }).toList();
  }

  Color _getGradeColor(int points) {
    if (points >= 13) return NexusTheme.success;
    if (points >= 10) return Colors.lightGreen;
    if (points >= 7) return NexusTheme.warning;
    if (points >= 4) return Colors.orange;
    return NexusTheme.danger;
  }

  Future<void> _deleteGrade(String id) async {
    final db = await _db.database;
    await db.delete('grades', where: 'id = ?', whereArgs: [id]);
    await _loadAllData();
  }

  // ============== ISERV TAB ==============
  Widget _buildIServTab(bool isDark) {
    return Consumer<IServProvider>(
      builder: (context, iservProvider, child) {
        if (!iservProvider.isConnected) {
          return _buildEmptyState(
            icon: Icons.school,
            title: 'IServ verbinden',
            subtitle: 'Verbinde dein IServ-Konto\num Aufgaben und Termine zu sehen',
            buttonText: 'Mit IServ anmelden',
            onAdd: () => _showIServLoginDialog(context),
            isDark: isDark,
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: NexusTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NexusTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: NexusTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'IServ verbunden',
                      style: TextStyle(
                        color: NexusTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => iservProvider.disconnect(),
                      child: const Text('Trennen'),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
                  ),
                ),
                child: TabBar(
                  tabs: const [
                    Tab(text: 'Aufgaben'),
                    Tab(text: 'Termine'),
                  ],
                  labelColor: NexusTheme.primaryColor,
                  unselectedLabelColor: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                  indicatorColor: NexusTheme.primaryColor,
                  dividerColor: Colors.transparent,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildIServComingSoon('IServ Aufgaben', isDark),
                    _buildIServComingSoon('IServ Termine', isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIServComingSoon(String title, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 48,
              color: NexusTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: NexusTheme.primaryGradient,
              ).createShader(bounds),
              child: const Text(
                'Bald verfügbar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$title werden bald unterstützt',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== HELPER WIDGETS ==============
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onAdd,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NexusTheme.primaryColor.withOpacity(0.2),
                    NexusTheme.secondaryColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: NexusTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? NexusTheme.darkText : NexusTheme.lightText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: FilledButton.styleFrom(backgroundColor: NexusTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLessonDialog(BuildContext context, Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => _LessonDialog(lesson: lesson),
    );
  }

  void _showIServLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _IServLoginDialog(),
    );
  }
}

// ============== HELPER CLASSES ==============
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
        ),
      ),
    );
  }
}

class _ColorPicker extends StatefulWidget {
  final String? selectedColor;
  final Function(String) onColorSelected;

  const _ColorPicker({this.selectedColor, required this.onColorSelected});

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late String? _selected;

  static const _colors = [
    '#667EEA', '#764BA2', '#F093FB',
    '#22C55E', '#F59E0B', '#EF4444',
    '#06B6D4', '#8B5CF6',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Farbe', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((color) {
            final isSelected = _selected == color;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = color);
                widget.onColorSelected(color);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ] : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Map<String, dynamic> subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({required this.subject, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = subject['color'] != null
        ? Color(int.parse((subject['color'] as String).replaceFirst('#', '0xFF')))
        : NexusTheme.primaryColor;

    return Dismissible(
      key: Key('subject_${subject['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: NexusTheme.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
        ),
        child: ListTile(
          onTap: onEdit,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                (subject['short_name'] ?? (subject['name'] as String).substring(0, 2)).toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          title: Text(subject['name'] as String),
          subtitle: subject['teacher'] != null ? Text(subject['teacher'] as String) : null,
          trailing: subject['room'] != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(subject['room'] as String, style: TextStyle(color: color, fontSize: 12)),
                )
              : null,
        ),
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final Map<String, dynamic> homework;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HomeworkCard({required this.homework, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = homework['completed'] == 1;
    final color = homework['subject_color'] != null
        ? Color(int.parse((homework['subject_color'] as String).replaceFirst('#', '0xFF')))
        : NexusTheme.primaryColor;

    return Dismissible(
      key: Key('hw_${homework['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: NexusTheme.danger, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
        ),
        child: ListTile(
          onTap: onEdit,
          leading: GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? NexusTheme.success : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isCompleted ? NexusTheme.success : Colors.grey),
              ),
              child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          ),
          title: Text(
            homework['title'] as String,
            style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : null),
          ),
          subtitle: Row(
            children: [
              if (homework['subject_name'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    homework['subject_name'] as String,
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (homework['due_date'] != null)
                Text(
                  DateFormat('d. MMM', 'de_DE').format(DateTime.parse(homework['due_date'] as String)),
                  style: TextStyle(fontSize: 12, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestExamCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isExam;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TestExamCard({required this.item, required this.isExam, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item['subject_color'] != null
        ? Color(int.parse((item['subject_color'] as String).replaceFirst('#', '0xFF')))
        : NexusTheme.primaryColor;

    return Dismissible(
      key: Key('${isExam ? 'exam' : 'test'}_${item['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: NexusTheme.danger, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
        ),
        child: ListTile(
          onTap: onEdit,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isExam ? Icons.edit_note : Icons.quiz, color: color),
          ),
          title: Text(item['title'] as String),
          subtitle: Row(
            children: [
              if (item['subject_name'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item['subject_name'] as String, style: TextStyle(color: color, fontSize: 10)),
                ),
                const SizedBox(width: 8),
              ],
              if (item['date'] != null)
                Text(
                  DateFormat('d. MMM yyyy', 'de_DE').format(DateTime.parse(item['date'] as String)),
                  style: TextStyle(fontSize: 12, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                ),
            ],
          ),
          trailing: item['grade'] != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NexusTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item['grade'] as String, style: TextStyle(color: NexusTheme.success, fontWeight: FontWeight.bold)),
                )
              : null,
        ),
      ),
    );
  }
}

// Full Grade Calculator with all desktop features
class _FullGradeCalculatorCard extends StatefulWidget {
  final bool isDark;
  final List<Map<String, dynamic>> subjects;

  const _FullGradeCalculatorCard({required this.isDark, required this.subjects});

  @override
  State<_FullGradeCalculatorCard> createState() => _FullGradeCalculatorCardState();
}

class _FullGradeCalculatorCardState extends State<_FullGradeCalculatorCard> {
  bool _isExpanded = false;

  // Points <-> Grade converter
  final _pointsController = TextEditingController();
  int? _selectedGradePoints;
  String _converterResult = '';

  // Target grade calculator
  final _currentAvgController = TextEditingController();
  final _gradeCountController = TextEditingController();
  final _targetAvgController = TextEditingController();
  String _targetResult = '';

  // Subject grade calculator (1/3 Klausur + 2/3 Sonstige)
  final _klausur1Controller = TextEditingController();
  final _klausur2Controller = TextEditingController();
  final _klausur3Controller = TextEditingController();
  final _klausur4Controller = TextEditingController();
  final _sonstigeAvgController = TextEditingController();
  final _sonstigeGradesController = TextEditingController();
  String _subjectGradeResult = '';

  static const _gradeTable = [
    {'points': 15, 'grade': '1+', 'rating': 'Sehr gut', 'color': Color(0xFF10B981)},
    {'points': 14, 'grade': '1', 'rating': 'Sehr gut', 'color': Color(0xFF10B981)},
    {'points': 13, 'grade': '1-', 'rating': 'Sehr gut', 'color': Color(0xFF10B981)},
    {'points': 12, 'grade': '2+', 'rating': 'Gut', 'color': Color(0xFF3B82F6)},
    {'points': 11, 'grade': '2', 'rating': 'Gut', 'color': Color(0xFF3B82F6)},
    {'points': 10, 'grade': '2-', 'rating': 'Gut', 'color': Color(0xFF3B82F6)},
    {'points': 9, 'grade': '3+', 'rating': 'Befriedigend', 'color': Color(0xFFF59E0B)},
    {'points': 8, 'grade': '3', 'rating': 'Befriedigend', 'color': Color(0xFFF59E0B)},
    {'points': 7, 'grade': '3-', 'rating': 'Befriedigend', 'color': Color(0xFFF59E0B)},
    {'points': 6, 'grade': '4+', 'rating': 'Ausreichend', 'color': Color(0xFFF97316)},
    {'points': 5, 'grade': '4', 'rating': 'Ausreichend', 'color': Color(0xFFF97316)},
    {'points': 4, 'grade': '4-', 'rating': 'Ausreichend', 'color': Color(0xFFF97316)},
    {'points': 3, 'grade': '5+', 'rating': 'Mangelhaft', 'color': Color(0xFFEF4444)},
    {'points': 2, 'grade': '5', 'rating': 'Mangelhaft', 'color': Color(0xFFEF4444)},
    {'points': 1, 'grade': '5-', 'rating': 'Mangelhaft', 'color': Color(0xFFEF4444)},
    {'points': 0, 'grade': '6', 'rating': 'Ungenügend', 'color': Color(0xFF991B1B)},
  ];

  String _pointsToGrade(int points) {
    if (points < 0 || points > 15) return '-';
    return _gradeTable.firstWhere((e) => e['points'] == points)['grade'] as String;
  }

  String _pointsToRating(int points) {
    if (points < 0 || points > 15) return '-';
    return _gradeTable.firstWhere((e) => e['points'] == points)['rating'] as String;
  }

  Color _pointsToColor(int points) {
    if (points < 0 || points > 15) return Colors.grey;
    return _gradeTable.firstWhere((e) => e['points'] == points)['color'] as Color;
  }

  void _convertPointsToGrade() {
    final points = int.tryParse(_pointsController.text);
    if (points != null && points >= 0 && points <= 15) {
      setState(() {
        _selectedGradePoints = points;
        _converterResult = '${_pointsToGrade(points)} (${_pointsToRating(points)})';
      });
    } else {
      setState(() {
        _selectedGradePoints = null;
        _converterResult = '';
      });
    }
  }

  void _convertGradeToPoints(int? points) {
    if (points != null) {
      setState(() {
        _selectedGradePoints = points;
        _pointsController.text = points.toString();
        _converterResult = '${_pointsToGrade(points)} (${_pointsToRating(points)})';
      });
    }
  }

  void _calculateNeededGrade() {
    final currentAvg = double.tryParse(_currentAvgController.text);
    final gradeCount = int.tryParse(_gradeCountController.text);
    final targetAvg = double.tryParse(_targetAvgController.text);

    if (currentAvg == null || gradeCount == null || targetAvg == null) {
      setState(() => _targetResult = 'Bitte alle Felder ausfüllen');
      return;
    }

    // Formula: (currentAvg * gradeCount + x) / (gradeCount + 1) = targetAvg
    // x = targetAvg * (gradeCount + 1) - currentAvg * gradeCount
    final neededGrade = targetAvg * (gradeCount + 1) - currentAvg * gradeCount;

    setState(() {
      if (neededGrade < 0) {
        _targetResult = 'Du brauchst weniger als 0 Punkte - Ziel bereits erreicht!';
      } else if (neededGrade > 15) {
        _targetResult = 'Du bräuchtest ${neededGrade.toStringAsFixed(1)} Punkte - leider nicht erreichbar';
      } else {
        final roundedGrade = neededGrade.ceil();
        _targetResult = 'Du brauchst mindestens $roundedGrade Punkte (${_pointsToGrade(roundedGrade)})';
      }
    });
  }

  void _calculateSubjectGrade() {
    // Get Klausur grades
    List<double> klausurGrades = [];
    for (final controller in [_klausur1Controller, _klausur2Controller, _klausur3Controller, _klausur4Controller]) {
      final grade = double.tryParse(controller.text);
      if (grade != null && grade >= 0 && grade <= 15) {
        klausurGrades.add(grade);
      }
    }

    // Get Sonstige grades
    List<double> sonstigeGrades = [];
    final sonstigeAvg = double.tryParse(_sonstigeAvgController.text);
    if (sonstigeAvg != null && sonstigeAvg >= 0 && sonstigeAvg <= 15) {
      sonstigeGrades.add(sonstigeAvg);
    } else if (_sonstigeGradesController.text.isNotEmpty) {
      // Parse comma-separated grades
      final parts = _sonstigeGradesController.text.split(RegExp(r'[,;\s]+'));
      for (final part in parts) {
        final grade = double.tryParse(part.trim());
        if (grade != null && grade >= 0 && grade <= 15) {
          sonstigeGrades.add(grade);
        }
      }
    }

    if (klausurGrades.isEmpty && sonstigeGrades.isEmpty) {
      setState(() => _subjectGradeResult = 'Bitte mindestens eine Note eingeben');
      return;
    }

    // Calculate averages
    double? klausurAvg = klausurGrades.isNotEmpty
        ? klausurGrades.reduce((a, b) => a + b) / klausurGrades.length
        : null;
    double? sonstigeAvgCalc = sonstigeGrades.isNotEmpty
        ? sonstigeGrades.reduce((a, b) => a + b) / sonstigeGrades.length
        : null;

    // Calculate final grade with 1/3 + 2/3 weighting
    double finalGrade;
    String breakdown;
    if (klausurAvg != null && sonstigeAvgCalc != null) {
      finalGrade = (klausurAvg * 1 + sonstigeAvgCalc * 2) / 3;
      breakdown = 'Klausuren: ${klausurAvg.toStringAsFixed(1)} (1/3) + Sonstige: ${sonstigeAvgCalc.toStringAsFixed(1)} (2/3)';
    } else if (klausurAvg != null) {
      finalGrade = klausurAvg;
      breakdown = 'Nur Klausuren: ${klausurAvg.toStringAsFixed(1)}';
    } else {
      finalGrade = sonstigeAvgCalc!;
      breakdown = 'Nur Sonstige: ${sonstigeAvgCalc.toStringAsFixed(1)}';
    }

    setState(() {
      _subjectGradeResult = 'Fachnote: ${finalGrade.toStringAsFixed(1)} Punkte (${_pointsToGrade(finalGrade.round())})\n$breakdown';
    });
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _currentAvgController.dispose();
    _gradeCountController.dispose();
    _targetAvgController.dispose();
    _klausur1Controller.dispose();
    _klausur2Controller.dispose();
    _klausur3Controller.dispose();
    _klausur4Controller.dispose();
    _sonstigeAvgController.dispose();
    _sonstigeGradesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NexusTheme.primaryColor.withOpacity(0.1),
            NexusTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header (always visible, tap to expand)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calculate, color: NexusTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Notenrechner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Points <-> Grade Converter
                  _buildSectionTitle('Punkte ⇄ Note'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pointsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Punkte (0-15)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (_) => _convertPointsToGrade(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('⇄', style: TextStyle(fontSize: 20, color: NexusTheme.primaryColor)),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedGradePoints,
                          decoration: InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _gradeTable.map((e) => DropdownMenuItem(
                            value: e['points'] as int,
                            child: Text('${e['grade']} (${e['points']}P)'),
                          )).toList(),
                          onChanged: _convertGradeToPoints,
                        ),
                      ),
                    ],
                  ),
                  if (_converterResult.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedGradePoints != null
                            ? _pointsToColor(_selectedGradePoints!).withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _converterResult,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedGradePoints != null
                                  ? _pointsToColor(_selectedGradePoints!)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Section 2: Target Grade Calculator
                  _buildSectionTitle('Welche Note brauche ich?'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _currentAvgController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Aktueller Ø',
                            hintText: 'z.B. 10.5',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _gradeCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Anzahl',
                            hintText: 'z.B. 5',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _targetAvgController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Ziel-Ø',
                            hintText: 'z.B. 12',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _calculateNeededGrade,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NexusTheme.primaryColor,
                        side: BorderSide(color: NexusTheme.primaryColor),
                      ),
                      child: const Text('Berechnen'),
                    ),
                  ),
                  if (_targetResult.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NexusTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_targetResult, textAlign: TextAlign.center),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Section 3: Subject Grade Calculator (1/3 + 2/3)
                  _buildSectionTitle('Fachnote berechnen (1/3 Klausur + 2/3 Sonstige)'),
                  const SizedBox(height: 12),
                  Text('Klausuren (1/3)', style: TextStyle(fontSize: 12, color: widget.isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildSmallInput(_klausur1Controller, 'K1')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSmallInput(_klausur2Controller, 'K2')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSmallInput(_klausur3Controller, 'K3')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSmallInput(_klausur4Controller, 'K4')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Sonstige Leistungen (2/3)', style: TextStyle(fontSize: 12, color: widget.isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sonstigeAvgController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Ø Sonstige',
                      hintText: 'z.B. 11.5',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('oder einzelne Noten:', style: TextStyle(fontSize: 11, color: widget.isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _sonstigeGradesController,
                    decoration: InputDecoration(
                      hintText: 'z.B. 12, 11, 13, 10, 9',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _calculateSubjectGrade,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NexusTheme.primaryColor,
                        side: BorderSide(color: NexusTheme.primaryColor),
                      ),
                      child: const Text('Fachnote berechnen'),
                    ),
                  ),
                  if (_subjectGradeResult.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NexusTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_subjectGradeResult, textAlign: TextAlign.center),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Section 4: Grade Table
                  _buildSectionTitle('Punkte-Noten-Tabelle'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: widget.isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: NexusTheme.primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(child: Text('Punkte', style: TextStyle(fontWeight: FontWeight.bold))),
                              const Expanded(child: Text('Note', style: TextStyle(fontWeight: FontWeight.bold))),
                              const Expanded(flex: 2, child: Text('Bewertung', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        // Rows
                        ...List.generate(_gradeTable.length, (index) {
                          final entry = _gradeTable[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: (entry['color'] as Color).withOpacity(0.05),
                              border: index < _gradeTable.length - 1
                                  ? Border(bottom: BorderSide(color: widget.isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${entry['points']}',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: entry['color'] as Color),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry['grade'] as String,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: entry['color'] as Color),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    entry['rating'] as String,
                                    style: TextStyle(color: entry['color'] as Color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: NexusTheme.primaryGradient),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildSmallInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }
}

// ============== LESSON CARD & DIALOGS ==============
class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isCurrentLesson;

  const _LessonCard({required this.lesson, required this.onDelete, required this.onEdit, this.isCurrentLesson = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lessonColor = lesson.color != null
        ? Color(int.parse(lesson.color!.replaceFirst('#', '0xFF')))
        : NexusTheme.primaryColor;

    return Dismissible(
      key: Key(lesson.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: NexusTheme.danger, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Stunde löschen?'),
            content: Text('Möchtest du "${lesson.subject}" wirklich löschen?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: NexusTheme.danger),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentLesson ? NexusTheme.primaryColor : (isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
            width: isCurrentLesson ? 2 : 1,
          ),
          boxShadow: isCurrentLesson ? [BoxShadow(color: NexusTheme.primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: lessonColor, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text('${lesson.lessonNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                          const SizedBox(width: 4),
                          Text(lesson.timeRange, style: TextStyle(fontSize: 13, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lesson.teacher != null) Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person, size: 14, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                      const SizedBox(width: 4),
                      Text(lesson.teacher!, style: TextStyle(fontSize: 12, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)),
                    ]),
                    if (lesson.room != null) ...[
                      const SizedBox(height: 2),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.room, size: 14, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                        const SizedBox(width: 4),
                        Text(lesson.room!, style: TextStyle(fontSize: 12, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)),
                      ]),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonDialog extends StatefulWidget {
  final Lesson? lesson;
  final int? dayOfWeek;

  const _LessonDialog({this.lesson, this.dayOfWeek});

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  late TextEditingController _subjectController;
  late TextEditingController _teacherController;
  late TextEditingController _roomController;
  late int _dayOfWeek;
  late int _lessonNumber;
  String _startTime = '08:00';
  String _endTime = '08:45';
  String? _selectedColor;

  static const _colorOptions = ['#667EEA', '#764BA2', '#F093FB', '#22C55E', '#F59E0B', '#EF4444', '#06B6D4', '#8B5CF6'];

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.lesson?.subject ?? '');
    _teacherController = TextEditingController(text: widget.lesson?.teacher ?? '');
    _roomController = TextEditingController(text: widget.lesson?.room ?? '');
    _dayOfWeek = widget.lesson?.dayOfWeek ?? widget.dayOfWeek ?? DateTime.now().weekday;
    if (_dayOfWeek > 5) _dayOfWeek = 1;
    _lessonNumber = widget.lesson?.lessonNumber ?? 1;
    _startTime = widget.lesson?.startTime ?? '08:00';
    _endTime = widget.lesson?.endTime ?? '08:45';
    _selectedColor = widget.lesson?.color;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lesson != null ? 'Stunde bearbeiten' : 'Neue Stunde'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Fach', hintText: 'z.B. Mathematik'), autofocus: true),
            const SizedBox(height: 16),
            TextField(controller: _teacherController, decoration: const InputDecoration(labelText: 'Lehrer (optional)', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 16),
            TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'Raum (optional)', prefixIcon: Icon(Icons.room))),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _dayOfWeek,
              decoration: const InputDecoration(labelText: 'Tag', prefixIcon: Icon(Icons.calendar_today)),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Montag')),
                DropdownMenuItem(value: 2, child: Text('Dienstag')),
                DropdownMenuItem(value: 3, child: Text('Mittwoch')),
                DropdownMenuItem(value: 4, child: Text('Donnerstag')),
                DropdownMenuItem(value: 5, child: Text('Freitag')),
              ],
              onChanged: (value) => setState(() => _dayOfWeek = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _lessonNumber,
              decoration: const InputDecoration(labelText: 'Stunde', prefixIcon: Icon(Icons.format_list_numbered)),
              items: List.generate(10, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n. Stunde'))).toList(),
              onChanged: (value) => setState(() => _lessonNumber = value!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.access_time), title: const Text('Start'), subtitle: Text(_startTime), onTap: () => _selectTime(true))),
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.access_time_filled), title: const Text('Ende'), subtitle: Text(_endTime), onTap: () => _selectTime(false))),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Farbe', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colorOptions.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                          boxShadow: isSelected ? [BoxShadow(color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.5), blurRadius: 8)] : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.lesson != null)
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteLesson(widget.lesson!.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: NexusTheme.danger),
            child: const Text('Löschen'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }

  Future<void> _selectTime(bool isStart) async {
    final currentTime = isStart ? _startTime : _endTime;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final time = await showTimePicker(context: context, initialTime: initialTime);
    if (time != null && mounted) {
      final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) _startTime = formatted; else _endTime = formatted;
      });
    }
  }

  void _save() {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte Fach eingeben')));
      return;
    }

    final provider = context.read<AppProvider>();

    if (widget.lesson != null) {
      provider.updateLesson(widget.lesson!.copyWith(
        subject: _subjectController.text.trim(),
        teacher: _teacherController.text.trim().isEmpty ? null : _teacherController.text.trim(),
        room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        dayOfWeek: _dayOfWeek,
        lessonNumber: _lessonNumber,
        startTime: _startTime,
        endTime: _endTime,
        color: _selectedColor,
      ));
    } else {
      provider.addLesson(
        subject: _subjectController.text.trim(),
        teacher: _teacherController.text.trim().isEmpty ? null : _teacherController.text.trim(),
        room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        dayOfWeek: _dayOfWeek,
        lessonNumber: _lessonNumber,
        startTime: _startTime,
        endTime: _endTime,
        color: _selectedColor,
      );
    }

    Navigator.pop(context);
  }
}

class _IServLoginDialog extends StatefulWidget {
  const _IServLoginDialog();

  @override
  State<_IServLoginDialog> createState() => _IServLoginDialogState();
}

class _IServLoginDialogState extends State<_IServLoginDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('IServ Anmeldung'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'IServ URL', hintText: 'z.B. gymnasium-berlin.de', prefixIcon: Icon(Icons.link)), keyboardType: TextInputType.url),
            const SizedBox(height: 16),
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Benutzername', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Passwort', prefixIcon: Icon(Icons.lock)), obscureText: true),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NexusTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NexusTheme.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: NexusTheme.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(color: NexusTheme.danger, fontSize: 13))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Anmelden'),
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (_urlController.text.trim().isEmpty || _usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Bitte alle Felder ausfüllen');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final provider = context.read<IServProvider>();
      final result = await provider.connect(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        iservUrl: _urlController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IServ erfolgreich verbunden')));
        } else {
          setState(() { _error = result['error'] ?? 'Anmeldung fehlgeschlagen'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Verbindungsfehler: ${e.toString()}'; _isLoading = false; });
    }
  }
}

void showAddLessonDialog(BuildContext context, {int? dayOfWeek}) {
  showDialog(context: context, builder: (context) => _LessonDialog(dayOfWeek: dayOfWeek));
}
