import 'espace.dart';

class Note {
  const Note({
    this.id,
    this.title = '',
    this.content = '',
    this.color = 0,
    this.pinned = false,
    this.espace = Espace.perso,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String content;
  final int color;
  final bool pinned;
  final Espace espace;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? color,
    bool? pinned,
    Espace? espace,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        color: color ?? this.color,
        pinned: pinned ?? this.pinned,
        espace: espace ?? this.espace,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'content': content,
        'color': color,
        'pinned': pinned ? 1 : 0,
        'espace': espace.key,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, Object?> map) => Note(
        id: map['id'] as int?,
        title: (map['title'] as String?) ?? '',
        content: (map['content'] as String?) ?? '',
        color: (map['color'] as int?) ?? 0,
        pinned: ((map['pinned'] as int?) ?? 0) == 1,
        espace: Espace.fromKey(map['espace']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
