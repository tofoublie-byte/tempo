import 'package:flutter/foundation.dart';

import '../database/notes_database.dart';
import '../models/agenda_event.dart';
import '../notifications/notification_service.dart';
import 'space_provider.dart';

class AgendaProvider extends ChangeNotifier {
  AgendaProvider(this._space, [NotesDatabase? database])
      : _db = database ?? NotesDatabase.instance {
    // Changer d'espace redessine les écrans qui affichent l'agenda.
    _space.addListener(notifyListeners);
  }

  final SpaceProvider _space;
  final NotesDatabase _db;
  List<AgendaEvent> _all = [];

  /// Les notifications des rendez-vous utilisent des identifiants à part
  /// pour ne jamais entrer en collision avec ceux des rappels.
  static int _notificationId(int eventId) => 1000000 + eventId;

  /// Rendez-vous de l'espace actif uniquement.
  List<AgendaEvent> get events =>
      List.unmodifiable(_all.where((e) => e.espace == _space.current).toList());

  /// Rendez-vous à venir, du plus proche au plus lointain.
  List<AgendaEvent> get upcoming => events.where((e) => !e.isPast).toList();

  List<AgendaEvent> eventsOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return events.where((e) => e.date == d).toList();
  }

  /// Relit la base. Ne notifie que si la liste a réellement changé, pour ne
  /// pas redessiner l'écran pour rien.
  Future<void> load() async {
    final List<AgendaEvent> loaded;
    try {
      loaded = await _db.agendaEvents();
    } catch (_) {
      return; // erreur ponctuelle : on garde l'affichage actuel
    }
    if (_sameAsCurrent(loaded)) return;
    _all = loaded;
    notifyListeners();
  }

  bool _sameAsCurrent(List<AgendaEvent> other) {
    if (other.length != _all.length) return false;
    for (var i = 0; i < other.length; i++) {
      final a = _all[i];
      final b = other[i];
      if (a.id != b.id ||
          a.date != b.date ||
          a.time != b.time ||
          a.title != b.title ||
          a.location != b.location ||
          a.espace != b.espace) {
        return false;
      }
    }
    return true;
  }

  /// Crée ou modifie un rendez-vous et (re)programme sa notification.
  /// Un nouveau rendez-vous va dans l'espace actif ; un rendez-vous existant
  /// garde le sien. Renvoie true si une notification a pu être programmée.
  Future<bool> save(AgendaEvent input) async {
    var espace = _space.current;
    if (input.id != null) {
      for (final e in _all) {
        if (e.id == input.id) {
          espace = e.espace;
          break;
        }
      }
    }
    final event = input.withEspace(espace);

    int id;
    if (event.id == null) {
      id = await _db.insertAgendaEvent(event);
    } else {
      id = event.id!;
      await _db.updateAgendaEvent(event);
      try {
        await NotificationService.instance.cancel(_notificationId(id));
      } catch (_) {}
    }

    var reminded = false;
    final when = event.dateTime;
    if (when.isAfter(DateTime.now())) {
      try {
        await NotificationService.instance.schedule(
          id: _notificationId(id),
          body: event.location.isEmpty
              ? 'Rendez-vous : ${event.title}'
              : 'Rendez-vous : ${event.title} — ${event.location}',
          when: when,
          espace: event.espace,
        );
        reminded = true;
      } catch (_) {
        // Le rendez-vous reste enregistré même si la notification échoue.
      }
    }
    await load();
    return reminded;
  }

  Future<void> delete(AgendaEvent event) async {
    final id = event.id;
    if (id == null) return;
    try {
      await NotificationService.instance.cancel(_notificationId(id));
    } catch (_) {}
    await _db.deleteAgendaEvent(id);
    await load();
  }
}
