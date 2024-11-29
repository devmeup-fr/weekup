import 'package:flutter/material.dart';

class LifeTrackerWidget extends StatefulWidget {
  final String playerName;
  final Color backgroundColor;
  final int initialLife;

  const LifeTrackerWidget({
    super.key,
    required this.playerName,
    required this.backgroundColor,
    this.initialLife = 40,
  });

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

  void _resetLife() {
    setState(() {
      _currentLife = widget.initialLife;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _adjustLife(1),
        onLongPress: () => _adjustLife(5),
        child: Stack(
          children: [
            Container(
              color: widget.backgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.playerName,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_currentLife',
                      style: const TextStyle(
                        fontSize: 60,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _adjustLife(-1),
                    onLongPress: () => _adjustLife(-5),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _adjustLife(1),
                    onLongPress: () => _adjustLife(5),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          '+',
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
