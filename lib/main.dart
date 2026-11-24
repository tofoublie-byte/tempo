import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'assistant/assistant_provider.dart';
import 'llm/groq_llm_provider.dart';
import 'llm/groq_settings.dart';
import 'providers/agenda_provider.dart';
import 'providers/notes_provider.dart';
import 'notifications/notification_service.dart';
import 'providers/personal_memory_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/space_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/weather_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  final preferences = await SharedPreferences.getInstance();
  final spaceProvider = SpaceProvider(preferences);
  final tasksProvider = TasksProvider(preferences, spaceProvider);
  final memoryProvider = PersonalMemoryProvider(preferences, spaceProvider);
  final notesProvider = NotesProvider(spaceProvider);
  await notesProvider.load();
  final remindersProvider = RemindersProvider(spaceProvider);
  await remindersProvider.load();
  final agendaProvider = AgendaProvider(spaceProvider);
  await agendaProvider.load();
  final weatherProvider = WeatherProvider(preferences);
  await weatherProvider.load();
  try {
    await NotificationService.instance.initialize();
  } catch (_) {
    // L'app reste utilisable même si les notifications échouent.
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<SpaceProvider>.value(value: spaceProvider),
      ChangeNotifierProvider<TasksProvider>.value(value: tasksProvider),
      ChangeNotifierProvider<PersonalMemoryProvider>.value(value: memoryProvider),
      ChangeNotifierProvider<NotesProvider>.value(value: notesProvider),
      ChangeNotifierProvider<RemindersProvider>.value(value: remindersProvider),
      ChangeNotifierProvider<AgendaProvider>.value(value: agendaProvider),
      ChangeNotifierProvider<WeatherProvider>.value(value: weatherProvider),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(preferences),
      ),
      ChangeNotifierProvider<AssistantProvider>(
        create: (_) => AssistantProvider(
          tasksProvider: tasksProvider,
          memoryProvider: memoryProvider,
          notesProvider: notesProvider,
          remindersProvider: remindersProvider,
          agendaProvider: agendaProvider,
          spaceProvider: spaceProvider,
          llmProvider: GroqLlmProvider(GroqSettings()),
          preferences: preferences,
        ),
      ),
    ],
    child: const TempoApp(),
  ));
}
