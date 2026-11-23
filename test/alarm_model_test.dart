import 'package:flutter_test/flutter_test.dart';
import 'package:weekup/models/alarm_model.dart';

AlarmModel _alarm({
  required int hour,
  int minute = 0,
  List<bool>? days,
  int weeks = 1,
  required DateTime createdAt,
  DateTime? createdFor,
  DateTime? skippedUntil,
  bool isSnooze = false,
}) {
  return AlarmModel(
    id: 1,
    time: DateTime(2026, 1, 1, hour, minute),
    assetAudio: 'marimba.mp3',
    selectedDays: days ?? List.filled(7, false),
    recurrenceWeeks: weeks,
    createdAt: createdAt,
    createdFor: createdFor ?? createdAt,
    skippedUntil: skippedUntil,
    isSnooze: isSnooze,
  );
}

const weekdays = [true, true, true, true, true, false, false];

void main() {
  // Lundi 23 novembre 2026
  final monday = DateTime(2026, 11, 23);

  group('one-shot', () {
    test('sonne aujourd\'hui si l\'heure n\'est pas passée', () {
      final now = monday.add(const Duration(hours: 6));
      final a = _alarm(hour: 7, createdAt: now);
      expect(a.getNextOccurrence(now: now), DateTime(2026, 11, 23, 7));
    });

    test('sonne demain si l\'heure est passée', () {
      final now = monday.add(const Duration(hours: 8));
      final a = _alarm(hour: 7, createdAt: now);
      expect(a.getNextOccurrence(now: now), DateTime(2026, 11, 24, 7));
    });

    test('expire après avoir sonné, sans glisser au lendemain', () {
      final created = monday.add(const Duration(hours: 6));
      final a = _alarm(hour: 7, createdAt: created);
      final after = DateTime(2026, 11, 23, 7, 1);
      expect(a.getNextOccurrence(now: after), isNull);
      expect(a.isExpired(now: after), isTrue);
    });

    test('réactivée des jours plus tard : jamais une date passée', () {
      final old = DateTime(2026, 11, 10, 6);
      final now = DateTime(2026, 11, 23, 9);
      final a = _alarm(hour: 7, createdAt: old)..createdAt = now.toUtc();
      expect(a.getNextOccurrence(now: now), DateTime(2026, 11, 24, 7));
    });

    test('date future choisie dans le calendrier', () {
      final now = DateTime(2026, 11, 23, 20);
      final a = _alarm(
        hour: 6,
        createdAt: now,
        createdFor: DateTime(2026, 12, 25),
      );
      expect(a.getNextOccurrence(now: now), DateTime(2026, 12, 25, 6));
    });
  });

  group('snooze', () {
    test('passage de minuit : sonne le lendemain', () {
      final now = DateTime(2026, 11, 23, 23, 55);
      final snoozeAt = DateTime(2026, 11, 24, 0, 5);
      final a = _alarm(
        hour: 0,
        minute: 5,
        createdAt: now,
        createdFor: snoozeAt,
        isSnooze: true,
      );
      expect(a.getNextOccurrence(now: now), snoozeAt);
      expect(a.isExpired(now: DateTime(2026, 11, 24, 0, 6)), isTrue);
    });
  });

  group('hebdomadaire', () {
    test('en semaine : le samedi passe au lundi', () {
      final saturday = DateTime(2026, 11, 28, 9);
      final a = _alarm(hour: 7, days: weekdays, createdAt: monday);
      expect(a.getNextOccurrence(now: saturday), DateTime(2026, 11, 30, 7));
    });

    test('plusieurs occurrences à venir', () {
      final now = DateTime(2026, 11, 26, 8); // jeudi après 7h
      final a = _alarm(hour: 7, days: weekdays, createdAt: monday);
      expect(a.upcomingOccurrences(3, now: now), [
        DateTime(2026, 11, 27, 7),
        DateTime(2026, 11, 30, 7),
        DateTime(2026, 12, 1, 7),
      ]);
    });

    test('1 semaine sur 2 alignée sur les semaines calendaires', () {
      // Créée un mercredi : la semaine de création est "active"
      final wednesday = DateTime(2026, 11, 25, 12);
      final a = _alarm(
        hour: 7,
        days: [true, false, false, false, true, false, false], // lun + ven
        weeks: 2,
        createdAt: wednesday,
      );
      expect(a.upcomingOccurrences(3, now: wednesday), [
        DateTime(2026, 11, 27, 7), // ven. semaine 0
        DateTime(2026, 12, 7, 7), // lun. semaine 2
        DateTime(2026, 12, 11, 7), // ven. semaine 2
      ]);
    });

    test('date de début dans le futur', () {
      final a = _alarm(
        hour: 7,
        days: List.filled(7, true),
        createdAt: monday,
        createdFor: DateTime(2026, 12, 1),
      );
      expect(a.getNextOccurrence(now: monday), DateTime(2026, 12, 1, 7));
    });

    test('passer la prochaine occurrence', () {
      final now = DateTime(2026, 11, 23, 8);
      final a = _alarm(
        hour: 7,
        days: weekdays,
        createdAt: monday,
        skippedUntil: DateTime(2026, 11, 24, 7),
      );
      expect(a.getNextOccurrence(now: now), DateTime(2026, 11, 25, 7));
      expect(a.isSkipping(now: now), isTrue);
    });

    test('changement d\'heure (passage à l\'heure d\'hiver) sans décalage', () {
      final now = DateTime(2026, 10, 24, 12);
      final a = _alarm(hour: 7, days: List.filled(7, true), createdAt: now);
      expect(a.upcomingOccurrences(3, now: now), [
        DateTime(2026, 10, 25, 7),
        DateTime(2026, 10, 26, 7),
        DateTime(2026, 10, 27, 7),
      ]);
    });

    test('ancien format quotidien (liste vide)', () {
      final now = DateTime(2026, 11, 23, 8);
      final a = _alarm(hour: 7, days: const [], createdAt: monday);
      expect(a.getNextOccurrence(now: now), DateTime(2026, 11, 24, 7));
    });

    test('inactive : aucune occurrence', () {
      final a = _alarm(hour: 7, days: weekdays, createdAt: monday)
        ..isActive = false;
      expect(a.getNextOccurrence(now: monday), isNull);
    });
  });

  test('sérialisation aller-retour', () {
    final a = _alarm(
      hour: 7,
      minute: 30,
      days: weekdays,
      weeks: 2,
      createdAt: monday,
      skippedUntil: DateTime(2026, 11, 24, 7, 30),
    )..title = 'Boulot';
    final b = AlarmModel.fromMap(a.toMap());
    expect(b.toMap(), a.toMap());
    expect(b.isSkipping(now: monday), isTrue);
  });
}
