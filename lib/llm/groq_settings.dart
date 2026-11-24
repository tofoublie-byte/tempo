import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GroqSettings {
  static const _storage = FlutterSecureStorage();

  static const _apiKeyName = 'tempo_groq_api_key';

  Future<void> saveApiKey(String key) async {
    await _storage.write(
      key: _apiKeyName,
      value: key.trim(),
    );
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyName);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyName);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}
