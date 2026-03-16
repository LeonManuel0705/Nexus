import 'package:flutter/material.dart';
import '../models/vbb.dart';
import '../services/vbb_service.dart';
import '../services/connectivity_service.dart';

class VbbProvider extends ChangeNotifier {
  final VbbService _service = VbbService();
  final ConnectivityService _connectivity = ConnectivityService();

  List<VbbKnownLocation> _knownLocations = [];
  List<VbbKnownLocation> get knownLocations => _knownLocations;

  List<VbbFavoriteRoute> _favoriteRoutes = [];
  List<VbbFavoriteRoute> get favoriteRoutes => _favoriteRoutes;

  List<VbbTicket> _tickets = [];
  List<VbbTicket> get tickets => _tickets;

  List<VbbLocation> _searchResults = [];
  List<VbbLocation> get searchResults => _searchResults;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  VbbLocation? _fromLocation;
  VbbLocation? get fromLocation => _fromLocation;

  VbbLocation? _toLocation;
  VbbLocation? get toLocation => _toLocation;

  List<VbbJourney> _journeys = [];
  List<VbbJourney> get journeys => _journeys;

  bool _isLoadingRoutes = false;
  bool get isLoadingRoutes => _isLoadingRoutes;

  List<VbbDeparture> _departures = [];
  List<VbbDeparture> get departures => _departures;

  VbbLocation? _selectedStation;
  VbbLocation? get selectedStation => _selectedStation;

  bool _isLoadingDepartures = false;
  bool get isLoadingDepartures => _isLoadingDepartures;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _routeError ?? _error;

  String? _routeError;

  bool get isOnline => _connectivity.isOnline.value;

  bool get needsSetup => !hasHome || !hasSchool;
  bool get hasHome => _knownLocations.any((l) => l.alias == 'home');
  bool get hasSchool => _knownLocations.any((l) => l.alias == 'school');

  VbbKnownLocation? get homeLocation =>
      _knownLocations.where((l) => l.alias == 'home').firstOrNull;
  VbbKnownLocation? get schoolLocation =>
      _knownLocations.where((l) => l.alias == 'school').firstOrNull;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.clearOldCache();
      _knownLocations = await _service.getKnownLocations();
      _favoriteRoutes = await _service.getFavoriteRoutes();
      _tickets = await _service.getTickets();
    } catch (e) {
      _error = 'Fehler beim Laden der Daten';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshKnownLocations() async {
    _knownLocations = await _service.getKnownLocations();
    notifyListeners();
  }

  Future<void> searchLocations(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _service.searchLocations(query);
      _error = null;
    } catch (e) {
      _searchResults = [];
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = msg;
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  void setFromLocation(VbbLocation? location) {
    _fromLocation = location;
    _journeys = [];
    _hasSearched = false;
    notifyListeners();
  }

  void setToLocation(VbbLocation? location) {
    _toLocation = location;
    _journeys = [];
    _hasSearched = false;
    notifyListeners();
  }

  void swapLocations() {
    final temp = _fromLocation;
    _fromLocation = _toLocation;
    _toLocation = temp;
    _journeys = [];
    _hasSearched = false;
    notifyListeners();
  }

  bool _hasSearched = false;
  bool get hasSearched => _hasSearched;

  Future<void> searchRoutes({DateTime? departure}) async {
    if (_fromLocation == null || _toLocation == null) {
      _error = 'Bitte Start und Ziel auswählen';
      notifyListeners();
      return;
    }

    _isLoadingRoutes = true;
    _routeError = null;
    _error = null;
    _hasSearched = true;
    notifyListeners();

    try {
      _journeys = await _service.searchRoutes(
        fromId: _fromLocation!.id,
        toId: _toLocation!.id,
        departure: departure,
      );

      if (_journeys.isEmpty) {
        _routeError = 'Keine Verbindungen für diese Strecke gefunden';
      }
    } catch (e) {
      _journeys = [];
      final raw = e.toString();
      final msg = raw.replaceFirst('Exception: ', '');
      _routeError = msg;
    } finally {
      _isLoadingRoutes = false;
      notifyListeners();
    }
  }

  void clearRoutes() {
    _journeys = [];
    _routeError = null;
    notifyListeners();
  }

  void setSelectedStation(VbbLocation? station) {
    _selectedStation = station;
    _departures = [];
    notifyListeners();
  }

  Future<void> loadDepartures() async {
    if (_selectedStation == null) return;

    _isLoadingDepartures = true;
    _error = null;
    notifyListeners();

    try {
      _departures = await _service.getDepartures(_selectedStation!.id);
    } catch (e) {
      _departures = [];
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = msg;
    } finally {
      _isLoadingDepartures = false;
      notifyListeners();
    }
  }

  Future<void> addKnownLocation({
    required String name,
    required String alias,
    required VbbLocation location,
  }) async {
    try {
      final knownLocation = await _service.addKnownLocation(
        name: name,
        alias: alias,
        location: location,
      );
      _knownLocations.add(knownLocation);
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Speichern des Ortes';
      notifyListeners();
    }
  }

  Future<void> removeKnownLocation(String id) async {
    await _service.removeKnownLocation(id);
    _knownLocations.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> addFavoriteRoute({
    required String name,
    required VbbLocation from,
    required VbbLocation to,
  }) async {
    try {
      final route = await _service.addFavoriteRoute(
        name: name,
        from: from,
        to: to,
      );
      _favoriteRoutes.add(route);
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Speichern der Route';
      notifyListeners();
    }
  }

  Future<void> removeFavoriteRoute(String id) async {
    await _service.removeFavoriteRoute(id);
    _favoriteRoutes.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void loadFavoriteRoute(VbbFavoriteRoute route) {
    _fromLocation = VbbLocation(
      id: route.fromId,
      name: route.fromName,
      type: 'station',
    );
    _toLocation = VbbLocation(
      id: route.toId,
      name: route.toName,
      type: 'station',
    );
    _journeys = [];
    notifyListeners();
  }

  void setHomeAsFrom() {
    final home = _knownLocations.where((l) => l.alias == 'home').firstOrNull;
    if (home != null) {
      _fromLocation = home.toLocation();
      _journeys = [];
      notifyListeners();
    }
  }

  void setSchoolAsTo() {
    final school = _knownLocations.where((l) => l.alias == 'school').firstOrNull;
    if (school != null) {
      _toLocation = school.toLocation();
      _journeys = [];
      notifyListeners();
    }
  }

  void planRouteToSchool() {
    setHomeAsFrom();
    setSchoolAsTo();
    searchRoutes();
  }

  void planRouteHome() {
    final home = _knownLocations.where((l) => l.alias == 'home').firstOrNull;
    final school = _knownLocations.where((l) => l.alias == 'school').firstOrNull;
    if (home != null && school != null) {
      _fromLocation = school.toLocation();
      _toLocation = home.toLocation();
      _journeys = [];
      searchRoutes();
    }
  }

  String? _pendingDestination;
  String? get pendingDestination => _pendingDestination;

  void setPendingDestination(String destination) {
    _pendingDestination = destination;
    notifyListeners();
  }

  void clearPendingDestination() {
    _pendingDestination = null;
    notifyListeners();
  }

  Future<void> loadTickets() async {
    _tickets = await _service.getTickets();
    notifyListeners();
  }

  Future<void> addTicket({
    required String ticketType,
    required String ticketName,
    required String zoneCoverage,
    DateTime? validFrom,
    DateTime? validUntil,
    bool autoRenews = false,
  }) async {
    try {
      final ticket = await _service.addTicket(
        ticketType: ticketType,
        ticketName: ticketName,
        zoneCoverage: zoneCoverage,
        validFrom: validFrom,
        validUntil: validUntil,
        autoRenews: autoRenews,
      );
      _tickets.insert(0, ticket);
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Speichern des Tickets';
      notifyListeners();
    }
  }

  Future<void> removeTicket(String id) async {
    await _service.removeTicket(id);
    _tickets.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _routeError = null;
    notifyListeners();
  }
}
