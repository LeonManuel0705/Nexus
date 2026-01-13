import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/vbb.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class VbbService {
  static final VbbService _instance = VbbService._internal();
  factory VbbService() => _instance;
  VbbService._internal();

  static const String _baseUrl = 'https://v6.vbb.transport.rest';
  static const Duration _locationCacheTtl = Duration(days: 7);
  static const Duration _routeCacheTtl = Duration(minutes: 30);

  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();
  final Uuid _uuid = const Uuid();

  Future<List<VbbLocation>> searchLocations(String query) async {
    if (query.length < 2) return [];

    final cached = await _db.getCachedVbbLocations(query);
    if (cached.isNotEmpty) {
      return cached;
    }

    if (!_connectivity.isOnline.value) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/locations?query=${Uri.encodeComponent(query)}&results=10'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final locations = data
            .map((json) => VbbLocation.fromApiResponse(json as Map<String, dynamic>))
            .where((loc) => loc.id.isNotEmpty && loc.name.isNotEmpty)
            .toList();

        await _db.cacheVbbLocations(query, locations);

        return locations;
      }
    } catch (e) {

    }

    return [];
  }

  Future<VbbLocation?> getStation(String id) async {
    if (!_connectivity.isOnline.value) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stops/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return VbbLocation.fromApiResponse(data);
      }
    } catch (e) {

    }

    return null;
  }

  Future<List<VbbJourney>> searchRoutes({
    required String fromId,
    required String toId,
    DateTime? departure,
    bool isDeparture = true,
  }) async {
    final cacheKey = '${fromId}_${toId}_${departure?.toIso8601String() ?? 'now'}';

    final cached = await _db.getCachedVbbRoutes(cacheKey);
    if (cached.isNotEmpty) {
      return cached;
    }

    if (!_connectivity.isOnline.value) {
      return [];
    }

    try {
      final params = {
        'from': fromId,
        'to': toId,
        'results': '5',
        'stopovers': 'true',
      };

      if (departure != null) {
        params[isDeparture ? 'departure' : 'arrival'] = departure.toIso8601String();
      }

      final uri = Uri.parse('$_baseUrl/journeys').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final journeysJson = data['journeys'] as List;
        final journeys = journeysJson
            .map((json) => VbbJourney.fromApiResponse(json as Map<String, dynamic>))
            .toList();

        await _db.cacheVbbRoutes(cacheKey, journeys);

        return journeys;
      }
    } catch (e) {

    }

    return [];
  }

  Future<List<VbbDeparture>> getDepartures(String stationId, {int duration = 30}) async {
    if (!_connectivity.isOnline.value) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stops/$stationId/departures?duration=$duration&results=20'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final departuresJson = data['departures'] as List;
        return departuresJson
            .map((json) => VbbDeparture.fromApiResponse(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {

    }

    return [];
  }

  Future<List<VbbKnownLocation>> getKnownLocations() async {
    return await _db.getVbbKnownLocations();
  }

  Future<VbbKnownLocation> addKnownLocation({
    required String name,
    required String alias,
    required VbbLocation location,
  }) async {
    final knownLocation = VbbKnownLocation(
      id: _uuid.v4(),
      name: name,
      alias: alias,
      locationId: location.id,
      locationName: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    await _db.insertVbbKnownLocation(knownLocation);
    return knownLocation;
  }

  Future<void> removeKnownLocation(String id) async {
    await _db.deleteVbbKnownLocation(id);
  }

  Future<List<VbbFavoriteRoute>> getFavoriteRoutes() async {
    return await _db.getVbbFavoriteRoutes();
  }

  Future<VbbFavoriteRoute> addFavoriteRoute({
    required String name,
    required VbbLocation from,
    required VbbLocation to,
  }) async {
    final route = VbbFavoriteRoute(
      id: _uuid.v4(),
      name: name,
      fromId: from.id,
      fromName: from.name,
      toId: to.id,
      toName: to.name,
      createdAt: DateTime.now(),
    );

    await _db.insertVbbFavoriteRoute(route);
    return route;
  }

  Future<void> removeFavoriteRoute(String id) async {
    await _db.deleteVbbFavoriteRoute(id);
  }

  Future<bool> hasKnownLocations() async {
    final existing = await getKnownLocations();
    return existing.isNotEmpty;
  }

  Future<bool> hasHomeLocation() async {
    final locations = await getKnownLocations();
    return locations.any((loc) => loc.alias == 'home');
  }

  Future<bool> hasSchoolLocation() async {
    final locations = await getKnownLocations();
    return locations.any((loc) => loc.alias == 'school');
  }

  Future<VbbKnownLocation?> getHomeLocation() async {
    final locations = await getKnownLocations();
    try {
      return locations.firstWhere((loc) => loc.alias == 'home');
    } catch (_) {
      return null;
    }
  }

  Future<VbbKnownLocation?> getSchoolLocation() async {
    final locations = await getKnownLocations();
    try {
      return locations.firstWhere((loc) => loc.alias == 'school');
    } catch (_) {
      return null;
    }
  }

  Future<void> clearOldCache() async {
    await _db.clearOldVbbCache();
  }
}
