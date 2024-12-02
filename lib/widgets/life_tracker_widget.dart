import 'dart:async';

import 'package:flutter/material.dart';

class LifeTrackerWidget extends StatefulWidget {
  final String playerName;
  final Color backgroundColor;
  final int initialLife;
  final void Function(int amount) onLifeChanged;

  const LifeTrackerWidget({
    super.key,
    required this.playerName,
    required this.backgroundColor,
    this.initialLife = 40,
    required this.onLifeChanged,
  });

  @override
  LifeTrackerWidgetState createState() => LifeTrackerWidgetState();
}

class LifeTrackerWidgetState extends State<LifeTrackerWidget> {
  late int _currentLife;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _currentLife = widget.initialLife;
  }

  void _adjustLife(int amount) {
    setState(() {
      // Vérifie si la vie ne descend pas en dessous de -20
      if (_currentLife + amount >= -20) {
        _currentLife += amount;
        widget.onLifeChanged(amount);
      }
    });
  }

  void resetLife() {
    setState(() {
      _currentLife = 40;
    });
  }

  void _startLongPressTimer(int amount) {
    _adjustLife(amount);
    // Start a timer that triggers every second while the user is pressing
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _adjustLife(amount); // Adjust life by 5 every second
    });
  }

  void _stopLongPressTimer() {
    // Cancel the timer when the user releases the press
    _longPressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _adjustLife(1),
        onLongPressStart: (details) =>
            _startLongPressTimer(5), // Start timer on long press
        onLongPressEnd: (_) =>
            _stopLongPressTimer(), // Stop timer when long press ends
        onLongPressCancel: () =>
            _stopLongPressTimer(), // Stop timer if the press is canceled
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
                        fontSize: 150,
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
                    onLongPressStart: (details) => _startLongPressTimer(
                        -5), // Start timer to subtract life
                    onLongPressEnd: (_) => _stopLongPressTimer(),
                    onLongPressCancel: () => _stopLongPressTimer(),
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
                    onLongPressStart: (details) =>
                        _startLongPressTimer(5), // Start timer to add life
                    onLongPressEnd: (_) => _stopLongPressTimer(),
                    onLongPressCancel: () => _stopLongPressTimer(),
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
