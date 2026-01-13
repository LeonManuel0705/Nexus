import 'package:flutter/material.dart';
import '../models/iserv.dart';
import '../services/iserv_service.dart';
import '../services/connectivity_service.dart';

class IServProvider extends ChangeNotifier {
  final IServService _service = IServService();
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _error;
  String? get error => _error;

  String? _username;
  String? get username => _username;

  List<IServNotification> _notifications = [];
  List<IServNotification> get notifications => _notifications;

  List<IServExercise> _exercises = [];
  List<IServExercise> get exercises => _exercises;

  List<IServEvent> _events = [];
  List<IServEvent> get events => _events;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  int get unreadNotifications =>
      _notifications.where((n) => !n.read).length;

  int get openExercises =>
      _exercises.where((e) => e.status == 'open').length;

  int get overdueExercises =>
      _exercises.where((e) => e.isOverdue).length;

  List<IServEvent> get upcomingEvents {
    final now = DateTime.now();
    return _events
        .where((e) => e.startTime?.isAfter(now) ?? false)
        .take(5)
        .toList();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {

      await _loadCachedData();

      final credentials = await _service.getSavedCredentials();
      if (credentials != null) {
        _username = credentials.username;

        if (_connectivity.isOnline.value) {
          final connected = await _service.autoReconnect();
          _isConnected = connected;

          if (connected) {
            await syncData();
          }
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCachedData() async {
    _notifications = await _service.getCachedNotifications();
    _exercises = await _service.getCachedExercises();
    _events = await _service.getCachedEvents();
  }

  Future<Map<String, dynamic>> connect({
    required String username,
    required String password,
    required String iservUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.connect(
        username: username,
        password: password,
        iservUrl: iservUrl,
      );

      if (result['success'] == true) {
        _isConnected = true;
        _username = username;
        await syncData();
        return {'success': true};
      } else {
        _error = result['error'] as String?;
        return {'success': false, 'error': _error ?? 'Anmeldung fehlgeschlagen'};
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    _isConnected = false;
    _username = null;
    _notifications = [];
    _exercises = [];
    _events = [];
    _lastSync = null;
    notifyListeners();
  }

  Future<void> syncData() async {
    if (!_isConnected && !await _service.autoReconnect()) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      await Future.wait([
        _syncNotifications(),
        _syncExercises(),
        _syncEvents(),
      ]);
      _lastSync = DateTime.now();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncNotifications() async {
    _notifications = await _service.getNotifications();
  }

  Future<void> _syncExercises() async {
    _exercises = await _service.getExercises();
  }

  Future<void> _syncEvents() async {
    _events = await _service.getEvents();
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
    }
  }
}
