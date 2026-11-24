import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/agenda_event.dart';
import '../providers/agenda_provider.dart';
import '../theme/app_theme.dart';
import '../utils/french_date.dart';
import '../widgets/soft_card.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String get _dateLabel {
    final d = frenchDate(_selectedDay);
    return '${d[0].toUpperCase()}${d.substring(1)}';
  }

  Future<void> _edit([AgendaEvent? event]) async {
    final result = await showDialog<AgendaEvent>(
      context: context,
      builder: (_) => _EventDialog(day: _selectedDay, event: event),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final reminded = await context.read<AgendaProvider>().save(result);
    messenger.showSnackBar(SnackBar(
      content: Text(reminded
          ? 'Rendez-vous enregistré, notification programmée à ${result.time}.'
          : 'Rendez-vous enregistré.'),
    ));
  }

  /// Ouvre Google Maps (ou le navigateur) avec l'itinéraire vers le lieu.
  Future<void> _openMaps(String place) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': place,
    });
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir Google Maps.')));
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir Google Maps.')));
    }
  }

  Future<void> _delete(AgendaEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le rendez-vous ?'),
        content: Text('Veux-tu vraiment supprimer « ${event.title} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Supprimer', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<AgendaProvider>().delete(event);
  }

  @override
  Widget build(BuildContext context) {
    final agenda = context.watch<AgendaProvider>();
    final dayEvents = agenda.eventsOn(_selectedDay);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withOpacity(0.55);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _edit(),
        icon: const Icon(Icons.event_available),
        label: const Text('Rendez-vous'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(8),
            child: TableCalendar<AgendaEvent>(
              locale: 'fr_FR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              rowHeight: 42,
              availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                leftChevronIcon: Icon(Icons.chevron_left, color: scheme.primary),
                rightChevronIcon: Icon(Icons.chevron_right, color: scheme.primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(color: AppColors.coral.withOpacity(0.9), fontWeight: FontWeight.w600),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: AppColors.coral.withOpacity(0.9)),
                todayDecoration: BoxDecoration(
                  color: AppColors.indigo.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.indigo,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: agenda.eventsOn,
              onDaySelected: (selected, focused) => setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              }),
              onPageChanged: (focused) => _focusedDay = focused,
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: Text(
                _dateLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${dayEvents.length} rendez-vous',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 10),
          if (dayEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Aucun rendez-vous prévu', style: TextStyle(color: muted))),
            )
          else
            for (final event in dayEvents)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  onTap: () => _edit(event),
                  padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withOpacity(event.isPast ? 0.08 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.time,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: event.isPast ? muted : AppColors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: event.isPast ? muted : null,
                          ),
                        ),
                        if (event.location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.place_outlined, size: 15, color: muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: muted),
                              ),
                            ),
                          ]),
                        ],
                      ]),
                    ),
                    if (event.location.isNotEmpty)
                      IconButton(
                        tooltip: 'Itinéraire Google Maps',
                        icon: const Icon(Icons.directions, color: AppColors.indigo),
                        onPressed: () => _openMaps(event.location),
                      ),
                    IconButton(
                      tooltip: 'Supprimer',
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      onPressed: () => _delete(event),
                    ),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({required this.day, this.event});

  final DateTime day;
  final AgendaEvent? event;

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.event?.title ?? '');
  late final TextEditingController _locationController =
      TextEditingController(text: widget.event?.location ?? '');
  late TimeOfDay _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      final p = e.time.split(':');
      _time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } else {
      _time = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String get _timeString =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Saisis un nom de rendez-vous.');
      return;
    }
    Navigator.pop(
      context,
      AgendaEvent(
        id: widget.event?.id,
        date: widget.day,
        title: title,
        time: _timeString,
        location: _locationController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = frenchDate(widget.day);
    return AlertDialog(
      
      title: Text(widget.event == null ? 'Nouveau rendez-vous' : 'Modifier le rendez-vous'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${d[0].toUpperCase()}${d.substring(1)}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          autofocus: widget.event == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Nom du rendez-vous'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Lieu (facultatif) : adresse ou nom',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickTime,
          icon: const Icon(Icons.schedule, size: 18),
          label: Text(_timeString),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.event == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}
