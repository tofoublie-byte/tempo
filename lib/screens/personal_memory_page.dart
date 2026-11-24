import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personal_memory_provider.dart';

class PersonalMemoryPage extends StatelessWidget {
  const PersonalMemoryPage({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Effacer toute la mémoire ?'),
        content: const Text(
          'Toutes les informations personnelles retenues par Tempo seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<PersonalMemoryProvider>().forgetAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final memory = context.watch<PersonalMemoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mémoire de Tempo'),
        actions: [
          if (memory.memories.isNotEmpty)
            IconButton(
              tooltip: 'Tout effacer',
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: memory.memories.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'La mémoire de Tempo est encore vide.\n\n'
                  'Quand tu lui communiqueras clairement une préférence, '
                  'une habitude ou un projet, il pourra le retenir automatiquement.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Informations retenues automatiquement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                for (final item in memory.memories)
                  Card(
                    child: ListTile(
                      title: Text(item.categoryLabel),
                      subtitle: Text(item.content),
                      trailing: IconButton(
                        tooltip: 'Oublier cette information',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await context
                              .read<PersonalMemoryProvider>()
                              .forgetMatching(item.content);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                 Text(
                  'Ces informations sont enregistrées localement sur ce téléphone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
    );
  }
}
