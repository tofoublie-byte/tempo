import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/personal_memory.dart';
import 'space_provider.dart';

/// Mémoire personnelle locale de Tempo.
///
/// Les informations restent sur le téléphone. La détection est volontairement
/// simple tant qu'un véritable fournisseur d'IA n'est pas connecté.
class PersonalMemoryProvider extends ChangeNotifier {
  PersonalMemoryProvider(this._preferences, this._space) {
    // Changer d'espace redessine la page Mémoire.
    _space.addListener(notifyListeners);
    _load();
  }

  static const String _storageKey = 'tempo_personal_memories';

  final SharedPreferences _preferences;
  final SpaceProvider _space;
  final List<PersonalMemory> _memories = []; // les deux espaces

  /// Souvenirs de l'espace actif uniquement.
  List<PersonalMemory> get _visible =>
      _memories.where((m) => m.espace == _space.current).toList();

  List<PersonalMemory> get memories => List.unmodifiable(_visible);

  /// Contexte court transmis au moteur de réponse pour personnaliser les échanges.
  String get contextForAssistant {
    final visible = _visible;
    if (visible.isEmpty) return '';
    return visible
        .take(10)
        .map((memory) => '${memory.categoryLabel}: ${memory.content}')
        .join('\n');
  }

  void _load() {
    final saved = _preferences.getString(_storageKey);
    if (saved == null) return;

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;
      _memories.addAll(
        decoded.map(
          (item) => PersonalMemory.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    } catch (_) {
      _memories.clear();
    }
  }

  Future<void> _save() async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(_memories.map((memory) => memory.toJson()).toList()),
    );
  }

  /// Mémorise une information seulement si elle correspond à une formulation
  /// reconnue et ne semble pas contenir de donnée sensible.
  Future<String?> rememberFromMessage(String message) async {
    final candidate = _extractCandidate(message);
    if (candidate == null) return null;

    final normalized = candidate.content.toLowerCase();
    final espace = _space.current;
    final alreadySaved = _memories.any(
      (memory) =>
          memory.espace == espace &&
          memory.category == candidate.category &&
          memory.content.toLowerCase() == normalized,
    );
    if (alreadySaved) return null;

    final memory = PersonalMemory(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: candidate.category,
      content: candidate.content,
      createdAt: DateTime.now(),
      espace: espace,
    );

    _memories.insert(0, memory);
    await _save();
    notifyListeners();
    return memory.content;
  }

  _MemoryCandidate? _extractCandidate(String message) {
    final text = message.trim();
    final lower = text.toLowerCase();

    // Les données sensibles ne sont jamais enregistrées automatiquement.
    const sensitiveTerms = [
      'mot de passe',
      'code secret',
      'code pin',
      'carte bancaire',
      'compte bancaire',
      'banque',
      'adresse exacte',
      'mon adresse',
      'numéro de téléphone',
      'numero de telephone',
      'téléphone',
      'telephone',
      'santé',
      'sante',
      'maladie',
      'médicament',
      'medicament',
      'traitement',
      'allerg',
      'diagnostic',
      'religion',
      'politique',
      'parti politique',
      'orientation sexuelle',
      'sexualité',
      'sexualite',
      'salaire',
      'revenu',
    ];
    if (sensitiveTerms.any(lower.contains)) return null;

    const rules = <_MemoryRule>[
      _MemoryRule('preference', [
        'je préfère ',
        'je prefere ',
        'j’aime ',
        "j'aime ",
        'j’adore ',
        "j'adore ",
        'je n’aime pas ',
        "je n'aime pas ",
        'je déteste ',
        'je deteste ',
      ]),
      _MemoryRule('routine', [
        'chaque matin ',
        'tous les matins ',
        'chaque soir ',
        'tous les soirs ',
        'tous les jours ',
        'd’habitude ',
        "d'habitude ",
        'habituellement ',
      ]),
      _MemoryRule('project', [
        'je travaille sur ',
        'je développe ',
        'je developpe ',
        'je construis ',
        'mon projet est ',
      ]),
      _MemoryRule('practical', [
        'je conduis une ',
        'je roule en ',
        'je possède une ',
        'je possede une ',
        'j’utilise ',
        "j'utilise ",
      ]),
    ];

    for (final rule in rules) {
      for (final prefix in rule.prefixes) {
        if (!lower.startsWith(prefix)) continue;

        var content = text.substring(prefix.length).trim();
        content = content.replaceFirst(RegExp(r'[.!?]+$'), '').trim();

        if (content.length < 3 || content.length > 140) return null;
        if (content.contains('\n')) return null;

        return _MemoryCandidate(rule.category, content);
      }
    }

    return null;
  }

  Future<bool> forgetMatching(String request) async {
    final query = request.toLowerCase().trim();
    if (query.isEmpty) return false;

    final espace = _space.current;
    final before = _memories.length;
    _memories.removeWhere((memory) {
      if (memory.espace != espace) return false;
      final content = memory.content.toLowerCase();
      return content.contains(query) || query.contains(content);
    });

    if (_memories.length == before) return false;
    await _save();
    notifyListeners();
    return true;
  }

  /// Efface seulement les souvenirs de l'espace actif.
  Future<void> forgetAll() async {
    final espace = _space.current;
    _memories.removeWhere((memory) => memory.espace == espace);
    await _save();
    notifyListeners();
  }

  String describeMemories() {
    final visible = _visible;
    if (visible.isEmpty) {
      return 'Je n’ai pas encore mémorisé d’informations personnelles. '
          'Je retiendrai automatiquement certaines préférences, habitudes et '
          'informations sur tes projets lorsque tu me les formuleras clairement.';
    }

    final lines = visible
        .map((memory) => '• ${memory.categoryLabel} : ${memory.content}')
        .join('\n');
    return 'Voici ce que j’ai retenu :\n$lines';
  }
}

class _MemoryRule {
  const _MemoryRule(this.category, this.prefixes);

  final String category;
  final List<String> prefixes;
}

class _MemoryCandidate {
  const _MemoryCandidate(this.category, this.content);

  final String category;
  final String content;
}
