import 'dart:convert';

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
  Future<void> saveAlarm(AlarmModel alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    // Convert Alarm to Map and store it
    final alarmMap = json.encode(alarm.toMap());
    alarmList.add(alarmMap);
    await prefs.setStringList(alarmKey, alarmList);
  }

  // Edit Alarm object in SharedPreferences
  Future<void> editAlarm(AlarmModel alarm, int index) async {
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
  }

  // Delete Alarm from SharedPreferences by index
  Future<void> deleteAlarm(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList(alarmKey) ?? [];

    if (index < alarmList.length) {
      alarmList.removeAt(index);
      await prefs.setStringList(alarmKey, alarmList);
    }
  }
}
