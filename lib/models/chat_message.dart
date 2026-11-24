enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.text, required this.role, required this.createdAt});
  final String text;
  final ChatRole role;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'text': text,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String,
        role: ChatRole.values.firstWhere(
          (role) => role.name == json['role'],
          orElse: () => ChatRole.assistant,
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
