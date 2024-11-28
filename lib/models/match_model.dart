enum MatchType {
  Friendly,
  Tournament,
  Draft,
  Sealed,
  Blitz,
  ClassicConstructed
}

class Match {
  String id;
  DateTime date;
  MatchType type;
  List<String> players; // IDs des joueurs
  String? tournamentId;
  String? winnerId;

  Match({
    required this.id,
    required this.date,
    required this.type,
    required this.players,
    this.tournamentId,
    this.winnerId,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      date: DateTime.parse(json['date']),
      type: MatchType.values[json['type']],
      players: List<String>.from(json['players']),
      tournamentId: json['tournamentId'],
      winnerId: json['winnerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.index,
      'players': players,
      'tournamentId': tournamentId,
      'winnerId': winnerId,
    };
  }
}
