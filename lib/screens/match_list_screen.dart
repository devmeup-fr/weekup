import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Matchs FAB")),
      body: FutureBuilder<List<Match>>(
        future: MatchService().getMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          final matches = snapshot.data ?? [];
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return ListTile(
                title: Text("Match ${match.id} - ${match.type}"),
                subtitle: Text("Date : ${match.date}"),
                onTap: () {
                  Navigator.pushNamed(context, '/match/${match.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
