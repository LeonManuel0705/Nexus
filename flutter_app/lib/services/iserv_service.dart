import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:sqflite/sqflite.dart';
import '../models/iserv.dart';
import 'database_service.dart' if (dart.library.html) 'database_service_web.dart';
import 'encryption_service.dart';

class IServService {
  static final IServService _instance = IServService._internal();
  factory IServService() => _instance;
  IServService._internal();

  final DatabaseService _db = DatabaseService();
  final EncryptionService _encryption = EncryptionService();
  Dio? _dio;
  CookieJar? _cookieJar;

  String? _sessionToken;
  String? _baseUrl;
  String? _currentUsername;
  bool _isWebViewSession = false;

  /// Returns true if connected via traditional login (with Dio) or WebView session
  bool get isConnected => (_sessionToken != null && _dio != null) ||
                          (_isWebViewSession && _baseUrl != null);

  /// Get the current IServ base URL (e.g., https://ehgwerder.de)
  String? get iservUrl => _baseUrl;

  /// Returns true if we have an active Dio session ready for requests
  bool get hasDioSession => _dio != null && _cookieJar != null;

  /// Check if we have actual cookies in the jar (async check)
  Future<bool> hasValidCookies() async {
    if (_dio == null || _cookieJar == null || _baseUrl == null) return false;
    try {
      final cookies = await _cookieJar!.loadForRequest(Uri.parse(_baseUrl!));
      return cookies.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Initialize Dio with cookie manager for proper session handling
  Dio _createDio(String baseUrl) {
    final cookieJar = CookieJar();
    _cookieJar = cookieJar;

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
      },
    ));

    dio.interceptors.add(CookieManager(cookieJar));

    return dio;
  }

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

      final dio = _createDio(_baseUrl!);

      String? csrfToken;

      try {
        final loginPageResponse = await dio.get('/iserv/login');

        final pageContent = loginPageResponse.data?.toString() ?? '';

        final csrfPatterns = [
          RegExp(r'name="_csrf_token"\s+value="([^"]+)"'),
          RegExp(r'name="_csrf_token"\s*value="([^"]+)"'),
          RegExp(r'value="([^"]+)"\s+name="_csrf_token"'),
          RegExp(r'_csrf_token["\s]*[:=]["\s]*"?([^"&\s<>]+)'),
          RegExp(r'"_csrf_token":"([^"]+)"'),
        ];

        for (final pattern in csrfPatterns) {
          final match = pattern.firstMatch(pageContent);
          if (match != null) {
            csrfToken = match.group(1);
            break;
          }
        }
      } catch (e) {
        return {'success': false, 'error': 'Server nicht erreichbar: ${e.toString()}'};
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
            'Origin': _baseUrl,
            'Referer': '$_baseUrl/iserv/login',
          },
        ),
      );

      String? finalLocation = response.headers.value('location');
      int redirectCount = 0;
      const maxRedirects = 10;
      bool loginSuccess = false;

      while (finalLocation != null && redirectCount < maxRedirects) {
        redirectCount++;

        String redirectUrl = finalLocation;
        if (!redirectUrl.startsWith('http')) {
          redirectUrl = redirectUrl.startsWith('/')
              ? '$_baseUrl$redirectUrl'
              : '$_baseUrl/$redirectUrl';
        }

        try {
          final redirectResponse = await dio.get(redirectUrl);

          finalLocation = redirectResponse.headers.value('location');

          if (redirectResponse.statusCode == 200) {
            final body = redirectResponse.data?.toString() ?? '';

            if (body.contains('login_check') && body.contains('_username') && body.contains('_password')) {
              return {'success': false, 'error': 'Benutzername oder Passwort falsch'};
            }

            if (body.contains('Abmelden') ||
                body.contains('logout') ||
                body.contains('iserv-nav') ||
                body.contains('Mein IServ') ||
                (body.contains('/iserv/') && !body.contains('login_check'))) {
              loginSuccess = true;
              break;
            }
          }
        } catch (e) {
        }
      }

      bool verificationPassed = false;
      try {
        final verifyResponse = await dio.get(
          '/iserv/',
          options: Options(followRedirects: true),
        );

        final verifyBody = verifyResponse.data?.toString() ?? '';

        if (verifyBody.contains('login_check') &&
            verifyBody.contains('_username') &&
            verifyBody.contains('_password') &&
            !verifyBody.contains('Abmelden')) {
          return {'success': false, 'error': 'Anmeldung fehlgeschlagen. Bitte Zugangsdaten prüfen.'};
        }

        verificationPassed = verifyBody.contains('Abmelden') ||
                             verifyBody.contains('logout') ||
                             verifyBody.contains('iserv-menu') ||
                             verifyBody.contains('iserv-nav') ||
                             verifyBody.contains('IServ-Dashboard') ||
                             verifyBody.contains('class="dashboard"') ||
                             verifyBody.contains('Mein IServ') ||
                             verifyBody.contains('data-module') ||
                             verifyBody.contains('class="nav"') ||
                             loginSuccess ||
                             (verifyBody.contains('/iserv/') && !verifyBody.contains('login_check'));

        if (!verificationPassed && !loginSuccess) {
          return {'success': false, 'error': 'Konnte Anmeldung nicht verifizieren. Bitte Zugangsdaten prüfen.'};
        }
      } catch (e) {
        if (!loginSuccess) {
          return {'success': false, 'error': 'Anmeldung konnte nicht verifiziert werden: ${e.toString()}'};
        }
      }

      List<dynamic> allCookies = [];
      final pathsToCheck = ['/', '/iserv/', '/iserv/login', ''];

      for (final path in pathsToCheck) {
        try {
          final uri = Uri.parse('$_baseUrl$path');
          final cookies = await _cookieJar?.loadForRequest(uri);
          if (cookies != null && cookies.isNotEmpty) {
            allCookies.addAll(cookies);
          }
        } catch (_) {}
      }

      final uniqueCookies = <String, dynamic>{};
      for (final cookie in allCookies) {
        uniqueCookies[cookie.name] = cookie;
      }

      if (uniqueCookies.isEmpty && !loginSuccess && !verificationPassed) {
        return {'success': false, 'error': 'Keine Session-Cookies erhalten. Bitte erneut versuchen.'};
      }

      _sessionToken = uniqueCookies.isNotEmpty
          ? uniqueCookies.values.map((c) => '${c.name}=${c.value}').join('; ')
          : 'session_active';
      _currentUsername = username;
      _dio = dio;
      _isWebViewSession = false;

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
    _dio = null;
    _cookieJar = null;
    _isWebViewSession = false;

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

    final password = savedCreds['password'] ?? '';

    if (password.isEmpty) {
      final iservUrl = savedCreds['iserv_url'];
      if (iservUrl != null && iservUrl.isNotEmpty) {
        String normalizedUrl = iservUrl
            .replaceAll(RegExp(r'^https?://'), '')
            .replaceAll(RegExp(r'/+$'), '');
        _baseUrl = 'https://$normalizedUrl';
        _currentUsername = savedCreds['username'];
        _isWebViewSession = true;
        _sessionToken = 'webview_session_restored';
        print('IServ: Restored WebView session for $_baseUrl (user: $_currentUsername)');
        return true;
      }
      return false;
    }

    final result = await connect(
      username: savedCreds['username']!,
      password: password,
      iservUrl: savedCreds['iserv_url']!,
    );

    return result['success'] == true;
  }

  /// Refresh Dio instance with cookies from WebView's CookieManager
  /// Call this before making API requests in a WebView session
  Future<bool> refreshWithWebViewCookies(List<dynamic> cookies) async {
    if (_baseUrl == null) return false;

    try {
      final cookieJar = CookieJar();
      _cookieJar = cookieJar;

      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
        },
      ));

      dio.interceptors.add(CookieManager(cookieJar));

      final uri = Uri.parse(_baseUrl!);
      final cookieList = <Cookie>[];

      for (final c in cookies) {
        try {
          String? name;
          String? value;

          if (c is Map) {
            name = c['name']?.toString();
            value = c['value']?.toString() ?? '';
          } else {
            name = c.name?.toString();
            value = c.value?.toString() ?? '';
          }

          if (name != null && name.isNotEmpty) {
            final cookie = Cookie(name, value ?? '');
            cookie.domain = uri.host;
            cookie.path = '/';
            cookieList.add(cookie);
          }
        } catch (_) {}
      }

      print('IServ: Refreshing Dio with ${cookieList.length} cookies from WebView');

      if (cookieList.isNotEmpty) {
        await cookieJar.saveFromResponse(uri, cookieList);
        _dio = dio;
        return true;
      }

      return false;
    } catch (e) {
      print('IServ: Failed to refresh cookies: $e');
      return false;
    }
  }

  /// Connect using cookies obtained from WebView login
  Future<Map<String, dynamic>> connectWithWebViewCookies({
    required String iservUrl,
    required List<dynamic> cookies,
    String? username,
  }) async {
    try {
      String normalizedUrl = iservUrl
          .replaceAll(RegExp(r'^https?://'), '')
          .replaceAll(RegExp(r'/+$'), '');
      _baseUrl = 'https://$normalizedUrl';

      final cookieJar = CookieJar();
      _cookieJar = cookieJar;

      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
        },
      ));

      dio.interceptors.add(CookieManager(cookieJar));

      final uri = Uri.parse(_baseUrl!);
      final cookieList = <Cookie>[];

      for (final c in cookies) {
        try {
          String? name;
          String? value;
          String? domain;
          String? path;

          if (c is Map) {
            name = c['name']?.toString();
            value = c['value']?.toString() ?? '';
            domain = c['domain']?.toString();
            path = c['path']?.toString();
          } else {
            name = c.name?.toString();
            value = c.value?.toString() ?? '';
            try { domain = c.domain?.toString(); } catch (_) {}
            try { path = c.path?.toString(); } catch (_) {}
          }

          if (name != null && name.isNotEmpty) {
            final cookie = Cookie(name, value ?? '');
            if (domain != null) cookie.domain = domain;
            if (path != null) cookie.path = path;
            try {
              if (c.expiresDate != null) {
                cookie.expires = DateTime.fromMillisecondsSinceEpoch(c.expiresDate!.toInt());
              }
            } catch (_) {}
            try { cookie.httpOnly = c.isHttpOnly ?? false; } catch (_) {}
            try { cookie.secure = c.isSecure ?? false; } catch (_) {}
            cookieList.add(cookie);
          }
        } catch (_) {}
      }

      final baseUri = Uri.parse(_baseUrl!);
      final cookieDomain = baseUri.host; // e.g., "ehgwerder.de"

      for (final cookie in cookieList) {
        cookie.domain = cookieDomain;
        cookie.path = '/';
      }

      print('IServ: Saving ${cookieList.length} cookies for domain: $cookieDomain');
      for (final c in cookieList) {
        final valuePreview = c.value.length > 10 ? '${c.value.substring(0, 10)}...' : c.value;
        print('  Cookie: ${c.name}=$valuePreview domain=${c.domain} path=${c.path}');
      }

      try {
        await cookieJar.saveFromResponse(baseUri, cookieList);
        print('IServ: Cookies saved successfully to jar');
      } catch (e) {
        print('IServ: Failed to save cookies: $e');
      }

      bool isLoggedIn = false;
      try {
        final verifyResponse = await dio.get('/iserv/');
        final verifyBody = verifyResponse.data?.toString() ?? '';

        isLoggedIn = verifyBody.contains('Abmelden') ||
                     verifyBody.contains('logout') ||
                     verifyBody.contains('iserv-menu') ||
                     verifyBody.contains('iserv-nav') ||
                     verifyBody.contains('IServ-Dashboard') ||
                     verifyBody.contains('Mein IServ') ||
                     verifyBody.contains('class="nav"') ||
                     verifyBody.contains('data-module') ||
                     (verifyBody.contains('/iserv/') && !verifyBody.contains('login_check') && !verifyBody.contains('_username'));
      } catch (e) {
        if (cookieList.isEmpty) {
          return {'success': false, 'error': 'Verbindungsfehler: ${e.toString()}'};
        }
      }

      if (!isLoggedIn && cookieList.isEmpty) {
        try {
          final retryDio = Dio(BaseOptions(
            baseUrl: _baseUrl!,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            followRedirects: true,
            headers: {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            },
          ));
          retryDio.interceptors.add(CookieManager(cookieJar));

          final retryResponse = await retryDio.get('/iserv/');
          final retryBody = retryResponse.data?.toString() ?? '';

          isLoggedIn = !retryBody.contains('login_check') &&
                       !retryBody.contains('_username') &&
                       !retryBody.contains('_password');
        } catch (_) {}
      }

      _sessionToken = cookieList.isNotEmpty
          ? cookieList.map((c) => '${c.name}=${c.value}').join('; ')
          : 'webview_session_active';
      _currentUsername = username ?? 'IServ-Nutzer';
      _dio = dio;
      _isWebViewSession = true;

      final credentialKey = await _encryption.storeIServCredentials(
        username: _currentUsername!,
        password: '', // No password stored for WebView login
        iservUrl: _baseUrl!,
      );

      final db = await _db.database;
      await db.insert(
        'iserv_credentials',
        IServCredentials(
          username: _currentUsername!,
          iservUrl: _baseUrl!,
          credentialKey: credentialKey,
          createdAt: DateTime.now(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {'success': true, 'username': _currentUsername};
    } catch (e) {
      return {'success': false, 'error': 'Fehler: ${e.toString()}'};
    }
  }

  Future<List<IServNotification>> getNotifications() async {
    if (!isConnected || _dio == null) return [];

    try {
      final response = await _dio!.get(
        '/iserv/messenger/api/messages',
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
    if (!isConnected || _dio == null) return [];

    try {
      final response = await _dio!.get(
        '/iserv/exercise/api/exercises',
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
    if (!isConnected || _dio == null) return [];

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final end = now.add(const Duration(days: 30));

      final response = await _dio!.get(
        '/iserv/calendar/api/events',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
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

  /// Fetch Vertretungsplan using authenticated IServ session (like macOS version)
  /// Downloads PDF/image files from infodisplay
  /// Returns: {success: bool, files: List<Map>?, isFromCache: bool, error: String?}
  Future<Map<String, dynamic>> fetchVertretungsplan({int displayId = 3}) async {
    if (_dio == null || _baseUrl == null) {
      final reconnected = await autoReconnect();
      if (!reconnected || _dio == null || _baseUrl == null) {
        return await _getCachedVertretungsplanResult();
      }
    }

    try {
      final List<Map<String, dynamic>> files = [];

      final showUrl = '$_baseUrl/iserv/infodisplay/show/$displayId';

      if (_cookieJar != null) {
        final cookies = await _cookieJar!.loadForRequest(Uri.parse(showUrl));
        print('IServ Vertretungsplan: Found ${cookies.length} cookies for $showUrl');
        for (final c in cookies) {
          print('  Cookie: ${c.name} domain=${c.domain} path=${c.path}');
        }
      } else {
        print('IServ Vertretungsplan: WARNING - No cookie jar available!');
      }

      final htmlResponse = await _dio!.get(
        showUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (htmlResponse.statusCode == 200) {
        final contentType = htmlResponse.headers.value('content-type') ?? '';

        if (contentType.contains('application/pdf')) {
          final data = base64Encode(htmlResponse.data as List<int>);
          await _db.cacheVertretungsplanFile(data: data, page: 1, contentType: 'application/pdf');
          return {
            'success': true,
            'files': [{'data': data, 'contentType': 'application/pdf', 'page': 1}],
            'isFromCache': false,
          };
        }

        if (contentType.contains('text/html')) {
          final html = htmlResponse.data?.toString() ?? '';

          final urlsToTry = <String>{};

          bool isInfodisplayUrl(String url) {
            final resolved = _resolveUrl(url);
            return resolved.contains('/iserv/infodisplay/');
          }

          final infodisplayRegex = RegExp(r'/iserv/infodisplay/(?:file|pdf)/[^\s"' "'" r'><]+', caseSensitive: false);
          for (final match in infodisplayRegex.allMatches(html)) {
            final src = match.group(0);
            if (src != null) urlsToTry.add(_resolveUrl(src));
          }

          final imgRegex = RegExp(r'<img[^>]+src=["' "'" r']([^"' "'" r']+)["' "'" r']', caseSensitive: false);
          for (final match in imgRegex.allMatches(html)) {
            final src = match.group(1);
            if (src != null && !src.startsWith('data:') && isInfodisplayUrl(src)) {
              urlsToTry.add(_resolveUrl(src));
            }
          }

          final iframeRegex = RegExp(r'<iframe[^>]+src=["' "'" r']([^"' "'" r']+)["' "'" r']', caseSensitive: false);
          for (final match in iframeRegex.allMatches(html)) {
            final src = match.group(1);
            if (src != null && isInfodisplayUrl(src)) {
              urlsToTry.add(_resolveUrl(src));
            }
          }

          final objectRegex = RegExp(r'(?:data|src)=["' "'" r']([^"' "'" r']+\.(?:pdf|png|jpg|jpeg|gif))["' "'" r']', caseSensitive: false);
          for (final match in objectRegex.allMatches(html)) {
            final src = match.group(1);
            if (src != null && isInfodisplayUrl(src)) {
              urlsToTry.add(_resolveUrl(src));
            }
          }

          for (int i = 1; i <= 6; i++) {
            urlsToTry.add('$_baseUrl/iserv/infodisplay/file/$displayId/$i');
          }

          print('IServ Vertretungsplan: Found ${urlsToTry.length} infodisplay URLs to try');

          for (final url in urlsToTry) {
            if (files.length >= 6) break;

            try {
              final response = await _dio!.get(
                url,
                options: Options(
                  responseType: ResponseType.bytes,
                  receiveTimeout: const Duration(seconds: 8),
                  validateStatus: (status) => status != null && status < 500,
                ),
              );

              if (response.statusCode == 200 && response.data != null) {
                final ct = response.headers.value('content-type') ?? '';
                final bytes = response.data as List<int>;

                if (ct.contains('text/html') || ct.contains('svg') || bytes.length < 1000) {
                  continue;
                }

                if (ct.contains('pdf') || ct.contains('image')) {
                  final data = base64Encode(bytes);
                  files.add({
                    'data': data,
                    'contentType': ct,
                    'page': files.length + 1,
                  });
                }
              }
            } catch (e) {
              continue;
            }
          }
        }
      }

      if (files.isNotEmpty) {
        await _db.clearVertretungsplanCache();
        for (final file in files) {
          await _db.cacheVertretungsplanFile(
            data: file['data'] as String,
            page: file['page'] as int,
            contentType: file['contentType'] as String,
          );
        }
        return {
          'success': true,
          'files': files,
          'isFromCache': false,
        };
      }

      return await _getCachedVertretungsplanResult();

    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return await _getCachedVertretungsplanResult();
      }
      return await _getCachedVertretungsplanResult();
    } catch (e) {
      return await _getCachedVertretungsplanResult();
    }
  }

  /// Resolve relative URLs to absolute URLs
  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    if (url.startsWith('/')) {
      return '$_baseUrl$url';
    }
    return '$_baseUrl/$url';
  }

  Future<Map<String, dynamic>> _getCachedVertretungsplanResult() async {
    final cachedFiles = await _db.getAllCachedVertretungsplanFiles();
    if (cachedFiles.isNotEmpty) {
      final files = cachedFiles.map((cached) => {
        'data': cached['data_base64'] as String?,
        'contentType': cached['content_type'] as String? ?? 'image/png',
        'page': cached['page'] as int? ?? 1,
      }).toList();

      return {
        'success': true,
        'files': files,
        'isFromCache': true,
        'cachedAt': cachedFiles.first['fetched_at'] as String?,
      };
    }
    return {
      'success': false,
      'error': 'Keine Daten verfügbar. Bitte mit IServ verbinden.',
      'isFromCache': false,
    };
  }

  Future<List<Map<String, dynamic>>> getCachedVertretungsplanFiles() async {
    return await _db.getAllCachedVertretungsplanFiles();
  }
}
