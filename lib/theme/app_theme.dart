import 'package:flutter/material.dart';

import '../models/espace.dart';

class AppColors {
  static const indigo = Color(0xFF5B5BD6);
  static const violet = Color(0xFF8B5CF6);
  static const teal = Color(0xFF14B8A6);
  static const coral = Color(0xFFFF7A59);
  static const amber = Color(0xFFF5A524);
  static const sky = Color(0xFF38BDF8);
  static const pink = Color(0xFFEC4899);
  static const orange = Color(0xFFEA580C); // couleur de l'espace Pro

  static const _darkBg = Color(0xFF111218);
  static const _darkCard = Color(0xFF1C1D27);
  static const _lightBg = Color(0xFFF5F6FB);

  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  static Color card(BuildContext c) => isDark(c) ? _darkCard : Colors.white;

  /// Couleur principale de chaque espace : indigo (Perso), orange (Pro).
  static Color accentFor(Espace espace) => espace == Espace.pro ? orange : indigo;

  /// Dégradé de l'en-tête selon l'heure : matin, après-midi, soir, nuit.
  /// L'espace Pro a ses propres tons orangés (jour / soir et nuit).
  static List<Color> heroGradient(int hour, {Espace espace = Espace.perso}) {
    if (espace == Espace.pro) {
      if (hour >= 5 && hour < 18) return const [Color(0xFFFB923C), Color(0xFFEA580C)];
      return const [Color(0xFF9A3412), Color(0xFFEA580C)];
    }
    if (hour >= 5 && hour < 12) return const [Color(0xFFFF9A5A), Color(0xFFFF5E7E)];
    if (hour >= 12 && hour < 18) return const [Color(0xFF3B82F6), Color(0xFF14B8A6)];
    if (hour >= 18 && hour < 22) return const [Color(0xFF5B5BD6), Color(0xFFB04FD6)];
    return const [Color(0xFF312E81), Color(0xFF5B5BD6)];
  }

  static const _notePastels = <Color>[
    Colors.white, // 0 = par défaut
    Color(0xFFFFF1A8), // jaune
    Color(0xFFFFD3E0), // rose
    Color(0xFFCDE7FF), // bleu
    Color(0xFFCDF3DD), // vert
    Color(0xFFE3D7FF), // lilas
  ];

  static int get noteColorCount => _notePastels.length;

  static Color noteColor(BuildContext c, int index) {
    if (index <= 0 || index >= _notePastels.length) return card(c);
    final pastel = _notePastels[index];
    return isDark(c) ? Color.lerp(pastel, _darkBg, 0.74)! : pastel;
  }
}

class AppTheme {
  static ThemeData light([Color accent = AppColors.indigo]) => _build(Brightness.light, accent);
  static ThemeData dark([Color accent = AppColors.indigo]) => _build(Brightness.dark, accent);

  static ThemeData _build(Brightness brightness, Color accent) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors._darkBg : AppColors._lightBg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: dark ? AppColors._darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x223B3FA0),
        indicatorColor: accent.withOpacity(dark ? 0.35 : 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        backgroundColor: dark ? AppColors._darkCard : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors._darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
