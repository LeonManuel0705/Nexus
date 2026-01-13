import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Task> _tasks = [];
  bool _isLoading = false;
  Map<String, int> _stats = {};

  List<Task> get tasks => _tasks;
  List<Task> get pendingTasks => _tasks.where((t) => !t.completed).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.completed).toList();
  bool get isLoading => _isLoading;
  Map<String, int> get stats => _stats;

  Future<void> loadTasks({bool? completed, String? category}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _db.getTasks(completed: completed, category: category);
      _stats = await _db.getTaskStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    final id = await _db.insertTask(task);
    _tasks.add(task.copyWith(id: id));
    _stats = await _db.getTaskStats();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    notifyListeners();
  }

  Future<void> toggleComplete(int id) async {
    await _db.toggleTaskComplete(id);
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        completed: !task.completed,
        completedAt: !task.completed ? DateTime.now() : null,
      );
    }
    _stats = await _db.getTaskStats();
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    _stats = await _db.getTaskStats();
    notifyListeners();
  }

  List<Task> getTasksForDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _tasks.where((t) => t.dueDate == dateStr).toList();
  }

  List<Task> getTodaysTasks() {
    return getTasksForDate(DateTime.now());
  }

  List<Task> getOverdueTasks() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _tasks
        .where((t) =>
            !t.completed && t.dueDate != null && t.dueDate!.compareTo(todayStr) < 0)
        .toList();
  }
}
