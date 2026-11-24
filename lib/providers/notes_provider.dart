import 'package:flutter/foundation.dart';

import '../database/notes_database.dart';
import '../models/note.dart';
import 'space_provider.dart';

class NotesProvider extends ChangeNotifier {
  NotesProvider(this._space, [NotesDatabase? database])
      : _db = database ?? NotesDatabase.instance {
    // Changer d'espace redessine les écrans qui affichent les notes.
    _space.addListener(notifyListeners);
  }

  final SpaceProvider _space;
  final NotesDatabase _db;
  List<Note> _all = [];
  String? _error;

  /// Notes de l'espace actif uniquement.
  List<Note> get notes =>
      List.unmodifiable(_all.where((n) => n.espace == _space.current).toList());
  String? get error => _error;

  Future<void> load() async {
    try {
      _all = await _db.all();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  List<Note> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return notes;
    return notes
        .where((n) => n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q))
        .toList();
  }

  /// Crée ou met à jour une note et renvoie la version enregistrée.
  /// Une nouvelle note va dans l'espace actif ; une note existante garde le sien.
  Future<Note> save(Note note) async {
    final now = DateTime.now();
    var espace = _space.current;
    if (note.id != null) {
      for (final n in _all) {
        if (n.id == note.id) {
          espace = n.espace;
          break;
        }
      }
    }
    var saved = note.copyWith(updatedAt: now, espace: espace);
    if (note.id == null) {
      final id = await _db.insert(saved);
      saved = saved.copyWith(id: id);
    } else {
      await _db.update(saved);
    }
    await load();
    return saved;
  }

  Future<void> delete(int id) async {
    await _db.delete(id);
    await load();
  }

  Future<void> togglePin(Note note) async {
    await save(note.copyWith(pinned: !note.pinned));
  }

  /// Utilisé par l'assistant : crée une note à partir d'une phrase.
  Future<Note> addQuick(String text) {
    final clean = text.trim();
    final now = DateTime.now();
    final firstLine = clean.split('\n').first;
    final title = firstLine.length > 40 ? '${firstLine.substring(0, 40)}…' : firstLine;
    return save(Note(title: title, content: clean, createdAt: now, updatedAt: now));
  }
}
