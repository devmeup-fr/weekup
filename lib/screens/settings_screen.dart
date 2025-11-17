import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text('À configurer…', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
