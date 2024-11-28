import 'package:flutter/material.dart';

class PlayerHeroSelector extends StatefulWidget {
  final List<String> players;
  final List<String> heroes;

  const PlayerHeroSelector(
      {super.key, required this.players, required this.heroes});

  @override
  _PlayerHeroSelectorState createState() => _PlayerHeroSelectorState();
}

class _PlayerHeroSelectorState extends State<PlayerHeroSelector> {
  String? _selectedPlayer;
  String? _selectedHero;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          hint: const Text("Sélectionner un joueur"),
          value: _selectedPlayer,
          onChanged: (value) {
            setState(() {
              _selectedPlayer = value;
            });
          },
          items: widget.players.map((player) {
            return DropdownMenuItem<String>(
              value: player,
              child: Text(player),
            );
          }).toList(),
        ),
        DropdownButton<String>(
          hint: const Text("Sélectionner un héros"),
          value: _selectedHero,
          onChanged: (value) {
            setState(() {
              _selectedHero = value;
            });
          },
          items: widget.heroes.map((hero) {
            return DropdownMenuItem<String>(
              value: hero,
              child: Text(hero),
            );
          }).toList(),
        ),
      ],
    );
  }
}
