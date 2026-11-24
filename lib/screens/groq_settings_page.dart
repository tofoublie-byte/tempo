import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../llm/groq_llm_provider.dart';
import '../llm/groq_settings.dart';
import '../models/chat_message.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class GroqSettingsPage extends StatefulWidget {
  const GroqSettingsPage({super.key});

  @override
  State<GroqSettingsPage> createState() => _GroqSettingsPageState();
}

class _GroqSettingsPageState extends State<GroqSettingsPage> {
  final _keyController = TextEditingController();
  late final TextEditingController _nameController;
  final _settings = GroqSettings();

  bool _saved = false;
  bool _loading = true;
  bool _testing = false;
  bool _showKey = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<SettingsProvider>().userName);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasKey = await _settings.hasApiKey();
    if (!mounted) return;
    setState(() {
      _saved = hasKey;
      _loading = false;
    });
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _status = 'Saisis ta clé Groq.');
      return;
    }
    await _settings.saveApiKey(key);
    if (!mounted) return;
    setState(() {
      _saved = true;
      _status = 'Clé enregistrée de façon sécurisée.';
    });
    _keyController.clear();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _status = 'Connexion à Groq en cours…';
    });
    try {
      final response = await GroqLlmProvider(_settings).reply([
        ChatMessage(
          text: 'Réponds simplement : Tempo est connecté !',
          role: ChatRole.user,
          createdAt: DateTime.now(),
        ),
      ]);
      if (!mounted) return;
      setState(() => _status = 'Connexion réussie ! Réponse : $response');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Échec de connexion : $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _deleteKey() async {
    await _settings.deleteApiKey();
    if (!mounted) return;
    setState(() {
      _saved = false;
      _status = 'Clé supprimée.';
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SoftCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ton prénom',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: (v) => context.read<SettingsProvider>().setUserName(v),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.indigo, AppColors.violet]),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Assistant Groq',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      if (_saved) const Icon(Icons.check_circle, color: AppColors.teal),
                    ]),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keyController,
                      obscureText: !_showKey,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: _saved ? 'Remplacer la clé API' : 'Clé API Groq',
                        hintText: 'gsk_…',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showKey = !_showKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saveKey,
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer la clé'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _saved && !_testing ? _testConnection : null,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Tester la connexion'),
                    ),
                    if (_saved)
                      TextButton.icon(
                        onPressed: _deleteKey,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer la clé'),
                      ),
                    if (_testing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_status.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_status),
                    ],
                  ]),
                ),
              ],
            ),
    );
  }
}
