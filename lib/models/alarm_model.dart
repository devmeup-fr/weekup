class AlarmModel {
  int? id;
  String title;
  String? subtitle;
  DateTime time;
  bool isActive;
  bool loopAudio;
  bool vibrate;
  double? volume;
  List<bool> selectedDays;
  int recurrenceWeeks;

  AlarmModel({
    this.id,
    required this.title,
    this.subtitle,
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
      'subtitle': subtitle,
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
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      time: DateTime.parse(map['time']),
      isActive: map['isActive'],
      loopAudio: map['loopAudio'],
      vibrate: map['vibrate'],
      volume: map['volume'],
      selectedDays: map['selectedDays'],
      recurrenceWeeks: map['recurrenceWeeks'],
    );
  }
}
