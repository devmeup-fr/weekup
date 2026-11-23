import 'dart:convert';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/alarm_service.dart';

const String kIgnoreAlarmAction = 'ignore_alarm';
const String kNotificationIcon = 'ic_launcher_monochrome';

/// Textes des notifications « alarme imminente », résolus avec un
/// BuildContext avant d'être utilisés hors de l'interface.
class UpcomingTexts {
  /// Modèles avec `{time}` (et `{title}` pour [titleNamed]).
  final String title;
  final String titleNamed;
  final String body;
  final String ignore;
  final String channelName;

  const UpcomingTexts({
    required this.title,
    required this.titleNamed,
    required this.body,
    required this.ignore,
    required this.channelName,
  });
}

/// Une notification à prévoir : la sonnerie [pluginId] de [alarm] à [date].
class UpcomingEntry {
  final int pluginId;
  final DateTime date;
  final AlarmModel alarm;

  const UpcomingEntry(this.pluginId, this.date, this.alarm);
}

/// Action « Ignorer » touchée alors que l'app est fermée : Android/iOS
/// lancent un moteur Flutter sans interface qui exécute ce point d'entrée.
@pragma('vm:entry-point')
Future<void> onUpcomingNotificationBackground(NotificationResponse r) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await UpcomingAlarmNotifications.handleResponse(r);
}

/// Notifications « Alarme à 07:00 » envoyées un peu avant chaque sonnerie,
/// avec un bouton pour ignorer cette sonnerie.
class UpcomingAlarmNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Les ids de notification sont décalés pour ne jamais croiser ceux du
  /// plugin d'alarme.
  static const int idOffset = 100000000;
  static const String channelId = 'upcoming_alarm';
  static const String categoryId = 'upcoming_alarm';

  /// Appelé après un « Ignorer » traité avec l'app ouverte.
  static VoidCallback? onChanged;

  static Future<void> init(UpcomingTexts texts) async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Fuseau horaire introuvable, UTC utilisé : $e');
    }

    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings(kNotificationIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              categoryId,
              actions: [
                DarwinNotificationAction.plain(
                  kIgnoreAlarmAction,
                  texts.ignore,
                  options: {DarwinNotificationActionOption.destructive},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (r) async {
        await handleResponse(r);
        onChanged?.call();
      },
      onDidReceiveBackgroundNotificationResponse:
          onUpcomingNotificationBackground,
    );
    _initialized = true;
  }

  static String _payload(UpcomingEntry e) => jsonEncode({
        'pluginId': e.pluginId,
        'date': e.date.toIso8601String(),
      });

  /// Replanifie les notifications. [leadMinutes] = 0 les désactive.
  static Future<void> sync(
    List<UpcomingEntry> entries,
    UpcomingTexts texts,
    int leadMinutes,
  ) async {
    await init(texts);
    final now = DateTime.now();
    final lead = Duration(minutes: leadMinutes);

    final wanted = <int, UpcomingEntry>{
      if (leadMinutes > 0)
        for (final e in entries)
          if (!e.alarm.isSnooze) idOffset + e.pluginId: e,
    };

    // Notifications déjà affichées : on garde celles toujours valables (pour
    // ne pas faire réapparaître une notification balayée par l'utilisateur).
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final active = await android?.getActiveNotifications() ?? const [];
    final shown = <int>{};
    for (final n in active) {
      final id = n.id;
      if (id == null || id < idOffset) continue;
      final e = wanted[id];
      if (e == null || n.payload != _payload(e)) {
        await _plugin.cancel(id: id);
      } else {
        shown.add(id);
      }
    }

    // Notifications programmées : on repart de zéro.
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.id >= idOffset) await _plugin.cancel(id: p.id);
    }

    for (final entry in wanted.entries) {
      final e = entry.value;
      final notifyAt = e.date.subtract(lead);
      if (shown.contains(entry.key) || !notifyAt.isAfter(now)) continue;

      final time =
          '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}';
      final title = e.alarm.hasTitle
          ? texts.titleNamed
              .replaceAll('{time}', time)
              .replaceAll('{title}', e.alarm.title!)
          : texts.title.replaceAll('{time}', time);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          texts.channelName,
          icon: kNotificationIcon,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          category: AndroidNotificationCategory.reminder,
          // Disparaît d'elle-même à l'heure de la sonnerie
          timeoutAfter: lead.inMilliseconds,
          actions: [
            AndroidNotificationAction(kIgnoreAlarmAction, texts.ignore),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: categoryId,
          presentSound: false,
        ),
      );

      final when = tz.TZDateTime.from(notifyAt, tz.local);
      try {
        await _plugin.zonedSchedule(
          id: entry.key,
          title: title,
          body: texts.body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: _payload(e),
        );
      } catch (_) {
        // Alarmes exactes refusées : une notification approximative suffit
        await _plugin.zonedSchedule(
          id: entry.key,
          title: title,
          body: texts.body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: _payload(e),
        );
      }
    }
  }

  /// « Ignorer » : annule cette sonnerie sans ouvrir l'app.
  static Future<void> handleResponse(NotificationResponse r) async {
    if (r.actionId != kIgnoreAlarmAction || r.payload == null) return;
    final data = jsonDecode(r.payload!) as Map<String, dynamic>;
    final pluginId = data['pluginId'] as int;
    final date = DateTime.parse(data['date'] as String);

    await AlarmService().ignoreOccurrence(
      AlarmService.modelIdFromAlarmId(pluginId),
      date,
    );
    try {
      await AlarmStorage.init();
      await Alarm.stop(pluginId);
    } catch (e) {
      debugPrint('Arrêt de la sonnerie $pluginId impossible : $e');
    }
  }
}
