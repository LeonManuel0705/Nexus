import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/iserv.dart';
import '../services/iserv_service.dart' if (dart.library.html) '../services/iserv_service_web.dart';
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

  /// Get the IServ base URL for WebView access
  String? get iservUrl => _service.iservUrl;

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
    } catch (_) {
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

  /// Connect using cookies from WebView login
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
        await syncData();
        fetchVertretungsplan();
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

  /// Fetch Vertretungsplan files (PDFs/images) using authenticated IServ session
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
        } catch (_) {
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
      _vertretungsplanError = 'Fehler beim Laden: ${e.toString()}';
      _vertretungsplanFiles = [];
    } finally {
      _isVertretungsplanLoading = false;
      notifyListeners();
    }
  }
}
