import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../services/player_service.dart';

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Joueurs")),
      body: FutureBuilder<List<Player>>(
        future: PlayerService().getPlayers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          final players = snapshot.data ?? [];
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return Card(
                child: ListTile(
                  title: Text(player.name),
                  subtitle: Text("Classement : ${player.ranking}"),
                  trailing: Text("V : ${player.wins} / D : ${player.losses}"),
                  onTap: () {
                    Navigator.pushNamed(context, '/player/${player.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
