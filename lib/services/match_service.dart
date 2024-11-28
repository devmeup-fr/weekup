import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_model.dart';

class MatchService {
  final CollectionReference _matchCollection =
      FirebaseFirestore.instance.collection('matches');

  Future<List<Match>> getMatches() async {
    final querySnapshot = await _matchCollection.get();
    return querySnapshot.docs
        .map((doc) => Match.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> createMatch(Match match) async {
    await _matchCollection.doc(match.id).set(match.toJson());
  }

  Future<void> updateMatch(Match match) async {
    await _matchCollection.doc(match.id).update(match.toJson());
  }

  Future<void> deleteMatch(String matchId) async {
    await _matchCollection.doc(matchId).delete();
  }
}
