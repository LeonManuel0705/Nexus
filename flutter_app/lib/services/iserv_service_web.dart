import '../models/iserv.dart';

class IServService {
  static final IServService _instance = IServService._internal();
  factory IServService() => _instance;
  IServService._internal();

  bool get isConnected => false;
  String? get iservUrl => null;

  Future<Map<String, dynamic>> connect({
    required String username,
    required String password,
    required String iservUrl,
  }) async {
    return {'success': false, 'error': 'IServ ist auf Web nicht verfügbar'};
  }

  Future<Map<String, dynamic>> connectWithWebViewCookies({
    required String iservUrl,
    required List<dynamic> cookies,
    String? username,
  }) async {
    return {'success': false, 'error': 'IServ ist auf Web nicht verfügbar'};
  }

  Future<void> refreshWithWebViewCookies(List<dynamic> cookies) async {}

  Future<bool> hasValidCookies() async => false;

  Future<void> disconnect() async {}

  Future<IServCredentials?> getSavedCredentials() async => null;

  Future<bool> autoReconnect() async => false;

  Future<List<IServNotification>> getNotifications() async => [];

  Future<List<IServExercise>> getExercises() async => [];

  Future<List<IServEvent>> getEvents() async => [];

  Future<List<IServNotification>> getCachedNotifications() async => [];

  Future<List<IServExercise>> getCachedExercises() async => [];

  Future<List<IServEvent>> getCachedEvents() async => [];

  Future<Map<String, dynamic>> fetchVertretungsplan() async {
    return {'success': false, 'error': 'IServ ist auf Web nicht verfügbar'};
  }

  Future<void> syncAll() async {}
}
