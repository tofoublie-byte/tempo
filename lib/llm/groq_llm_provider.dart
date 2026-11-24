import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../utils/french_date.dart';
import 'groq_settings.dart';
import 'llm_provider.dart';

class GroqLlmProvider implements LlmProvider {
  GroqLlmProvider(this.settings);

  final GroqSettings settings;

  static const _model = 'openai/gpt-oss-20b';
  static const _maxToolRounds = 4;

 
String _systemPrompt(String memoryContext) {
  final now = DateTime.now();

  final memoryBlock = memoryContext.trim().isEmpty
      ? ''
      : 'Informations mémorisées sur l’utilisateur :\n'
          '$memoryContext\n';

  return '''
Tu es Tempo, un véritable assistant personnel francophone.

PERSONNALITÉ
- Tu es chaleureux, organisé, attentif et proactif.
- Tu tutoies naturellement l'utilisateur.
- Tu engages régulièrement la conversation.
- Tu ne te comportes pas comme un simple moteur de questions/réponses.
- Tu proposes spontanément ton aide lorsque cela est pertinent.
- Tu restes naturel, jamais insistant ou répétitif.

DATE ET HEURE
Nous sommes le ${frenchDate(now)} ${now.year}.
Il est ${timeLabel(now)}.
Date ISO : ${now.toIso8601String().substring(0, 10)}.

$memoryBlock

CONTEXTE DE CONVERSATION
- Tiens compte des messages précédents.
- Comprends les réponses courtes comme « oui », « non », « demain » ou « à 15h » en fonction de la discussion.
- Ne redemande pas une information déjà fournie.
- Si une demande fait référence à une conversation précédente, utilise ce contexte.
- Si tu ne comprends pas, pose une seule question précise.
- Ne prétends jamais avoir une information que tu ne possèdes pas.

GESTION DES RAPPELS
- Un rappel est différent d'une tâche.
- Pour créer un rappel, utilise create_reminder.
- N'utilise jamais add_task pour une demande de rappel.
- Si la date ou l'heure manque, demande une précision.
- Ne devine pas une date ambiguë.
- « Ce soir » signifie 20h00.
- « Demain matin » signifie 9h00.
- « Demain après-midi » signifie 14h00.
- « Demain soir » signifie 20h00.
- Les dates doivent être calculées à partir de la date et heure indiquées plus haut.
- Utilise une date locale au format AAAA-MM-JJTHH:MM.
- Vérifie que le rappel est dans le futur.

GESTION DE L'AGENDA
- Un rendez-vous (médecin, réunion, visite...) est différent d'un rappel et d'une tâche.
- Pour créer un rendez-vous, utilise add_event (date AAAA-MM-JJ, heure HH:MM, lieu facultatif).
- Pour consulter l'agenda, utilise list_events.
- Si la date ou l'heure manque, demande une précision.
- Ne dis jamais que le rendez-vous est ajouté avant le résultat de l'outil.

GESTION DES TÂCHES
- Utilise add_task pour une nouvelle tâche.
- Utilise complete_task pour terminer une tâche.
- Vérifie les listes avant de confirmer une action.
- Ne crée pas de doublons inutilement.

GESTION DES NOTES
- Utilise add_note pour enregistrer une information.
- Utilise list_notes pour consulter les notes.

UTILISATION DES OUTILS
- Lorsque l'utilisateur demande une action réalisable, utilise l'outil adapté.
- Ne dis jamais qu'une action est effectuée avant le résultat de l'outil.
- Si un outil renvoie une erreur, explique-la simplement.
- N'invente jamais le résultat d'une action.

PROACTIVITÉ
- Propose de préparer la journée lorsque cela est pertinent.
- Signale les tâches en attente si l'utilisateur demande son programme.
- Propose des rappels lorsqu'une échéance est évoquée.
- Évite de répéter les mêmes propositions.
- Ne prétends pas connaître la météo ou des informations en direct sans accès à une source.

LIMITES
- Tu n'as pas d'accès direct à Internet.
- Tu n'as pas accès à un agenda externe (seulement à l'agenda de l'application).
- Tu ne peux pas envoyer de SMS ou de courriels.
- Tu réponds uniquement par écrit.

STYLE
- Réponses naturelles, claires et concises.
- Utilise des listes lorsque cela facilite la lecture.
- Évite les réponses mécaniques.
''';
}


  Future<Map<String, dynamic>> _post(
    String apiKey,
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  ) async {
    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            if (tools != null) 'tools': tools,
            if (tools != null) 'tool_choice': 'auto',
            'temperature': 0.5,
            // Modèle à raisonnement : on laisse de la marge pour que la
            // réponse ne soit pas coupée avant d'être écrite.
            'max_tokens': 2048,
          }),
        )
        .timeout(const Duration(seconds: 45));

    // Groq n'indique pas toujours l'encodage : on décode en UTF-8 nous-mêmes.
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Clé Groq refusée (401). Vérifie-la dans les réglages.');
      }
      if (response.statusCode == 429) {
        throw Exception('Limite Groq atteinte (429). Réessaie dans un moment.');
      }
      throw _GroqHttpError(response.statusCode, body);
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  @override
  Future<String> reply(
    List<ChatMessage> conversation, {
    String memoryContext = '',
    List<Map<String, dynamic>>? tools,
    ToolHandler? onToolCall,
  }) async {
    final apiKey = await settings.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Clé Groq non configurée.');
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt(memoryContext)},
      for (final m in conversation)
        {
          'role': m.role == ChatRole.user ? 'user' : 'assistant',
          'content': m.text,
        },
    ];

    var activeTools = (tools != null && onToolCall != null) ? tools : null;

    for (var round = 0; round <= _maxToolRounds; round++) {
      Map<String, dynamic> data;
      try {
        data = await _post(apiKey, messages, activeTools);
      } on _GroqHttpError catch (e) {
        // Le modèle a parfois mal formé un appel d'outil : on réessaie sans outils.
        if (activeTools != null && e.status == 400) {
          activeTools = null;
          continue;
        }
        throw Exception('Erreur Groq ${e.status}: ${e.body}');
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Groq n’a pas fourni de réponse.');
      }
      final message = Map<String, dynamic>.from((choices.first as Map)['message'] as Map);
      final calls = message['tool_calls'] as List<dynamic>?;

      if (calls != null && calls.isNotEmpty && activeTools != null && round < _maxToolRounds) {
        messages.add({
          'role': 'assistant',
          'content': message['content'] ?? '',
          'tool_calls': calls,
        });
        for (final raw in calls) {
          final call = Map<String, dynamic>.from(raw as Map);
          final fn = Map<String, dynamic>.from(call['function'] as Map);
          var args = <String, dynamic>{};
          try {
            final decoded = jsonDecode((fn['arguments'] ?? '{}').toString());
            if (decoded is Map) args = Map<String, dynamic>.from(decoded);
          } catch (_) {}
          final result = await onToolCall!(fn['name'].toString(), args);
          messages.add({
            'role': 'tool',
            'tool_call_id': call['id'],
            'content': result,
          });
        }
        continue;
      }

      final content = message['content']?.toString().trim();
      if (content == null || content.isEmpty) {
        throw Exception('Réponse Groq vide.');
      }
      return content;
    }
    throw Exception('Trop d’étapes pour cette demande. Reformule-la plus simplement.');
  }
}

class _GroqHttpError implements Exception {
  _GroqHttpError(this.status, this.body);
  final int status;
  final String body;
}
