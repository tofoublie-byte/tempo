import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/espace.dart';

/// Notifications Android locales (rappels programmés).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _askedExactAlarm = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'tempo_reminders',
      'Rappels',
      channelDescription: 'Rappels programmés dans Tempo',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    await _android?.requestNotificationsPermission();
    _ready = true;
  }

  /// Programme une notification (titre « [Perso] Tempo » ou « [Pro] Tempo »).
  /// Renvoie true si l'heure est exacte, false si Android n'a accordé que
  /// l'alarme « approximative ».
  Future<bool> schedule({
    required int id,
    required String body,
    required DateTime when,
    Espace espace = Espace.perso,
  }) async {
    await initialize();
    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      var canExact = await _android?.canScheduleExactNotifications() ?? false;
      if (!canExact && !_askedExactAlarm) {
        _askedExactAlarm = true;
        await _android?.requestExactAlarmsPermission();
        canExact = await _android?.canScheduleExactNotifications() ?? false;
      }
      if (canExact) mode = AndroidScheduleMode.exactAllowWhileIdle;
    } catch (_) {
      // On retombe sur le mode approximatif.
    }

    // On utilise un instant absolu (UTC) : pas besoin de connaître le fuseau.
    final instant = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.UTC,
      when.millisecondsSinceEpoch,
    );
    await _plugin.zonedSchedule(
      id,
      '[${espace.label}] Tempo',
      body,
      instant,
      _details,
      androidScheduleMode: mode,
    );
    return mode == AndroidScheduleMode.exactAllowWhileIdle;
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  /// Notification immédiate pour vérifier que tout fonctionne.
  Future<void> showTest() async {
    await initialize();
    await _plugin.show(0, 'Tempo', 'Les notifications fonctionnent ✅', _details);
  }
}
