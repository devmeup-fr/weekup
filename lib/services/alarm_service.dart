import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekup/core/enums/storage_keys_enum.dart';
import 'package:weekup/core/utils/localization_util.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/next_alarm_widget_service.dart';
import 'package:weekup/services/settings_service.dart';
import 'package:weekup/services/upcoming_notification_service.dart';
import 'package:weekup/theme/colors.dart';
import 'package:weekup/utils/alarm_format.dart';
import 'package:weekup/utils/audio_utils.dart';

/// Textes de notification, résolus avant tout `await` pour ne pas
/// utiliser le BuildContext après un gap asynchrone.
class AlarmNotificationTexts {
  final String defaultTitle;
  final String body;
  final String stopButton;
  final UpcomingTexts upcoming;
  final NextAlarmWidgetTexts widget;

  const AlarmNotificationTexts({
    required this.defaultTitle,
    required this.body,
    required this.stopButton,
    required this.upcoming,
    required this.widget,
  });

  factory AlarmNotificationTexts.of(BuildContext context) {
    return AlarmNotificationTexts(
      defaultTitle: context.translate('alarm_notification_title'),
      body: context.translate('alarm_notification_body'),
      stopButton: context.translate('stop_alarm_button'),
      upcoming: UpcomingTexts(
        title: context.translate('upcoming.title'),
        titleNamed: context.translate('upcoming.title_named'),
        body: context.translate('upcoming.body'),
        ignore: context.translate('upcoming.ignore'),
        channelName: context.translate('upcoming.channel'),
        ringBody: context.translate('ring_notif.body'),
        ringStop: context.translate('alarmStop'),
        ringSnooze: context.translate('alarmSnooze'),
        ringChannel: context.translate('ring_notif.channel'),
      ),
      widget: NextAlarmWidgetTexts(
        header: context.translate('nextDateTitle'),
        empty: context.translate('noAlarmEnabled'),
        today: context.translate('day.today'),
        tomorrow: context.translate('day.tomorrow'),
        snooze: context.translate('logs_isSnooze'),
        locale: Localizations.localeOf(context).languageCode,
      ),
    );
  }

  static const String _cacheKey = 'cached_notification_texts';

  Map<String, dynamic> toMap() => {
        'defaultTitle': defaultTitle,
        'body': body,
        'stopButton': stopButton,
        'upcoming': upcoming.toMap(),
        'widget': widget.toMap(),
      };

  factory AlarmNotificationTexts.fromMap(Map<String, dynamic> m) =>
      AlarmNotificationTexts(
        defaultTitle: m['defaultTitle'] as String,
        body: m['body'] as String,
        stopButton: m['stopButton'] as String,
        upcoming: UpcomingTexts.fromMap(m['upcoming'] as Map<String, dynamic>),
        widget:
            NextAlarmWidgetTexts.fromMap(m['widget'] as Map<String, dynamic>),
      );

  /// Derniers textes connus, pour reprogrammer sans interface (bouton d'une
  /// notification traité app fermée).
  static Future<AlarmNotificationTexts?> cached() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return AlarmNotificationTexts.fromMap(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> cache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(toMap()));
  }
}

class AlarmService {
  static const String alarmKey = 'alarm_data';

  /// Chaque alarme réserve [idFactor] identifiants côté plugin
  /// (id * idFactor + k) : on planifie ses [occurrencesPerAlarm] prochaines
  /// occurrences pour qu'elle sonne même si l'app n'est pas rouverte.
  static const int idFactor = 10;
  static const int occurrencesPerAlarm = 7;

  static int modelIdFromAlarmId(int alarmId) => alarmId ~/ idFactor;

  static Future<void> _syncQueue = Future.value();

  // ---------------------------------------------------
  // Récupération / Persistance
  // ---------------------------------------------------
  Future<List<AlarmModel>> getAlarms({bool withoutSnooze = false}) async {
    final prefs = await SharedPreferences.getInstance();
    // Un bouton de notification a pu modifier les alarmes depuis le moteur
    // d'arrière-plan : relire le stockage plutôt que le cache de l'isolat.
    await prefs.reload();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    final alarms = <AlarmModel>[];
    for (final s in alarmList) {
      try {
        alarms.add(AlarmModel.fromMap(json.decode(s)));
      } catch (e) {
        debugPrint('AlarmService: alarme illisible ignorée ($e)');
      }
    }

    if (!withoutSnooze) return alarms;
    return alarms.where((a) => !a.isSnooze).toList();
  }

  Future<AlarmModel?> getAlarmById(int id) async {
    final alarms = await getAlarms();
    for (final a in alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> _persistAll(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final list = alarms.map((a) => json.encode(a.toMap())).toList();
    await prefs.setStringList(alarmKey, list);
  }

  /// Retire l'alarme [id] et les rappels différés qui en découlent.
  static List<AlarmModel> withoutAlarm(List<AlarmModel> alarms, int id) =>
      alarms.where((a) => a.id != id && a.snoozeOfId != id).toList();

  /// Retire les rappels différés de l'alarme [id].
  static List<AlarmModel> withoutSnoozesOf(List<AlarmModel> alarms, int id) =>
      alarms.where((a) => !(a.isSnooze && a.snoozeOfId == id)).toList();

  Future<void> _resetSnoozeChain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefStorageKeys.snoozeChainCount.name);
    await prefs.remove(PrefStorageKeys.snoozeChainAt.name);
  }

  int _nextId(List<AlarmModel> alarms) {
    final maxId = alarms.fold<int>(
      0,
      (m, a) => a.id != null && a.id! > m ? a.id! : m,
    );
    return maxId + 1;
  }

  // ---------------------------------------------------
  // CREATE
  // ---------------------------------------------------
  Future<AlarmModel> saveAlarm(
    BuildContext context,
    AlarmModel alarm, {
    bool reschedule = true,
    bool showToast = true,
  }) async {
    final texts = AlarmNotificationTexts.of(context);
    final alarms = await getAlarms();

    alarm.id ??= _nextId(alarms);
    alarms.add(alarm);
    await _persistAll(alarms);

    if (reschedule) await syncAlarms(texts);
    if (showToast && context.mounted) toastNextOccurrence(context, alarm);
    return alarm;
  }

  // ---------------------------------------------------
  // UPDATE (by id)
  // ---------------------------------------------------
  Future<void> editAlarmById(
    BuildContext context,
    AlarmModel alarm, {
    bool reschedule = true,
    bool showToast = true,
  }) async {
    if (alarm.id == null) {
      throw ArgumentError('editAlarmById: alarm.id est null');
    }
    final texts = AlarmNotificationTexts.of(context);
    final alarms = await getAlarms();

    final idx = alarms.indexWhere((a) => a.id == alarm.id);
    if (idx < 0) throw StateError('Aucune alarme avec id=${alarm.id}');

    alarms[idx] = alarm;
    if (alarm.isActive) {
      await _persistAll(alarms);
    } else {
      final kept = withoutSnoozesOf(alarms, alarm.id!);
      if (kept.length != alarms.length) await _resetSnoozeChain();
      await _persistAll(kept);
    }

    if (reschedule) await syncAlarms(texts);
    if (showToast && context.mounted) toastNextOccurrence(context, alarm);
  }

  // ---------------------------------------------------
  // DELETE (by id)
  // ---------------------------------------------------
  Future<void> deleteAlarmById(
    BuildContext context,
    int id, {
    bool reschedule = true,
  }) async {
    final texts = AlarmNotificationTexts.of(context);
    final alarms = await getAlarms();
    final kept = withoutAlarm(alarms, id);
    if (kept.any((a) => a.isSnooze) != alarms.any((a) => a.isSnooze)) {
      await _resetSnoozeChain();
    }
    await _persistAll(kept);
    if (reschedule) await syncAlarms(texts);
  }

  // ---------------------------------------------------
  // SNOOZE
  // ---------------------------------------------------
  /// Nombre de reports déjà faits pour la sonnerie en cours. Le compteur
  /// expire de lui-même (cas d'un arrêt depuis la notification, app fermée).
  Future<int> _snoozeChainCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final at = prefs.getInt(PrefStorageKeys.snoozeChainAt.name);
    if (at == null) return 0;
    final last = DateTime.fromMillisecondsSinceEpoch(at);
    if (DateTime.now().difference(last) > const Duration(hours: 1)) return 0;
    return prefs.getInt(PrefStorageKeys.snoozeChainCount.name) ?? 0;
  }

  /// Nombre de reports encore possibles pour l'alarme qui sonne.
  Future<int> remainingSnoozes() async {
    final settings = await AppSettings.load();
    final used = await _snoozeChainCount();
    return (settings.maxSnoozes - used).clamp(0, settings.maxSnoozes);
  }

  /// Crée un rappel différé à partir de l'alarme qui sonne.
  /// Retourne null si la limite de reports est atteinte.
  Future<AlarmModel?> snooze(BuildContext context, AlarmSettings ringing) =>
      snoozeWith(AlarmNotificationTexts.of(context), ringing);

  /// Variante sans BuildContext (bouton « Reporter » d'une notification).
  Future<AlarmModel?> snoozeWith(
    AlarmNotificationTexts texts,
    AlarmSettings ringing,
  ) async {
    final settings = await AppSettings.load();
    final count = await _snoozeChainCount() + 1;
    if (count > settings.maxSnoozes) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefStorageKeys.snoozeChainCount.name, count);
    await prefs.setInt(
      PrefStorageKeys.snoozeChainAt.name,
      DateTime.now().millisecondsSinceEpoch,
    );

    final snoozeDate = DateTime.now()
        .add(Duration(minutes: settings.snoozeMinutes))
        .copyWith(second: 0, millisecond: 0, microsecond: 0);

    final alarms = await getAlarms();
    final source = await getAlarmById(modelIdFromAlarmId(ringing.id));
    final shadow = AlarmModel(
      snoozeOfId: source?.isSnooze == true ? source!.snoozeOfId : source?.id,
      id: _nextId(alarms),
      title: source?.title ?? ringing.notificationSettings.title,
      time: snoozeDate,
      isActive: true,
      loopAudio: ringing.loopAudio,
      vibrate: ringing.vibrate,
      volume: ringing.volume,
      assetAudio: source?.assetAudio ?? ringing.assetAudioPath.split('/').last,
      selectedDays: List.filled(7, false),
      createdFor: snoozeDate,
      isSnooze: true,
      countSnooze: count,
    );

    // Un seul rappel différé à la fois
    final kept = alarms.where((a) => !a.isSnooze).toList()..add(shadow);
    await _persistAll(kept);
    await syncAlarms(texts);
    return shadow;
  }

  /// Arrêt définitif : supprime les rappels différés et remet le compteur à 0.
  Future<void> clearSnoozes(BuildContext context) =>
      clearSnoozesWith(AlarmNotificationTexts.of(context));

  Future<void> clearSnoozesWith(AlarmNotificationTexts texts) async {
    await _resetSnoozeChain();

    final alarms = await getAlarms();
    final kept = alarms.where((a) => !a.isSnooze).toList();
    if (kept.length != alarms.length) await _persistAll(kept);
    await syncAlarms(texts);
  }

  /// N'importe quelle sonnerie prévue peut être ignorée (depuis la
  /// notification « alarme imminente ») : une alarme ponctuelle est
  /// désactivée, une récurrente saute cette occurrence. Sans BuildContext :
  /// appelé aussi quand l'app est fermée.
  Future<void> ignoreOccurrence(int modelId, DateTime date) async {
    final alarms = await getAlarms();
    final idx = alarms.indexWhere((a) => a.id == modelId);
    if (idx < 0) return;
    final alarm = alarms[idx];
    if (alarm.isOneShot) {
      alarm.isActive = false;
    } else if (alarm.skippedUntil == null ||
        alarm.skippedUntil!.isBefore(date)) {
      alarm.skippedUntil = date.toUtc();
    }
    await _persistAll(alarms);
  }

  // ---------------------------------------------------
  // CLEANUP : désactive les one-shot passées, supprime les snoozes passés
  // ---------------------------------------------------
  Future<List<AlarmModel>> cleanup() async {
    final alarms = await getAlarms();
    final now = DateTime.now();
    var changed = false;
    final kept = <AlarmModel>[];

    for (final a in alarms) {
      if (a.isSnooze) {
        if (!a.isActive || a.isExpired(now: now)) {
          changed = true;
          continue;
        }
      } else if (a.isActive && a.isExpired(now: now)) {
        a.isActive = false;
        changed = true;
      }
      if (a.skippedUntil != null && !a.skippedUntil!.isAfter(now)) {
        a.skippedUntil = null;
        changed = true;
      }
      kept.add(a);
    }

    if (changed) await _persistAll(kept);
    return kept;
  }

  // ---------------------------------------------------
  // FIND NEXT
  // ---------------------------------------------------
  Future<({AlarmModel alarm, DateTime date})?> findNextAlarm() async {
    final alarms = await cleanup();
    final resumeAt = await AppSettings.vacationResumeAt();
    ({AlarmModel alarm, DateTime date})? next;
    for (final a in alarms) {
      final date = a.getNextOccurrence(resumeAt: resumeAt);
      if (date == null) continue;
      if (next == null || date.isBefore(next.date)) {
        next = (alarm: a, date: date);
      }
    }
    return next;
  }

  // ---------------------------------------------------
  // SYNC : planifie toutes les occurrences à venir dans le plugin
  // ---------------------------------------------------
  Future<void> syncAlarms(AlarmNotificationTexts texts) {
    final run = _syncQueue.then((_) => _doSync(texts));
    _syncQueue = run.catchError((Object e, StackTrace s) {
      debugPrint('Echec synchronisation alarmes: $e\n$s');
    });
    return _syncQueue;
  }

  Future<void> _doSync(AlarmNotificationTexts texts) async {
    await texts.cache();
    final settings = await AppSettings.load();
    final resumeAt = await AppSettings.vacationResumeAt();
    final alarms = await cleanup();

    // Ne jamais toucher à une alarme qui sonne
    final ringingIds = <int>{};
    for (final a in await AlarmStorage.getSavedAlarms()) {
      if (await Alarm.isRinging(a.id)) {
        ringingIds.add(a.id);
      } else {
        await Alarm.stop(a.id);
      }
    }

    // Deux réglages à la même seconde se remplacent dans le plugin :
    // on ne garde que le premier.
    final usedTimes = <int>{};
    final now = DateTime.now();
    final upcoming = <UpcomingEntry>[];
    final forWidget = <({DateTime date, AlarmModel alarm})>[];

    for (final alarm in alarms) {
      if (alarm.id == null) continue;
      final dates = alarm.upcomingOccurrences(
        alarm.isSnooze ? 1 : occurrencesPerAlarm,
        now: now,
        resumeAt: resumeAt,
      );
      if (dates.isEmpty) continue;
      forWidget.addAll(dates.map((d) => (date: d, alarm: alarm)));

      final audioPath = await resolveAlarmAudio(alarm.assetAudio);

      for (var k = 0; k < dates.length; k++) {
        final pluginId = alarm.id! * idFactor + k;
        final key = dates[k].millisecondsSinceEpoch ~/ 1000;
        if (ringingIds.contains(pluginId) || !usedTimes.add(key)) continue;

        final alarmSettings = AlarmSettings(
          id: pluginId,
          dateTime: dates[k],
          loopAudio: alarm.loopAudio,
          vibrate: alarm.vibrate,
          volume: alarm.volume,
          volumeEnforced: true,
          fadeDuration: settings.fadeSeconds.toDouble(),
          androidFullScreenIntent: true,
          warningNotificationOnKill: Platform.isIOS,
          assetAudioPath: audioPath,
          notificationSettings: NotificationSettings(
            title: alarm.hasTitle ? alarm.title! : texts.defaultTitle,
            body: texts.body,
            stopButton: texts.stopButton,
            icon: kNotificationIcon,
          ),
        );

        try {
          await Alarm.set(alarmSettings: alarmSettings);
          upcoming.add(UpcomingEntry(pluginId, dates[k], alarm));
        } catch (e, s) {
          debugPrint('Echec Alarm.set($pluginId): $e\n$s');
        }
      }
    }

    try {
      await UpcomingAlarmNotifications.sync(
        upcoming,
        texts.upcoming,
        settings.upcomingMinutes,
      );
    } catch (e, s) {
      debugPrint('Echec notifications « alarme imminente »: $e\n$s');
    }

    try {
      await NextAlarmWidgetService.update(forWidget, texts.widget);
    } catch (e, s) {
      debugPrint('Echec mise à jour du widget: $e\n$s');
    }
  }

  // ---------------------------------------------------
  // Toast
  // ---------------------------------------------------
  Future<void> toastNextOccurrence(
    BuildContext context,
    AlarmModel alarm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final resumeAt = await AppSettings.vacationResumeAt();
    if (!context.mounted) return;
    final nextOccurrence = alarm.getNextOccurrence(resumeAt: resumeAt);
    if (!alarm.isActive || nextOccurrence == null) return;

    final message = context.translate(
      'nextDateToast',
      translationParams: {
        'duration': formatCountdown(
          context,
          nextOccurrence.difference(DateTime.now()),
        ),
      },
    );

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ThemeColors.nightSurfaceHigh,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
