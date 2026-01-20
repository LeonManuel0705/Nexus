import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/lesson.dart';
import '../models/quick_note.dart';
import '../services/database_service.dart' if (dart.library.html) '../services/database_service_web.dart';
import '../services/demo_data_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final DemoDataService _demo = DemoDataService();
  final _uuid = const Uuid();

  List<Task> _tasks = [];
  List<Event> _events = [];
  List<Lesson> _lessons = [];
  int _openTaskCount = 0;
  int _todayEventCount = 0;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _demoMode = false;

  List<Task> get tasks => _demoMode ? _demo.getDemoTasks() : _tasks;
  List<Event> get events => _demoMode ? _demo.getDemoEvents() : _events;
  List<Lesson> get lessons => _demoMode ? _demo.getDemoLessons() : _lessons;
  int get openTaskCount => _demoMode ? _demo.getDemoOpenTaskCount() : _openTaskCount;
  int get todayEventCount => _demoMode ? _demo.getDemoTodayEventCount() : _todayEventCount;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  bool get demoMode => _demoMode;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _demoMode = prefs.getBool('demo_mode') ?? false;

      if (!_demoMode) {
        await Future.wait([
          loadTasks(),
          loadEvents(),
          loadLessons(),
          loadStats(),
        ]);
      }
    } catch (e) {
      debugPrint('AppProvider initialize error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setDemoMode(bool enabled) async {
    _demoMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode', enabled);
    notifyListeners();
  }

  Future<void> toggleDemoMode() async {
    await setDemoMode(!_demoMode);
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> loadTasks() async {
    try {
      _tasks = await _db.getTasks();
      notifyListeners();
    } catch (e) {
      debugPrint('loadTasks error: $e');
    }
  }

  Future<List<Task>> getTodayTasks() async {
    if (_demoMode) return _demo.getDemoTodayTasks();
    return await _db.getTodayTasks();
  }

  Future<List<Task>> getOpenTasks() async {
    if (_demoMode) return _demo.getDemoOpenTasks();
    return await _db.getOpenTasks();
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String category = 'general',
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertTask(task);
    await loadTasks();
    await loadStats();
  }

  Future<void> updateTask(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());
    await _db.updateTask(updatedTask);
    await loadTasks();
    await loadStats();
  }

  Future<void> toggleTaskComplete(String id) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      await _db.toggleTaskComplete(id, !task.completed);
      await loadTasks();
      await loadStats();
    }
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    await loadTasks();
    await loadStats();
  }

  Future<void> loadEvents() async {
    try {
      _events = await _db.getEvents();
      notifyListeners();
    } catch (e) {
      debugPrint('loadEvents error: $e');
    }
  }

  Future<List<Event>> getTodayEvents() async {
    if (_demoMode) return _demo.getDemoTodayEvents();
    return await _db.getTodayEvents();
  }

  Future<List<Event>> getUpcomingEvents({int days = 7}) async {
    if (_demoMode) return _demo.getDemoUpcomingEvents(days: days);
    return await _db.getUpcomingEvents(days: days);
  }

  Future<void> addEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
    bool allDay = false,
    String? color,
    String category = 'personal',
  }) async {
    final now = DateTime.now();
    final event = Event(
      id: _uuid.v4(),
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      allDay: allDay,
      color: color,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertEvent(event);
    await loadEvents();
    await loadStats();
  }

  Future<void> updateEvent(Event event) async {
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());
    await _db.updateEvent(updatedEvent);
    await loadEvents();
    await loadStats();
  }

  Future<void> deleteEvent(String id) async {
    await _db.deleteEvent(id);
    await loadEvents();
    await loadStats();
  }

  Future<void> loadLessons() async {
    try {
      _lessons = await _db.getLessons();
      notifyListeners();
    } catch (e) {
      debugPrint('loadLessons error: $e');
    }
  }

  Future<List<Lesson>> getTodayLessons() async {
    if (_demoMode) return _demo.getDemoTodayLessons();
    return await _db.getTodayLessons();
  }

  Future<List<Lesson>> getLessonsByDay(int dayOfWeek) async {
    if (_demoMode) {
      return _demo.getDemoLessons().where((l) => l.dayOfWeek == dayOfWeek).toList();
    }
    return await _db.getLessonsByDay(dayOfWeek);
  }

  Future<void> addLesson({
    required String subject,
    String? teacher,
    String? room,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int lessonNumber,
    String? color,
    String? lessonType,
  }) async {
    final now = DateTime.now();
    final lesson = Lesson(
      id: _uuid.v4(),
      subject: subject,
      teacher: teacher,
      room: room,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      lessonNumber: lessonNumber,
      color: color,
      lessonType: lessonType,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertLesson(lesson);
    await loadLessons();
  }

  Future<void> updateLesson(Lesson lesson) async {
    final updatedLesson = lesson.copyWith(updatedAt: DateTime.now());
    await _db.updateLesson(updatedLesson);
    await loadLessons();
  }

  Future<void> deleteLesson(String id) async {
    await _db.deleteLesson(id);
    await loadLessons();
  }

  Future<void> loadStats() async {
    try {
      _openTaskCount = await _db.getOpenTaskCount();
      _todayEventCount = await _db.getTodayEventCount();
      notifyListeners();
    } catch (e) {
      debugPrint('loadStats error: $e');
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    if (_demoMode) return _demo.getDemoSubjects();
    return await _db.getSubjects();
  }

  Future<int> addSubject({
    required String name,
    String? shortName,
    String? color,
    String? teacher,
    String? room,
  }) async {
    return await _db.insertSubject(
      name: name,
      shortName: shortName,
      color: color,
      teacher: teacher,
      room: room,
    );
  }

  Future<void> addHomework({
    required String title,
    int? subjectId,
    String? notes,
    DateTime? dueDate,
  }) async {
    await _db.insertHomework(
      id: _uuid.v4(),
      title: title,
      subjectId: subjectId,
      notes: notes,
      dueDate: dueDate,
    );
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getHomework() async {
    if (_demoMode) return _demo.getDemoHomework();
    return await _db.getHomework();
  }

  Future<List<Map<String, dynamic>>> getOpenHomework() async {
    if (_demoMode) return _demo.getDemoOpenHomework();
    return await _db.getOpenHomework();
  }

  Future<void> toggleHomeworkComplete(String id, bool completed) async {
    await _db.toggleHomeworkComplete(id, completed);
    notifyListeners();
  }

  Future<void> deleteHomework(String id) async {
    await _db.deleteHomework(id);
    notifyListeners();
  }

  Future<void> addQuickNote({
    required String type,
    required String title,
    String? content,
  }) async {
    final now = DateTime.now();
    final wordCount = QuickNote.calculateWordCount(content ?? '');

    final note = QuickNote(
      id: _uuid.v4(),
      type: type,
      title: title,
      content: content ?? '',
      wordCount: wordCount,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertQuickNote(note);
    notifyListeners();
  }
}
