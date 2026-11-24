const _days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const _shortMonths = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// « samedi 14 novembre »
String frenchDate(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

String _two(int v) => v.toString().padLeft(2, '0');

/// « 14:05 » aujourd'hui, « Hier », « 12 nov. » ou « 12/11/2025 ».
String shortDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '${_two(d.hour)}:${_two(d.minute)}';
  if (diff == 1) return 'Hier';
  if (d.year == now.year) return '${d.day} ${_shortMonths[d.month - 1]}';
  return '${_two(d.day)}/${_two(d.month)}/${d.year}';
}

/// « 21h05 »
String timeLabel(DateTime d) => '${_two(d.hour)}h${_two(d.minute)}';

/// « aujourd’hui à 21h05 », « demain à 9h00 » ou « samedi 14 novembre à 21h05 ».
String describeWhen(DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(when.year, when.month, when.day);
  final diff = day.difference(today).inDays;
  final time = timeLabel(when);
  if (diff == 0) return 'aujourd’hui à $time';
  if (diff == 1) return 'demain à $time';
  return '${frenchDate(when)} à $time';
}
