import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_alarms/core/utils/localization_util.dart';
import 'package:my_alarms/models/alarm_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static const String alarmKey = 'alarm_data';

  // Retrieve Alarm objects from SharedPreferences
  Future<List<AlarmModel>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    return alarmList
        .map((alarmData) => AlarmModel.fromMap(json.decode(alarmData)))
        .toList();
  }

  // Save Alarm object to SharedPreferences
  Future<void> saveAlarm(BuildContext context, AlarmModel alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    // Convert Alarm to Map and store it
    final alarmMap = json.encode(alarm.toMap());
    alarmList.add(alarmMap);
    await prefs.setStringList(alarmKey, alarmList);

    await setNextAlarm(context);
  }

  // Edit Alarm object in SharedPreferences
  Future<void> editAlarm(
      BuildContext context, AlarmModel alarm, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    // Ensure the index is within bounds
    if (index >= 0 && index < alarmList.length) {
      // Convert Alarm to Map and replace the alarm at the specified index
      final alarmMap = json.encode(alarm.toMap());
      alarmList[index] = alarmMap; // Replace the alarm at the specified index
    } else {
      throw RangeError(
          'Index $index out of bounds for alarm list of length ${alarmList.length}');
    }

    // Save the updated alarm list back to SharedPreferences
    await prefs.setStringList(alarmKey, alarmList);

    await setNextAlarm(context);
  }

  // Delete Alarm from SharedPreferences by index
  Future<void> deleteAlarm(BuildContext context, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    if (index < alarmList.length) {
      alarmList.removeAt(index);
      await prefs.setStringList(alarmKey, alarmList);
    }
    await setNextAlarm(context);
  }

  Future<void> setNextAlarm(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    final alarms = await AlarmStorage.getSavedAlarms();
    for (var alarm in alarms) {
      await Alarm.stop(alarm.id);
      await AlarmStorage.unsaveAlarm(alarm.id);
    }

    if (alarmList.isEmpty) {
      // No alarms set, do nothing
      return;
    }

    // find next alarm in the list
    AlarmModel? nextAlarm;

    for (var i = 0; i < alarmList.length; i++) {
      var currentAlarm = AlarmModel.fromMap(json.decode(alarmList[i]));

      DateTime? currentAlarmDate = currentAlarm.getNextOccurrence();

      if (currentAlarmDate != null &&
          currentAlarm.selectedDays.every((day) => !day) &&
          currentAlarmDate.difference(currentAlarm.createdAt).inDays > 0) {
        currentAlarm.isActive = false;
        await editAlarm(context, currentAlarm, i);

        continue;
      }

      if (currentAlarmDate != null &&
          (nextAlarm == null ||
              nextAlarm.getNextOccurrence() == null ||
              currentAlarmDate.isBefore(nextAlarm.getNextOccurrence()!))) {
        nextAlarm = currentAlarm;
      }
    }

    if (nextAlarm == null) {
      // No alarms set, do nothing
      return;
    }

    // Convert AlarmMap to AlarmModel and set it as the next alarm
    AlarmSettings alarmSettings = AlarmSettings(
      id: nextAlarm.id != null ? (nextAlarm.id! + 1) : 1,
      dateTime: nextAlarm.getNextOccurrence()!,
      loopAudio: nextAlarm.loopAudio,
      vibrate: nextAlarm.vibrate,
      volume: nextAlarm.volume,
      fadeDuration: 3.0,
      androidFullScreenIntent: true,
      warningNotificationOnKill: Platform.isIOS,
      assetAudioPath: "assets/musics/${nextAlarm.assetAudio}",
      notificationSettings: NotificationSettings(
        title: nextAlarm.title ?? context.translate('alarm_notification_title'),
        body: context.translate('alarm_notification_body'),
        stopButton: context.translate('stop_alarm_button'),
        icon: 'notification_icon',
      ),
    );

    Alarm.set(alarmSettings: alarmSettings);
  }
}
