import 'package:flutter/foundation.dart';

import '../database/notes_database.dart';
import '../models/reminder.dart';
import '../notifications/notification_service.dart';
import 'space_provider.dart';

class RemindersProvider extends ChangeNotifier {
  RemindersProvider(this._space, [NotesDatabase? database])
      : _db = database ?? NotesDatabase.instance {
    // Changer d'espace redessine les écrans qui affichent les rappels.
    _space.addListener(notifyListeners);
  }

  final SpaceProvider _space;
  final NotesDatabase _db;
  List<Reminder> _all = [];

  /// Rappels de l'espace actif uniquement.
  List<Reminder> get reminders =>
      List.unmodifiable(_all.where((r) => r.espace == _space.current).toList());
  List<Reminder> get upcoming => reminders.where((r) => !r.isPast).toList();
  List<Reminder> get past => reminders.where((r) => r.isPast).toList().reversed.toList();

  Future<void> load() async {
    try {
      _all = await _db.reminders();
    } catch (_) {
      _all = [];
    }
    notifyListeners();
  }

  /// Crée le rappel dans l'espace actif et programme la notification Android
  /// (titre préfixé [Perso] ou [Pro]). Renvoie true si l'heure est exacte.
  Future<bool> add(String title, DateTime when) async {
    final espace = _space.current;
    final id = await _db.insertReminder(
      Reminder(title: title, scheduledAt: when, espace: espace),
    );
    try {
      final exact = await NotificationService.instance
          .schedule(id: id, body: title, when: when, espace: espace);
      await load();
      return exact;
    } catch (e) {
      await _db.deleteReminder(id);
      await load();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await NotificationService.instance.cancel(id);
    } catch (_) {}
    await _db.deleteReminder(id);
    await load();
  }

  /// Supprime les rappels passés de l'espace actif seulement.
  Future<void> clearPast() async {
    for (final r in past) {
      if (r.id != null) await _db.deleteReminder(r.id!);
    }
    await load();
  }
}
