class Tournament {
  String id;
  String name;
  DateTime date;
  String format;
  List<String> participants; // IDs des joueurs
  String status; // ex. "En cours", "Terminé", "Planifié"

  Tournament({
    required this.id,
    required this.name,
    required this.date,
    required this.format,
    required this.participants,
    required this.status,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      format: json['format'],
      participants: List<String>.from(json['participants']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'format': format,
      'participants': participants,
      'status': status,
    };
  }
}
