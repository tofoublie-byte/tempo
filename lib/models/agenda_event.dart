import 'espace.dart';

/// Un rendez-vous de l'agenda (jour + heure HH:mm).
class AgendaEvent {
  AgendaEvent({
    this.id,
    required DateTime date,
    required this.title,
    required this.time,
    this.location = '',
    this.espace = Espace.perso,
  }) : date = DateTime(date.year, date.month, date.day);

  final int? id;
  final DateTime date; // jour seul (minuit)
  final String title;
  final String time; // HH:mm
  final String location; // lieu (facultatif), adresse ou nom de lieu
  final Espace espace;

  /// Même rendez-vous, rangé dans un autre espace.
  AgendaEvent withEspace(Espace e) => AgendaEvent(
        id: id,
        date: date,
        title: title,
        time: time,
        location: location,
        espace: e,
      );

  /// Date + heure complètes (tri, notification, affichage).
  DateTime get dateTime {
    final p = time.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(p[0]), int.parse(p[1]));
  }

  bool get isPast => !dateTime.isAfter(DateTime.now());

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': dayKey(date),
        'time': time,
        'title': title,
        'location': location,
        'espace': espace.key,
      };

  factory AgendaEvent.fromMap(Map<String, Object?> m) => AgendaEvent(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        title: (m['title'] as String?) ?? '',
        time: (m['time'] as String?) ?? '09:00',
        location: (m['location'] as String?) ?? '',
        espace: Espace.fromKey(m['espace']),
      );
}
