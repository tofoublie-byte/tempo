import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/agenda_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/reminders_provider.dart';
import '../models/espace.dart';
import '../providers/space_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/french_date.dart';
import '../utils/weather_codes.dart';
import '../widgets/note_card.dart';
import '../widgets/soft_card.dart';
import 'groq_settings_page.dart';
import 'note_editor_page.dart';
import 'personal_memory_page.dart';
import 'home_shell.dart';
import 'weather_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _addTask(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _NewTaskDialog(),
    );
    if (result != null && context.mounted) {
      context.read<TasksProvider>().addTask(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();
    final notes = context.watch<NotesProvider>();
    final reminders = context.watch<RemindersProvider>();
    final nextReminder = reminders.upcoming.isEmpty ? null : reminders.upcoming.first;
    final agendaUpcoming = context.watch<AgendaProvider>().upcoming;
    final nextEvent = agendaUpcoming.isEmpty ? null : agendaUpcoming.first;
    final weather = context.watch<WeatherProvider>();
    final space = context.watch<SpaceProvider>();
    final gradient = AppColors.heroGradient(DateTime.now().hour, espace: space.current);
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;

    final total = tasks.totalCount;
    final remaining = tasks.remainingCount;
    final String heroText;
    if (total == 0) {
      heroText = 'Ajoute ta première tâche pour lancer la journée.';
    } else if (remaining == 0) {
      heroText = 'Tout est fait, bravo ! 🎉';
    } else {
      heroText = '$remaining tâche${remaining > 1 ? 's' : ''} à faire sur $total';
    }

    final date = frenchDate(now);
    final dateLabel = '${date[0].toUpperCase()}${date.substring(1)}';
    final recentNotes = notes.notes.take(6).toList();

    return Scaffold(
      //floatingActionButton: FloatingActionButton.extended(
      //  heroTag: null,
      //  onPressed: () => _addTask(context),
      //  icon: const Icon(Icons.add_task),
      //  label: const Text('Tâche1'),
    //  ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            // ----- En-tête -----
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 12, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient.last.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mémoire de Tempo',
                      color: Colors.white,
                      icon: const Icon(Icons.psychology_outlined),
                      onPressed: () => _go(context, const PersonalMemoryPage()),
                    ),
                    IconButton(
                      tooltip: 'Réglages',
                      color: Colors.white,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _go(context, const GroqSettingsPage()),
                    ),
                  ]),
                  _SpaceSwitch(value: space.current, onChanged: space.select),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!weather.isLoading && weather.current == null) {
                          // Échec de chargement : un tap relance la recherche météo.
                          weather.refresh(force: true);
                        } else {
                          _go(context, const WeatherPage());
                        }
                      },
                      child: _HeroWeather(weather: weather),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(heroText, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: tasks.doneCount / total),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, __) => LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----- Raccourcis -----
          //  Row(children: [
          //    Expanded(
          //      child: _QuickAction(
          //        icon: Icons.chat_bubble_outline,
          //        label: 'Discuter',
          //        color: AppColors.indigo,
          //        onTap: () => HomeShell.goTo(context, 1),
         //       ),
          //    ),
         //     const SizedBox(width: 10),
         //     Expanded(
         //       child: _QuickAction(
        //          icon: Icons.edit_note,
        //          label: 'Nouvelle note',
        //          color: AppColors.amber,
        //          onTap: () => _go(context, const NoteEditorPage()),
        //        ),
       //       ),
        //      const SizedBox(width: 10),
        //      Expanded(
        //        child: _QuickAction(
         //         icon: Icons.psychology_outlined,
         //         label: 'Mémoire',
        //          color: AppColors.teal,
         //         onTap: () => _go(context, const PersonalMemoryPage()),
        //        ),
       //       ),
       //       const SizedBox(width: 10),
       //       Expanded(
       //         child: _QuickAction(
       //           icon: Icons.alarm,
      //            label: 'Rappels',
      //            color: AppColors.coral,
      //            onTap: () => HomeShell.goTo(context, 3),
      //          ),
       //       ),
      //      ]),
            if (nextEvent != null) ...[
              const SizedBox(height: 16),
              SoftCard(
                onTap: () => HomeShell.goTo(context, 4),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: space.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event, color: space.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Prochain rendez-vous',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        nextEvent.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(describeWhen(nextEvent.dateTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.6),
                          )),
                    ]),
                  ),
                  const Icon(Icons.chevron_right),
                ]),
              ),
            ],
            if (nextReminder != null) ...[
              const SizedBox(height: 16),
              SoftCard(
                onTap: () => HomeShell.goTo(context, 3),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alarm, color: AppColors.coral),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Prochain rappel',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        nextReminder.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(describeWhen(nextReminder.scheduledAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.6),
                          )),
                    ]),
                  ),
                  const Icon(Icons.chevron_right),
                ]),
              ),
            ],
            const SizedBox(height: 24),

            // ----- Tâches -----
            Row(children: [
              Text('Mes tâches', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (tasks.doneCount > 0)
                TextButton(
                  onPressed: tasks.clearCompleted,
                  child: const Text('Effacer les terminées'),
                ),
            ]),
            const SizedBox(height: 8),
          //  if (tasks.tasks.isEmpty)
              SoftCard(
                onTap: () => _addTask(context),
                child: const Row(children: [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 12),
                  Expanded(child: Text('Aucune tâche. Appuie ici pour en ajouter une.')),
                ]),
              ),
            for (final task in tasks.tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey('task_${task.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    final index = tasks.tasks.indexWhere((t) => t.id == task.id);
                    tasks.deleteTask(task.id);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: const Text('Tâche supprimée'),
                        action: SnackBarAction(
                          label: 'Annuler',
                          onPressed: () => tasks.restoreTask(task, index < 0 ? 0 : index),
                        ),
                      ));
                  },
                  child: SoftCard(
                    onTap: () => tasks.toggleTask(task.id),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isDone ? AppColors.teal : Colors.transparent,
                          border: Border.all(
                            color: task.isDone ? AppColors.teal : scheme.outline,
                            width: 2,
                          ),
                        ),
                        child: task.isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? scheme.onSurface.withOpacity(0.45) : null,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // ----- Notes récentes -----
          //  Row(children: [
          ///    Text('Notes récentes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          //    const Spacer(),
          //    TextButton(
          //      onPressed: () => HomeShell.goTo(context, 2),
           //     child: const Text('Tout voir'),
          //    ),
          //  ]),
         //   const SizedBox(height: 8),
          //  if (recentNotes.isEmpty)
          //    SoftCard(
          //      onTap: () => _go(context, const NoteEditorPage()),
          //      child: const Row(children: [
           //       Icon(Icons.edit_note),
          //        SizedBox(width: 12),
           //       Expanded(child: Text('Aucune note. Appuie ici pour écrire la première.')),
           //     ]),
           //   )
         //   else
         //     SizedBox(
          //      height: 130,
          //      child: ListView.separated(
           //       scrollDirection: Axis.horizontal,
           //       itemCount: recentNotes.length,
           //       separatorBuilder: (_, __) => const SizedBox(width: 12),
           //       itemBuilder: (context, i) => SizedBox(
            //        width: 160,
            //        child: NoteCard(
            //          note: recentNotes[i],
             //         compact: true,
            //        // onTap: () => _go(context, NoteEditorPage(note: recentNotes[i])),
             //       ),
             //     ),
            //    ),
           //   ),
          ],
        ),
      ),
    );
  }
}

/// Bloc météo affiché dans l'en-tête à la place de la salutation.
class _HeroWeather extends StatelessWidget {
  const _HeroWeather({required this.weather});

  final WeatherProvider weather;

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(children: [
        if (weather.isLoading && current == null)
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        else if (current == null)
          const Icon(Icons.cloud_off_outlined, color: Colors.white, size: 36)
        else
          Icon(
            weatherIcon(current.weatherCode, isDay: current.isDay),
            color: Colors.white,
            size: 42,
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current == null
                    ? (weather.isLoading
                        ? 'Chargement de la météo…'
                        : 'Météo indisponible')
                    : '${current.temperature.round()}° · ${weatherLabel(current.weatherCode)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                current == null
                    ? 'Toucher pour réessayer'
                    : 'Météo à ${weather.cityName} — voir les prévisions',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.white70),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

/// Dialogue qui possède son propre champ de saisie : il le libère lui-même
/// à la fin de l'animation de fermeture (évite l'erreur `_dependents.isEmpty`).
class _NewTaskDialog extends StatefulWidget {
  const _NewTaskDialog();

  @override
  State<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<_NewTaskDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle tâche'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Ex. : Acheter du pain'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

/// Sélecteur Perso / Pro affiché dans l'en-tête de l'accueil.
class _SpaceSwitch extends StatelessWidget {
  const _SpaceSwitch({required this.value, required this.onChanged});

  final Espace value;
  final ValueChanged<Espace> onChanged;

  static IconData _icon(Espace e) =>
      e == Espace.pro ? Icons.work_outline : Icons.person_outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in Espace.values)
            GestureDetector(
              onTap: () => onChanged(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: e == value ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _icon(e),
                    size: 18,
                    color: e == value ? AppColors.accentFor(e) : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: e == value ? AppColors.accentFor(e) : Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
