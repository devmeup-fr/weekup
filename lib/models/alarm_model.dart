import 'package:flutter/foundation.dart';

class AlarmModel {
  int? id;
  String? title;

  /// Seules l'heure et la minute de `time` sont utilisées pour la sonnerie.
  DateTime time;

  bool isActive;
  bool loopAudio;
  bool vibrate;
  double? volume; // 0.0..1.0Q111
  String assetAudio;

  /// Matrice hebdo de 7 booléens (lun..dim) :
  /// - 7 booléens tous à false => ONE-SHOT (jour de référence = createdFor)
  /// - Au moins un true       => hebdo sur ces jours-là
  /// - Liste vide             => quotidien (tous les jours)
  List<bool> selectedDays;

  /// Récurrence en semaines (1 = chaque semaine, 2 = toutes les 2 semaines, …)
  int recurrenceWeeks;

  /// Dates persistées en UTC
  DateTime createdAt;
  DateTime? createdFor;

  // Snooze params
  bool isSnooze;
  int countSnooze;

  AlarmModel({
    this.id,
    this.title,
    required this.time,
    this.isActive = true,
    this.loopAudio = true,
    this.vibrate = true,
    this.volume,
    required this.assetAudio,
    this.selectedDays = const [],
    this.recurrenceWeeks = 1,
    DateTime? createdAt,
    DateTime? createdFor,
    this.isSnooze = false,
    this.countSnooze = 0,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        createdFor = (createdFor ?? DateTime.now()).toUtc();

  // --------------------------
  // Helpers de sémantique jours
  // --------------------------

  /// true si `selectedDays` contient 7 valeurs (lun..dim)
  bool get isWeeklyMatrix => selectedDays.length == 7;

  /// true si quotidien (aucune matrice fournie)
  bool get isDaily => selectedDays.isEmpty;

  /// true si ONE-SHOT (matrice 7 éléments et tous false)
  bool get isOneShot => isWeeklyMatrix && selectedDays.every((d) => !d);

  // --------------------------
  // Serialization
  // --------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time.toIso8601String(),
      'isActive': isActive,
      'loopAudio': loopAudio,
      'vibrate': vibrate,
      'volume': volume,
      'assetAudio': assetAudio,
      'selectedDays': selectedDays,
      'recurrenceWeeks': recurrenceWeeks,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'createdFor': createdFor?.toUtc().toIso8601String(),
      'isSnooze': isSnooze,
      'countSnooze': countSnooze,
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    final rawSelected = (map['selectedDays'] as List<dynamic>? ?? [])
        .map((e) => e as bool)
        .toList(growable: false);

    return AlarmModel(
      id: map['id'] as int?,
      title: map['title'] as String?,
      time: DateTime.parse(map['time'] as String),
      isActive: map['isActive'] as bool? ?? true,
      loopAudio: map['loopAudio'] as bool? ?? true,
      vibrate: map['vibrate'] as bool? ?? true,
      volume: (map['volume'] as num?)?.toDouble(),
      assetAudio: map['assetAudio'] as String,
      selectedDays: rawSelected,
      recurrenceWeeks: (map['recurrenceWeeks'] as int?) ?? 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      createdFor: (map['createdFor'] != null)
          ? DateTime.parse(map['createdFor'] as String)
          : null,
      isSnooze: map['isSnooze'] as bool? ?? false,
      countSnooze: map['countSnooze'] as int? ?? 0,
    );
  }

  // --------------------------
  // Logic utilitaire
  // --------------------------

  DateTime getDateFor() {
    if (createdFor != null && createdFor!.isAfter(createdAt)) {
      return createdFor!;
    }
    return createdAt;
  }

  /// Calcule la prochaine occurrence en tenant compte de :
  /// - one-shot (7×false) basé sur createdFor
  /// - hebdo via selectedDays (>=1 true)
  /// - quotidien si selectedDays vide
  /// - récurrence toutes les N semaines alignée sur createdFor
  ///
  /// Calcul en **local** pour éviter les glisses de jour.
  DateTime? getNextOccurrence() {
    if (!isActive) return null;

    final now = DateTime.now();

    final baseCreatedForLocal = (createdFor ?? createdAt).toLocal();
    final hm = time.toLocal();

    // Ancre initiale = createdFor + hh:mm
    DateTime nextDate = DateTime(
      baseCreatedForLocal.year,
      baseCreatedForLocal.month,
      baseCreatedForLocal.day,
      hm.hour,
      hm.minute,
    );

    // ONE-SHOT : jour unique = ancre ; si passé, décaler au lendemain
    if (isOneShot) {
      if (!isSnooze && !nextDate.isAfter(now)) {
        nextDate = DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day + 1,
          hm.hour,
          hm.minute,
        );
      }
      return nextDate;
    }

    // Rattrapage par blocs de semaines (alignement createdFor)
    final daysSinceCreation = now.difference(baseCreatedForLocal).inDays;
    if (daysSinceCreation > 0) {
      final weeksSinceCreation = daysSinceCreation ~/ 7;
      final missedBlocks = weeksSinceCreation ~/ recurrenceWeeks;
      nextDate =
          nextDate.add(Duration(days: missedBlocks * recurrenceWeeks * 7));
    }

    bool dayAllowed(DateTime d) {
      if (isDaily) return true;
      if (isWeeklyMatrix) {
        // weekday: 1=lundi ... 7=dimanche
        return selectedDays[d.weekday - 1];
      }
      return true;
    }

    bool weekAllowed(DateTime d) {
      final weeksFromCreation = d.difference(baseCreatedForLocal).inDays ~/ 7;
      return (weeksFromCreation % recurrenceWeeks) == 0;
    }

    if (!nextDate.isAfter(now)) {
      nextDate = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        hm.hour,
        hm.minute,
      ).add(const Duration(days: 1));
    }

    int guard = 0;
    while (nextDate.isBefore(now) ||
        !dayAllowed(nextDate) ||
        !weekAllowed(nextDate)) {
      // Semaine invalide → sauter au prochain bloc valide
      if (!weekAllowed(nextDate)) {
        final weeksFromCreation =
            nextDate.difference(baseCreatedForLocal).inDays ~/ 7;
        final delta =
            (recurrenceWeeks - (weeksFromCreation % recurrenceWeeks)) %
                recurrenceWeeks;
        nextDate = DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day + delta * 7,
          hm.hour,
          hm.minute,
        );
        continue;
      }
      // Sinon avancer d'un jour
      nextDate = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day + 1,
        hm.hour,
        hm.minute,
      );

      if (++guard > 4000) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('AlarmModel.getNextOccurrence: guard hit, check data');
        }
        break;
      }
    }

    return nextDate;
  }
}
