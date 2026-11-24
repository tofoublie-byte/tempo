import 'espace.dart';

class PersonalMemory {
  const PersonalMemory({
    required this.id,
    required this.category,
    required this.content,
    required this.createdAt,
    this.espace = Espace.perso,
  });

  final String id;
  final String category;
  final String content;
  final DateTime createdAt;
  final Espace espace;

  String get categoryLabel {
    switch (category) {
      case 'preference':
        return 'Préférence';
      case 'routine':
        return 'Habitude';
      case 'project':
        return 'Projet';
      case 'practical':
        return 'Information pratique';
      default:
        return 'Information';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'espace': espace.key,
      };

  factory PersonalMemory.fromJson(Map<String, dynamic> json) {
    return PersonalMemory(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'other',
      content: json['content'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      espace: Espace.fromKey(json['espace']),
    );
  }
}
