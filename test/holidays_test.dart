import 'package:flutter_test/flutter_test.dart';
import 'package:weekup/models/alarm_model.dart';
import 'package:weekup/utils/holidays.dart';

const weekdays = [true, true, true, true, true, false, false];

AlarmModel _weekdayAlarm({bool skipHolidays = true}) => AlarmModel(
      id: 1,
      time: DateTime(2026, 1, 1, 7),
      assetAudio: 'marimba.mp3',
      selectedDays: weekdays,
      skipHolidays: skipHolidays,
      createdAt: DateTime(2026, 1, 1),
      createdFor: DateTime(2026, 1, 1),
    );

void main() {
  test('dimanche de Pâques', () {
    expect(easterSunday(2025), DateTime(2025, 4, 20));
    expect(easterSunday(2026), DateTime(2026, 4, 5));
    expect(easterSunday(2027), DateTime(2027, 3, 28));
  });

  test('jours fériés mobiles et fixes 2026', () {
    expect(holidayOn(DateTime(2026, 4, 6)), Holiday.easterMonday);
    expect(holidayOn(DateTime(2026, 5, 14)), Holiday.ascension);
    expect(holidayOn(DateTime(2026, 5, 25)), Holiday.whitMonday);
    expect(holidayOn(DateTime(2026, 12, 25, 7, 30)), Holiday.christmas);
    expect(holidayOn(DateTime(2026, 12, 24)), isNull);
    expect(frenchHolidays(2026), hasLength(11));
  });

  test('pas de sonnerie le jour de Noël', () {
    final now = DateTime(2026, 12, 24, 8); // jeudi
    expect(
      _weekdayAlarm().getNextOccurrence(now: now),
      DateTime(2026, 12, 28, 7),
    );
    expect(
      _weekdayAlarm(skipHolidays: false).getNextOccurrence(now: now),
      DateTime(2026, 12, 25, 7),
    );
  });

  test('mode vacances : les récurrentes reprennent au retour', () {
    final now = DateTime(2026, 12, 18, 8);
    final resumeAt = DateTime(2027, 1, 4); // dernier jour off : 3 janvier
    expect(
      _weekdayAlarm().upcomingOccurrences(2, now: now, resumeAt: resumeAt),
      [DateTime(2027, 1, 4, 7), DateTime(2027, 1, 5, 7)],
    );
  });

  test('mode vacances : une alarme ponctuelle sonne quand même', () {
    final now = DateTime(2026, 12, 18, 8);
    final flight = AlarmModel(
      id: 2,
      time: DateTime(2026, 1, 1, 5),
      assetAudio: 'marimba.mp3',
      selectedDays: List.filled(7, false),
      createdAt: now,
      createdFor: DateTime(2026, 12, 22),
    );
    expect(
      flight.getNextOccurrence(now: now, resumeAt: DateTime(2027, 1, 4)),
      DateTime(2026, 12, 22, 5),
    );
  });

  test('planning : les occurrences exclues restent visibles et marquées', () {
    final alarm = _weekdayAlarm()
      ..skippedUntil = DateTime(2026, 12, 21, 7); // lundi sauté
    final list = alarm.occurrencesBetween(
      DateTime(2026, 12, 21),
      DateTime(2026, 12, 28),
      resumeAt: DateTime(2026, 12, 24), // vacances lun.–mer.
    );
    expect(list.map((o) => (o.date.day, o.excludedBy)).toList(), [
      (21, OccurrenceExclusion.paused),
      (22, OccurrenceExclusion.paused),
      (23, OccurrenceExclusion.paused),
      (24, null),
      (25, OccurrenceExclusion.holiday),
    ]);
  });

  test('« sonne aussi en vacances » ignore la pause', () {
    final now = DateTime(2026, 12, 18, 8);
    final resumeAt = DateTime(2027, 1, 4);
    final pills = _weekdayAlarm(skipHolidays: false)..ignoreVacation = true;
    expect(
      pills.getNextOccurrence(now: now, resumeAt: resumeAt),
      DateTime(2026, 12, 21, 7),
    );
    final week = pills.occurrencesBetween(
      DateTime(2026, 12, 21),
      DateTime(2026, 12, 26),
      resumeAt: resumeAt,
    );
    expect(week.every((o) => o.rings), isTrue);
  });

  test('« sonne aussi en vacances » respecte toujours les jours fériés', () {
    final alarm = _weekdayAlarm()..ignoreVacation = true;
    expect(
      alarm.getNextOccurrence(
        now: DateTime(2026, 12, 24, 8),
        resumeAt: DateTime(2027, 1, 4),
      ),
      DateTime(2026, 12, 28, 7),
    );
  });
}
