import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../assistant/assistant_provider.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import 'personal_memory_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'Mes tâches',
    'Mes rappels',
    'Rappelle-moi a 15h de controler mes messages whatsapp',
    'Note : idée de week-end',
    'Aide-moi à organiser ma journée',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Liste inversée : la position 0 est le bas de la conversation.
  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    if (preset == null) _controller.clear();
    _scrollToBottom();
    await context.read<AssistantProvider>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final assistant = context.watch<AssistantProvider>();
    final count = assistant.messages.length + (assistant.isThinking ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.indigo, AppColors.violet]),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Tempo'),
        ]),
        actions: [
          IconButton(
            tooltip: 'Mémoire de Tempo',
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalMemoryPage()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                await context.read<AssistantProvider>().clearConversation();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Nouvelle conversation')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          // reverse: true -> le dernier message reste toujours collé en bas,
          // même quand le clavier s'ouvre ou qu'une réponse arrive.
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: count,
            itemBuilder: (context, i) {
              if (assistant.isThinking) {
                if (i == 0) return const _ThinkingBubble();
                i -= 1;
              }
              final m = assistant.messages[assistant.messages.length - 1 - i];
              return _Bubble(text: m.text, isUser: m.role == ChatRole.user);
            },
          ),
        ),
        if (!assistant.isThinking)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_suggestions[i]),
                onPressed: () => _send(_suggestions[i]),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.isDark(context)
                    ? null
                    : const [
                        BoxShadow(color: Color(0x143B3FA0), blurRadius: 16, offset: Offset(0, 6)),
                      ],
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Écris ton message…',
                      filled: false,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: assistant.isThinking ? null : () => _send(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: assistant.isThinking
                            ? [Colors.grey, Colors.grey]
                            : const [AppColors.indigo, AppColors.violet],
                      ),
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isUser});
  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    const big = Radius.circular(18);
    const small = Radius.circular(4);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [AppColors.indigo, AppColors.violet])
              : null,
          color: isUser ? null : AppColors.card(context),
          borderRadius: BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: isUser ? big : small,
            bottomRight: isUser ? small : big,
          ),
          boxShadow: isUser || AppColors.isDark(context)
              ? null
              : const [BoxShadow(color: Color(0x143B3FA0), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: SelectableText.rich(
          _formatted(
            text,
            TextStyle(
              fontSize: 15,
              height: 1.35,
              color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Tempo réfléchit…'),
        ]),
      ),
    );
  }
}

/// Mini-rendu Markdown : **gras** et listes « - » / « * » → « • ».
TextSpan _formatted(String text, TextStyle base) {
  final bold = RegExp(r'\*\*(.+?)\*\*');
  final spans = <InlineSpan>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].replaceFirstMapped(RegExp(r'^(\s*)[-*]\s+'), (m) => '${m[1]}• ');
    line = line.replaceFirst(RegExp(r'^#{1,3}\s+'), '');
    var last = 0;
    for (final m in bold.allMatches(line)) {
      if (m.start > last) spans.add(TextSpan(text: line.substring(last, m.start)));
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
  }
  return TextSpan(style: base, children: spans);
}
