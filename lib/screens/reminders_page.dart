import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../notifications/notification_service.dart';
import '../providers/reminders_provider.dart';
import '../theme/app_theme.dart';
import '../utils/french_date.dart';
import '../widgets/soft_card.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  Future<void> _add(BuildContext context) async {
    final result = await showDialog<_NewReminder>(
      context: context,
      builder: (_) => const _NewReminderDialog(),
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final exact = await context.read<RemindersProvider>().add(result.title, result.when);
      messenger.showSnackBar(SnackBar(
        content: Text(exact
            ? 'Rappel programmé ${describeWhen(result.when)}.'
            : 'Rappel programmé ${describeWhen(result.when)} (heure approximative : autorise les alarmes exactes pour Tempo).'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Impossible de programmer le rappel : $e')));
    }
  }

  Future<void> _test(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationService.instance.showTest();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Échec de la notification : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RemindersProvider>();
    final upcoming = provider.upcoming;
    final past = provider.past;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rappels'),
        actions: [
          IconButton(
            tooltip: 'Tester une notification',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => _test(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Ajouter manuellement'),
      ),
      body: provider.reminders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.alarm, size: 64, color: AppColors.coral.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text('Aucun rappel', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Appuie sur « Rappel », ou écris dans le chat :\n« Rappel fermer les portes à 21h05 ».',
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (upcoming.isNotEmpty) const _Header('À venir'),
                for (final r in upcoming) _ReminderTile(reminder: r),
                if (past.isNotEmpty) ...[
                  Row(children: [
                    const Expanded(child: _Header('Passés')),
                    TextButton(onPressed: provider.clearPast, child: const Text('Effacer')),
                  ]),
                  for (final r in past) _ReminderTile(reminder: r),
                ],
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final past = reminder.isPast;
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('reminder_${reminder.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => context.read<RemindersProvider>().delete(reminder.id!),
        child: SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (past ? Colors.grey : AppColors.coral).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(past ? Icons.check : Icons.alarm, color: past ? muted : AppColors.coral),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: past ? TextDecoration.lineThrough : null,
                    color: past ? muted : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(describeWhen(reminder.scheduledAt), style: TextStyle(fontSize: 13, color: muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NewReminder {
  const _NewReminder(this.title, this.when);
  final String title;
  final DateTime when;
}

class _NewReminderDialog extends StatefulWidget {
  const _NewReminderDialog();

  @override
  State<_NewReminderDialog> createState() => _NewReminderDialogState();
}

class _NewReminderDialogState extends State<_NewReminderDialog> {
  final _controller = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final soon = DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(soon.year, soon.month, soon.day);
    _time = TimeOfDay(hour: soon.hour, minute: soon.minute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime get _when => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day)) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Écris ce dont je dois te rappeler.');
      return;
    }
    if (!_when.isAfter(DateTime.now())) {
      setState(() => _error = 'Choisis une heure à venir.');
      return;
    }
    Navigator.pop(context, _NewReminder(title, _when));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau rappel'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex. : Fermer les portes'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(describeWhen(DateTime(_date.year, _date.month, _date.day, 12)).split(' à ').first),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(timeLabel(_when)),
          ),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: const Text('Programmer')),
      ],
    );
  }
}
