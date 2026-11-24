import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import '../utils/french_date.dart';

/// Éditeur de note avec sauvegarde automatique dans SQLite.
class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.note});
  final Note? note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final NotesProvider _notes;
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final DateTime _created;
  late int _color;
  late bool _pinned;
  int? _id;
  bool _dirty = false;
  bool _deleted = false;
  Timer? _timer;
  Future<void> _queue = Future.value();

  @override
  void initState() {
    super.initState();
    _notes = context.read<NotesProvider>();
    final n = widget.note;
    _id = n?.id;
    _created = n?.createdAt ?? DateTime.now();
    _color = n?.color ?? 0;
    _pinned = n?.pinned ?? false;
    _title = TextEditingController(text: n?.title ?? '');
    _content = TextEditingController(text: n?.content ?? '');
  }

  void _changed() {
    _dirty = true;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), _flush);
  }

  /// Prend une photo des champs tout de suite, puis enregistre à la suite.
  void _flush() {
    _timer?.cancel();
    if (!_dirty || _deleted) return;
    _dirty = false;
    final title = _title.text.trim();
    final content = _content.text.trim();
    final color = _color;
    final pinned = _pinned;
    _queue = _queue.then((_) => _persist(title, content, color, pinned));
  }

  Future<void> _persist(String title, String content, int color, bool pinned) async {
    if (_deleted) return;
    if (title.isEmpty && content.isEmpty) {
      final id = _id;
      if (id != null) {
        await _notes.delete(id);
        _id = null;
      }
      return;
    }
    final saved = await _notes.save(Note(
      id: _id,
      title: title,
      content: content,
      color: color,
      pinned: pinned,
      createdAt: _created,
      updatedAt: DateTime.now(),
    ));
    _id = saved.id;
  }

  @override
  void dispose() {
    _flush();
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    _timer?.cancel();
    _dirty = false;
    _deleted = true;
    await _queue;
    final id = _id;
    if (id != null) await _notes.delete(id);
    if (mounted) Navigator.pop(context);
  }

  void _pickColor() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < AppColors.noteColorCount; i++)
                GestureDetector(
                  onTap: () {
                    setState(() => _color = i);
                    _changed();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.noteColor(ctx, i),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == i ? AppColors.indigo : Colors.black26,
                        width: _color == i ? 3 : 1,
                      ),
                    ),
                    child: _color == i ? const Icon(Icons.check, size: 20) : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _color == 0
        ? Theme.of(context).scaffoldBackgroundColor
        : AppColors.noteColor(context, _color);
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: _pinned ? 'Désépingler' : 'Épingler',
            icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () {
              setState(() => _pinned = !_pinned);
              _changed();
            },
          ),
          IconButton(
            tooltip: 'Couleur',
            icon: const Icon(Icons.palette_outlined),
            onPressed: _pickColor,
          ),
          if (_id != null)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              onChanged: (_) => _changed(),
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Titre',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _content,
                onChanged: (_) => _changed(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Écris ta note…',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            Text(
              _id == null ? 'Enregistrement automatique' : 'Modifiée ${shortDate(DateTime.now())} · enregistrement automatique',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
