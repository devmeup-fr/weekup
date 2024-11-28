import 'package:flutter/material.dart';

import '../models/tournament_model.dart';
import '../services/tournament_service.dart';

class TournamentListScreen extends StatelessWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tournois")),
      body: FutureBuilder<List<Tournament>>(
        future: TournamentService().getTournaments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          final tournaments = snapshot.data ?? [];
          return ListView.builder(
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return Card(
                child: ListTile(
                  title: Text(tournament.name),
                  subtitle: Text("Date : ${tournament.date.toLocal()}"),
                  trailing: Text(tournament.status),
                  onTap: () {
                    Navigator.pushNamed(
                        context, '/tournament/${tournament.id}');
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
