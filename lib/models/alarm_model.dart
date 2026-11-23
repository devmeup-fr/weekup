import 'package:weekup/utils/holidays.dart';

/// Raison pour laquelle une occurrence prévue ne sonnera pas.
enum OccurrenceExclusion { skipped, holiday, paused }

class Occurrence {
  final DateTime date;
  final OccurrenceExclusion? excludedBy;

  const Occurrence(this.date, [this.excludedBy]);

  bool get rings => excludedBy == null;
}

class AlarmModel {
  int? id;
  String? title;

  /// Seules l'heure et la minute de `time` sont utilisées pour la sonnerie.
  DateTime time;

  bool isActive;
  bool loopAudio;
  bool vibrate;
  double? volume; // 0.0..1.0
  String assetAudio;

  /// Matrice hebdo de 7 booléens (lun..dim) :
  /// - 7 booléens tous à false => ONE-SHOT (jour de référence = createdFor)
  /// - Au moins un true       => hebdo sur ces jours-là
  /// - Liste vide             => quotidien (tous les jours)
  List<bool> selectedDays;

  /// Récurrence en semaines (1 = chaque semaine, 2 = toutes les 2 semaines, …)
  /// alignée sur les semaines calendaires (lundi) de `createdFor`.
  int recurrenceWeeks;

  /// Dates persistées en UTC.
  /// `createdAt` = dernier enregistrement / activation.
  /// `createdFor` = jour de la sonnerie (one-shot) ou date de début (hebdo).
  DateTime createdAt;
  DateTime? createdFor;

  /// Occurrences antérieures ou égales à cette date sont ignorées
  /// ("passer la prochaine alarme").
  DateTime? skippedUntil;

  /// Ne pas sonner les jours fériés (alarmes récurrentes uniquement).
  bool skipHolidays;

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
    this.skippedUntil,
    this.skipHolidays = false,
    this.isSnooze = false,
    this.countSnooze = 0,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        createdFor = (createdFor ?? DateTime.now()).toUtc();

  // --------------------------
  // Helpers de sémantique jours
  // --------------------------

  /// true si `selectedDays` contient 7 valeurs (lun..dim)
  bool get isWeeklyMatrix => selectedDays.length == 7;

  /// true si quotidien (aucune matrice fournie ou tous les jours cochés)
  bool get isDaily =>
      selectedDays.isEmpty || (isWeeklyMatrix && selectedDays.every((d) => d));

  /// true si ONE-SHOT (matrice 7 éléments et tous false)
  bool get isOneShot => isWeeklyMatrix && selectedDays.every((d) => !d);

  bool get hasTitle => title != null && title!.trim().isNotEmpty;

  /// La prochaine occurrence est actuellement sautée.
  bool isSkipping({DateTime? now}) {
    if (skippedUntil == null || isOneShot) return false;
    return skippedUntil!.isAfter(now ?? DateTime.now());
  }

  AlarmModel copy() => AlarmModel.fromMap(toMap());

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
      'skippedUntil': skippedUntil?.toUtc().toIso8601String(),
      'skipHolidays': skipHolidays,
      'isSnooze': isSnooze,
      'countSnooze': countSnooze,
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    final rawSelected = (map['selectedDays'] as List<dynamic>? ?? [])
        .map((e) => e as bool)
        .toList();

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
      recurrenceWeeks: ((map['recurrenceWeeks'] as int?) ?? 1).clamp(1, 52),
      createdAt: DateTime.parse(map['createdAt'] as String),
      createdFor: (map['createdFor'] != null)
          ? DateTime.parse(map['createdFor'] as String)
          : null,
      skippedUntil: (map['skippedUntil'] != null)
          ? DateTime.parse(map['skippedUntil'] as String)
          : null,
      skipHolidays: map['skipHolidays'] as bool? ?? false,
      isSnooze: map['isSnooze'] as bool? ?? false,
      countSnooze: map['countSnooze'] as int? ?? 0,
    );
  }

  // --------------------------
  // Calcul des occurrences (en heure locale, jour par jour pour être
  // insensible aux changements d'heure)
  // --------------------------

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  static int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  DateTime _at(DateTime day) {
    final hm = time.toLocal();
    return DateTime(day.year, day.month, day.day, hm.hour, hm.minute);
  }

  bool _dayAllowed(DateTime d) {
    if (!isWeeklyMatrix) return true;
    return selectedDays[d.weekday - 1];
  }

  /// Date unique d'une alarme one-shot : premier hh:mm à partir du jour
  /// `createdFor`, strictement après le dernier enregistrement (`createdAt`).
  DateTime? oneShotDate() {
    if (!isOneShot) return null;
    final saved = createdAt.toLocal();
    final ref = (createdFor ?? createdAt).toLocal();
    final day = _day(ref).isBefore(_day(saved)) ? _day(saved) : _day(ref);
    var target = _at(day);
    if (!target.isAfter(saved)) {
      target = _at(DateTime(day.year, day.month, day.day + 1));
    }
    return target;
  }

  /// Une alarme one-shot dont l'heure est passée.
  bool isExpired({DateTime? now}) {
    if (!isOneShot) return false;
    final date = oneShotDate();
    return date != null && !date.isAfter(now ?? DateTime.now());
  }

  /// Occurrences prévues par les jours / semaines, à partir du jour `from`,
  /// chacune marquée de son éventuelle exclusion. Les alarmes ponctuelles et
  /// les rappels différés ne sont pas concernés par les exclusions.
  ///
  /// [resumeAt] : fin du mode vacances (les récurrentes reprennent à cette date).
  Iterable<Occurrence> _schedule(DateTime from, {DateTime? resumeAt}) sync* {
    if (isOneShot) {
      final date = oneShotDate()!;
      if (!_day(date).isBefore(_day(from))) yield Occurrence(date);
      return;
    }

    final start = (createdFor ?? createdAt).toLocal();
    final anchorWeek = _weekStart(_day(start));
    final first = _day(from).isBefore(_day(start)) ? _day(start) : _day(from);
    final skip = skippedUntil?.toLocal();
    final weeks = recurrenceWeeks < 1 ? 1 : recurrenceWeeks;

    // Borne de sécurité (~2 ans) : une pause ou des exclusions peuvent
    // espacer fortement les occurrences.
    for (var i = 0; i < 800; i++) {
      final d = DateTime(first.year, first.month, first.day + i);
      if (!_dayAllowed(d)) continue;
      if ((_daysBetween(anchorWeek, d) ~/ 7) % weeks != 0) continue;

      final candidate = _at(d);
      OccurrenceExclusion? excluded;
      if (resumeAt != null && candidate.isBefore(resumeAt)) {
        excluded = OccurrenceExclusion.paused;
      } else if (skipHolidays && holidayOn(d) != null) {
        excluded = OccurrenceExclusion.holiday;
      } else if (skip != null && !candidate.isAfter(skip)) {
        excluded = OccurrenceExclusion.skipped;
      }
      yield Occurrence(candidate, excluded);
    }
  }

  /// Les `count` prochaines occurrences qui sonneront (triées), en tenant
  /// compte de :
  /// - one-shot (7×false) basé sur createdFor
  /// - hebdo via selectedDays (>=1 true), quotidien si selectedDays vide
  /// - récurrence toutes les N semaines alignée sur la semaine de createdFor
  /// - la date de début (createdFor), l'occurrence sautée (skippedUntil),
  ///   les jours fériés (skipHolidays) et le mode vacances ([resumeAt])
  List<DateTime> upcomingOccurrences(
    int count, {
    DateTime? now,
    DateTime? resumeAt,
  }) {
    if (!isActive || count <= 0) return const [];
    now ??= DateTime.now();
    return _schedule(now, resumeAt: isSnooze ? null : resumeAt)
        .where((o) => o.rings && o.date.isAfter(now!))
        .map((o) => o.date)
        .take(count)
        .toList();
  }

  /// Toutes les occurrences prévues entre `from` et `to` (exclues comprises),
  /// pour le planning.
  List<Occurrence> occurrencesBetween(
    DateTime from,
    DateTime to, {
    DateTime? resumeAt,
  }) {
    if (!isActive) return const [];
    return _schedule(from, resumeAt: isSnooze ? null : resumeAt)
        .where((o) => !o.date.isBefore(from))
        .takeWhile((o) => o.date.isBefore(to))
        .toList();
  }

  /// Prochaine occurrence, ou null si inactive / expirée.
  DateTime? getNextOccurrence({DateTime? now, DateTime? resumeAt}) {
    final next = upcomingOccurrences(1, now: now, resumeAt: resumeAt);
    return next.isEmpty ? null : next.first;
  }
}
