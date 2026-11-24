import '../models/agenda_event.dart';
import '../providers/agenda_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/reminders_provider.dart';
import '../providers/tasks_provider.dart';
import '../utils/french_date.dart';

/// Les « outils » que le modèle (Groq) peut appeler pour agir dans l'app.
class AssistantTools {
  AssistantTools(this._tasks, this._notes, this._reminders, this._agenda);

  final TasksProvider _tasks;
  final NotesProvider _notes;
  final RemindersProvider _reminders;
  final AgendaProvider _agenda;

  static Map<String, dynamic> _tool(
    String name,
    String description, [
    Map<String, dynamic> properties = const {},
    List<String> required = const [],
  ]) =>
      {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': {
            'type': 'object',
            'properties': properties,
            'required': required,
          },
        },
      };

  static final List<Map<String, dynamic>> definitions = [
    _tool(
      'add_task',
      'Ajoute une tâche à la liste du jour.',
      {'title': {'type': 'string', 'description': 'Intitulé court de la tâche'}},
      ['title'],
    ),
    _tool('list_tasks', 'Liste les tâches (en attente et terminées).'),
    _tool(
      'complete_task',
      'Marque une tâche comme terminée.',
      {'title': {'type': 'string', 'description': 'Mot(s) du titre de la tâche'}},
      ['title'],
    ),
    _tool(
      'add_note',
      'Crée une note dans le bloc-notes.',
      {
        'title': {'type': 'string', 'description': 'Titre court (optionnel)'},
        'content': {'type': 'string', 'description': 'Contenu de la note'},
      },
      ['content'],
    ),
    _tool('list_notes', 'Liste les dernières notes.'),
    _tool(
      'create_reminder',
      'Programme un rappel avec notification Android à une date et heure précises.',
      {
        'title': {'type': 'string', 'description': 'Texte du rappel, ex. « Fermer les portes »'},
        'datetime': {
          'type': 'string',
          'description': 'Date et heure locales au format AAAA-MM-JJTHH:MM '
              '(sans fuseau), ex. 2026-11-18T21:05. Doit être dans le futur.',
        },
      },
      ['title', 'datetime'],
    ),
    _tool(
      'add_event',
      'Ajoute un rendez-vous dans l’agenda (puce sur le calendrier + notification). '
          'À utiliser pour un rendez-vous (médecin, réunion, visite...), pas pour un simple rappel.',
      {
        'title': {'type': 'string', 'description': 'Nom du rendez-vous, ex. « Dentiste »'},
        'date': {'type': 'string', 'description': 'Date locale au format AAAA-MM-JJ'},
        'time': {'type': 'string', 'description': 'Heure locale au format HH:MM, ex. 14:30'},
        'location': {'type': 'string', 'description': 'Lieu ou adresse (optionnel)'},
      },
      ['title', 'date', 'time'],
    ),
    _tool('list_events', 'Liste les rendez-vous à venir de l’agenda.'),
    _tool('list_reminders', 'Liste les rappels à venir.'),
    _tool(
      'cancel_reminder',
      'Supprime un rappel à venir.',
      {'title': {'type': 'string', 'description': 'Mot(s) du texte du rappel'}},
      ['title'],
    ),
  ];

  String _s(Map<String, dynamic> a, String key) => (a[key] ?? '').toString().trim();

  Future<String> execute(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'add_task':
          final title = _s(args, 'title');
          if (title.isEmpty) return 'Erreur : titre manquant.';
          _tasks.addTask(title);
          return 'OK : tâche « $title » ajoutée.';

        case 'list_tasks':
          if (_tasks.tasks.isEmpty) return 'Aucune tâche.';
          return _tasks.tasks.map((t) => '${t.isDone ? '[fait]' : '[à faire]'} ${t.title}').join('\n');

        case 'complete_task':
          final q = _s(args, 'title').toLowerCase();
          if (q.isEmpty) return 'Erreur : titre manquant.';
          final matches = _tasks.tasks
              .where((t) => !t.isDone && t.title.toLowerCase().contains(q))
              .toList();
          if (matches.isEmpty) return 'Erreur : aucune tâche en attente ne correspond à « $q ».';
          _tasks.toggleTask(matches.first.id);
          return 'OK : tâche « ${matches.first.title} » terminée.';

        case 'add_note':
          final content = _s(args, 'content');
          if (content.isEmpty) return 'Erreur : contenu manquant.';
          final title = _s(args, 'title');
          final note = await _notes.addQuick(title.isEmpty ? content : '$title\n$content');
          return 'OK : note « ${note.title} » créée.';

        case 'list_notes':
          final list = _notes.notes.take(8).toList();
          if (list.isEmpty) return 'Aucune note.';
          return list.map((n) => '- ${n.title.trim().isEmpty ? 'Sans titre' : n.title}').join('\n');

        case 'create_reminder':
          final title = _s(args, 'title');
          final when = DateTime.tryParse(_s(args, 'datetime'))?.toLocal();
          if (title.isEmpty) return 'Erreur : texte du rappel manquant.';
          if (when == null) return 'Erreur : date invalide, utilise AAAA-MM-JJTHH:MM.';
          if (!when.isAfter(DateTime.now())) {
            return 'Erreur : cette date est déjà passée. Demande une date à venir à l’utilisateur.';
          }
          final exact = await _reminders.add(title, when);
          return 'OK : rappel « $title » programmé ${describeWhen(when)}.'
              '${exact ? '' : ' Attention : alarmes exactes non autorisées, la notification peut avoir un peu de retard.'}';

        case 'add_event':
          final title = _s(args, 'title');
          if (title.isEmpty) return 'Erreur : nom du rendez-vous manquant.';
          final parsed = DateTime.tryParse(_s(args, 'date'));
          if (parsed == null) return 'Erreur : date invalide, utilise AAAA-MM-JJ.';
          final m = RegExp(r'^(\d{1,2})[:hH](\d{2})$').firstMatch(_s(args, 'time'));
          if (m == null) return 'Erreur : heure invalide, utilise HH:MM.';
          final hour = int.parse(m.group(1)!);
          final minute = int.parse(m.group(2)!);
          if (hour > 23 || minute > 59) return 'Erreur : heure invalide.';
          final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          final event = AgendaEvent(
            // Minuit : AgendaProvider.eventsOn compare des dates sans heure.
            date: DateTime(parsed.year, parsed.month, parsed.day),
            title: title,
            time: time,
            location: _s(args, 'location'),
          );
          if (!event.dateTime.isAfter(DateTime.now())) {
            return 'Erreur : ce rendez-vous est déjà passé. Demande une date à venir à l’utilisateur.';
          }
          final reminded = await _agenda.save(event);
          return 'OK : rendez-vous « $title » ajouté à l’agenda le ${_s(args, 'date')} à $time.'
              '${reminded ? ' Notification programmée.' : ''}';

        case 'list_events':
          final next = _agenda.upcoming.take(8).toList();
          if (next.isEmpty) return 'Aucun rendez-vous à venir.';
          return next
              .map((e) =>
                  '- ${e.title} — ${e.date.toIso8601String().substring(0, 10)} ${e.time}'
                  '${e.location.isEmpty ? '' : ' (${e.location})'}')
              .join('\n');

        case 'list_reminders':
          final next = _reminders.upcoming.take(8).toList();
          if (next.isEmpty) return 'Aucun rappel à venir.';
          return next.map((r) => '- ${r.title} — ${describeWhen(r.scheduledAt)}').join('\n');

        case 'cancel_reminder':
          final q = _s(args, 'title').toLowerCase();
          if (q.isEmpty) return 'Erreur : texte manquant.';
          final matches =
              _reminders.upcoming.where((r) => r.title.toLowerCase().contains(q)).toList();
          if (matches.isEmpty) return 'Erreur : aucun rappel à venir ne correspond à « $q ».';
          await _reminders.delete(matches.first.id!);
          return 'OK : rappel « ${matches.first.title} » supprimé.';

        default:
          return 'Erreur : outil inconnu « $name ».';
      }
    } catch (e) {
      return 'Erreur : $e';
    }
  }
}
