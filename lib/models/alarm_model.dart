class AlarmModel {
  int? id;
  String? title;
  DateTime time;
  bool isActive;
  bool loopAudio;
  bool vibrate;
  double? volume;
  List<bool> selectedDays;
  int recurrenceWeeks;

  AlarmModel({
    this.id,
    this.title,
    required this.time,
    this.isActive = true,
    this.loopAudio = true,
    this.vibrate = true,
    this.volume,
    this.selectedDays = const [],
    this.recurrenceWeeks = 1,
  });

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
      'selectedDays': selectedDays,
      'recurrenceWeeks': recurrenceWeeks,
    };
  }

  // Convert Map to Alarm object
  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id'] as int,
      title: map['title'] as String,
      time: DateTime.parse(map['time'] as String),
      isActive: map['isActive'] as bool,
      loopAudio: map['loopAudio'] as bool,
      vibrate: map['vibrate'] as bool,
      volume: (map['volume'] as num?)?.toDouble(),
      selectedDays: (map['selectedDays'] as List<dynamic>)
          .map((day) => day as bool)
          .toList(),
      recurrenceWeeks: map['recurrenceWeeks'] as int,
    );
  }

  /// Calculate the next occurrence of the alarm
  DateTime? getNextOccurrence() {
    if (!isActive || selectedDays.every((day) => !day)) {
      return null; // Alarm is inactive or no days selected
    }

    final now = DateTime.now();
    DateTime nextDate =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Check today
    if (selectedDays[now.weekday - 1] && now.isBefore(nextDate)) {
      return nextDate;
    }

    // Check subsequent days
    for (int i = 1; i <= 7; i++) {
      final nextWeekDay = (now.weekday - 1 + i) % 7; // Circular week
      if (selectedDays[nextWeekDay]) {
        nextDate = nextDate.add(Duration(days: i));
        break;
      }
    }

    return nextDate;
  }
}
