import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final String city;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.city,
    required this.timestamp,
  });

  String get weatherDescription {
    switch (weatherCode) {
      case 0:
        return 'Sonnig';
      case 1:
      case 2:
      case 3:
        return 'Teilweise bewölkt';
      case 45:
      case 48:
        return 'Neblig';
      case 51:
      case 53:
      case 55:
        return 'Nieselregen';
      case 61:
      case 63:
      case 65:
        return 'Regen';
      case 66:
      case 67:
        return 'Gefrierender Regen';
      case 71:
      case 73:
      case 75:
        return 'Schnee';
      case 77:
        return 'Graupel';
      case 80:
      case 81:
      case 82:
        return 'Regenschauer';
      case 85:
      case 86:
        return 'Schneeschauer';
      case 95:
        return 'Gewitter';
      case 96:
      case 99:
        return 'Gewitter mit Hagel';
      default:
        return 'Unbekannt';
    }
  }

  String get weatherIcon {
    switch (weatherCode) {
      case 0:
        return '☀️';
      case 1:
      case 2:
      case 3:
        return '⛅';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return '🌧️';
      case 66:
      case 67:
        return '🌨️';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '❄️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌤️';
    }
  }
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final Dio _dio = Dio();
  WeatherData? _cachedData;
  DateTime? _lastFetch;

  Future<WeatherData?> getWeather() async {

    if (_cachedData != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      return _cachedData;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('weather_city');
      final lat = prefs.getDouble('weather_lat');
      final lon = prefs.getDouble('weather_lon');

      if (city == null || lat == null || lon == null) {
        return null;
      }

      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': 'temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m',
          'timezone': 'Europe/Berlin',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final current = response.data['current'];
        _cachedData = WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          weatherCode: current['weather_code'] as int,
          windSpeed: (current['wind_speed_10m'] as num).toDouble(),
          humidity: current['relative_humidity_2m'] as int,
          city: city,
          timestamp: DateTime.now(),
        );
        _lastFetch = DateTime.now();
        return _cachedData;
      }
    } catch (e) {

      return _cachedData;
    }

    return null;
  }

  void clearCache() {
    _cachedData = null;
    _lastFetch = null;
  }
}
