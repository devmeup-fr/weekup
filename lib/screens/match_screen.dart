import 'package:flutter/material.dart';

import '../widgets/life_tracker_widget.dart';

class MatchScreen extends StatelessWidget {
  final String matchId;

  const MatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    final players = ['Joueur 1', 'Joueur 2'];

    return Scaffold(
      appBar: AppBar(title: Text("Match $matchId")),
      body: Column(
        children: players
            .map((player) => LifeTrackerWidget(playerName: player))
            .toList(),
      ),
    );
  }
}
