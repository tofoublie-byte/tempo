import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/weather.dart';
import '../providers/weather_provider.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/weather_codes.dart';

/// Page météo : prévisions sur 7 jours et choix de la ville.
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _service = WeatherService();
  Timer? _debounce;

  List<CityLocation> _results = const [];
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await _service.searchCities(trimmed);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = 'Recherche indisponible, vérifiez votre connexion.';
      });
    }
  }

  Future<void> _selectCity(CityLocation city) async {
    _debounce?.cancel();
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _results = const []);
    await context.read<WeatherProvider>().selectCity(city);
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return "Aujourd'hui";
    if (day == today.add(const Duration(days: 1))) return 'Demain';
    final weekday = DateFormat('EEEE', 'fr_FR').format(date);
    return '${weekday[0].toUpperCase()}${weekday.substring(1)}';
  }

  String _dateLabel(DateTime date) {
    final formatted = DateFormat('d MMMM', 'fr_FR').format(date);
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Météo')),
      body: RefreshIndicator(
        onRefresh: () => weather.refresh(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (weather.isLoading && weather.current == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (weather.current == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('Météo indisponible'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: weather.refresh,
                    child: const Text('Réessayer'),
                  ),
                ]),
              )
            else ...[
              _CurrentCard(city: weather.cityName, current: weather.current!),
              const SizedBox(height: 20),
            ],

            // ----- Choix de la ville -----
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Choisir une ville',
                hintText: 'Ex. : Lyon, Nantes, Bruxelles…',
                border: OutlineInputBorder(),
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              )
            else if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_searchError!, style: TextStyle(color: scheme.error)),
              )
            else if (_results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: Column(children: [
                    for (final city in _results)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(city.name),
                        subtitle:
                            city.subtitle.isEmpty ? null : Text(city.subtitle),
                        onTap: () => _selectCity(city),
                      ),
                  ]),
                ),
              ),
            const SizedBox(height: 20),

            // ----- Prévisions 7 jours -----
            Text('Prévisions sur 7 jours',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (weather.forecast.isEmpty)
              Text(
                weather.isLoading ? 'Chargement…' : 'Aucune prévision disponible.',
                style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
              )
            else
              for (final day in weather.forecast)
                _ForecastTile(day: day, dayLabel: _dayLabel(day.date), dateLabel: _dateLabel(day.date)),
          ],
        ),
      ),
    );
  }
}

/// Carte "maintenant" affichée en haut de la page météo.
class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.city, required this.current});

  final String city;
  final CurrentWeather current;

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.heroGradient(DateTime.now().hour);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(city,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: [
          Icon(weatherIcon(current.weatherCode, isDay: current.isDay),
              color: Colors.white, size: 56),
          const SizedBox(width: 16),
          Text('${current.temperature.round()}°',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(weatherLabel(current.weatherCode),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Ressenti ${current.apparentTemperature.round()}°',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.water_drop_outlined, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text('${current.humidity} % d\u2019humidité',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 18),
          const Icon(Icons.air, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text('${current.windSpeed.round()} km/h de vent',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ]),
    );
  }
}

/// Une ligne du tableau des 7 jours.
class _ForecastTile extends StatelessWidget {
  const _ForecastTile({
    required this.day,
    required this.dayLabel,
    required this.dateLabel,
  });

  final DayForecast day;
  final String dayLabel;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Icon(weatherIcon(day.weatherCode), color: AppColors.sky),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dayLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(dateLabel,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurface.withOpacity(0.6))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${day.tempMax.round()}° / ${day.tempMin.round()}°',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${day.precipitationProbability} % de pluie',
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurface.withOpacity(0.6))),
            ]),
          ]),
        ),
      ),
    );
  }
}
