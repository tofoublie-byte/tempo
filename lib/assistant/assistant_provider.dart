import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../llm/llm_provider.dart';
import '../models/chat_message.dart';
import '../models/espace.dart';
import '../providers/space_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/personal_memory_provider.dart';
import '../providers/reminders_provider.dart';
import '../providers/tasks_provider.dart';
import 'assistant_actions.dart';
import 'assistant_tools.dart';
import 'assistant_engine.dart';
import '../providers/agenda_provider.dart'; 

class AssistantProvider extends ChangeNotifier {
  AssistantProvider({
    required TasksProvider tasksProvider,
    required PersonalMemoryProvider memoryProvider,
    required NotesProvider notesProvider,
    required RemindersProvider remindersProvider,
    required AgendaProvider agendaProvider, 
    required SpaceProvider spaceProvider,
    required LlmProvider llmProvider,
    required SharedPreferences preferences,
  })  : _preferences = preferences,
        _space = spaceProvider,
        _memoryProvider = memoryProvider,
        _engine = AssistantEngine(
          llmProvider: llmProvider,
          actions: AssistantActions(tasksProvider, memoryProvider, notesProvider, remindersProvider),
          tools: AssistantTools(tasksProvider, notesProvider, remindersProvider, agendaProvider),
        ) {
    // Changer d'espace affiche l'historique de l'autre espace.
    _space.addListener(notifyListeners);
    for (final espace in Espace.values) {
      _loadMessages(espace);
    }
  }

  final SharedPreferences _preferences;
  final SpaceProvider _space;
  final PersonalMemoryProvider _memoryProvider;
  final AssistantEngine _engine;

  /// Un historique de conversation par espace. L'historique Perso reste
  /// enregistré sous l'ancienne clé `tempo_messages`.
  final Map<Espace, List<ChatMessage>> _byEspace = {
    Espace.perso: [],
    Espace.pro: [],
  };
  bool _isThinking = false;

  static String _storageKey(Espace e) =>
      e == Espace.pro ? 'tempo_messages_pro' : 'tempo_messages';

  List<ChatMessage> get messages => List.unmodifiable(_byEspace[_space.current]!);
  bool get isThinking => _isThinking;

  static const _maxStored = 100;
  static const _maxSentToModel = 20;

  void _loadMessages(Espace espace) {
    final list = _byEspace[espace]!;
    final saved = _preferences.getString(_storageKey(espace));
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        list.addAll(decoded.map((item) => ChatMessage.fromJson(
              Map<String, dynamic>.from(item as Map),
            )));
      } catch (_) {
        list.clear();
      }
    }
    if (list.isEmpty) {
      list.add(_welcome(espace));
      _saveMessages(espace);
    }
  }

  /// Efface la conversation de l'espace actif seulement.
  Future<void> clearConversation() async {
    final espace = _space.current;
    final list = _byEspace[espace]!;
    list.clear();
    list.add(_welcome(espace));
    _saveMessages(espace);
    notifyListeners();
  }

  ChatMessage _welcome(Espace espace) => ChatMessage(
        text: espace == Espace.pro
            ? 'Bonjour ! Je suis Tempo, côté pro. Je peux t’aider à organiser ton travail, '
                'gérer tes tâches et tes notes professionnelles. Essaie : « Ajoute une note compte rendu de réunion ».'
            : 'Bonjour ! Je suis Tempo. Je peux t’aider à organiser ta journée, '
                'gérer tes tâches et ton bloc-notes. Essaie : « Ajoute une note idée de week-end ».',
        role: ChatRole.assistant,
        createdAt: DateTime.now(),
      );

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('Clé Groq non configurée')) {
      return 'Il manque ta clé Groq. Ouvre les Réglages pour l’ajouter.';
    }
    if (text.contains('401') || text.contains('429')) {
      return text.replaceFirst('Exception: ', '');
    }
    if (text.contains('SocketException') ||
        text.contains('TimeoutException') ||
        text.contains('ClientException')) {
      return 'Je n’arrive pas à joindre Groq. Vérifie ta connexion internet et réessaie.';
    }
    return 'Je rencontre un problème pour répondre : ${text.replaceFirst('Exception: ', '')}';
  }

  void _saveMessages(Espace espace) {
    final list = _byEspace[espace]!;
    if (list.length > _maxStored) {
      list.removeRange(0, list.length - _maxStored);
    }
    _preferences.setString(
      _storageKey(espace),
      jsonEncode(list.map((message) => message.toJson()).toList()),
    );
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isThinking) return;

    // La réponse est rangée dans l'espace où la question a été posée.
    final espace = _space.current;
    final messages = _byEspace[espace]!;

    messages.add(ChatMessage(
      text: clean,
      role: ChatRole.user,
      createdAt: DateTime.now(),
    ));
    _saveMessages(espace);
    _isThinking = true;
    notifyListeners();

    try {
      // Les demandes de consultation ou d'effacement sont traitées comme
      // des commandes, elles ne sont pas ajoutées à la mémoire.
      final lower = clean.toLowerCase();
      final isMemoryCommand = lower.contains('qu’est-ce que tu sais sur moi') ||
          lower.contains("qu'est-ce que tu sais sur moi") ||
          lower.contains('que sais-tu sur moi') ||
          lower.contains('qu’as-tu retenu') ||
          lower.contains("qu'as-tu retenu") ||
          lower.startsWith('oublie ') ||
          lower.startsWith('oublies ') ||
          lower.startsWith('efface ') ||
          lower.startsWith('supprime de ta mémoire ') ||
          lower.startsWith('supprime de ta memoire ');

      final remembered = isMemoryCommand
          ? null
          : await _memoryProvider.rememberFromMessage(clean);

      final history = messages.length > _maxSentToModel
          ? messages.sublist(messages.length - _maxSentToModel)
          : List<ChatMessage>.of(messages);

      var answer = await _engine.answer(
        clean,
        history,
        memoryContext: _memoryProvider.contextForAssistant,
      );
      if (remembered != null) {
        answer = '$answer\n\nJe retiens aussi : « $remembered ».';
      }

      messages.add(ChatMessage(
        text: answer,
        role: ChatRole.assistant,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      messages.add(ChatMessage(
        text: _friendlyError(e),
        role: ChatRole.assistant,
        createdAt: DateTime.now(),
      ));
    } finally {
      _saveMessages(espace);
      _isThinking = false;
      notifyListeners();
    }
  }
}
