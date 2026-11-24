import '../llm/llm_provider.dart';
import '../models/chat_message.dart';
import 'assistant_actions.dart';
import 'assistant_tools.dart';

class AssistantEngine {
  AssistantEngine({
    required LlmProvider llmProvider,
    required AssistantActions actions,
    required AssistantTools tools,
  })  : _llm = llmProvider,
        _actions = actions,
        _tools = tools;

  final LlmProvider _llm;
  final AssistantActions _actions;
  final AssistantTools _tools;

  Future<String> answer(
    String message,
    List<ChatMessage> conversation, {
    String memoryContext = '',
  }) async {
    // 1) Commandes très précises traitées localement (rapide, fonctionne hors ligne).
    final actionReply = await _actions.tryExecute(message);
    if (actionReply != null) return actionReply;

    // 2) Sinon, Groq comprend la phrase et appelle les outils lui-même.
    return _llm.reply(
      conversation,
      memoryContext: memoryContext,
      tools: AssistantTools.definitions,
      onToolCall: _tools.execute,
    );
  }
}
