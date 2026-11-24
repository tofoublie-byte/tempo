import 'package:flutter/material.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/french_date.dart';
import 'soft_card.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.onTap, this.compact = false});

  final Note note;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.65);
    return SoftCard(
      color: AppColors.noteColor(context, note.color),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                note.title.trim().isEmpty ? 'Sans titre' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            if (note.pinned) Icon(Icons.push_pin, size: 15, color: muted),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              note.content,
              maxLines: compact ? 3 : 7,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, height: 1.3, color: muted),
            ),
          ),
          Text(shortDate(note.updatedAt), style: TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }
}
