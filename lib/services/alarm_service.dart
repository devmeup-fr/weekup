import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/enums/storage_keys_enum.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:my_alarms/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static const String alarmKey = 'alarm_data';

  // ---------------------------------------------------
  // Récupération / Persistance
  // ---------------------------------------------------
  Future<List<AlarmModel>> getAlarms({bool withoutSnooze = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    final alarms =
        alarmList.map((s) => AlarmModel.fromMap(json.decode(s))).toList();

    if (!withoutSnooze) return alarms;

    return alarms.where((a) => a.isSnooze != true).toList();
  }

  Future<bool> isSnoozeAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    final alarms =
        alarmList.map((s) => AlarmModel.fromMap(json.decode(s))).toList();

    return alarms.any((a) => a.isSnooze == true);
  }

  Future<void> _persistAll(
      SharedPreferences prefs, List<AlarmModel> alarms) async {
    final list = alarms.map((a) => json.encode(a.toMap())).toList();
    await prefs.setStringList(alarmKey, list);
  }

  Future<int> _nextId() async {
    final alarms = await getAlarms();
    final maxId =
        alarms.fold<int>(0, (m, a) => a.id != null && a.id! > m ? a.id! : m);
    return maxId + 1;
  }

  Future<void> _maybeReschedule(BuildContext context,
      {required bool reschedule}) async {
    if (reschedule && context.mounted) {
      await setNextAlarm(context);
    }
  }

  // ---------------------------------------------------
  // CREATE
  // ---------------------------------------------------
  Future<void> saveAlarm(
    BuildContext context,
    AlarmModel alarm, {
    bool reschedule = true,
    bool showToast = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAlarms();

    // --- Gestion du snooze ---
    // Limite de snooze : 3 (le 4e est refusé)
    const int kMaxSnoozes = 4;

    if (alarm.isSnooze == true) {
      final existingSnoozes = alarms.where((a) => a.isSnooze == true).toList();

      int nextCount = 1;

      if (existingSnoozes.isNotEmpty) {
        final previous = existingSnoozes.reduce((p, n) {
          final pc = p.countSnooze;
          final nc = n.countSnooze;
          if (pc != nc) return pc > nc ? p : n;

          final pDate = p.getNextOccurrence();
          final nDate = n.getNextOccurrence();
          if (pDate == null && nDate == null) return p;
          if (pDate == null) return n;
          if (nDate == null) return p;
          return pDate.isAfter(nDate) ? p : n;
        });

        nextCount = (previous.countSnooze) + 1;

        // Refuse le 4e snooze
        if (nextCount > kMaxSnoozes) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(context.translate('snooze_limit_reached'))),
            );
          }
          return;
        }

        alarms.removeWhere((a) => a.id == previous.id);
      }

      alarm.countSnooze = nextCount;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('snooze_alarm'))),
        );
      }
    }

    alarm.id ??= await _nextId();
    alarms.add(alarm);

    await _persistAll(prefs, alarms);
    await _maybeReschedule(context, reschedule: reschedule);

    if (showToast && context.mounted) toastNextOccurrence(context, alarm);
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

    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAlarms();

    final idx = alarms.indexWhere((a) => a.id == alarm.id);
    if (idx < 0) throw StateError('Aucune alarme avec id=${alarm.id}');

    alarms[idx] = alarm;
    await _persistAll(prefs, alarms);

    await _maybeReschedule(context, reschedule: reschedule);
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
    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAlarms();
    final newAlarms = alarms.where((a) => a.id != id).toList();

    await _persistAll(prefs, newAlarms);
    await _maybeReschedule(context, reschedule: reschedule);
  }

  // ---------------------------------------------------
  // FIND NEXT
  // ---------------------------------------------------
  Future<AlarmModel?> findNextAlarm(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    if (alarmList.isEmpty) return null;

    AlarmModel? nextAlarm;

    for (var i = 0; i < alarmList.length; i++) {
      var currentAlarm = AlarmModel.fromMap(json.decode(alarmList[i]));
      final currentAlarmDate = currentAlarm.getNextOccurrence();

      // One-shot expirée → désactiver/supprimer SANS replanification
      final weeklyMatrix = currentAlarm.selectedDays.length == 7;
      final isOneShot = weeklyMatrix &&
          !currentAlarm.isSnooze &&
          currentAlarm.selectedDays.every((d) => !d);

      if (currentAlarmDate != null &&
          isOneShot &&
          currentAlarmDate.difference(currentAlarm.getDateFor()).inDays > 0) {
        currentAlarm.isActive = false;
        if (context.mounted) {
          await editAlarmById(
            context,
            currentAlarm,
            reschedule: false,
            showToast: false,
          );
        }
        continue;
      }

      // ---------------------------------------------------
      // Remove past Snooze
      // ---------------------------------------------------
      if (currentAlarm.isSnooze && currentAlarm.id != null) {
        final snoozeDate = currentAlarm.getNextOccurrence();

        // Si la date est expirée → suppression du snooze
        if (snoozeDate == null || snoozeDate.isBefore(DateTime.now())) {
          await deleteAlarmById(
            context,
            currentAlarm.id!,
            reschedule: false,
          );
        }
      }

      if (currentAlarmDate != null &&
          (nextAlarm == null ||
              nextAlarm.getNextOccurrence() == null ||
              currentAlarmDate.isBefore(nextAlarm.getNextOccurrence()!))) {
        nextAlarm = currentAlarm;
      }
    }

    return nextAlarm;
  }

  // ---------------------------------------------------
  // Remove All Snooze
  // ---------------------------------------------------
  Future<void> removeAllSnooze(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    if (alarmList.isEmpty) return;

    for (var i = 0; i < alarmList.length; i++) {
      var currentAlarm = AlarmModel.fromMap(json.decode(alarmList[i]));

      // ---------------------------------------------------
      // Remove past Snooze
      // ---------------------------------------------------
      if (currentAlarm.isSnooze && currentAlarm.id != null) {
        final snoozeDate = currentAlarm.getNextOccurrence();

        // Si la date est expirée → suppression du snooze
        if (snoozeDate == null || snoozeDate.isBefore(DateTime.now())) {
          await deleteAlarmById(
            context,
            currentAlarm.id!,
            reschedule: false,
          );
        }
      }
    }
  }

  // ---------------------------------------------------
  // SET NEXT
  // ---------------------------------------------------
  Future<void> setNextAlarm(BuildContext context,
      {removeSnooze = false}) async {
    final saved = await AlarmStorage.getSavedAlarms();

    for (final a in saved) {
      final isRinging = await Alarm.isRinging(a.id);
      if (!isRinging) {
        await Alarm.stop(a.id);
        await AlarmStorage.unsaveAlarm(a.id);
      }
    }
    if (removeSnooze) await removeAllSnooze(context);

    if (context.mounted) {
      final nextAlarm = await findNextAlarm(context);
      if (nextAlarm == null) return;

      final settings = AlarmSettings(
        id: nextAlarm.id != null ? (nextAlarm.id! + 1) : 1,
        dateTime: nextAlarm.getNextOccurrence()!,
        loopAudio: nextAlarm.loopAudio,
        vibrate: nextAlarm.vibrate,
        volume: nextAlarm.volume,
        volumeEnforced: true,
        fadeDuration: 10.0,
        androidFullScreenIntent: true,
        warningNotificationOnKill: Platform.isIOS,
        assetAudioPath: "assets/musics/${nextAlarm.assetAudio}",
        notificationSettings: NotificationSettings(
          title:
              nextAlarm.title ?? context.translate('alarm_notification_title'),
          body: context.translate('alarm_notification_body'),
          stopButton: context.translate('stop_alarm_button'),
          icon: 'notification_icon',
        ),
      );

      await Alarm.set(alarmSettings: settings);
    }
  }

  Future<void> saveAlarmLog(AlarmSettings alarmSettings) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(SecureStorageKeys.alarmLogs.name) ?? [];

    final logEntry = jsonEncode({
      'id': alarmSettings.id,
      'title': alarmSettings.notificationSettings.title,
      'firedAt': DateTime.now().toIso8601String(),
      'scheduledFor': alarmSettings.dateTime.toIso8601String(),
    });

    logs.add(logEntry);
    await prefs.setStringList(SecureStorageKeys.alarmLogs.name, logs);
  }

  // ---------------------------------------------------
  // Toast
  // ---------------------------------------------------
  void toastNextOccurrence(BuildContext context, AlarmModel alarm) {
    final nextOccurrence = alarm.getNextOccurrence();
    if (alarm.isActive && nextOccurrence != null) {
      final now = DateTime.now();
      final diff = nextOccurrence.difference(now);

      if (diff.inSeconds <= 0 || diff.inSeconds < 60) return;

      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final mins = diff.inMinutes % 60;

      final parts = <String>[];
      if (days > 0) {
        parts.add(
            "$days ${days > 1 ? context.translate('common.days') : context.translate('common.day')}");
      }
      if (hours > 0) {
        parts.add(
            "$hours ${hours > 1 ? context.translate('common.hours') : context.translate('common.hour')}");
      }
      if (mins > 0) {
        parts.add(
            "$mins ${mins > 1 ? context.translate('common.minutes') : context.translate('common.minute')}");
      }

      String durationText;
      if (parts.length > 1) {
        durationText =
            "${parts.sublist(0, parts.length - 1).join(' ')} ${context.translate('common.and')} ${parts.last}";
      } else {
        durationText = parts.isNotEmpty ? parts.first : "";
      }

      final message = "${context.translate('nextDateToast')} $durationText";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: ThemeColors.primary,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
