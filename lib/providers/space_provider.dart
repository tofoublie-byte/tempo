import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/espace.dart';
import '../theme/app_theme.dart';

/// Espace actif (Perso ou Pro), mémorisé entre deux lancements.
/// Les autres providers l'écoutent pour filtrer leurs listes.
class SpaceProvider extends ChangeNotifier {
  SpaceProvider(this._preferences) {
    _current = Espace.fromKey(_preferences.getString(_key));
  }

  static const _key = 'tempo_espace';

  final SharedPreferences _preferences;
  late Espace _current;

  Espace get current => _current;
  bool get isPro => _current == Espace.pro;
  Color get accent => AppColors.accentFor(_current);

  Future<void> select(Espace espace) async {
    if (espace == _current) return;
    _current = espace;
    notifyListeners();
    await _preferences.setString(_key, espace.key);
  }
}
