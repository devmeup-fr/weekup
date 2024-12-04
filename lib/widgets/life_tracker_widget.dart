import 'dart:async';

import 'package:fab_dracailles/models/game_player_model.dart';
import 'package:flutter/material.dart';

class LifeTrackerWidget extends StatefulWidget {
  final GamePlayer gamePlayer;
  final bool invertMode;
  final void Function(int amount) onLifeChanged;

  const LifeTrackerWidget({
    super.key,
    required this.gamePlayer,
    this.invertMode = false,
    required this.onLifeChanged,
  });

  @override
  LifeTrackerWidgetState createState() => LifeTrackerWidgetState();
}

class LifeTrackerWidgetState extends State<LifeTrackerWidget> {
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
  }

  void _adjustLife(int amount) {
    setState(() {
      if (widget.gamePlayer.life + amount >= -10) {
        widget.gamePlayer.adjustLife(amount);
        widget.onLifeChanged(amount);
      }
    });
  }

  void resetLife() {
    setState(() {
      widget.gamePlayer.resetLife();
    });
  }

  void _startLongPressTimer(int amount) {
    _adjustLife(amount);
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _adjustLife(amount);
    });
  }

  void _stopLongPressTimer() {
    _longPressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform(
        alignment: Alignment.center,
        transform: widget.invertMode
            ? Matrix4.rotationZ(3.14159) // 180° rotation
            : Matrix4.identity(),
        child: Container(
          color: widget.gamePlayer.color,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.gamePlayer.name,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 40.0),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          widget.gamePlayer.life.toString(),
                          style: const TextStyle(
                            fontSize: 150,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _adjustLife(-1),
                      onLongPressStart: (_) => _startLongPressTimer(-5),
                      onLongPressEnd: (_) => _stopLongPressTimer(),
                      onLongPressCancel: () => _stopLongPressTimer(),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _adjustLife(1),
                      onLongPressStart: (_) => _startLongPressTimer(5),
                      onLongPressEnd: (_) => _stopLongPressTimer(),
                      onLongPressCancel: () => _stopLongPressTimer(),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
