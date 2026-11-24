import '../models/chat_message.dart';
import 'llm_provider.dart';

/// Fournisseur local de démonstration : aucun accès Internet ni clé API.
/// Il reçoit déjà la mémoire personnelle, comme le fera le futur vrai LLM.
class DemoLlmProvider implements LlmProvider {
  @override
  Future<String> reply(
    List<ChatMessage> conversation, {
    String memoryContext = '',
    List<Map<String, dynamic>>? tools,
    ToolHandler? onToolCall,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final message = conversation.isEmpty
        ? ''
        : conversation.last.text.toLowerCase();
    final preference = _memoryFor(memoryContext, 'Préférence');
    final routine = _memoryFor(memoryContext, 'Habitude');
    final project = _memoryFor(memoryContext, 'Projet');

    if (message.contains('météo') || message.contains('temps')) {
      return _withRelevantMemory(
        "Je pourrai te donner la météo lorsque nous connecterons un service météo.",
        preference,
        message,
      );
    }

    if (message.contains('bonjour') || message.contains('salut')) {
      return "Bonjour ! Je suis Tempo. Je peux t'aider à organiser ta journée. "
          "Que souhaites-tu faire ?";
    }

    if (_asksForExplanation(message) && preference != null) {
      return 'Je vais tenir compte de ta préférence : « $preference ». '
          'Je suis encore en mode démonstration : je ne peux pas encore '
          'développer une vraie explication complète, mais cette information '
          'est maintenant transmise à mon moteur de réponse.';
    }

    if (_asksAboutPlanning(message) && routine != null) {
      return 'Pour t’aider à organiser ta journée, je tiendrai compte de ton '
          'habitude : « $routine ». '
          'Je suis encore en mode démonstration ; nous ajouterons ensuite '
          'la préparation complète du planning.';
    }

    if (_asksAboutProject(message) && project != null) {
      return 'Je garde ton projet en tête : « $project ». '
          'Je pourrai m’appuyer sur cette information pour reprendre le sujet '
          'sans que tu aies à tout réexpliquer. Pour le moment, je fonctionne '
          'encore en mode démonstration.';
    }

    if (memoryContext.trim().isNotEmpty) {
      return "J'ai bien reçu ton message. Je dispose maintenant des informations "
          'que tu m’as confiées et je pourrai les utiliser lorsqu’elles seront '
          'pertinentes. Je fonctionne encore en mode démonstration : nous '
          'connecterons ensuite un véritable modèle d’intelligence artificielle.';
    }

    return "J'ai bien reçu ton message. Je fonctionne actuellement en mode "
        'démonstration. Nous connecterons ensuite un véritable modèle '
        'd’intelligence artificielle.';
  }

  String? _memoryFor(String context, String category) {
    for (final line in context.split('\n')) {
      final prefix = '$category: ';
      if (line.startsWith(prefix)) return line.substring(prefix.length).trim();
    }
    return null;
  }

  bool _asksForExplanation(String message) {
    return message.contains('explique') ||
        message.contains('comment') ||
        message.contains('aide-moi') ||
        message.contains('aide moi') ||
        message.contains('étape') ||
        message.contains('comprendre');
  }

  bool _asksAboutPlanning(String message) {
    return message.contains('organis') ||
        message.contains('planning') ||
        message.contains('programme') ||
        message.contains('journée') ||
        message.contains('demain') ||
        message.contains('routine');
  }

  bool _asksAboutProject(String message) {
    return message.contains('projet') ||
        message.contains('reprendre') ||
        message.contains('application') ||
        message.contains('développement');
  }

  String _withRelevantMemory(
    String answer,
    String? preference,
    String message,
  ) {
    if (preference != null && _asksForExplanation(message)) {
      return '$answer\n\nJe tiendrai aussi compte de ta préférence : « $preference ». ';
    }
    return answer;
  }
}
