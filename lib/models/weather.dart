/// Ville renvoyée par la recherche de localité (géocodage Open-Meteo).
class CityLocation {
  const CityLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1 = '',
    this.country = '',
  });

  final String name;
  final String admin1;
  final String country;
  final double latitude;
  final double longitude;

  String get subtitle {
    final parts = [
      if (admin1.isNotEmpty) admin1,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }
}

/// Météo du moment pour une ville.
class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
  });

  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
}

/// Prévision d'une journée (7 jours affichés).
class DayForecast {
  const DayForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMin,
    required this.tempMax,
    required this.precipitationProbability,
  });

  final DateTime date;
  final int weatherCode;
  final double tempMin;
  final double tempMax;
  final int precipitationProbability;
}
