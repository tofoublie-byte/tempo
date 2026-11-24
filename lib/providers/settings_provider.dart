import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._preferences) {
    _userName = _preferences.getString(_nameKey) ?? '';
    _proactiveAssistantEnabled = _preferences.getBool(_proactiveKey) ?? true;
  }

  static const _nameKey = 'tempo_user_name';
  static const _proactiveKey = 'tempo_proactive';

  final SharedPreferences _preferences;
  String _userName = '';
  bool _proactiveAssistantEnabled = true;

  String get userName => _userName;
  bool get proactiveAssistantEnabled => _proactiveAssistantEnabled;

  void setUserName(String value) {
    _userName = value.trim();
    _preferences.setString(_nameKey, _userName);
    notifyListeners();
  }

  void setProactiveAssistantEnabled(bool value) {
    _proactiveAssistantEnabled = value;
    _preferences.setBool(_proactiveKey, value);
    notifyListeners();
  }
}
