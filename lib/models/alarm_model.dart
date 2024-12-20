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
    };
  }

  // Convert Map to Alarm object
  factory AlarmModel.fromMap(Map<String, dynamic> map) {
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
    );
  }

  /// Calculate the next occurrence of the alarm
  DateTime? getNextOccurrence() {
    if (!isActive) {
      return null; // Alarm is inactive
    }

    final now = DateTime.now();
    DateTime nextDate =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Considérer tous les jours comme actifs si selectedDays est entièrement faux
    final allDaysSelected = selectedDays.every((day) => !day);

    // Nombre total de jours écoulés depuis la création
    final totalDaysSinceCreation = now.difference(createdAt).inDays;

    // Vérifie si la semaine actuelle est incluse dans la récurrence
    final currentWeekOffset = totalDaysSinceCreation ~/ 7;
    if (currentWeekOffset % recurrenceWeeks != 0) {
      // Passer à la prochaine occurrence valide dans la récurrence
      final weeksToAdd =
          recurrenceWeeks - (currentWeekOffset % recurrenceWeeks);
      nextDate = nextDate.add(Duration(days: weeksToAdd * 7));
    }

    // Vérifier si aujourd'hui est un jour actif
    if ((allDaysSelected || selectedDays[now.weekday - 1]) &&
        now.isBefore(nextDate)) {
      return nextDate;
    }

    // Vérifier les jours suivants dans la semaine
    for (int i = 1; i <= 7; i++) {
      final nextWeekDay = (now.weekday - 1 + i) % 7; // Semaine circulaire
      if (allDaysSelected || selectedDays[nextWeekDay]) {
        nextDate = nextDate.add(Duration(days: i));

        // Vérifier à nouveau la condition de récurrence
        final futureTotalDays =
            nextDate.difference(createdAt).inDays; // Total de jours au futur
        if ((futureTotalDays ~/ 7) % recurrenceWeeks == 0) {
          break;
        }
      }
    }

    return nextDate;
  }
}
