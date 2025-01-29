class AlarmModel {
  int? id;
  String? title;
  DateTime time;
  bool isActive;
  bool loopAudio;
  bool vibrate;
  double? volume;
  String assetAudio;
  List<bool> selectedDays;
  int recurrenceWeeks;
  DateTime createdAt;
  DateTime? createdFor;

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
    DateTime? createdAt, // Default to now if not provided
    DateTime? createdFor,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Alarm object to Map (for SharedPreferences storage)
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
      'createdAt': createdAt.toIso8601String(),
      'createdFor': createdFor?.toIso8601String(),
    };
  }

  // Convert Map to Alarm object
  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    String? createdFor = map['createdFor'] as String?;

    return AlarmModel(
      id: map['id'] as int?,
      title: map['title'] as String?,
      time: DateTime.parse(map['time'] as String),
      isActive: map['isActive'] as bool,
      loopAudio: map['loopAudio'] as bool,
      vibrate: map['vibrate'] as bool,
      volume: (map['volume'] as num?)?.toDouble(),
      assetAudio: map['assetAudio'] as String,
      selectedDays: (map['selectedDays'] as List<dynamic>)
          .map((day) => day as bool)
          .toList(),
      recurrenceWeeks: map['recurrenceWeeks'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      createdFor: createdFor != null ? DateTime.parse(createdFor) : null,
    );
  }

  bool isAllDaysFalse() {
    return selectedDays.every((day) => !day);
  }

  /// Calculate the next occurrence of the alarm considering past missed alarms.
  DateTime? getNextOccurrence() {
    if (!isActive) {
      return null; // Alarm is inactive
    }
    DateTime dateInit = createdFor ?? createdAt;

    final now = DateTime.now();
    DateTime nextDate = DateTime(
      dateInit.year,
      dateInit.month,
      dateInit.day,
      time.hour,
      time.minute,
    );

    // Considérer tous les jours comme actifs si `selectedDays` est entièrement faux
    final allDaysSelected = isAllDaysFalse();

    // Calculer la différence totale en jours depuis la création
    final totalDaysSinceCreation = now.difference(dateInit).inDays;

    // Vérifie si des occurrences auraient dû être déclenchées dans le passé
    if (totalDaysSinceCreation > 0) {
      final weeksSinceCreation = totalDaysSinceCreation ~/ 7;
      final missedOccurrences = weeksSinceCreation ~/ recurrenceWeeks;

      // Ajuster `nextDate` si des occurrences ont été manquées
      nextDate =
          time.add(Duration(days: missedOccurrences * recurrenceWeeks * 7));
    }

    // Avancer jusqu'à la prochaine occurrence valide
    while (nextDate.isBefore(now) ||
        !(allDaysSelected || selectedDays[nextDate.weekday - 1])) {
      nextDate = nextDate.add(Duration(days: 1)); // Vérifier le jour suivant

      // Vérifier la condition de récurrence
      final daysFromCreation = nextDate.difference(dateInit).inDays;
      if ((daysFromCreation ~/ 7) % recurrenceWeeks != 0) {
        // Sauter aux prochaines semaines valides
        final weeksToAdd =
            recurrenceWeeks - (daysFromCreation ~/ 7) % recurrenceWeeks;
        nextDate = nextDate.add(Duration(days: weeksToAdd * 7));
      }
    }

    return nextDate;
  }
}
