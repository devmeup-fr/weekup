import 'package:flutter/material.dart';

class LifeTrackerWidget extends StatefulWidget {
  final String playerName;
  final int initialLife;

  const LifeTrackerWidget(
      {super.key, required this.playerName, this.initialLife = 40});

  @override
  _LifeTrackerWidgetState createState() => _LifeTrackerWidgetState();
}

class _LifeTrackerWidgetState extends State<LifeTrackerWidget> {
  late int _currentLife;

  @override
  void initState() {
    super.initState();
    _currentLife = widget.initialLife;
  }

  void _adjustLife(int amount) {
    setState(() {
      _currentLife += amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.playerName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Points de vie : $_currentLife',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _adjustLife(1),
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _adjustLife(-1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
