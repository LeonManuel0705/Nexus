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
      dio.options.connectTimeout = const Duration(seconds: 20);
      dio.options.receiveTimeout = const Duration(seconds: 20);
      dio.options.followRedirects = false;
      dio.options.validateStatus = (status) => status != null && status < 500;

      // Common headers for all requests
      final commonHeaders = {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
      };

      String? csrfToken;
      Map<String, String> allCookies = {};

      // Step 1: Get login page and extract CSRF token and initial cookies
      try {
        final loginPageResponse = await dio.get(
          '/iserv/login',
          options: Options(headers: commonHeaders),
        );

        _extractCookies(loginPageResponse.headers['set-cookie'], allCookies);

        final pageContent = loginPageResponse.data?.toString() ?? '';
        final csrfMatch = RegExp(r'name="_csrf_token"\s+value="([^"]+)"').firstMatch(pageContent);
        csrfToken = csrfMatch?.group(1);

        // Also try alternative CSRF patterns
        if (csrfToken == null) {
          final altMatch = RegExp(r'_csrf_token["\s]*[:=]["\s]*([^"&\s]+)').firstMatch(pageContent);
          csrfToken = altMatch?.group(1);
        }
      } catch (e) {
        return {'success': false, 'error': 'Server nicht erreichbar: $e'};
      }

      String sessionCookie = allCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

      final loginData = {
        '_username': username,
        '_password': password,
      };
      if (csrfToken != null) {
        loginData['_csrf_token'] = csrfToken;
      }

      // Step 2: Submit login
      final response = await dio.post(
        '/iserv/login_check',
        data: loginData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            ...commonHeaders,
            'Cookie': sessionCookie,
            'Origin': _baseUrl,
            'Referer': '$_baseUrl/iserv/login',
          },
        ),
      );

      // Extract cookies from login response
      _extractCookies(response.headers['set-cookie'], allCookies);
      sessionCookie = allCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

      // Step 3: Follow redirects and collect all cookies
      String? finalLocation = response.headers.value('location');
      int redirectCount = 0;
      const maxRedirects = 8;

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
              headers: {...commonHeaders, 'Cookie': sessionCookie},
              followRedirects: false,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          _extractCookies(redirectResponse.headers['set-cookie'], allCookies);
          sessionCookie = allCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

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

      // Check if we collected any cookies
      if (allCookies.isEmpty) {
        return {'success': false, 'error': 'Keine Session-Cookies erhalten. Server möglicherweise nicht erreichbar.'};
      }

      // Step 4: Verify login by accessing dashboard
      try {
        final verifyResponse = await dio.get(
          '/iserv/',
          options: Options(
            headers: {...commonHeaders, 'Cookie': sessionCookie},
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        // Collect any additional cookies
        _extractCookies(verifyResponse.headers['set-cookie'], allCookies);
        sessionCookie = allCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

        final verifyBody = verifyResponse.data?.toString() ?? '';

        // Check if we got redirected back to login - this means auth failed
        if (verifyBody.contains('login_check') ||
            (verifyBody.contains('_username') && verifyBody.contains('_password') && !verifyBody.contains('Abmelden'))) {
          return {'success': false, 'error': 'Anmeldung fehlgeschlagen. Bitte Zugangsdaten prüfen.'};
        }

        // Check for common IServ elements to verify login
        final isLoggedIn = verifyBody.contains('Abmelden') ||
                           verifyBody.contains('logout') ||
                           verifyBody.contains('iserv-menu') ||
                           verifyBody.contains('iserv-nav') ||
                           verifyBody.contains('IServ-Dashboard') ||
                           verifyBody.contains('class="dashboard"') ||
                           verifyBody.contains('Mein IServ') ||
                           (verifyBody.contains('/iserv/') && !verifyBody.contains('login_check'));

        if (!isLoggedIn) {
          return {'success': false, 'error': 'Konnte Anmeldung nicht verifizieren. Bitte Zugangsdaten prüfen.'};
        }
      } catch (e) {
        // If verification fails but we have cookies, try to proceed anyway
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

  /// Helper to extract and parse cookies from Set-Cookie headers
  void _extractCookies(List<String>? cookies, Map<String, String> target) {
    if (cookies == null) return;

    for (final cookie in cookies) {
      // Get only the cookie name=value part (before the first semicolon)
      final parts = cookie.split(';').first.split('=');
      if (parts.length >= 2) {
        final name = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        if (name.isNotEmpty && value.isNotEmpty) {
          target[name] = value;
        }
      }
    }
  }
}
