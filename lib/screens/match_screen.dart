import 'package:flutter/material.dart';

import '../widgets/life_tracker_widget.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final List<Map<String, dynamic>> players = [
    {'name': 'Joueur 1', 'color': Colors.blueAccent},
    {'name': 'Joueur 2', 'color': Colors.purpleAccent},
  ];

  String _matchType = "Standard"; // Default match type
  final int _dieSides = 6; // Default die sides

  void _changeMatchType() {
    setState(() {
      _matchType = _matchType == "Standard" ? "Tournament" : "Standard";
    });
  }

  void _rollDie() {
    final rolledNumber =
        (1 + (DateTime.now().millisecondsSinceEpoch % _dieSides));
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Rolled a $_dieSides-sided Die"),
          content: Text("You rolled: $rolledNumber"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Players and their life trackers
          Column(
            children: [
              LifeTrackerWidget(
                playerName: players[0]['name'] as String,
                backgroundColor: players[0]['color'] as Color,
              ),
              LifeTrackerWidget(
                playerName: players[1]['name'] as String,
                backgroundColor: players[1]['color'] as Color,
              ),
            ],
          ),

          // Logo in the center with a circular background
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo_dracailles_min.png',
                height: 100,
              ),
            ),
          ),

          // Full width white zone with icons and buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reset Button Icon
                  IconButton(
                    onPressed: () {
                      // Reset players' health to initial
                      players[0]['life'] = 40;
                      players[1]['life'] = 40;
                    },
                    icon:
                        const Icon(Icons.refresh, size: 30, color: Colors.blue),
                    tooltip: "Reset Life",
                  ),

                  // Match Type Button Icon
                  IconButton(
                    onPressed: _changeMatchType,
                    icon: Icon(
                      _matchType == "Standard"
                          ? Icons.check_box
                          : Icons.toggle_off,
                      size: 30,
                      color: Colors.green,
                    ),
                    tooltip: "Change Match Type",
                  ),

                  // Die Roll Button Icon
                  IconButton(
                    onPressed: _rollDie,
                    icon: const Icon(Icons.casino,
                        size: 30, color: Colors.orange),
                    tooltip: "Roll a Die",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
