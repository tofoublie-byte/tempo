
class ParsedReminder {
  const ParsedReminder(this.title, this.when);

  final String title;
  final DateTime when;
}

const _weekdays = <String, int>{
  'lundi': DateTime.monday,
  'mardi': DateTime.tuesday,
  'mercredi': DateTime.wednesday,
  'jeudi': DateTime.thursday,
  'vendredi': DateTime.friday,
  'samedi': DateTime.saturday,
  'dimanche': DateTime.sunday,
};

final _relative = RegExp(
  r'\bdans\s+(\d{1,3})\s*(minutes?|mins?|heures?|h|jours?)\b',
  caseSensitive: false,
);

final _time = RegExp(
  r'\bà\s*(?<hour1>\d{1,2})(?:\s*(?:h|heures?)\s*(?<minute1>\d{1,2})?|\s*:\s*(?<minute2>\d{2}))?'
  r'|\b(?<hour2>\d{1,2})\s*(?:h|heures?)\s*(?<minute3>\d{1,2})?'
  r'|\b(?<hour3>\d{1,2}):(?<minute4>\d{2})',
  caseSensitive: false,
);

final _dayWords = RegExp(
  r"\baujourd['’]hui\b|\bapr[èe]s[- ]demain\b|\bdemain\b",
  caseSensitive: false,
);

final _weekdayPattern = RegExp(
  r'\b(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)'
  r'(?:\s+(prochain|qui vient))?\b',
  caseSensitive: false,
);

final _reminderTrigger = RegExp(
  r'\b(?:rappelle?[\s-]*moi|rappel)\b',
  caseSensitive: false,
);

ParsedReminder? parseReminder(String message, {DateTime? now}) {
  now ??= DateTime.now();

  if (message.length > 200) return null;

  if (!_reminderTrigger.hasMatch(message)) return null;

  final relative = _relative.firstMatch(message);
  final timeMatch = _time.firstMatch(message);

  int hour = 9;
  int minute = 0;
  var hasTime = false;

  if (timeMatch != null) {
    final hourText = timeMatch.namedGroup('hour1') ??
        timeMatch.namedGroup('hour2') ??
        timeMatch.namedGroup('hour3');

    final minuteText = timeMatch.namedGroup('minute1') ??
        timeMatch.namedGroup('minute2') ??
        timeMatch.namedGroup('minute3') ??
        timeMatch.namedGroup('minute4');

    hour = int.parse(hourText!);
    minute = int.tryParse(minuteText ?? '0') ?? 0;

    if (hour > 23 || minute > 59) return null;

    hasTime = true;
  }

  late DateTime when;

  if (relative != null) {
    final amount = int.parse(relative.group(1)!);
    final unit = relative.group(2)!.toLowerCase();

    if (amount == 0) return null;

    if (unit.startsWith('jour')) {
      when = DateTime(
        now.year,
        now.month,
        now.day + amount,
        hasTime ? hour : now.hour,
        hasTime ? minute : now.minute,
      );
    } else {
      if (hasTime) return null;

      if (unit.startsWith('heure') || unit == 'h') {
        when = now.add(Duration(hours: amount));
      } else {
        when = now.add(Duration(minutes: amount));
      }
    }
  } else {
    var days = 0;

    final dayMatch = _dayWords.firstMatch(message);
    final weekdayMatch = _weekdayPattern.firstMatch(message);

    if (dayMatch != null) {
      final day = dayMatch.group(0)!.toLowerCase();

      if (day.startsWith('apr')) {
        days = 2;
      } else if (day == 'demain') {
        days = 1;
      }
    } else if (weekdayMatch != null) {
      final target = _weekdays[
        weekdayMatch.group(1)!.toLowerCase()
      ];

      if (target != null) {
        days = (target - now.weekday + 7) % 7;

        if (weekdayMatch.group(2) != null && days == 0) {
          days = 7;
        }
      }
    }

    if (!hasTime) return null;

    when = DateTime(
      now.year,
      now.month,
      now.day + days,
      hour,
      minute,
    );

    if (dayMatch == null && weekdayMatch == null && !when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }

    if (weekdayMatch != null &&
        days == 0 &&
        !when.isAfter(now)) {
      when = when.add(const Duration(days: 7));
    }
  }

  // Nettoyage du titre.
  var title = message;

  if (relative != null) {
    title = title.replaceRange(relative.start, relative.end, ' ');
  }

  if (timeMatch != null) {
    title = title.replaceRange(timeMatch.start, timeMatch.end, ' ');
  }

  title = title
      .replaceAll(_dayWords, ' ')
      .replaceAll(_weekdayPattern, ' ')
      .replaceAll(_reminderTrigger, ' ')
      .replaceFirst(
        RegExp(
          r"^\s*(?:de|pour|d['’])\s*",
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s:,;.\-–]+|[\s:,;.\-–]+$'), '')
      .trim();

  if (title.isEmpty) title = 'Rappel';

  if (title.length > 80) {
    title = '${title.substring(0, 80)}…';
  }

  title = '${title[0].toUpperCase()}${title.substring(1)}';

  return ParsedReminder(title, when);
}
