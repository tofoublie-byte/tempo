import 'espace.dart';

class Reminder {
  const Reminder({
    this.id,
    required this.title,
    required this.scheduledAt,
    this.espace = Espace.perso,
  });

  final int? id;
  final String title;
  final DateTime scheduledAt;
  final Espace espace;

  bool get isPast => !scheduledAt.isAfter(DateTime.now());

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'scheduled_at': scheduledAt.millisecondsSinceEpoch,
        'espace': espace.key,
      };

  factory Reminder.fromMap(Map<String, Object?> map) => Reminder(
        id: map['id'] as int?,
        title: (map['title'] as String?) ?? '',
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(map['scheduled_at'] as int),
        espace: Espace.fromKey(map['espace']),
      );
}
