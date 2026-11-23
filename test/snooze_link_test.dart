import 'package:flutter_test/flutter_test.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/services/alarm_service.dart';

AlarmModel _alarm(int id, {int? snoozeOf}) => AlarmModel(
      id: id,
      time: DateTime(2026, 11, 24, 7),
      assetAudio: 'marimba.mp3',
      selectedDays: snoozeOf == null
          ? const [true, true, true, true, true, false, false]
          : List.filled(7, false),
      isSnooze: snoozeOf != null,
      snoozeOfId: snoozeOf,
    );

void main() {
  final alarms = [_alarm(1), _alarm(2), _alarm(3, snoozeOf: 1)];

  test('supprimer une alarme supprime aussi son rappel différé', () {
    final kept = AlarmService.withoutAlarm(alarms, 1);
    expect(kept.map((a) => a.id), [2]);
  });

  test('supprimer une autre alarme garde le rappel différé', () {
    final kept = AlarmService.withoutAlarm(alarms, 2);
    expect(kept.map((a) => a.id), [1, 3]);
  });

  test('désactiver une alarme retire seulement son rappel différé', () {
    final kept = AlarmService.withoutSnoozesOf(alarms, 1);
    expect(kept.map((a) => a.id), [1, 2]);
  });

  test('le lien est conservé à la sérialisation', () {
    final copy = AlarmModel.fromMap(alarms[2].toMap());
    expect(copy.snoozeOfId, 1);
  });
}
