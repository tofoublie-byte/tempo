import 'package:sqflite/sqflite.dart';

import '../models/agenda_event.dart';
import '../models/note.dart';
import '../models/reminder.dart';

/// Base SQLite locale (fichier tempo.db) : bloc-notes, rappels et agenda.
class NotesDatabase {
  NotesDatabase._();
  static final NotesDatabase instance = NotesDatabase._();

  Future<Database>? _opening;

  Future<Database> get _db => _opening ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/tempo.db',
      version: 5,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createReminders(db);
        if (oldVersion < 3) {
          await _createAgenda(db);
        } else if (oldVersion < 4) {
          await db.execute("ALTER TABLE agenda_events ADD COLUMN location TEXT NOT NULL DEFAULT ''");
        }
        // v5 : espaces Perso / Pro. Les données existantes passent en « perso ».
        if (oldVersion < 5) await _addEspace(db);
      },
      onCreate: (db, version) async {
        await _createReminders(db);
        await _createAgenda(db);
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL DEFAULT '',
            content TEXT NOT NULL DEFAULT '',
            color INTEGER NOT NULL DEFAULT 0,
            pinned INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await _addEspace(db);
      },
    );
  }

  /// Ajoute la colonne `espace` (défaut « perso ») aux 3 tables, si elle manque.
  Future<void> _addEspace(Database db) async {
    for (final table in const ['notes', 'reminders', 'agenda_events']) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      if (columns.any((c) => c['name'] == 'espace')) continue;
      await db.execute("ALTER TABLE $table ADD COLUMN espace TEXT NOT NULL DEFAULT 'perso'");
    }
  }

  Future<void> _createReminders(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        scheduled_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createAgenda(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agenda_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        title TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_agenda_date ON agenda_events(date)');
  }

  Future<List<AgendaEvent>> agendaEvents() async {
    final db = await _db;
    final rows = await db.query('agenda_events', orderBy: 'date ASC, time ASC');
    return rows.map(AgendaEvent.fromMap).toList();
  }

  Future<int> insertAgendaEvent(AgendaEvent e) async {
    final db = await _db;
    return db.insert('agenda_events', e.toMap()..remove('id'));
  }

  Future<void> updateAgendaEvent(AgendaEvent e) async {
    final db = await _db;
    await db.update('agenda_events', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteAgendaEvent(int id) async {
    final db = await _db;
    await db.delete('agenda_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Reminder>> reminders() async {
    final db = await _db;
    final rows = await db.query('reminders', orderBy: 'scheduled_at ASC');
    return rows.map(Reminder.fromMap).toList();
  }

  Future<int> insertReminder(Reminder r) async {
    final db = await _db;
    return db.insert('reminders', r.toMap()..remove('id'));
  }

  Future<void> deleteReminder(int id) async {
    final db = await _db;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> all() async {
    final db = await _db;
    final rows = await db.query('notes', orderBy: 'pinned DESC, updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<int> insert(Note note) async {
    final db = await _db;
    final map = note.toMap()..remove('id');
    return db.insert('notes', map);
  }

  Future<void> update(Note note) async {
    final db = await _db;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
