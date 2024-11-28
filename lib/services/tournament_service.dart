import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_model.dart';

class TournamentService {
  final CollectionReference _tournamentCollection =
      FirebaseFirestore.instance.collection('tournaments');

  Future<List<Tournament>> getTournaments() async {
    final querySnapshot = await _tournamentCollection.get();
    return querySnapshot.docs
        .map((doc) => Tournament.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTournament(Tournament tournament) async {
    await _tournamentCollection.doc(tournament.id).set(tournament.toJson());
  }

  Future<void> updateTournament(Tournament tournament) async {
    await _tournamentCollection.doc(tournament.id).update(tournament.toJson());
  }

  Future<void> deleteTournament(String tournamentId) async {
    await _tournamentCollection.doc(tournamentId).delete();
  }
}
