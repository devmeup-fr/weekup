import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekup/core/enums/storage_keys_enum.dart';
import 'package:weekup/models/alarm_log_model.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/alarm_service.dart';

extension AlarmLogsApi on AlarmService {
  Future<List<AlarmLogModel>> getAlarmLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(SecureStorageKeys.alarmLogs.name) ?? [];
    final parsed = <AlarmLogModel>[];
    for (final s in logs) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        parsed.add(AlarmLogModel.fromJson(map));
      } catch (_) {}
    }
    parsed.sort((a, b) => b.firedAt.compareTo(a.firedAt));
    return parsed;
  }

  Future<void> clearAlarmLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SecureStorageKeys.alarmLogs.name);
  }

  Future<void> saveAlarmLog(AlarmSettings alarmSettings) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(SecureStorageKeys.alarmLogs.name) ?? [];

    final logEntry = AlarmLogModel(
      id: alarmSettings.id,
      title: alarmSettings.notificationSettings.title,
      firedAt: DateTime.now(),
      scheduledFor: alarmSettings.dateTime,
    ).toJson();

    logs.add(logEntry);
    await prefs.setStringList(SecureStorageKeys.alarmLogs.name, logs);
  }

  Future<void> snoozeAlarmLog(AlarmModel alarmModel) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(SecureStorageKeys.alarmLogs.name) ?? [];

    final logEntry = jsonEncode({
      'id': alarmModel.id,
      'title': alarmModel.title,
      'firedAt': DateTime.now().toIso8601String(),
      'scheduledFor': alarmModel.getNextOccurrence()?.toIso8601String(),
    });

    logs.add(logEntry);
    await prefs.setStringList(SecureStorageKeys.alarmLogs.name, logs);
  }
}
