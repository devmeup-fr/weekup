import 'dart:convert';

class AlarmLogModel {
  final int id;
  final String title;
  final DateTime firedAt;
  final DateTime scheduledFor;
  final bool isSnooze;

  AlarmLogModel({
    required this.id,
    required this.title,
    required this.firedAt,
    required this.scheduledFor,
    this.isSnooze = false,
  });

  String toJson() {
    return jsonEncode({
      'id': id,
      'title': title,
      'firedAt': firedAt.toIso8601String(),
      'scheduledFor': scheduledFor.toIso8601String(),
      'isSnooze': isSnooze,
    });
  }

  factory AlarmLogModel.fromJson(Map<String, dynamic> j) {
    return AlarmLogModel(
      id: (j['id'] as num).toInt(),
      title: (j['title'] as String?) ?? '',
      firedAt: DateTime.parse(j['firedAt'] as String),
      scheduledFor: DateTime.parse(j['scheduledFor'] as String),
      isSnooze: (j['isSnooze'] as bool?) ?? false,
    );
  }
}
