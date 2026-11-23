import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/alarm_service.dart';

AlarmModel _alarm(int id, List<bool> days) => AlarmModel(
      id: id,
      time: DateTime(2026, 1, 1, 7),
      assetAudio: 'marimba.mp3',
      selectedDays: days,
      createdAt: DateTime(2026, 11, 23),
      createdFor: DateTime(2026, 11, 23),
    );

void main() {
  final service = AlarmService();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AlarmService.alarmKey: [
        _alarm(1, const [true, true, true, true, true, false, false]),
        _alarm(2, List.filled(7, false)),
      ].map((a) => jsonEncode(a.toMap())).toList(),
    });
  });

  test('« Ignorer » sur une récurrente saute seulement cette sonnerie',
      () async {
    final ring = DateTime(2026, 11, 24, 7);
    await service.ignoreOccurrence(1, ring);
    final alarm = (await service.getAlarmById(1))!;
    expect(alarm.isActive, isTrue);
    expect(
      alarm.getNextOccurrence(now: DateTime(2026, 11, 23, 20)),
      DateTime(2026, 11, 25, 7),
    );
  });

  test('« Ignorer » sur une ponctuelle la désactive', () async {
    await service.ignoreOccurrence(2, DateTime(2026, 11, 24, 7));
    expect((await service.getAlarmById(2))!.isActive, isFalse);
  });

  test('id inconnu : rien ne change', () async {
    await service.ignoreOccurrence(42, DateTime(2026, 11, 24, 7));
    expect(await service.getAlarms(), hasLength(2));
  });
}
