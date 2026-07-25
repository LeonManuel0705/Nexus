import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/iserv.dart';
import '../services/iserv_service.dart' if (dart.library.html) '../services/iserv_service_web.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';

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

  String? get iservUrl => _service.iservUrl;
  String get serviceApiLog => kDebugMode ? _service.apiLog : '';
  String get discoveryLog => kDebugMode ? _service.discoveryLog : '';

  List<IServNotification> _notifications = [];
  List<IServNotification> get notifications => _notifications;

  List<IServExercise> _exercises = [];
  List<IServExercise> get exercises => _exercises;

  List<IServEvent> _events = [];
  List<IServEvent> get events => _events;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  List<Map<String, dynamic>> _vertretungsplanFiles = [];
  List<Map<String, dynamic>> get vertretungsplanFiles => _vertretungsplanFiles;

  String? _vertretungsplanHtml;
  String? get vertretungsplanHtml => _vertretungsplanHtml;

  bool _isVertretungsplanLoading = false;
  bool get isVertretungsplanLoading => _isVertretungsplanLoading;

  bool _isVertretungsplanFromCache = false;
  bool get isVertretungsplanFromCache => _isVertretungsplanFromCache;

  String? _vertretungsplanError;
  String? get vertretungsplanError => _vertretungsplanError;

  DateTime? _vertretungsplanCachedAt;
  DateTime? get vertretungsplanCachedAt => _vertretungsplanCachedAt;

  int? _userGrade;
  int? get userGrade => _userGrade;

  bool _gradeAutoIncrement = true;
  bool get gradeAutoIncrement => _gradeAutoIncrement;

  Future<void> setUserGrade(int? grade) async {
    _userGrade = grade;
    final prefs = await SharedPreferences.getInstance();
    if (grade != null) {
      await prefs.setInt('iserv_user_grade', grade);
    } else {
      await prefs.remove('iserv_user_grade');
    }
    _invalidateCache();
    notifyListeners();
    if (_isConnected) await syncData();
  }

  Future<void> setGradeAutoIncrement(bool value) async {
    _gradeAutoIncrement = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iserv_grade_auto_increment', value);
    notifyListeners();
  }

  void _checkGradeAutoIncrement(SharedPreferences prefs) {
    if (!_gradeAutoIncrement || _userGrade == null) return;
    final lastCheck = prefs.getString('iserv_grade_last_check');
    final now = DateTime.now();
    if (now.month >= 8) {
      final thisYear = now.year.toString();
      if (lastCheck == null || !lastCheck.startsWith(thisYear)) {
        _userGrade = (_userGrade! + 1).clamp(5, 13);
        prefs.setInt('iserv_user_grade', _userGrade!);
        prefs.setString('iserv_grade_last_check', now.toIso8601String().substring(0, 7));
        _log('Grade auto-incremented to $_userGrade');
      }
    }
  }

  String _debugLog = '';
  String get debugLog => kDebugMode ? _debugLog : '';

  String? _lastSyncResult;
  String? get lastSyncResult => _lastSyncResult;

  void _log(String msg) {
    if (kDebugMode) {
      print('IServProvider: $msg');
      _debugLog += '${DateTime.now().toString().substring(11, 19)} $msg\n';
      if (_debugLog.length > 2000) {
        _debugLog = _debugLog.substring(_debugLog.length - 1500);
      }
    }
  }

  int _cachedUnreadNotifications = 0;
  int _cachedOpenExercises = 0;
  int _cachedOverdueExercises = 0;
  List<IServEvent>? _cachedUpcomingEvents;
  List<Event>? _cachedCalendarEvents;

  int get unreadNotifications => _cachedUnreadNotifications;
  int get openExercises => _cachedOpenExercises;
  int get overdueExercises => _cachedOverdueExercises;

  List<IServEvent> get upcomingEvents {
    if (_cachedUpcomingEvents != null) return _cachedUpcomingEvents!;
    final now = DateTime.now();
    _cachedUpcomingEvents = _events
        .where((e) => e.startTime?.isAfter(now) ?? false)
        .take(5)
        .toList();
    return _cachedUpcomingEvents!;
  }

  bool _showIServInCalendar = true;
  bool get showIServInCalendar => _showIServInCalendar;
  set showIServInCalendar(bool value) {
    _showIServInCalendar = value;
    _invalidateCalendarCache();
    notifyListeners();
  }

  List<Event> get calendarEvents {
    if (!_showIServInCalendar) return const [];
    if (_cachedCalendarEvents != null) return _cachedCalendarEvents!;
    _cachedCalendarEvents = _events
        .where((e) => e.startTime != null)
        .map((e) => e.toCalendarEvent())
        .whereType<Event>()
        .toList();
    return _cachedCalendarEvents!;
  }

  void _invalidateCache() {
    _cachedUnreadNotifications = _notifications.where((n) => !n.read).length;
    _cachedOpenExercises = _exercises.where((e) => e.status == 'open').length;
    _cachedOverdueExercises = _exercises.where((e) => e.isOverdue).length;
    _cachedUpcomingEvents = null;
    _cachedCalendarEvents = null;
  }

  void _invalidateCalendarCache() {
    _cachedCalendarEvents = null;
  }

  bool _isInitializing = false;

  Future<void> initialize() async {
    if (_isInitializing) {
      _log('initialize() skipped — already in progress');
      return;
    }
    _isInitializing = true;
    _log('initialize() called');
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _userGrade = prefs.getInt('iserv_user_grade');
      _gradeAutoIncrement = prefs.getBool('iserv_grade_auto_increment') ?? true;
      _checkGradeAutoIncrement(prefs);

      await _loadCachedData();
      _log('Cached: ${_events.length} events, ${_notifications.length} notif, ${_exercises.length} exercises');
      _log('Grade: $_userGrade, autoIncrement: $_gradeAutoIncrement');

      final credentials = await _service.getSavedCredentials();
      _log('Credentials: ${credentials != null ? "found (${credentials.username})" : "none"}');

      if (credentials != null) {
        _username = credentials.username;

        _log('Online: ${_connectivity.isOnline.value}');
        if (_connectivity.isOnline.value) {
          final connected = await _service.autoReconnect();
          _isConnected = connected;
          _log('autoReconnect: $connected');

          if (connected) {
            await syncData();
            _log('After sync: ${_events.length} events, ${calendarEvents.length} calEvents');
          }
        }
      }

      _connectivity.onConnected(_onConnectivityRestored);
    } catch (e) {
      _log('initialize ERROR: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onConnectivityRestored() {
    if (_isConnected || _username != null) {
      syncData().catchError((e) {
        _log('Connectivity restored sync error: $e');
      });
    }
  }

  Future<void> _loadCachedData() async {
    _notifications = await _service.getCachedNotifications();
    _exercises = await _service.getCachedExercises();
    _events = await _service.getCachedEvents();
    _invalidateCache();
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

  Future<Map<String, dynamic>> connectWithWebViewCookies({
    required String iservUrl,
    required List<dynamic> cookies,
    String? username,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.connectWithWebViewCookies(
        iservUrl: iservUrl,
        cookies: cookies,
        username: username,
      );

      if (result['success'] == true) {
        _isConnected = true;
        _username = result['username'] as String? ?? username ?? 'IServ-Nutzer';
        _vertretungsplanError = null;
        _vertretungsplanFiles = [];
        _log('WebView login OK, username=$_username');
        await syncData();
        await fetchVertretungsplan();
        return {'success': true};
      } else {
        _error = result['error'] as String?;
        _log('WebView login FAILED: $_error');
        return {'success': false, 'error': _error ?? 'Anmeldung fehlgeschlagen'};
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncData() async {
    if (_isSyncing) return;
    _log('syncData() called, isConnected=$_isConnected');
    if (!_isConnected) {
      final reconnected = await _service.autoReconnect();
      if (!reconnected) {
        _log('syncData: autoReconnect failed, aborting');
        return;
      }
      _isConnected = true;
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
      _invalidateCache();
      _lastSyncResult = 'OK: ${_events.length} Termine, ${_notifications.length} Nachrichten';
      _log('syncData DONE: ${_events.length} events, ${_notifications.length} notif, ${_exercises.length} exercises');
    } catch (e) {
      _lastSyncResult = 'Synchronisation fehlgeschlagen';
      _log('syncData ERROR: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncNotifications() async {
    final previousIds = _notifications.map((n) => n.id).toSet();
    _notifications = await _service.getNotifications();

    final newUnread = _notifications.where(
      (n) => !n.read && !previousIds.contains(n.id),
    ).toList();

    for (int i = 0; i < newUnread.length; i++) {
      final n = newUnread[i];
      await NotificationService().showNotification(
        id: n.id.hashCode,
        title: n.title,
        body: n.message ?? 'Neue IServ-Benachrichtigung',
      );
    }
  }

  Future<void> _syncExercises() async {
    _exercises = await _service.getExercises();
  }

  Future<void> _syncEvents() async {
    _log('Syncing events... (grade=$_userGrade)');
    _service.clearApiLog();
    _events = await _service.getEvents(userGrade: _userGrade);
    final apiLog = _service.apiLog;
    if (apiLog.isNotEmpty) {
      _log('API log:\n$apiLog');
    }
    _log('Events synced: ${_events.length} events');
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _cachedUnreadNotifications = _notifications.where((n) => !n.read).length;
      notifyListeners();
    }
  }

  Future<void> fetchVertretungsplan() async {
    _isVertretungsplanLoading = true;
    _vertretungsplanError = null;
    notifyListeners();

    try {
      final iservUrl = _service.iservUrl;
      final hasValidCookies = await _service.hasValidCookies();

      if (iservUrl != null && !hasValidCookies) {
        try {
          final cookieManager = CookieManager.instance();
          final cookies = await cookieManager.getCookies(url: WebUri(iservUrl));

          if (cookies.isNotEmpty) {
            await _service.refreshWithWebViewCookies(cookies);
          } else {
            _vertretungsplanError = 'Sitzung abgelaufen. Bitte erneut mit IServ anmelden.';
            _vertretungsplanFiles = [];
            _isVertretungsplanLoading = false;
            notifyListeners();
            return;
          }
        } catch (e) {
          _log('CookieManager not available: $e');
        }
      }

      final result = await _service.fetchVertretungsplan();

      if (result['success'] == true) {
        if (result['files'] != null) {
          _vertretungsplanFiles = List<Map<String, dynamic>>.from(result['files'] as List);
        }

        _vertretungsplanHtml = result['html'] as String?;

        _isVertretungsplanFromCache = result['isFromCache'] == true;

        if (result['cachedAt'] != null) {
          _vertretungsplanCachedAt = DateTime.tryParse(result['cachedAt'] as String);
        } else if (!_isVertretungsplanFromCache) {
          _vertretungsplanCachedAt = DateTime.now();
        }
      } else {
        _vertretungsplanError = result['error'] as String?;
        _vertretungsplanFiles = [];
      }
    } catch (e) {
      _log('Vertretungsplan load error: $e');
      _vertretungsplanError = 'Fehler beim Laden. Bitte versuche es erneut.';
      _vertretungsplanFiles = [];
    } finally {
      _isVertretungsplanLoading = false;
      notifyListeners();
    }
  }
}
