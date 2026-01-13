import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../models/iserv.dart';
import 'database_service.dart';
import 'encryption_service.dart';

class IServService {
  static final IServService _instance = IServService._internal();
  factory IServService() => _instance;
  IServService._internal();

  final DatabaseService _db = DatabaseService();
  final EncryptionService _encryption = EncryptionService();
  final Dio _dio = Dio();

  String? _sessionToken;
  String? _baseUrl;
  String? _currentUsername;

  bool get isConnected => _sessionToken != null;

  Future<Map<String, dynamic>> connect({
    required String username,
    required String password,
    required String iservUrl,
  }) async {
    try {

      String normalizedUrl = iservUrl
          .replaceAll(RegExp(r'^https?://'), '')
          .replaceAll(RegExp(r'/+$'), '');
      _baseUrl = 'https://$normalizedUrl';

      final dio = Dio();
      dio.options.baseUrl = _baseUrl!;
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);
      dio.options.followRedirects = false;
      dio.options.validateStatus = (status) => status != null && status < 500;

      String? csrfToken;
      String sessionCookie = '';

      try {
        final loginPageResponse = await dio.get('/iserv/login');
        final loginCookies = loginPageResponse.headers['set-cookie'];
        if (loginCookies != null) {
          sessionCookie = loginCookies.map((c) => c.split(';').first).join('; ');
        }

        final pageContent = loginPageResponse.data?.toString() ?? '';
        final csrfMatch = RegExp(r'name="_csrf_token"\s+value="([^"]+)"').firstMatch(pageContent);
        csrfToken = csrfMatch?.group(1);
      } catch (e) {

      }

      final loginData = {
        '_username': username,
        '_password': password,
      };
      if (csrfToken != null) {
        loginData['_csrf_token'] = csrfToken;
      }

      final response = await dio.post(
        '/iserv/login_check',
        data: loginData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Cookie': sessionCookie,
            'Origin': _baseUrl,
            'Referer': '$_baseUrl/iserv/login',
          },
        ),
      );

      final responseCookies = response.headers['set-cookie'];
      if (responseCookies != null && responseCookies.isNotEmpty) {
        for (final cookie in responseCookies) {
          final cookiePart = cookie.split(';').first;
          if (cookiePart.contains('=')) {
            if (sessionCookie.isNotEmpty) {
              sessionCookie += '; ';
            }
            sessionCookie += cookiePart;
          }
        }
      }

      String? finalLocation = response.headers.value('location');
      int redirectCount = 0;
      const maxRedirects = 5;

      while (finalLocation != null && redirectCount < maxRedirects) {
        redirectCount++;

        String redirectUrl = finalLocation;
        if (!redirectUrl.startsWith('http')) {
          redirectUrl = redirectUrl.startsWith('/')
              ? '$_baseUrl$redirectUrl'
              : '$_baseUrl/$redirectUrl';
        }

        try {
          final redirectResponse = await dio.get(
            redirectUrl,
            options: Options(
              headers: {'Cookie': sessionCookie},
              followRedirects: false,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          final moreCookies = redirectResponse.headers['set-cookie'];
          if (moreCookies != null) {
            for (final cookie in moreCookies) {
              final cookiePart = cookie.split(';').first;
              if (cookiePart.contains('=') && !sessionCookie.contains(cookiePart.split('=').first)) {
                sessionCookie += '; $cookiePart';
              }
            }
          }

          finalLocation = redirectResponse.headers.value('location');

          if (redirectResponse.statusCode == 200) {
            final body = redirectResponse.data?.toString() ?? '';

            if (body.contains('_username') && body.contains('_password') && body.contains('login_check')) {
              return {'success': false, 'error': 'Benutzername oder Passwort falsch'};
            }

            // Successfully logged in if we're on an IServ page without login form
            if (body.contains('/iserv/') && !body.contains('login_check')) {
              break;
            }
          }
        } catch (e) {
          break;
        }
      }

      // Check for any valid session cookie (IServ uses different names across versions)
      // Common patterns: IServSession, IServSAT, PHPSESSID, session, _session
      final hasSessionCookie = sessionCookie.contains('IServ') ||
                                sessionCookie.contains('PHPSESSID') ||
                                sessionCookie.contains('session') ||
                                sessionCookie.contains('SESS');

      if (!hasSessionCookie || sessionCookie.isEmpty) {
        return {'success': false, 'error': 'Keine gültige Session erhalten. Bitte Zugangsdaten prüfen.'};
      }

      // Verify we can actually access a logged-in page
      try {
        final verifyResponse = await dio.get(
          '/iserv/',
          options: Options(
            headers: {'Cookie': sessionCookie},
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        final verifyBody = verifyResponse.data?.toString() ?? '';

        // Check if we got redirected back to login
        if (verifyBody.contains('login_check') || verifyBody.contains('_username')) {
          return {'success': false, 'error': 'Anmeldung fehlgeschlagen. Bitte Zugangsdaten prüfen.'};
        }
      } catch (e) {
        // Ignore verification errors, proceed with session
      }

      _sessionToken = sessionCookie;
      _currentUsername = username;

      _dio.options.baseUrl = _baseUrl!;

      final credentialKey = await _encryption.storeIServCredentials(
        username: username,
        password: password,
        iservUrl: _baseUrl!,
      );

      final db = await _db.database;
      await db.insert(
        'iserv_credentials',
        IServCredentials(
          username: username,
          iservUrl: _baseUrl!,
          credentialKey: credentialKey,
          createdAt: DateTime.now(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {'success': true, 'username': username};
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'error': 'Verbindung zum Server fehlgeschlagen. Bitte Netzwerk prüfen.'};
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'error': 'Server antwortet nicht. Bitte später erneut versuchen.'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'error': 'Keine Internetverbindung oder Server nicht erreichbar.'};
      }
      return {'success': false, 'error': 'Verbindungsfehler: ${e.message ?? 'Unbekannter Fehler'}'};
    } catch (e) {
      return {'success': false, 'error': 'Fehler: ${e.toString()}'};
    }
  }

  Future<void> disconnect() async {
    _sessionToken = null;
    _baseUrl = null;
    _currentUsername = null;

    final db = await _db.database;
    await db.delete('iserv_credentials');
  }

  Future<IServCredentials?> getSavedCredentials() async {
    final db = await _db.database;
    final results = await db.query('iserv_credentials', limit: 1);
    if (results.isEmpty) return null;
    return IServCredentials.fromMap(results.first);
  }

  Future<bool> autoReconnect() async {
    final credentials = await getSavedCredentials();
    if (credentials == null) return false;

    final savedCreds = await _encryption.getIServCredentials(credentials.credentialKey);
    if (savedCreds == null) return false;

    final result = await connect(
      username: savedCreds['username']!,
      password: savedCreds['password']!,
      iservUrl: savedCreds['iserv_url']!,
    );

    return result['success'] == true;
  }

  Future<List<IServNotification>> getNotifications() async {
    if (!isConnected) return [];

    try {
      final response = await _dio.get(
        '/iserv/messenger/api/messages',
        options: Options(
          headers: {'Cookie': _sessionToken},
        ),
      );

      if (response.statusCode != 200) return [];

      final data = response.data;
      final List<IServNotification> notifications = [];
      final now = DateTime.now();

      if (data is List) {
        for (final item in data) {
          notifications.add(IServNotification(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? item['subject'] ?? '',
            message: item['message'] ?? item['body'] ?? '',
            type: item['type'],
            read: item['read'] == true,
            timestamp: item['date'] != null
                ? DateTime.parse(item['date'])
                : now,
            cachedAt: now,
          ));
        }
      }

      await _cacheNotifications(notifications);

      return notifications;
    } catch (e) {

      return getCachedNotifications();
    }
  }

  Future<List<IServExercise>> getExercises() async {
    if (!isConnected) return [];

    try {
      final response = await _dio.get(
        '/iserv/exercise/api/exercises',
        options: Options(
          headers: {'Cookie': _sessionToken},
        ),
      );

      if (response.statusCode != 200) return [];

      final data = response.data;
      final List<IServExercise> exercises = [];
      final now = DateTime.now();

      if (data is Map && data['data'] is List) {
        for (final item in data['data']) {
          exercises.add(IServExercise(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            description: item['description'],
            course: item['course']?['name'] ?? item['course'],
            teacher: item['teacher']?['name'] ?? item['teacher'],
            dueDate: item['endDate'] != null
                ? DateTime.parse(item['endDate'])
                : null,
            status: item['status'] ?? 'open',
            cachedAt: now,
          ));
        }
      }

      await _cacheExercises(exercises);

      return exercises;
    } catch (e) {

      return getCachedExercises();
    }
  }

  Future<List<IServEvent>> getEvents() async {
    if (!isConnected) return [];

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final end = now.add(const Duration(days: 30));

      final response = await _dio.get(
        '/iserv/calendar/api/events',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        options: Options(
          headers: {'Cookie': _sessionToken},
        ),
      );

      if (response.statusCode != 200) return [];

      final data = response.data;
      final List<IServEvent> events = [];

      if (data is List) {
        for (final item in data) {
          events.add(IServEvent(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            startTime: item['start'] != null
                ? DateTime.parse(item['start'])
                : null,
            endTime: item['end'] != null
                ? DateTime.parse(item['end'])
                : null,
            location: item['location'],
            description: item['description'],
            calendar: item['calendar'],
            allDay: item['allDay'] == true,
            cachedAt: now,
          ));
        }
      }

      await _cacheEvents(events);

      return events;
    } catch (e) {

      return getCachedEvents();
    }
  }

  Future<void> _cacheNotifications(List<IServNotification> notifications) async {
    final db = await _db.database;
    final batch = db.batch();

    batch.delete('iserv_notifications');

    for (final notification in notifications) {
      batch.insert('iserv_notifications', notification.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<void> _cacheExercises(List<IServExercise> exercises) async {
    final db = await _db.database;
    final batch = db.batch();

    batch.delete('iserv_exercises');

    for (final exercise in exercises) {
      batch.insert('iserv_exercises', exercise.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<void> _cacheEvents(List<IServEvent> events) async {
    final db = await _db.database;
    final batch = db.batch();

    batch.delete('iserv_events');

    for (final event in events) {
      batch.insert('iserv_events', event.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<List<IServNotification>> getCachedNotifications() async {
    final db = await _db.database;
    final results = await db.query('iserv_notifications', orderBy: 'timestamp DESC');
    return results.map((m) => IServNotification.fromMap(m)).toList();
  }

  Future<List<IServExercise>> getCachedExercises() async {
    final db = await _db.database;
    final results = await db.query('iserv_exercises', orderBy: 'due_date ASC');
    return results.map((m) => IServExercise.fromMap(m)).toList();
  }

  Future<List<IServEvent>> getCachedEvents() async {
    final db = await _db.database;
    final results = await db.query('iserv_events', orderBy: 'start_time ASC');
    return results.map((m) => IServEvent.fromMap(m)).toList();
  }

  Future<void> syncAll() async {
    if (!isConnected) {
      final reconnected = await autoReconnect();
      if (!reconnected) return;
    }

    await Future.wait([
      getNotifications(),
      getExercises(),
      getEvents(),
    ]);
  }
}
