import 'espace.dart';

class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    this.isDone = false,
    this.espace = Espace.perso,
  });
  final int id;
  final String title;
  final bool isDone;
  final Espace espace;

  DailyTask copyWith({String? title, bool? isDone}) => DailyTask(
        id: id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        espace: espace,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'isDone': isDone, 'espace': espace.key};

  factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
        id: json['id'] as int,
        title: json['title'] as String,
        isDone: json['isDone'] as bool? ?? false,
        espace: Espace.fromKey(json['espace']),
      );
}
