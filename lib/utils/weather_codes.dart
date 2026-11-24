import 'package:flutter/material.dart';

/// Libellés français des codes météo WMO utilisés par Open-Meteo.
String weatherLabel(int code) {
  switch (code) {
    case 0:
      return 'Ciel dégagé';
    case 1:
      return 'Principalement dégagé';
    case 2:
      return 'Partiellement nuageux';
    case 3:
      return 'Ciel couvert';
    case 45:
    case 48:
      return 'Brouillard';
    case 51:
      return 'Bruine légère';
    case 53:
      return 'Bruine';
    case 55:
      return 'Bruine dense';
    case 56:
    case 57:
      return 'Bruine verglaçante';
    case 61:
      return 'Pluie faible';
    case 63:
      return 'Pluie';
    case 65:
      return 'Pluie forte';
    case 66:
    case 67:
      return 'Pluie verglaçante';
    case 71:
      return 'Neige faible';
    case 73:
      return 'Neige';
    case 75:
      return 'Neige forte';
    case 77:
      return 'Grains de neige';
    case 80:
      return 'Averses faibles';
    case 81:
      return 'Averses';
    case 82:
      return 'Averses violentes';
    case 85:
    case 86:
      return 'Averses de neige';
    case 95:
      return 'Orage';
    case 96:
    case 99:
      return 'Orage avec grêle';
    default:
      return 'Météo inconnue';
  }
}

/// Icône correspondant à un code météo WMO.
IconData weatherIcon(int code, {bool isDay = true}) {
  switch (code) {
    case 0:
    case 1:
      return isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round;
    case 2:
      return isDay ? Icons.wb_twilight : Icons.nightlight_round;
    case 3:
      return Icons.cloud;
    case 45:
    case 48:
      return Icons.blur_on;
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
      return Icons.grain;
    case 61:
    case 63:
    case 65:
    case 66:
    case 67:
    case 80:
    case 81:
    case 82:
      return Icons.umbrella;
    case 71:
    case 73:
    case 75:
    case 77:
    case 85:
    case 86:
      return Icons.ac_unit;
    case 95:
    case 96:
    case 99:
      return Icons.flash_on;
    default:
      return Icons.cloud_outlined;
  }
}
