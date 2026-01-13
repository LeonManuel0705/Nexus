import 'package:flutter/material.dart';
import '../services/calendar_sync_service.dart';
import '../services/connectivity_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncProvider extends ChangeNotifier {
  final CalendarSyncService _calendarService = CalendarSyncService();
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  String? _userEmail;
  String? get userEmail => _userEmail;

  List<GoogleCalendar> _calendars = [];
  List<GoogleCalendar> get calendars => _calendars;

  List<GoogleCalendar> get selectedCalendars =>
      _calendars.where((c) => c.isSelected).toList();

  List<GoogleEvent> _events = [];
  List<GoogleEvent> get events => _events;

  List<GoogleEvent> get todayEvents {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _events.where((e) {
      return e.start.isAfter(startOfDay) && e.start.isBefore(endOfDay);
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  List<GoogleEvent> get upcomingEvents {
    final now = DateTime.now();
    return _events.where((e) => e.start.isAfter(now))
        .take(10)
        .toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  SyncStatus _syncStatus = SyncStatus.idle;
  SyncStatus get syncStatus => _syncStatus;

  bool get isSyncing => _syncStatus == SyncStatus.syncing;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  String? _error;
  String? get error => _error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isOnline => _connectivity.isOnline.value;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isSignedIn = await _calendarService.hasValidCredentials();

      if (_isSignedIn) {
        await loadCalendars();
        await loadEvents();
      }
    } catch (e) {
      _error = 'Fehler bei der Initialisierung';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle({
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
    String? email,
  }) async {
    try {
      await _calendarService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiry: expiry,
      );

      _isSignedIn = true;
      _userEmail = email;

      await loadCalendars();
      await syncAll();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Anmeldung fehlgeschlagen';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _calendarService.clearTokens();
    _isSignedIn = false;
    _userEmail = null;
    _calendars = [];
    _events = [];
    _lastSync = null;
    notifyListeners();
  }

  Future<void> loadCalendars() async {
    try {
      _calendars = await _calendarService.getCalendars();
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Laden der Kalender';
      notifyListeners();
    }
  }

  Future<void> toggleCalendarSelection(String calendarId) async {
    final index = _calendars.indexWhere((c) => c.id == calendarId);
    if (index != -1) {
      _calendars[index] = _calendars[index].copyWith(
        isSelected: !_calendars[index].isSelected,
      );
      notifyListeners();
      await loadEvents();
    }
  }

  Future<void> loadEvents({DateTime? from, DateTime? to}) async {
    try {
      from ??= DateTime.now().subtract(const Duration(days: 7));
      to ??= DateTime.now().add(const Duration(days: 30));

      _events = await _calendarService.getAllEvents(from: from, to: to);
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Laden der Termine';
      notifyListeners();
    }
  }

  Future<void> syncAll() async {
    if (!isOnline) {
      _error = 'Keine Internetverbindung';
      notifyListeners();
      return;
    }

    _syncStatus = SyncStatus.syncing;
    _error = null;
    notifyListeners();

    try {
      final results = await _calendarService.syncAllCalendars();

      bool allSuccess = results.values.every((r) => r.success);
      if (allSuccess) {
        _syncStatus = SyncStatus.success;
        _lastSync = DateTime.now();
      } else {
        _syncStatus = SyncStatus.error;
        final errors = results.values.where((r) => !r.success).map((r) => r.error);
        _error = errors.isNotEmpty ? errors.first : 'Sync fehlgeschlagen';
      }

      await loadEvents();
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _error = 'Sync fehlgeschlagen: $e';
    }

    notifyListeners();
  }

  Future<GoogleEvent?> createEvent({
    required String summary,
    required DateTime start,
    required DateTime end,
    bool isAllDay = false,
    String? description,
    String? location,
    String? calendarId,
  }) async {

    final targetCalendar = calendarId ??
        _calendars.where((c) => c.isPrimary).firstOrNull?.id ??
        _calendars.firstOrNull?.id;

    if (targetCalendar == null) {
      _error = 'Kein Kalender verfügbar';
      notifyListeners();
      return null;
    }

    try {
      final event = await _calendarService.createEvent(
        calendarId: targetCalendar,
        summary: summary,
        start: start,
        end: end,
        isAllDay: isAllDay,
        description: description,
        location: location,
      );

      if (event != null) {
        _events.add(event);
        _events.sort((a, b) => a.start.compareTo(b.start));
        notifyListeners();
      }

      return event;
    } catch (e) {
      _error = 'Fehler beim Erstellen des Termins';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateEvent(GoogleEvent event) async {
    try {
      final success = await _calendarService.updateEvent(event);

      if (success) {
        final index = _events.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          _events[index] = event;
          _events.sort((a, b) => a.start.compareTo(b.start));
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _error = 'Fehler beim Aktualisieren des Termins';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    final event = _events.where((e) => e.id == eventId).firstOrNull;
    if (event == null) return false;

    try {
      final success = await _calendarService.deleteEvent(eventId, event.calendarId);

      if (success) {
        _events.removeWhere((e) => e.id == eventId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Fehler beim Löschen des Termins';
      notifyListeners();
      return false;
    }
  }

  List<GoogleEvent> getEventsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _events.where((e) {

      if (e.start.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          e.start.isBefore(endOfDay)) {
        return true;
      }

      if (e.start.isBefore(startOfDay) && e.end.isAfter(startOfDay)) {
        return true;
      }
      return false;
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  List<GoogleEvent> getEventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _events.where((e) {
      return e.start.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
             e.start.isBefore(weekEnd);
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String get lastSyncDisplay {
    if (_lastSync == null) return 'Noch nie synchronisiert';
    final diff = DateTime.now().difference(_lastSync!);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return '${_lastSync!.day}.${_lastSync!.month}.';
  }
}
