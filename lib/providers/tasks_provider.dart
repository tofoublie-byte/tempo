import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_task.dart';
import 'space_provider.dart';

class TasksProvider extends ChangeNotifier {
  TasksProvider(this._preferences, this._space) {
    // Changer d'espace redessine les écrans qui affichent les tâches.
    _space.addListener(notifyListeners);
    final saved = _preferences.getString('tempo_tasks');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _tasks = decoded
            .map((item) => DailyTask.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        return;
      } catch (_) {
        // Si les données sont illisibles, on repart sur les tâches de départ.
      }
    }
    _tasks = [
      const DailyTask(id: 1, title: 'Préparer la journée'),
      const DailyTask(id: 2, title: 'Vérifier les rendez-vous'),
    ];
    _save();
  }

  final SharedPreferences _preferences;
  final SpaceProvider _space;
  late List<DailyTask> _tasks;

  /// Tâches de l'espace actif.
  List<DailyTask> get _visible => _tasks.where((t) => t.espace == _space.current).toList();

  List<DailyTask> get tasks => List.unmodifiable(_visible);
  int get remainingCount => _visible.where((t) => !t.isDone).length;
  int get totalCount => _visible.length;
  int get doneCount => _visible.where((t) => t.isDone).length;

  void _save() {
    _preferences.setString('tempo_tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  void addTask(String title) {
    final clean = title.trim();
    if (clean.isEmpty) return;
    // Les identifiants restent uniques sur l'ensemble des deux espaces.
    final id = _tasks.isEmpty ? 1 : _tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    _tasks.add(DailyTask(id: id, title: clean, espace: _space.current));
    _save();
    notifyListeners();
  }

  /// Utilisé pour « Annuler » après une suppression.
  /// [index] est la position dans la liste affichée (espace actif).
  void restoreTask(DailyTask task, int index) {
    if (_tasks.any((t) => t.id == task.id)) return;
    final visible = _visible;
    final at = (index >= 0 && index < visible.length)
        ? _tasks.indexOf(visible[index])
        : _tasks.length;
    _tasks.insert(at < 0 ? _tasks.length : at, task);
    _save();
    notifyListeners();
  }

  void toggleTask(int id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    _tasks[i] = _tasks[i].copyWith(isDone: !_tasks[i].isDone);
    _save();
    notifyListeners();
  }

  void deleteTask(int id) {
    _tasks.removeWhere((t) => t.id == id);
    _save();
    notifyListeners();
  }

  /// Supprime les tâches terminées de l'espace actif seulement.
  void clearCompleted() {
    _tasks.removeWhere((t) => t.isDone && t.espace == _space.current);
    _save();
    notifyListeners();
  }
}
