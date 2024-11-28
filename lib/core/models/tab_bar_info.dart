import 'package:flutter/material.dart';

class TabBarInfo {
  final String label;
  final IconData icon;
  final Widget screen;
  final Widget? badge;

  const TabBarInfo(
      {Key? key,
      required this.label,
      required this.icon,
      required this.screen,
      this.badge});
}
