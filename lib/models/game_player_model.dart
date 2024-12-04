import 'package:flutter/material.dart';

class GamePlayer {
  String name;
  int life;
  Color color;

  GamePlayer({
    required this.name,
    this.life = 40,
    this.color = Colors.blueAccent,
  });

  void resetLife() {
    life = 40;
  }

  void adjustLife(int amount) {
    life += amount;
  }
}
