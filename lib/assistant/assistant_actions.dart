import '../providers/notes_provider.dart';
import '../providers/personal_memory_provider.dart';
import '../providers/reminders_provider.dart';
import '../utils/french_date.dart';
import '../utils/reminder_parser.dart';
import '../providers/tasks_provider.dart';

class AssistantActions {
  AssistantActions(this._tasks, this._memory, this._notes, this._reminders);

  final TasksProvider _tasks;
  final PersonalMemoryProvider _memory;
  final NotesProvider _notes;
  final RemindersProvider _reminders;

  Future<String?> tryExecute(String message) async {
    final text = message.trim();
    final lower = text.toLowerCase();

    if (lower.contains('qu’est-ce que tu sais sur moi') ||
        lower.contains("qu'est-ce que tu sais sur moi") ||
        lower.contains('que sais-tu sur moi') ||
        lower.contains('qu’as-tu retenu') ||
        lower.contains("qu'as-tu retenu") ||
        lower.contains('montre ta mémoire') ||
        lower.contains('montre ta memoire') ||
        lower.contains('mes informations mémorisées') ||
        lower.contains('mes informations memorisees')) {
      return _memory.describeMemories();
    }

    if (lower == 'oublie tout' ||
        lower == 'oublie tout ce que tu sais sur moi' ||
        lower == 'efface toute ta mémoire' ||
        lower == 'efface toute ta memoire') {
      await _memory.forgetAll();
      return 'C’est fait. J’ai effacé toutes les informations de ma mémoire personnelle.';
    }

    for (final prefix in ['oublie ', 'oublies ', 'efface ', 'supprime de ta mémoire ', 'supprime de ta memoire ']) {
      if (lower.startsWith(prefix)) {
        final request = text.substring(prefix.length).trim();
        if (request.isEmpty) {
          return 'Quelle information souhaites-tu que j’oublie ?';
        }
        final removed = await _memory.forgetMatching(request);
        return removed
            ? 'C’est fait. J’ai supprimé cette information de ma mémoire.'
            : 'Je n’ai pas trouvé cette information dans ma mémoire.';
      }
    }

    const prefixes = [
      'ajoute une tâche ',
      'ajoute une tache ',
      'ajoute la tâche ',
      'ajoute la tache ',
      'ajoute tâche ',
      'ajoute tache ',
      
    ];
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        final title = text.substring(prefix.length).trim();
        if (title.isEmpty) return 'Que dois-je ajouter à ta liste ?';
        _tasks.addTask(title);
        return 'C’est noté. J’ai ajouté « $title » à ta liste de tâches.';
      }
    }

    // --- Rappels ---
    if (lower.contains('mes rappels')) {
      final next = _reminders.upcoming.take(5).toList();
      if (next.isEmpty) return 'Tu n’as aucun rappel à venir.';
      return 'Tes prochains rappels :\n${next.map((r) => '• ${r.title} — ${describeWhen(r.scheduledAt)}').join('\n')}';
    }

    final parsed = parseReminder(text);
    if (parsed != null) {
      if (!parsed.when.isAfter(DateTime.now())) {
        return 'Cette heure est déjà passée. Donne-moi une heure à venir, par exemple « dans 20 minutes » ou « demain à 9h ».';
      }
      try {
        final exact = await _reminders.add(parsed.title, parsed.when);
        final note = exact
            ? ''
            : '\n(Android n’a pas autorisé les alarmes exactes : la notification peut arriver avec un peu de retard.)';
        return '⏰ C’est programmé : « ${parsed.title} » ${describeWhen(parsed.when)}. Tu recevras une notification.$note';
      } catch (e) {
        return 'Je n’ai pas pu programmer ce rappel : $e';
      }
    }

    if (RegExp(r'\b(rappel|rappelle-moi)\b')
    .hasMatch(lower)) {

      return 'À quelle heure ? ex : « Rappel fermer les portes à 21h05 » ou « Rappel dans 20 minutes sortir le linge ».';
    }

    const notePrefixes = [
      'ajoute une note ',
      'ajoute la note ',
      'crée une note ',
      'cree une note ',
      'note : ',
      'note: ',
    ];
    for (final prefix in notePrefixes) {
      if (lower.startsWith(prefix)) {
        final content = text.substring(prefix.length).trim();
        if (content.isEmpty) return 'Que dois-je écrire dans la note ?';
        await _notes.addQuick(content);
        return 'C’est noté. J’ai créé une note dans ton bloc-notes.';
      }
    }

    if (lower.contains('mes notes')) {
      final notes = _notes.notes.take(5).toList();
      if (notes.isEmpty) return 'Ton bloc-notes est vide.';
      return 'Tes dernières notes :\n${notes.map((n) => '• ${n.title.trim().isEmpty ? 'Sans titre' : n.title}').join('\n')}';
    }

    if (lower.contains('mes tâches') || lower.contains('mes taches')) {
      final pending = _tasks.tasks.where((task) => !task.isDone).toList();
      if (pending.isEmpty) return 'Tu n’as aucune tâche en attente.';
      return 'Voici tes tâches en attente :\n${pending.map((task) => '• ${task.title}').join('\n')}';
    }

    return null;
  }
}
