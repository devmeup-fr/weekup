import 'dart:convert';

enum AlarmLogAction { ring, snooze, stop, missed }

class AlarmLogModel {
  final int id;
  final String title;
  final DateTime firedAt;
  final DateTime scheduledFor;
  final bool isSnooze;
  final AlarmLogAction action;

  AlarmLogModel({
    required this.id,
    required this.title,
    required this.firedAt,
    required this.scheduledFor,
    this.isSnooze = false,
    this.action = AlarmLogAction.ring,
  });

  String toJson() {
    return jsonEncode({
      'id': id,
      'title': title,
      'firedAt': firedAt.toIso8601String(),
      'scheduledFor': scheduledFor.toIso8601String(),
      'isSnooze': isSnooze,
      'action': action.name,
    });
  }

  factory AlarmLogModel.fromJson(Map<String, dynamic> j) {
    final firedAt = DateTime.parse(j['firedAt'] as String);
    final isSnooze = (j['isSnooze'] as bool?) ?? false;
    return AlarmLogModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: (j['title'] as String?) ?? '',
      firedAt: firedAt,
      scheduledFor: j['scheduledFor'] != null
          ? DateTime.parse(j['scheduledFor'] as String)
          : firedAt,
      isSnooze: isSnooze,
      action: AlarmLogAction.values.firstWhere(
        (a) => a.name == j['action'],
        orElse: () => isSnooze ? AlarmLogAction.snooze : AlarmLogAction.ring,
      ),
    );
  }
}
