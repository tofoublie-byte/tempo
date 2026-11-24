import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

/// Résultat combiné d'un appel de prévisions : météo actuelle + 7 jours.
class WeatherSnapshot {
  const WeatherSnapshot({required this.current, required this.daily});

  final CurrentWeather current;
  final List<DayForecast> daily;
}

/// Client de l'API Open-Meteo (gratuite, sans clé) : géocodage + prévisions.
class WeatherService {
  static const _geocodingUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _forecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _timeout = Duration(seconds: 10);

  /// Recherche des villes correspondant à une saisie (résultats en français).
  Future<List<CityLocation>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final uri = Uri.parse(_geocodingUrl).replace(queryParameters: {
      'name': trimmed,
      'count': '8',
      'language': 'fr',
      'format': 'json',
    });
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Recherche de ville indisponible (${response.statusCode})');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final results = data['results'];
    if (results is! List) return const [];
    return [
      for (final item in results.cast<Map<String, dynamic>>())
        CityLocation(
          name: item['name'] as String? ?? '',
          admin1: item['admin1'] as String? ?? '',
          country: item['country'] as String? ?? '',
          latitude: (item['latitude'] as num).toDouble(),
          longitude: (item['longitude'] as num).toDouble(),
        ),
    ];
  }

  /// Météo actuelle et prévisions sur 7 jours pour une position.
  Future<WeatherSnapshot> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastUrl).replace(queryParameters: {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Service météo indisponible (${response.statusCode})');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final currentJson = data['current'] as Map<String, dynamic>? ?? const {};
    final dailyJson = data['daily'] as Map<String, dynamic>? ?? const {};
    final current = CurrentWeather(
      temperature: (currentJson['temperature_2m'] as num?)?.toDouble() ?? 0,
      apparentTemperature: (currentJson['apparent_temperature'] as num?)?.toDouble() ?? 0,
      humidity: (currentJson['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (currentJson['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      weatherCode: (currentJson['weather_code'] as num?)?.toInt() ?? 0,
      isDay: (currentJson['is_day'] as num?)?.toInt() == 1,
    );
    final dates = (dailyJson['time'] as List?)?.cast<String>() ?? const [];
    final codes = (dailyJson['weather_code'] as List?)?.cast<num>() ?? const [];
    final tMax = (dailyJson['temperature_2m_max'] as List?)?.cast<num>() ?? const [];
    final tMin = (dailyJson['temperature_2m_min'] as List?)?.cast<num>() ?? const [];
    final precip =
        (dailyJson['precipitation_probability_max'] as List?)?.cast<num>() ?? const [];
    final daily = <DayForecast>[
      for (var i = 0; i < dates.length; i++)
        DayForecast(
          date: DateTime.parse(dates[i]),
          weatherCode: i < codes.length ? codes[i].toInt() : 0,
          tempMax: i < tMax.length ? tMax[i].toDouble() : 0,
          tempMin: i < tMin.length ? tMin[i].toDouble() : 0,
          precipitationProbability: i < precip.length ? precip[i].toInt() : 0,
        ),
    ];
    return WeatherSnapshot(current: current, daily: daily);
  }
}
