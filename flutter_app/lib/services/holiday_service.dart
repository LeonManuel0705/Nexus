import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import 'database_service.dart';

class HolidayService {
  static final HolidayService _instance = HolidayService._internal();
  factory HolidayService() => _instance;
  HolidayService._internal();

  final Dio _dio = Dio();
  final DatabaseService _db = DatabaseService();

  // Map of German Bundesland names to their API codes
  static const bundeslandCodes = {
    'Baden-Württemberg': 'BW',
    'Bayern': 'BY',
    'Berlin': 'BE',
    'Brandenburg': 'BB',
    'Bremen': 'HB',
    'Hamburg': 'HH',
    'Hessen': 'HE',
    'Mecklenburg-Vorpommern': 'MV',
    'Niedersachsen': 'NI',
    'Nordrhein-Westfalen': 'NW',
    'Rheinland-Pfalz': 'RP',
    'Saarland': 'SL',
    'Sachsen': 'SN',
    'Sachsen-Anhalt': 'ST',
    'Schleswig-Holstein': 'SH',
    'Thüringen': 'TH',
  };

  /// Get the user's selected Bundesland
  Future<String?> getUserBundesland() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_bundesland');
  }

  /// Get the Bundesland code for API calls
  String? getBundeslandCode(String bundesland) {
    return bundeslandCodes[bundesland];
  }

  /// Fetch and import all holidays for the user's Bundesland
  Future<List<Event>> importHolidays({int? year}) async {
    final bundesland = await getUserBundesland();
    if (bundesland == null) {
      return [];
    }

    final code = getBundeslandCode(bundesland);
    if (code == null) {
      return [];
    }

    final targetYear = year ?? DateTime.now().year;
    final events = <Event>[];

    // Fetch public holidays (Feiertage)
    final publicHolidays = await _fetchPublicHolidays(code, targetYear);
    events.addAll(publicHolidays);

    // Also fetch for next year if we're in the last quarter
    if (DateTime.now().month >= 10 && year == null) {
      final nextYearHolidays = await _fetchPublicHolidays(code, targetYear + 1);
      events.addAll(nextYearHolidays);
    }

    // Fetch school holidays (Schulferien)
    final schoolHolidays = await _fetchSchoolHolidays(code, targetYear);
    events.addAll(schoolHolidays);

    // Also fetch for next year
    if (year == null) {
      final nextYearSchoolHolidays = await _fetchSchoolHolidays(code, targetYear + 1);
      events.addAll(nextYearSchoolHolidays);
    }

    // Save to database
    await _saveHolidaysToDatabase(events);

    return events;
  }

  /// Fetch public holidays from feiertage-api.de
  Future<List<Event>> _fetchPublicHolidays(String bundeslandCode, int year) async {
    try {
      final response = await _dio.get(
        'https://feiertage-api.de/api/',
        queryParameters: {
          'jahr': year,
          'nur_land': bundeslandCode,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        return [];
      }

      final Map<String, dynamic> data = response.data;
      final events = <Event>[];
      final now = DateTime.now();

      for (final entry in data.entries) {
        final holidayName = entry.key;
        final holidayData = entry.value as Map<String, dynamic>;
        final dateStr = holidayData['datum'] as String?;

        if (dateStr == null) continue;

        final date = DateTime.parse(dateStr);
        final id = 'holiday_${bundeslandCode}_${dateStr}_${holidayName.hashCode}';

        events.add(Event(
          id: id,
          title: holidayName,
          description: 'Gesetzlicher Feiertag',
          startTime: DateTime(date.year, date.month, date.day, 0, 0),
          endTime: DateTime(date.year, date.month, date.day, 23, 59),
          allDay: true,
          category: 'holiday',
          color: '#EF4444', // Red color for holidays
          createdAt: now,
          updatedAt: now,
        ));
      }

      return events;
    } catch (e) {
      // Fallback to date.nager.at API
      return _fetchPublicHolidaysNager(bundeslandCode, year);
    }
  }

  /// Fallback: Fetch public holidays from date.nager.at
  Future<List<Event>> _fetchPublicHolidaysNager(String bundeslandCode, int year) async {
    try {
      final response = await _dio.get(
        'https://date.nager.at/api/v3/publicholidays/$year/DE',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        return [];
      }

      final List<dynamic> data = response.data;
      final events = <Event>[];
      final now = DateTime.now();

      for (final holiday in data) {
        // Check if holiday applies to this Bundesland
        final counties = holiday['counties'] as List<dynamic>?;
        final isNational = counties == null || counties.isEmpty;
        final appliesToBundesland = isNational ||
            counties.any((c) => c.toString().contains(bundeslandCode));

        if (!appliesToBundesland) continue;

        final dateStr = holiday['date'] as String?;
        final name = holiday['localName'] as String? ?? holiday['name'] as String?;

        if (dateStr == null || name == null) continue;

        final date = DateTime.parse(dateStr);
        final id = 'holiday_nager_${bundeslandCode}_${dateStr}_${name.hashCode}';

        events.add(Event(
          id: id,
          title: name,
          description: 'Gesetzlicher Feiertag',
          startTime: DateTime(date.year, date.month, date.day, 0, 0),
          endTime: DateTime(date.year, date.month, date.day, 23, 59),
          allDay: true,
          category: 'holiday',
          color: '#EF4444',
          createdAt: now,
          updatedAt: now,
        ));
      }

      return events;
    } catch (e) {
      return [];
    }
  }

  /// Fetch school holidays from ferien-api.de
  Future<List<Event>> _fetchSchoolHolidays(String bundeslandCode, int year) async {
    try {
      final response = await _dio.get(
        'https://ferien-api.de/api/v1/holidays/$bundeslandCode/$year',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        return [];
      }

      final List<dynamic> data = response.data;
      final events = <Event>[];
      final now = DateTime.now();

      for (final holiday in data) {
        final name = holiday['name'] as String?;
        final startStr = holiday['start'] as String?;
        final endStr = holiday['end'] as String?;

        if (name == null || startStr == null || endStr == null) continue;

        // Parse ISO 8601 dates
        final start = DateTime.parse(startStr);
        final end = DateTime.parse(endStr);
        final id = 'vacation_${bundeslandCode}_${startStr}_${name.hashCode}';

        // Translate common vacation names to German
        final translatedName = _translateVacationName(name);

        events.add(Event(
          id: id,
          title: translatedName,
          description: 'Schulferien',
          startTime: DateTime(start.year, start.month, start.day, 0, 0),
          endTime: DateTime(end.year, end.month, end.day, 23, 59),
          allDay: true,
          category: 'vacation',
          color: '#22C55E', // Green color for vacations
          createdAt: now,
          updatedAt: now,
        ));
      }

      return events;
    } catch (e) {
      return [];
    }
  }

  /// Translate vacation names to German
  String _translateVacationName(String name) {
    final translations = {
      'winterferien': 'Winterferien',
      'osterferien': 'Osterferien',
      'pfingstferien': 'Pfingstferien',
      'sommerferien': 'Sommerferien',
      'herbstferien': 'Herbstferien',
      'weihnachtsferien': 'Weihnachtsferien',
    };

    final lowerName = name.toLowerCase();
    for (final entry in translations.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    return name;
  }

  /// Save holidays to database (avoiding duplicates)
  Future<void> _saveHolidaysToDatabase(List<Event> events) async {
    final db = await _db.database;

    for (final event in events) {
      // Check if event already exists
      final existing = await db.query(
        'events',
        where: 'id = ?',
        whereArgs: [event.id],
      );

      if (existing.isEmpty) {
        await db.insert('events', event.toMap());
      }
    }
  }

  /// Delete all imported holidays
  Future<void> clearHolidays() async {
    final db = await _db.database;
    await db.delete(
      'events',
      where: 'category IN (?, ?)',
      whereArgs: ['holiday', 'vacation'],
    );
  }

  /// Refresh holidays (clear and re-import)
  Future<List<Event>> refreshHolidays() async {
    await clearHolidays();
    return importHolidays();
  }

  /// Check if holidays have been imported for the current year
  Future<bool> hasImportedHolidays() async {
    final db = await _db.database;
    final year = DateTime.now().year;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);

    final result = await db.query(
      'events',
      where: 'category IN (?, ?) AND start_time >= ? AND start_time <= ?',
      whereArgs: ['holiday', 'vacation', startOfYear.toIso8601String(), endOfYear.toIso8601String()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get all holidays from database
  Future<List<Event>> getHolidays() async {
    final db = await _db.database;
    final results = await db.query(
      'events',
      where: 'category IN (?, ?)',
      whereArgs: ['holiday', 'vacation'],
      orderBy: 'start_time ASC',
    );
    return results.map((m) => Event.fromMap(m)).toList();
  }
}
