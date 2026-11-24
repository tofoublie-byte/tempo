import '../models/chat_message.dart';

/// Exécute un outil demandé par le modèle (ex. « create_reminder »)
/// et renvoie un texte décrivant le résultat.
typedef ToolHandler = Future<String> Function(String name, Map<String, dynamic> args);

abstract class LlmProvider {
  Future<String> reply(
    List<ChatMessage> conversation, {
    String memoryContext = '',
    List<Map<String, dynamic>>? tools,
    ToolHandler? onToolCall,
  });
}
