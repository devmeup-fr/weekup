class Player {
  String id;
  String name;
  String email;
  int ranking; // Classement global
  int wins;
  int losses;

  Player({
    required this.id,
    required this.name,
    required this.email,
    this.ranking = 0,
    this.wins = 0,
    this.losses = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      ranking: json['ranking'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'ranking': ranking,
      'wins': wins,
      'losses': losses,
    };
  }
}
