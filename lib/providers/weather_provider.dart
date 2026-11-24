import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';
import '../services/weather_service.dart';

/// État météo global : ville choisie (persistée) + météo actuelle + prévisions.
class WeatherProvider extends ChangeNotifier {
  WeatherProvider(this._preferences);

  static const _nameKey = 'tempo_weather_city';
  static const _latKey = 'tempo_weather_lat';
  static const _lonKey = 'tempo_weather_lon';

  final SharedPreferences _preferences;
  final WeatherService _service = WeatherService();

  String _cityName = 'Paris';
  double _latitude = 48.8566;
  double _longitude = 2.3522;

  CurrentWeather? _current;
  List<DayForecast> _forecast = const [];
  bool _loading = false;
  bool _failed = false;

  String get cityName => _cityName;
  CurrentWeather? get current => _current;
  List<DayForecast> get forecast => _forecast;
  bool get isLoading => _loading;
  bool get hasFailed => _failed;

  /// Restaure la dernière ville choisie puis charge la météo.
  Future<void> load() async {
    final name = _preferences.getString(_nameKey);
    if (name != null && name.isNotEmpty) _cityName = name;
    final lat = _preferences.getDouble(_latKey);
    final lon = _preferences.getDouble(_lonKey);
    if (lat != null && lon != null) {
      _latitude = lat;
      _longitude = lon;
    }
    await refresh();
  }

  Future<void> refresh({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    _failed = false;
    notifyListeners();
    try {
      final snapshot =
          await _service.fetchWeather(latitude: _latitude, longitude: _longitude);
      _current = snapshot.current;
      _forecast = snapshot.daily;
    } catch (_) {
      _failed = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Change de ville, mémorise le choix puis recharge la météo.
  Future<void> selectCity(CityLocation city) async {
    _cityName = city.name;
    _latitude = city.latitude;
    _longitude = city.longitude;
    _current = null;
    _forecast = const [];
    await _preferences.setString(_nameKey, _cityName);
    await _preferences.setDouble(_latKey, _latitude);
    await _preferences.setDouble(_lonKey, _longitude);
    notifyListeners();
    await refresh(force: true);
  }
}
