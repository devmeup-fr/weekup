import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekup/core/enums/storage_keys_enum.dart';
import 'package:weekup/models/alarm_log_model.dart';
import 'package:weekup/services/alarm_service.dart';

extension AlarmLogsApi on AlarmService {
  static const int maxLogs = 300;

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

  Future<void> _appendLog(AlarmLogModel entry) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(SecureStorageKeys.alarmLogs.name) ?? [];
    logs.add(entry.toJson());
    final trimmed =
        logs.length > maxLogs ? logs.sublist(logs.length - maxLogs) : logs;
    await prefs.setStringList(SecureStorageKeys.alarmLogs.name, trimmed);
  }

  Future<void> saveAlarmLog(
    AlarmSettings alarmSettings, {
    AlarmLogAction action = AlarmLogAction.ring,
    DateTime? scheduledFor,
  }) async {
    final model = await getAlarmById(
      AlarmService.modelIdFromAlarmId(alarmSettings.id),
    );
    await _appendLog(AlarmLogModel(
      id: alarmSettings.id,
      title: alarmSettings.notificationSettings.title,
      firedAt: DateTime.now(),
      scheduledFor: scheduledFor ?? alarmSettings.dateTime,
      isSnooze: model?.isSnooze ?? false,
      action: action,
    ));
  }
}
