import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:weekup/models/alarm_log_model.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/alarm_log_service.dart';
import 'package:weekup/services/alarm_service.dart';

const String kIgnoreAlarmAction = 'ignore_alarm';
const String kStopRingAction = 'ring_stop';
const String kSnoozeRingAction = 'ring_snooze';
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

  /// Notification de sonnerie (relayée aux montres) : `{time}` dans ringBody.
  final String ringBody;
  final String ringStop;
  final String ringSnooze;
  final String ringChannel;

  const UpcomingTexts({
    required this.title,
    required this.titleNamed,
    required this.body,
    required this.ignore,
    required this.channelName,
    required this.ringBody,
    required this.ringStop,
    required this.ringSnooze,
    required this.ringChannel,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'titleNamed': titleNamed,
        'body': body,
        'ignore': ignore,
        'channelName': channelName,
        'ringBody': ringBody,
        'ringStop': ringStop,
        'ringSnooze': ringSnooze,
        'ringChannel': ringChannel,
      };

  factory UpcomingTexts.fromMap(Map<String, dynamic> m) => UpcomingTexts(
        title: m['title'] as String,
        titleNamed: m['titleNamed'] as String,
        body: m['body'] as String,
        ignore: m['ignore'] as String,
        channelName: m['channelName'] as String,
        ringBody: m['ringBody'] as String? ?? '{time}',
        ringStop: m['ringStop'] as String? ?? 'Stop',
        ringSnooze: m['ringSnooze'] as String? ?? 'Snooze',
        ringChannel: m['ringChannel'] as String? ?? 'Alarm',
      );
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

  static const int ringIdOffset = 200000000;
  static const String ringChannelId = 'ringing_alarm';
  static const String ringCategoryId = 'ringing_alarm';

  /// « pluginId » de la sonnerie déjà traitée par un bouton de notification,
  /// pour que l'écran de sonnerie ne l'arrête pas une seconde fois.
  static const String _handledKey = 'ring_handled_by_notification';

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
            DarwinNotificationCategory(
              ringCategoryId,
              actions: [
                DarwinNotificationAction.plain(kStopRingAction, texts.ringStop),
                DarwinNotificationAction.plain(
                    kSnoozeRingAction, texts.ringSnooze),
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

  // ---------------------------------------------------
  // Notification de sonnerie (montres connectées)
  // ---------------------------------------------------

  /// Notification classique doublant celle du plugin d'alarme : celle du
  /// plugin est « en cours » et souvent pas relayée aux montres. Celle-ci
  /// l'est, fait vibrer la montre et porte Arrêter / Reporter.
  static Future<void> showRinging(
    AlarmSettings ringing,
    UpcomingTexts texts, {
    required bool canSnooze,
    required Duration timeout,
  }) async {
    await init(texts);
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _plugin.show(
      id: ringIdOffset + ringing.id,
      title: ringing.notificationSettings.title,
      body: texts.ringBody.replaceAll('{time}', time),
      payload: jsonEncode({'pluginId': ringing.id}),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ringChannelId,
          texts.ringChannel,
          icon: kNotificationIcon,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          // Le son vient déjà du plugin ; la montre, elle, vibre.
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
          autoCancel: false,
          timeoutAfter: timeout.inMilliseconds,
          actions: [
            AndroidNotificationAction(kStopRingAction, texts.ringStop),
            if (canSnooze)
              AndroidNotificationAction(kSnoozeRingAction, texts.ringSnooze),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: ringCategoryId,
          presentSound: false,
        ),
      ),
    );
  }

  static Future<void> cancelRinging(int pluginId) async {
    if (!_initialized) return;
    await _plugin.cancel(id: ringIdOffset + pluginId);
  }

  /// La sonnerie [pluginId] a-t-elle été traitée par un bouton de
  /// notification ? (consomme l'information)
  static Future<bool> consumeHandled(int pluginId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (prefs.getInt(_handledKey) != pluginId) return false;
    await prefs.remove(_handledKey);
    return true;
  }

  static Future<void> handleResponse(NotificationResponse r) async {
    if (r.payload == null) return;
    final data = jsonDecode(r.payload!) as Map<String, dynamic>;
    final pluginId = data['pluginId'] as int;

    switch (r.actionId) {
      case kIgnoreAlarmAction:
        await _ignore(pluginId, DateTime.parse(data['date'] as String));
      case kStopRingAction:
        await _handleRing(pluginId, snooze: false);
      case kSnoozeRingAction:
        await _handleRing(pluginId, snooze: true);
    }
  }

  /// « Arrêter » / « Reporter » touché sur la notification (ou la montre).
  /// Tourne dans le moteur d'arrière-plan, sans BuildContext.
  static Future<void> _handleRing(int pluginId, {required bool snooze}) async {
    final service = AlarmService();
    final texts = await AlarmNotificationTexts.cached();
    await AlarmStorage.init();
    final ringing = await Alarm.getAlarm(pluginId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_handledKey, pluginId);
    await Alarm.stop(pluginId);
    // Android retire déjà la notification touchée ; ceci couvre iOS.
    try {
      await _plugin.cancel(id: ringIdOffset + pluginId);
    } catch (_) {}
    if (ringing == null || texts == null) return;

    AlarmModel? shadow;
    if (snooze) shadow = await service.snoozeWith(texts, ringing);
    if (shadow != null) {
      await service.saveAlarmLog(
        ringing,
        action: AlarmLogAction.snooze,
        scheduledFor: shadow.getNextOccurrence(),
      );
    } else {
      await service.saveAlarmLog(ringing, action: AlarmLogAction.stop);
      await service.clearSnoozesWith(texts);
    }
  }

  /// « Ignorer » : annule cette sonnerie sans ouvrir l'app.
  static Future<void> _ignore(int pluginId, DateTime date) async {
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
